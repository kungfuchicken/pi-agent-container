FROM node:22-bookworm

ARG PI_VERSION
RUN test -n "$PI_VERSION" || { echo "PI_VERSION build arg is required"; exit 1; }

RUN npm install -g "@mariozechner/pi-coding-agent@${PI_VERSION}" \
    && npm cache clean --force

ENTRYPOINT ["/bin/bash"]
