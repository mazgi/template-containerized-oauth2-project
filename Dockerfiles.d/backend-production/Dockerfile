# Production Dockerfile for the NestJS backend
# suitable for Cloud Run or any container-hosted environment.

# --- build stage -----------------------------------------------------------
# Wolfi-based image with shell, apk, and corepack included
FROM cgr.dev/chainguard/node:latest-dev AS builder

# Default user is nonroot; switch to root for global installs
USER root

# enable corepack so pnpm is available
RUN corepack enable && corepack prepare pnpm@latest --activate \
    && npm install -g npm-check-updates sort-package-json

WORKDIR /usr/src/app

# copy lockfile and package manifests first to take advantage of Docker cache
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY tsconfig.json nest-cli.json ./

# install all dependencies (including devtools) so we can build
RUN pnpm install --frozen-lockfile

# copy the rest of the backend sources
COPY . ./

# generate prisma client and compile typescript
RUN pnpm prisma:generate
RUN pnpm build

# remove dev dependencies to shrink the image (pnpm prune does this)
RUN pnpm prune --prod

# --- runtime stage ---------------------------------------------------------
FROM gcr.io/distroless/nodejs24-debian12:nonroot AS runner

WORKDIR /usr/src/app

# copy over only what we need from the builder
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/prisma ./prisma

# default port; Cloud Run will override via PORT env var
ENV PORT=4000
EXPOSE 4000

CMD ["dist/main"]
