# Production Dockerfile for the NestJS backend
# suitable for Cloud Run or any container-hosted environment.

# --- build stage -----------------------------------------------------------
# Use Debian-based Node image for the builder so that Prisma's schema-engine
# binary works on both amd64 and arm64 (Chainguard Wolfi lacks compatibility).
FROM node:24-bookworm-slim AS builder

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
