# CI / GitHub Actions

## Workflows

### E2E Tests (on push/PR to `main`)

| Workflow | Runner | Description |
|----------|--------|-------------|
| `backend.e2e-tests.yaml` | `ubuntu-latest` | Backend image + NestJS E2E tests via Docker Compose |
| `web.e2e-tests.yaml` | `ubuntu-latest` | Full stack + Playwright E2E tests |
| `android.e2e-tests.yaml` | `ubuntu-latest` | Backend + API-35 emulator (KVM + AVD cache) + Espresso |
| `macos-ios.e2e-tests.yaml` | `macos-15` | PostgreSQL + backend natively + XCUITest on iPhone 17 sim |
| `windows.e2e-tests.yaml` | `windows-2025` | PostgreSQL + backend natively + Appium E2E |

> **UID/GID in CI:** E2E workflows append `UID=$(id -u)` and `GID=$(id -g)` to `.secrets.env` before `docker compose build` so container user matches the runner (avoids `EACCES` errors).

### Production Builds

| Workflow | Description |
|----------|-------------|
| `backend.production-build.yaml` | Builds + pushes backend image to GHCR (+ ECR/ACR/Artifact Registry if configured). Passes `GIT_SHA` build-arg. |
| `web.production-build.yaml` | Builds + pushes web image to GHCR (+ ECR/ACR/Artifact Registry if configured). Passes `GIT_SHA` build-arg for `NEXT_PUBLIC_GIT_SHA`. |

### IaC (Terraform)

| Workflow | Description |
|----------|-------------|
| `iac.yaml` | Persistent layer: `dorny/paths-filter` → affected providers only. PR = plan, push to main = apply. |
| `iac.ephemeral.yaml` | Ephemeral layer: manual dispatch (plan/apply/destroy). |

## Setup

### E2E tests only

Copy `.example.secrets.env` → `.secrets.env`, fill values, then:

```sh
gh secret set --env Staging --env-file .staging.secrets.env
```

Replace `Staging` with `Production` for the production environment.

### Cloud deployment (E2E + production builds + IaC)

1. **E2E secrets** — same as above
2. **OIDC auth** — see [OIDC Setup](oidc-setup.md)
3. **Variables** — `cp .example.env .env`, edit, then `gh variable set --env Staging --env-file .staging.env`

### Reset secrets/variables

```sh
gh secret list --env Staging --json name --jq '.[].name' | xargs -I {} gh secret delete --env Staging {}
gh variable list --env Staging --json name --jq '.[].name' | xargs -I {} gh variable delete --env Staging {}
```

Replace `Staging` with `Production` for the production environment.

## Required Secrets

### E2E test secrets

| Secret | Description |
|--------|-------------|
| `AUTH_JWT_SECRET` | Access token signing — `openssl rand -base64 32` |
| `AUTH_JWT_REFRESH_SECRET` | Refresh token signing (must differ) |
| `AUTH_APPLE_CLIENT_ID` | Apple Services ID |
| `AUTH_APPLE_TEAM_ID` | Apple Developer Team ID |
| `AUTH_APPLE_KEY_ID` | Apple Sign In key ID |
| `AUTH_APPLE_PRIVATE_KEY` | Apple `.p8` key (newlines → `\n`) |
| `AUTH_DISCORD_CLIENT_ID` / `_SECRET` | Discord OAuth2 credentials |
| `AUTH_GITHUB_CLIENT_ID` / `_SECRET` | GitHub OAuth App credentials |
| `AUTH_GOOGLE_CLIENT_ID` / `_SECRET` | Google OAuth2 credentials |
| `AUTH_TWITTER_CLIENT_ID` / `_SECRET` | X (Twitter) OAuth2 credentials |
| `AUTH_SESSION_SECRET` | Session cookies (Twitter PKCE) — `openssl rand -base64 32` |

All OAuth2 secrets required so backend starts, even though Android/iOS/Windows E2E tests only exercise email/password auth.

### IaC secrets

Cloud auth uses OIDC (no static credentials). Only additional secret:

| Secret | Description |
|--------|-------------|
| `TF_VAR_database_password` | PostgreSQL password |

Other backend secrets are stored directly in cloud secret stores (not Terraform-managed).

## Required Variables

### Terraform state backends

| Variable | Example |
|----------|---------|
| `AWS_TF_STATE_BUCKET` | `my-tf-state-bucket` |
| `AWS_TF_STATE_REGION` | `us-east-1` |
| `AZURE_TF_STATE_RESOURCE_GROUP` | `terraform-state-rg` |
| `AZURE_TF_STATE_STORAGE_ACCOUNT` | `mytfstatestorage` |
| `AZURE_TF_STATE_LOCATION` | `eastus` |
| `GOOGLE_TF_STATE_BUCKET` | `my-tf-state-bucket` |
| `GOOGLE_TF_STATE_LOCATION` | `us-central1` |

### Cloud provider identifiers

| Variable | Example |
|----------|---------|
| `TF_VAR_app_unique_id` | `oauth2-app` |
| `TF_VAR_base_domain_name` | `example.com` |
| `TF_VAR_image_tag` | `latest` (optional) |
| `AWS_IAM_ROLE_ARN` | `arn:aws:iam::123456789012:role/github-actions-iac` |
| `ARM_CLIENT_ID` / `ARM_TENANT_ID` / `ARM_SUBSCRIPTION_ID` | Azure AD identifiers |
| `AZURE_CONTAINER_REGISTRY_NAME` | `oauth2appacr` |
| `GOOGLE_PROJECT_ID` | `my-project-id` |
| `GOOGLE_REGION` | `us-central1` |
| `GOOGLE_WORKLOAD_IDENTITY_PROVIDER` | `projects/.../providers/github` |
| `GOOGLE_SERVICE_ACCOUNT` | `github-actions@project.iam.gserviceaccount.com` |
