# ============================================================
# Stage 1: builder — download and install toolchains
# ============================================================
FROM debian:bookworm-slim AS builder

# === Pinned versions (bump these) ===
ARG NODE_VERSION=24.15.0
ARG RUST_VERSION=1.95.0
ARG UV_VERSION=0.11.7
ARG PYTHON_VERSION=3.14.4
ARG RUFF_VERSION=0.15.12
ARG MYPY_VERSION=1.20.2
ARG PYTEST_VERSION=9.0.3
ARG ESLINT_VERSION=10.2.1
ARG PRETTIER_VERSION=3.8.3
ARG TYPESCRIPT_VERSION=6.0.3
ARG VITEST_VERSION=4.1.5
ARG ZOLA_VERSION=0.21.0

# Minimal deps for downloading and building
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Node.js — direct tarball, architecture-aware
RUN ARCH=$(uname -m) \
    && case "$ARCH" in \
         x86_64)  NODE_ARCH=x64   ;; \
         aarch64) NODE_ARCH=arm64 ;; \
         *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
       esac \
    && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" \
       | tar -xJ -C /usr/local --strip-components=1

# Rust — rustup with pinned stable version
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH="/usr/local/cargo/bin:${PATH}"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain "${RUST_VERSION}" --profile default \
    && rustup component add clippy rustfmt rust-analyzer

# uv — standalone installer (pinned)
RUN curl -LsSf "https://astral.sh/uv/${UV_VERSION}/install.sh" \
    | env UV_INSTALL_DIR=/usr/local/bin sh

# Python via uv (pinned)
ENV UV_PYTHON_INSTALL_DIR=/opt/python
RUN uv python install "${PYTHON_VERSION}" \
    && ln -s "$(uv python find "${PYTHON_VERSION}")" /usr/local/bin/python3 \
    && ln -s /usr/local/bin/python3 /usr/local/bin/python

# Python tools via uv (pinned)
ENV UV_TOOL_DIR=/opt/uv-tools \
    UV_TOOL_BIN_DIR=/usr/local/bin
RUN uv tool install "ruff==${RUFF_VERSION}" \
    && uv tool install "mypy==${MYPY_VERSION}" \
    && uv tool install "pytest==${PYTEST_VERSION}"

# Global npm tools (pinned)
RUN npm install -g \
    "eslint@${ESLINT_VERSION}" \
    "prettier@${PRETTIER_VERSION}" \
    "typescript@${TYPESCRIPT_VERSION}" \
    "vitest@${VITEST_VERSION}" \
    && npm cache clean --force

# Zola — direct release tarball, architecture-aware (pinned)
RUN ARCH=$(uname -m) \
    && case "$ARCH" in \
         x86_64)  ZOLA_ARCH=x86_64-unknown-linux-gnu  ;; \
         aarch64) ZOLA_ARCH=aarch64-unknown-linux-gnu ;; \
         *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
       esac \
    && curl -fsSL "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-${ZOLA_ARCH}.tar.gz" \
      | tar -xz -C /usr/local/bin zola \
    && chmod +x /usr/local/bin/zola


# ============================================================
# Stage 2: runtime — clean image with all tools
# ============================================================
FROM debian:bookworm-slim

ARG PI_VERSION
RUN test -n "$PI_VERSION" || { echo "PI_VERSION build arg is required"; exit 1; }

# Runtime apt packages — C++ toolchain, dev utilities, common build deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    jq \
    openssh-client \
    build-essential \
    cmake \
    clang \
    clang-tidy \
    clang-format \
    pkg-config \
    libssl-dev \
    ripgrep \
    fd-find \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s "$(which fdfind)" /usr/local/bin/fd

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# --- COPY toolchains from builder ---

# Node.js
COPY --from=builder /usr/local/bin/node /usr/local/bin/
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Zola
COPY --from=builder /usr/local/bin/zola /usr/local/bin/

# Rust
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo
COPY --from=builder /usr/local/rustup /usr/local/rustup
COPY --from=builder /usr/local/cargo /usr/local/cargo

# uv + Python + Python tools
ENV UV_PYTHON_INSTALL_DIR=/opt/python \
    UV_TOOL_DIR=/opt/uv-tools \
    UV_TOOL_BIN_DIR=/usr/local/bin
COPY --from=builder /usr/local/bin/uv /usr/local/bin/
COPY --from=builder /opt/python /opt/python
COPY --from=builder /opt/uv-tools /opt/uv-tools
COPY --from=builder /usr/local/bin/python3 /usr/local/bin/
COPY --from=builder /usr/local/bin/python /usr/local/bin/
COPY --from=builder /usr/local/bin/ruff /usr/local/bin/
COPY --from=builder /usr/local/bin/mypy /usr/local/bin/
COPY --from=builder /usr/local/bin/pytest /usr/local/bin/

# PATH — add cargo/bin for rustc, cargo, clippy, rustfmt, rust-analyzer
ENV PATH="/usr/local/cargo/bin:${PATH}"

# pi-coding-agent
RUN npm install -g "@mariozechner/pi-coding-agent@${PI_VERSION}" \
    && npm cache clean --force

# --- User and workspace setup ---

# Create pac user (UID 1001) — avoids root-owned files on host bind mounts
RUN groupadd -g 1001 pac \
    && useradd -m -u 1001 -g pac -d /home/pac -s /bin/bash pac

# Pre-create mount targets so bind mounts have directories to land on.
# /workspace is the ro workspace root; rw overlays land on subdirs.
# Home dirs are for agent state, caches, and credential mounts.
RUN mkdir -p \
    /workspace \
    /home/pac/.pi \
    /home/pac/.claude \
    /home/pac/.config/gh \
    /home/pac/.cache/uv \
    && chown -R pac:pac /home/pac /workspace

USER pac
ENTRYPOINT ["/bin/bash"]
