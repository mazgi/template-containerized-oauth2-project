# CI / GitHub Actions

## Workflows

### E2E Tests

Five workflows run on every push and pull request to `main`:

| Workflow | Runner | Description |
|----------|--------|-------------|
| `.github/workflows/backend.e2e-tests.yaml` | `ubuntu-latest` | Builds the backend image, runs NestJS E2E tests via `docker compose run` |
| `.github/workflows/web.e2e-tests.yaml` | `ubuntu-latest` | Starts the full stack via Docker Compose, runs Playwright E2E tests |
| `.github/workflows/android.e2e-tests.yaml` | `ubuntu-latest` | Starts the backend via Docker Compose, boots an API-35 emulator (KVM + AVD cache), runs Espresso E2E tests |
| `.github/workflows/macos-ios.e2e-tests.yaml` | `macos-15` | Starts PostgreSQL + backend natively, runs XCUITest E2E tests on iPhone 17 simulator |
| `.github/workflows/windows.e2e-tests.yaml` | `windows-2025` | Starts PostgreSQL + backend natively, builds and deploys WinUI app, runs Appium E2E tests |

### Production Builds

| Workflow | Runner | Description |
|----------|--------|-------------|
| `.github/workflows/backend.production-build.yaml` | `ubuntu-latest` | Builds and pushes backend Docker image to GHCR (+ ECR / ACR / Artifact Registry if configured) |
| `.github/workflows/web.production-build.yaml` | `ubuntu-latest` | Builds and pushes web Docker image to GHCR (+ ECR / ACR / Artifact Registry if configured) |

### IaC (Terraform)

Two workflows manage infrastructure across AWS, Azure, and GCP:

| Workflow | Runner | Description |
|----------|--------|-------------|
| `.github/workflows/iac.yaml` | `ubuntu-latest` | Validates/plans on PR, applies on main — container registries & API enablement |
| `.github/workflows/iac.ephemeral.yaml` | `ubuntu-latest` | Manual dispatch only (plan/apply/destroy) — VPC, DB, compute |

**How it works:**

- **`iac.yaml` (persistent):** `dorny/paths-filter` detects which providers changed; only affected providers run in the matrix. PR → plan only. Push to main → plan + apply. Manual dispatch → plan all providers.
- **`iac.ephemeral.yaml` (ephemeral):** Manual dispatch only — select a provider and action (plan/apply/destroy) from the Actions UI.

## Setup

### For E2E tests only

Only **Step 1** is required. The E2E test workflows need the same secrets as your local `.env` file.

#### Step 1: E2E test secrets

Copy `.env.example` → `.env`, fill in your values, then set them as GitHub Actions secrets:

```sh
cp .env.example .env
# Edit .env with your values
gh secret set --env-file .env
```

