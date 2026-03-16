# Cloud Deployment

Deploy the backend and web services to AWS, Azure, or Google Cloud.

## Deployment methods

There are two ways to deploy:

- **Manual (Terraform CLI)** — Follow the provider-specific instructions linked below
- **CI/CD (GitHub Actions)** — Automate deployment via GitHub Actions. See [CI / GitHub Actions](ci.md)

## Production images

Before deploying, build production Docker images:

```sh
# Build backend image
docker build \
  -f Dockerfiles.d/backend-build/Dockerfile \
  -t myregistry/backend:latest \
  backend

# Build web image
docker build \
  -f Dockerfiles.d/web-build/Dockerfile \
  -t myregistry/web:latest \
  web/app
```

The resulting images contain compiled output and pruned dependencies. Push them to your registry of choice (ECR / ACR / Artifact Registry) before deploying. See the provider-specific docs for registry authentication and image push commands.

## Architecture: persistent + ephemeral layers

Each provider has two Terraform layers:

- **Persistent** (`iac/{provider}/`) — Container registries, IAM roles, VPC/subnets, and API enablement. Low cost (~$0-5/month). Always running.
- **Ephemeral** (`iac/{provider}/ephemeral/`) — Databases, compute services, VPC connectors. Higher cost (~$170-210/month). Create for testing, destroy when done.

Each ephemeral layer reads outputs from its persistent layer via `terraform_remote_state` (see `remote-state.tf` in each ephemeral directory).

## Secrets

Each provider stores 9 backend secrets (JWT keys, OAuth2 client secrets, etc.). The persistent layer creates empty secret containers; 8 of the 9 must be populated manually before deploying the ephemeral layer. See [Secrets Management](secrets.md) for the full list, naming conventions, and CLI commands.

## Terraform commands

All commands run via Docker Compose with `-chdir` to select the provider and layer. The `init` command requires `-backend-config` to inject the state backend location (see each provider guide for the specific flags):

```sh
docker compose --profile=iac run --rm iac terraform -chdir=<provider> init \
  -backend-config="..."
docker compose --profile=iac run --rm iac terraform -chdir=<provider> apply -var-file=terraform.tfvars

docker compose --profile=iac run --rm iac terraform -chdir=<provider>/ephemeral init \
  -backend-config="..."
docker compose --profile=iac run --rm iac terraform -chdir=<provider>/ephemeral apply -var-file=terraform.tfvars
docker compose --profile=iac run --rm iac terraform -chdir=<provider>/ephemeral destroy -var-file=terraform.tfvars
```

## Using staging environment variables

To use staging-specific files (`.staging.env` and `.staging.secrets.env`), pass them via `--env-file`:

```sh
docker compose --env-file .staging.env --env-file .staging.secrets.env \
  --profile=iac run --rm iac \
  terraform -chdir=<provider>/ephemeral apply
```

To force-update a resource when Terraform cannot detect changes (e.g. the image tag is unchanged but the image contents have been updated):

```sh
docker compose --env-file .staging.env --env-file .staging.secrets.env \
  --profile=iac run --rm iac \
  terraform -chdir=google/ephemeral apply -replace="google_cloud_run_v2_job.db_push"
```

## Provider guides

- [AWS ECS Express Mode](cloud-deployment-aws.md)
- [Azure Container Apps](cloud-deployment-azure.md)
- [Google Cloud Run](cloud-deployment-google.md)
