# Wolfi-based image with shell, apk, and corepack included
FROM cgr.dev/chainguard/node:latest-dev

# Default user is nonroot; switch to root for global installs
USER root

RUN corepack enable \
    && npm install -g npm-check-updates sort-package-json

ARG UID=1000
ARG GID=1000
# Create a user matching the host user's UID/GID so that files written to
# bind-mounted volumes are owned by the correct user, and Node.js
# os.userInfo() resolves the user natively without /etc/passwd workarounds.
RUN apk add --no-cache shadow \
    && groupadd --gid ${GID} developer \
    && useradd --uid ${UID} --gid ${GID} --create-home developer

USER developer

# Prepare pnpm as the developer user so corepack stores it in the developer's
# home directory (~/.cache/node/corepack), which is baked into the image.
# This prevents corepack from downloading pnpm again at container runtime.
RUN corepack prepare pnpm@latest --activate

# Clear default ENTRYPOINT (/usr/bin/node) so compose "command: sh -c ..."
# is executed directly as the container command
ENTRYPOINT []
