Update base Docker image versions in all Dockerfiles under `Dockerfiles.d/`.

## Steps

1. List all `FROM` lines across `Dockerfiles.d/*/Dockerfile`.
2. For each image, check the latest stable version:
   - `node`: check latest LTS major at https://nodejs.org/en
   - `mcr.microsoft.com/playwright`: must match `@playwright/test` in `web/e2e-tests/package.json` — check `npm view @playwright/test version`
   - `gcr.io/distroless/*`: check https://github.com/GoogleContainerTools/distroless/releases
   - `cgr.dev/chainguard/go`: check https://images.chainguard.dev/directory/image/go/versions
   - `hashicorp/terraform`: check https://releases.hashicorp.com/terraform/
3. Update each `FROM` line. If a version is pinned elsewhere (e.g., Playwright in package.json), update those too.
4. Do not change `:latest` or `:nonroot` suffix tags. Only update the version portion.
5. Show a summary of changes and remind the user to rebuild.
