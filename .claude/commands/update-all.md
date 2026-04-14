Update all dependency versions across the project. Run each category in order, showing a summary of changes at the end.

## 1. Docker base images

Check and update `FROM` lines in all Dockerfiles under `Dockerfiles.d/`:

| Image | Files |
|-------|-------|
| `node:24-bookworm-slim` | backend/Dockerfile, web/Dockerfile, backend-build/Dockerfile, web-build/Dockerfile |
| `node:24` (if used) | Check all Dockerfiles |
| `mcr.microsoft.com/playwright:v<VERSION>` | web-e2e-tests/Dockerfile — **MUST update `web/e2e-tests/package.json` `@playwright/test` to the same version simultaneously** |
| `cgr.dev/chainguard/go` | web-build/Dockerfile |
| `gcr.io/distroless/static-debian12` | web-build/Dockerfile |
| `gcr.io/distroless/nodejs24-debian12` | backend-build/Dockerfile |
| `hashicorp/terraform` | iac/Dockerfile |

For Node.js, check the latest LTS major version. For Playwright, check `npm view @playwright/test version` and use that version for **both** the Docker image tag and the package.json pin — they must always be identical. For others, check their registries.

Only update when there is a newer stable version. Do not downgrade. Do not change `:latest` tags.

## 2. npm packages

For each of these directories, run `npm-check-updates --upgrade` then `pnpm install`:

- `web/app/`
- `web/e2e-tests/` — respect `.ncurc.json` (skips `@playwright/test`, which is updated with the Docker image in step 1)
- `backend/`

After updating, check that the `overrides` field in `web/app/package.json` is still needed by verifying whether the overridden vulnerability ranges still apply. Remove any overrides that are no longer necessary.

## 3. Terraform providers

Update provider version constraints in:

- `iac/aws/versions.tf` and `iac/aws/ephemeral/versions.tf`
- `iac/azure/versions.tf` and `iac/azure/ephemeral/versions.tf`
- `iac/google/versions.tf` and `iac/google/ephemeral/versions.tf`

Check the latest versions at the Terraform Registry:
- `hashicorp/aws` — https://registry.terraform.io/providers/hashicorp/aws/latest
- `hashicorp/azurerm` — https://registry.terraform.io/providers/hashicorp/azurerm/latest
- `hashicorp/google` — https://registry.terraform.io/providers/hashicorp/google/latest
- `hashicorp/random` — https://registry.terraform.io/providers/hashicorp/random/latest

Keep the `~>` pessimistic constraint operator but update the minor version floor.

## 4. GitHub Actions

Update action version tags in all files under `.github/workflows/` and `.github/actions/`:

Key actions to check:
- `actions/checkout`, `actions/cache`, `actions/setup-node`, `actions/setup-java`, `actions/upload-artifact`
- `docker/setup-qemu-action`, `docker/setup-buildx-action`, `docker/login-action`, `docker/build-push-action`
- `aws-actions/configure-aws-credentials`, `aws-actions/amazon-ecr-login`
- `azure/login`
- `google-github-actions/auth`, `google-github-actions/setup-gcloud`
- `hashicorp/setup-terraform`
- `dorny/paths-filter`

Check the latest major version tag for each on GitHub. Only bump major versions if there are no known breaking changes.

## 5. Summary

After all updates, show a table summarizing:
- What was updated (dependency name)
- Old version → New version
- Files changed

Remind the user to:
- Rebuild Docker images
- Run tests to verify nothing broke
- Review any major version bumps for breaking changes
