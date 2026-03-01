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
  -f Dockerfiles.d/backend-production/Dockerfile \
  -t myregistry/backend:latest \
  backend

# Build web image
docker build \
  -f Dockerfiles.d/web-production/Dockerfile \
  -t myregistry/web:latest \
  web/app
```

The resulting images contain compiled output and pruned dependencies. Push them to your registry of choice (ECR / ACR / Artifact Registry) before deploying. See the provider-specific docs for registry authentication and image push commands.

## Architecture: persistent + ephemeral layers

Each provider has two Terraform layers:

- **Persistent** (`iac/{provider}/`) — Container registries, IAM roles, VPC/subnets, and API enablement. Low cost (~$0-5/month). Always running.
- **Ephemeral** (`iac/{provider}/ephemeral/`) — Databases, compute services, VPC connectors. Higher cost (~$170-210/month). Create for testing, destroy when done.

Each ephemeral layer reads outputs from its persistent layer via `terraform_remote_state` (see `remote-state.tf` in each ephemeral directory).

## Terraform commands

All commands run via Docker Compose with `-chdir` to select the provider and layer:

```sh
docker compose --profile=iac run --rm iac -chdir=<provider> init
docker compose --profile=iac run --rm iac -chdir=<provider> apply -var-file=terraform.tfvars

docker compose --profile=iac run --rm iac -chdir=<provider>/ephemeral init
docker compose --profile=iac run --rm iac -chdir=<provider>/ephemeral apply -var-file=terraform.tfvars
docker compose --profile=iac run --rm iac -chdir=<provider>/ephemeral destroy -var-file=terraform.tfvars
```

## Provider guides

- [AWS ECS Express Mode](cloud-deployment-aws.md)
- [Azure Container Apps](cloud-deployment-azure.md)
- [Google Cloud Run](cloud-deployment-google.md)
