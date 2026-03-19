# Google Cloud Run

See [Cloud Deployment](cloud-deployment.md) for production image builds and architecture overview.

## Prerequisites

- A Google Cloud project with billing enabled
- `gcloud` CLI installed on the host
- Docker Engine + Docker Compose running (Terraform runs inside a container)

### Enable required APIs

The IAM Service Account Credentials API must be enabled for Workload Identity Federation (used by CI) to impersonate service accounts:

```sh
gcloud services enable iamcredentials.googleapis.com --project=YOUR_PROJECT_ID
```

### Authenticate with Google Cloud on the host

The `iac` container mounts `~/.config/gcloud` as read-only, so credentials configured on the host are automatically available inside the container.

**Option A — User account (interactive)**

```sh
gcloud auth login
gcloud auth application-default login
# A browser window opens for each command. Sign in with your Google account.
# This writes credentials to ~/.config/gcloud/.
```

**Option B — Service account**

```sh
gcloud auth activate-service-account \
  --key-file=path/to/key.json

export GOOGLE_APPLICATION_CREDENTIALS=path/to/key.json
```

**Set the default project**

```sh
gcloud config set project YOUR_PROJECT_ID
```

**Verify**

```sh
gcloud auth list
gcloud config get project
```

If these return your active account and project, the credentials are ready and will be available in the `iac` container.

## 1. Create the Terraform state bucket

```sh
gsutil mb -p YOUR_PROJECT_ID -l us-central1 gs://YOUR_BUCKET_NAME
gsutil versioning set on gs://YOUR_BUCKET_NAME
```

Set the bucket name in `.env` as `GOOGLE_TF_STATE_BUCKET` and pass it via `-backend-config` at `terraform init` time (see step 3), so you do not need to edit `versions.tf`.

## 2. Configure variables

```sh
cp iac/google/terraform.tfvars.example iac/google/terraform.tfvars
cp iac/google/ephemeral/terraform.tfvars.example iac/google/ephemeral/terraform.tfvars
```

Edit `iac/google/terraform.tfvars`:

- `gcp_project_id` — your GCP project ID
- `base_domain_name` — your base domain (e.g. `example.com`)

Edit `iac/google/ephemeral/terraform.tfvars`:

- `gcp_project_id` — your GCP project ID
- `base_domain_name` — must match the persistent layer
- `database_password` — generate with `openssl rand -base64 32`
- OAuth2 client IDs (`apple_client_id`, `discord_client_id`, `gh_client_id`, `google_oauth_client_id`, `twitter_client_id`) and Apple config (`apple_team_id`, `apple_key_id`)
- `native_app_url_scheme` — e.g. `oauth2app`

> **Note:** JWT secrets, session secret, and OAuth2 client secrets are stored directly in Secret Manager — populate them externally (CLI or GCP Console), not via Terraform. Service URLs are derived from DNS: `https://{web,backend}.{app_unique_id}-google.{base_domain_name}`.

## 3. Create persistent infrastructure and push images

```sh
source .env
docker compose --profile=iac run --rm iac terraform -chdir=google init \
  -backend-config="bucket=$GOOGLE_TF_STATE_BUCKET"
docker compose --profile=iac run --rm iac terraform -chdir=google apply -var-file=terraform.tfvars
```

Then build and push the production images (the registry URL comes from the persistent layer output):

```sh
# Authenticate Docker with Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Build and push backend
docker build \
  -f Dockerfiles.d/backend-build/Dockerfile \
  -t us-central1-docker.pkg.dev/YOUR_PROJECT/oauth2-app/backend:latest \
  backend
docker push us-central1-docker.pkg.dev/YOUR_PROJECT/oauth2-app/backend:latest

# Build and push web
docker build \
  -f Dockerfiles.d/web-build/Dockerfile \
  -t us-central1-docker.pkg.dev/YOUR_PROJECT/oauth2-app/web:latest \
  web/app
docker push us-central1-docker.pkg.dev/YOUR_PROJECT/oauth2-app/web:latest
```

The ephemeral layer derives the registry URL from the persistent layer's Artifact Registry output. The `image_tag` variable defaults to `latest`.

## 4. Deploy ephemeral infrastructure

```sh
source .env
docker compose --profile=iac run --rm iac terraform -chdir=google/ephemeral init \
  -backend-config="bucket=$GOOGLE_TF_STATE_BUCKET"
docker compose --profile=iac run --rm iac terraform -chdir=google/ephemeral apply -var-file=terraform.tfvars
```

Service URLs are derived from DNS (`https://{web,backend}.{app_unique_id}-google.{base_domain_name}`), so no second apply is needed. Verify the deployed URLs:

```sh
docker compose --profile=iac run --rm iac terraform -chdir=google/ephemeral output
```

## 5. Custom domain mapping

To map a custom domain to Cloud Run services, the IaC service account must be verified as a domain owner in Google Search Console.

1. Open [Google Search Console — Users & Permissions](https://search.google.com/search-console/users) for your domain property (e.g. `sc-domain:example.com`)
2. Click **Add user**
3. Enter the IaC service account email (e.g. `github-actions-iac@YOUR_PROJECT.iam.gserviceaccount.com`)
4. Set permission to **Owner**
5. Click **Add**

Without this step, `terraform apply` will fail with a domain ownership verification error when creating `google_cloud_run_domain_mapping` resources.

> **Note:** This is a Google Search Console setting, not a GCP IAM role. The service account needs to be registered as a property owner in Search Console, which is separate from any IAM permissions in the GCP project.

## 6. Tear down (after testing)

```sh
docker compose --profile=iac run --rm iac terraform -chdir=google/ephemeral destroy -var-file=terraform.tfvars
```

Persistent Artifact Registry and API enablement remain — images are available for the next test cycle.

## Resources created

| Layer | Resource | Description |
|-------|----------|-------------|
| Persistent | Project Services | API enablement (Cloud Run, SQL Admin, etc.) |
| Persistent | Artifact Registry | Docker image repository |
| Persistent | VPC, Subnets, Peering | Private network for Cloud SQL |
| Persistent | Secret Manager | 9 backend secrets (empty containers) |
| Persistent | DNS Zone | `google.{app_unique_id}.{base_domain_name}` |
| Ephemeral | VPC Connector | Cloud Run → VPC access (~$20/mo) |
| Ephemeral | Cloud SQL (PostgreSQL 17) | Database instance + database + user |
| Ephemeral | Cloud Run (backend) | NestJS API on port 4000 |
| Ephemeral | Cloud Run (web) | Static site + Go reverse proxy on port 3000 |
| Ephemeral | Cloud Run Job (db-migrate) | Runs `prisma migrate deploy` (triggered by CI) |
| Ephemeral | Cloud Run Job (db-push) | Runs `prisma db push` (triggered by CI) |
| Ephemeral | IAM bindings | Public access (`allUsers` → `roles/run.invoker`) |
| Ephemeral | DNS records | CNAME records for backend and web services |

> **Note:** Cloud SQL has `deletion_protection = false` for template convenience. Enable it for production use.
