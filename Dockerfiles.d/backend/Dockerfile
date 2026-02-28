# Wolfi-based image with shell, apk, and corepack included
FROM cgr.dev/chainguard/node:latest-dev

# Default user is nonroot; switch to root for global installs
USER root

RUN corepack enable && corepack prepare pnpm@latest --activate \
    && npm install -g npm-check-updates sort-package-json

# Clear default ENTRYPOINT (/usr/bin/node) so compose "command: sh -c ..."
# is executed directly as the container command
ENTRYPOINT []
