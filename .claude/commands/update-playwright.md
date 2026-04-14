Update the Playwright version. Keep the Docker image tag and npm package in sync.

## Steps

1. Check the latest stable version: `npm view @playwright/test version`
2. Update these files to the new version:
   - `Dockerfiles.d/web-e2e-tests/Dockerfile`: update `mcr.microsoft.com/playwright:v<VERSION>` image tag
   - `web/e2e-tests/package.json`: update `@playwright/test` to the exact version (no `^` prefix)
3. Verify the Docker image tag exists by fetching `https://mcr.microsoft.com/v2/playwright/tags/list`.
4. Show old version → new version and remind the user to rebuild the Docker image.
