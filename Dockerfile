FROM node:22-bookworm

ARG PI_VERSION
RUN test -n "$PI_VERSION" || { echo "PI_VERSION build arg is required"; exit 1; }

RUN npm install -g "@mariozechner/pi-coding-agent@${PI_VERSION}" \
    && npm cache clean --force

# Pre-create mount points for plans and reports
RUN mkdir -p /working/plans /working/reports

ENTRYPOINT ["/bin/bash"]
