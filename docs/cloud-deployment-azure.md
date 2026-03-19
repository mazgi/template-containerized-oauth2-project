# Azure Container Apps

See [Cloud Deployment](cloud-deployment.md) for production image builds and architecture overview.

## Prerequisites

- An Azure subscription with appropriate permissions
- Azure CLI installed on the host
- Docker Engine + Docker Compose running (Terraform runs inside a container)

### Authenticate with Azure on the host

The `iac` container mounts `~/.azure` as read-only, so credentials configured on the host are automatically available inside the container.

**Option A — Interactive login**

```sh
az login
# A browser window opens. Sign in with your Azure account.
# This writes tokens to ~/.azure/.
```

**Option B — Service principal**

```sh
az login --service-principal \
  -u APP_ID -p CLIENT_SECRET --tenant TENANT_ID
```

**Register the Container Apps resource provider** (required once per subscription):

```sh
az provider register --namespace Microsoft.App
```

**Verify**

```sh
az account show
```

If this returns your subscription details, the credentials are ready and will be available in the `iac` container.

## 1. Create the Terraform state storage

```sh
az group create --name terraform-state-rg --location eastus
az storage account create --name YOUR_STORAGE_ACCOUNT --resource-group terraform-state-rg \
  --location eastus --sku Standard_LRS
az storage container create --name tfstate --account-name YOUR_STORAGE_ACCOUNT
```

Set the resource group and storage account names in `.env` as `AZURE_TF_STATE_RESOURCE_GROUP` and `AZURE_TF_STATE_STORAGE_ACCOUNT`, and pass them via `-backend-config` at `terraform init` time (see step 3), so you do not need to edit `versions.tf`.

## 2. Configure variables

```sh
cp iac/azure/terraform.tfvars.example iac/azure/terraform.tfvars
cp iac/azure/ephemeral/terraform.tfvars.example iac/azure/ephemeral/terraform.tfvars
```

Edit `iac/azure/terraform.tfvars`:

- `azure_subscription_id` — your Azure subscription ID
- `azure_location` — your Azure region (default: `eastus`)
- `base_domain_name` — your base domain (e.g. `example.com`)

Edit `iac/azure/ephemeral/terraform.tfvars`:

- `azure_subscription_id` — your Azure subscription ID
- `base_domain_name` — must match the persistent layer
- `database_password` — generate with `openssl rand -base64 32`
- OAuth2 client IDs (`apple_client_id`, `discord_client_id`, `gh_client_id`, `google_oauth_client_id`, `twitter_client_id`) and Apple config (`apple_team_id`, `apple_key_id`)
- `native_app_url_scheme` — e.g. `oauth2app`

> **Note:** JWT secrets, session secret, and OAuth2 client secrets are stored directly in Key Vault — populate them externally (CLI or Azure Portal), not via Terraform. Service URLs are derived from DNS: `https://{web,backend}.{app_unique_id}-azure.{base_domain_name}`.

## 3. Create persistent infrastructure and push images

```sh
source .env
docker compose --profile=iac run --rm iac terraform -chdir=azure init \
  -backend-config="resource_group_name=$AZURE_TF_STATE_RESOURCE_GROUP" \
  -backend-config="storage_account_name=$AZURE_TF_STATE_STORAGE_ACCOUNT"
docker compose --profile=iac run --rm iac terraform -chdir=azure apply -var-file=terraform.tfvars
```

Then build and push the production images (the registry URL comes from the persistent layer output):

```sh
# Authenticate Docker with ACR
az acr login --name YOUR_REGISTRY_NAME

# Build and push backend
docker build \
  -f Dockerfiles.d/backend-build/Dockerfile \
  -t YOUR_REGISTRY_NAME.azurecr.io/oauth2-app-backend:latest \
  backend
docker push YOUR_REGISTRY_NAME.azurecr.io/oauth2-app-backend:latest

# Build and push web
docker build \
  -f Dockerfiles.d/web-build/Dockerfile \
  -t YOUR_REGISTRY_NAME.azurecr.io/oauth2-app-web:latest \
  web/app
docker push YOUR_REGISTRY_NAME.azurecr.io/oauth2-app-web:latest
```

The ephemeral layer derives the registry URL from the persistent layer's ACR login server output. The `image_tag` variable defaults to `latest`.

## 4. Deploy ephemeral infrastructure

```sh
source .env
docker compose --profile=iac run --rm iac terraform -chdir=azure/ephemeral init \
  -backend-config="resource_group_name=$AZURE_TF_STATE_RESOURCE_GROUP" \
  -backend-config="storage_account_name=$AZURE_TF_STATE_STORAGE_ACCOUNT"
docker compose --profile=iac run --rm iac terraform -chdir=azure/ephemeral apply -var-file=terraform.tfvars
```

Service URLs are derived from DNS (`https://{web,backend}.{app_unique_id}-azure.{base_domain_name}`), so no second apply is needed. Verify the deployed URLs:

```sh
docker compose --profile=iac run --rm iac terraform -chdir=azure/ephemeral output
```

## 5. Tear down (after testing)

```sh
docker compose --profile=iac run --rm iac terraform -chdir=azure/ephemeral destroy -var-file=terraform.tfvars
```

Persistent ACR remains — images are available for the next test cycle.

## Resources created

| Layer | Resource | Description |
|-------|----------|-------------|
| Persistent | Resource Group | `oauth2-app-persistent-rg` for registry |
| Persistent | Container Registry | Docker image repository (Basic SKU) |
| Persistent | Key Vault | 9 backend secrets (empty containers) |
| Persistent | DNS Zone | `azure.{app_unique_id}.{base_domain_name}` |
| Ephemeral | Resource Group | `oauth2-app-rg` containing ephemeral resources |
| Ephemeral | Log Analytics Workspace | Container Apps logging |
| Ephemeral | VNet | Custom VNet with Container Apps (/23) + PostgreSQL (/24) subnets |
| Ephemeral | Private DNS Zone | PostgreSQL private DNS resolution |
| Ephemeral | PostgreSQL Flexible Server 17 | Database instance (`B_Standard_B1ms`) with VNet integration |
| Ephemeral | Container Apps Environment | VNet-integrated shared environment |
| Ephemeral | Container App (backend) | NestJS API on port 4000, scaling 1-2 replicas |
| Ephemeral | Container App (web) | Static site + reverse proxy on port 3000, scaling 1-2 replicas |
| Ephemeral | DNS records | CNAME records for backend and web services |

> **Note:** ACR uses admin credentials for simplicity. Switch to managed identity for production use.
