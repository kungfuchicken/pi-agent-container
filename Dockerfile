FROM node:22-bookworm

ARG PI_VERSION
RUN test -n "$PI_VERSION" || { echo "PI_VERSION build arg is required"; exit 1; }

RUN npm install -g "@mariozechner/pi-coding-agent@${PI_VERSION}" \
    && npm cache clean --force

# Pre-create workspace layout: code goes in /workspace/project,
# ~working sits alongside it (mirrors host directory structure).
RUN mkdir -p /workspace/~working/plans /workspace/~working/reports /workspace/code

ENTRYPOINT ["/bin/bash"]