See [Required secrets — E2E test secrets](#e2e-test-secrets) for the full list.

### For cloud deployment (E2E tests + production builds + IaC)

All three steps are required.

#### Step 1: E2E test secrets

Same as above — see [For E2E tests only](#for-e2e-tests-only).

#### Step 2: OIDC authentication

Set up keyless authentication between GitHub Actions and your cloud provider(s). This is a one-time setup per provider.

See [OIDC Setup](oidc-setup.md) for step-by-step instructions for AWS, Azure, and GCP.

#### Step 3: GitHub Actions variables

Configure Terraform state backends, cloud provider identifiers, and app settings:

```sh
cp .github/.vars.example .github/.vars
# Edit .github/.vars with your values
gh variable set --env-file .github/.vars
```

See [Required variables](#required-variables) for the full list.

### Resetting secrets and variables

```sh
# Delete all secrets
gh secret list --json name --jq '.[].name' | xargs -I {} gh secret delete {}

# Delete all variables
gh variable list --json name --jq '.[].name' | xargs -I {} gh variable delete {}
```

## Required secrets

Add the following under **Settings > Secrets and variables > Actions** in the GitHub repository:

### E2E test secrets

| Secret | Description |
|--------|-------------|
| `AUTH_JWT_SECRET` | Signs access tokens — generate with `openssl rand -base64 32` |
| `AUTH_JWT_REFRESH_SECRET` | Signs refresh tokens — must differ from `AUTH_JWT_SECRET` |
| `AUTH_APPLE_CLIENT_ID` | Apple Services ID |
| `AUTH_APPLE_TEAM_ID` | Apple Developer Team ID |
| `AUTH_APPLE_KEY_ID` | Apple Sign In key ID |
| `AUTH_APPLE_PRIVATE_KEY` | Apple `.p8` private key content (newlines replaced with `\n`) |
| `AUTH_DISCORD_CLIENT_ID` | Discord OAuth2 Client ID |
| `AUTH_DISCORD_CLIENT_SECRET` | Discord OAuth2 Client Secret |
| `AUTH_GITHUB_CLIENT_ID` | GitHub OAuth App Client ID |
| `AUTH_GITHUB_CLIENT_SECRET` | GitHub OAuth App Client Secret |
| `AUTH_GOOGLE_CLIENT_ID` | Google OAuth2 Client ID |
| `AUTH_GOOGLE_CLIENT_SECRET` | Google OAuth2 Client Secret |
| `AUTH_TWITTER_CLIENT_ID` | X (Twitter) OAuth2 Client ID |
| `AUTH_TWITTER_CLIENT_SECRET` | X (Twitter) OAuth2 Client Secret |
| `AUTH_SESSION_SECRET` | Signs session cookies for Twitter PKCE — generate with `openssl rand -base64 32` |

`AUTH_JWT_SECRET` and `AUTH_JWT_REFRESH_SECRET` are required by all workflows. The OAuth2 secrets (Apple, Discord, GitHub, Google, Twitter, Session) are required by the Android, macOS/iOS, and Windows workflows so the NestJS backend starts successfully — even though those E2E tests only exercise email/password auth and the items API.

### IaC secrets

**Cloud authentication (OIDC):**

All three cloud providers use OIDC (OpenID Connect) for keyless authentication from GitHub Actions. No static credentials (access keys, client secrets, or JSON keys) are stored as secrets. Cloud identity variables are stored as GitHub Actions **variables** (not secrets). See [OIDC Setup](oidc-setup.md) for one-time setup instructions.

**Ephemeral-layer Terraform secrets:**

| Secret | Description |
|--------|-------------|
| `TF_VAR_database_password` | PostgreSQL password (used to construct `DATABASE_URL`) |

All other backend secrets (`AUTH_JWT_SECRET`, `AUTH_JWT_REFRESH_SECRET`, `AUTH_SESSION_SECRET`, OAuth2 client secrets) are populated directly in the cloud provider's secret store (AWS Secrets Manager / Azure Key Vault / GCP Secret Manager) — not managed by Terraform.

## Required variables

Add the following under **Settings > Variables > Actions**:

### Terraform state backends

| Variable | Used by | Example | Description |
|----------|---------|---------|-------------|
| `AWS_TF_STATE_BUCKET` | aws, aws/ephemeral | `my-tf-state-bucket` | S3 bucket name for AWS Terraform state |
| `AWS_TF_STATE_REGION` | aws, aws/ephemeral | `us-east-1` | S3 bucket region |
| `AZURE_TF_STATE_RESOURCE_GROUP` | azure, azure/ephemeral | `terraform-state-rg` | Resource group for Azure state storage |
| `AZURE_TF_STATE_STORAGE_ACCOUNT` | azure, azure/ephemeral | `mytfstatestorage` | Storage account for Azure state |
| `AZURE_TF_STATE_LOCATION` | azure, azure/ephemeral | `eastus` | Azure region for state storage (used by bootstrap action) |
| `GOOGLE_TF_STATE_BUCKET` | google, google/ephemeral | `my-tf-state-bucket` | GCS bucket name for Google Terraform state |
| `GOOGLE_TF_STATE_LOCATION` | google, google/ephemeral | `us-central1` | GCS bucket location (used by bootstrap action) |

### Ephemeral layer

Service URLs (`frontend_url`, `backend_base_url`) are derived as `https://{web,backend}.{cdp}.{app_unique_id}.{base_domain_name}`. Container image registry URLs are derived from the persistent layer's remote state (ECR / ACR / Artifact Registry outputs). Only the tag is configurable:

| Variable | Example | Description |
|----------|---------|-------------|
| `TF_VAR_base_domain_name` | `example.com` | Base domain for DNS and service URLs |
| `TF_VAR_image_tag` | `latest` | Container image tag (optional, defaults to `latest`) |

### Other

| Variable | Used by | Example | Description |
|----------|---------|---------|-------------|
| `TF_VAR_app_unique_id` | aws, aws/ephemeral, azure, azure/ephemeral, google, google/ephemeral | `oauth2-app` | Unique identifier used as a prefix for all resource names |
| `AWS_IAM_ROLE_ARN` | aws, aws/ephemeral, production builds | `arn:aws:iam::123456789012:role/github-actions-iac` | IAM role ARN with GitHub OIDC trust policy |
| `ARM_CLIENT_ID` | azure, azure/ephemeral, production builds | `00000000-0000-0000-0000-000000000000` | Azure AD application (client) ID |
| `ARM_TENANT_ID` | azure, azure/ephemeral, production builds | `00000000-0000-0000-0000-000000000000` | Azure AD tenant ID |
| `ARM_SUBSCRIPTION_ID` | azure, azure/ephemeral, production builds | `00000000-0000-0000-0000-000000000000` | Azure subscription ID |
| `GOOGLE_PROJECT_ID` | google, google/ephemeral | `my-project-id` | Google Cloud project ID |
| `GOOGLE_REGION` | google, google/ephemeral | `us-central1` | Google Cloud region (defaults to `us-central1` if not set) |
| `GOOGLE_WORKLOAD_IDENTITY_PROVIDER` | google, google/ephemeral, production builds | `projects/123456789/locations/global/workloadIdentityPools/github/providers/github` | Workload Identity Federation provider resource name |
| `GOOGLE_SERVICE_ACCOUNT` | google, google/ephemeral, production builds | `github-actions@project.iam.gserviceaccount.com` | Google Cloud service account email for impersonation |
| `AZURE_CONTAINER_REGISTRY_NAME` | azure | `oauth2appacr` | ACR name (used by azure persistent layer) |

## Deployment Workflow Order

Infrastructure must be deployed in a specific order because the ephemeral layer depends on resources and secrets created in earlier steps.

### 1. Deploy the persistent layer

```sh
# For each provider (aws / azure / google):
docker compose --profile=iac run --rm iac -chdir=<provider> init
docker compose --profile=iac run --rm iac -chdir=<provider> apply -var-file=terraform.tfvars
```

This creates container registries (ECR / ACR / Artifact Registry), secret store containers (Secrets Manager / Key Vault / Secret Manager), VPC/networking, and IAM resources.

### 2. Populate secrets in the cloud provider's secret store

After the persistent layer is up, manually set the following secrets via the cloud console, CLI, or CI pipeline:

| Secret | Description |
|--------|-------------|
| `jwt-secret` | Signs access tokens — generate with `openssl rand -base64 32` |
| `jwt-refresh-secret` | Signs refresh tokens — must differ from `jwt-secret` |
| `session-secret` | Signs session cookies (used by Twitter PKCE) — generate with `openssl rand -base64 32` |
| `apple-private-key` | Apple `.p8` private key content (newlines replaced with `\n`) |
| `discord-client-secret` | Discord OAuth2 Client Secret |
| `gh-client-secret` | GitHub OAuth App Client Secret |
| `google-client-secret` | Google OAuth2 Client Secret |
| `twitter-client-secret` | X (Twitter) OAuth2 Client Secret |

These secrets are **not managed by Terraform**. The ephemeral layer's compute resources (ECS / Container Apps / Cloud Run) reference them at runtime from the secret store.

> **Note:** `DATABASE_URL` is the only secret populated by Terraform because it depends on the database endpoint created in the ephemeral layer.

### 3. Deploy the ephemeral layer

```sh
docker compose --profile=iac run --rm iac -chdir=<provider>/ephemeral init
docker compose --profile=iac run --rm iac -chdir=<provider>/ephemeral apply -var-file=terraform.tfvars
```

This creates compute services, databases, and the `DATABASE_URL` secret version.
