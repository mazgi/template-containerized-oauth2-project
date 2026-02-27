FROM node:24-alpine

RUN corepack enable && corepack prepare pnpm@latest --activate \
    && npm install -g npm-check-updates sort-package-json
