# AWS ECS Express Mode

See [Cloud Deployment](cloud-deployment.md) for production image builds and architecture overview.

## Prerequisites

- An AWS account with appropriate permissions
- AWS CLI installed on the host
- Docker Desktop running (Terraform runs inside a container)

### Authenticate with AWS on the host

The `iac` container mounts `~/.aws` as read-only, so credentials configured on the host are automatically available inside the container.

**Option A — Long-lived credentials (IAM user)**

```sh
aws configure
# Enter your Access Key ID, Secret Access Key, default region, and output format.
# This writes to ~/.aws/credentials and ~/.aws/config.
```

**Option B — SSO / Identity Center**

```sh
aws configure sso
# Follow the prompts to set up an SSO profile.

aws sso login --profile YOUR_PROFILE
```

List available profiles to find the correct name:

```sh
aws configure list-profiles
```

When using an SSO profile, set the `AWS_PROFILE` environment variable so the container picks it up:

```sh
export AWS_PROFILE=YOUR_PROFILE
```

Or add `AWS_PROFILE` to your `.env` file — the `iac` service loads it via `env_file`.

**Verify**

```sh
aws sts get-caller-identity
```

If this returns your account and ARN, the credentials are ready and will be available in the `iac` container.

## 1. Create the Terraform state bucket

```sh
aws s3api create-bucket --bucket YOUR_BUCKET_NAME --region us-east-1
aws s3api put-bucket-versioning --bucket YOUR_BUCKET_NAME \
  --versioning-configuration Status=Enabled
```

The bucket name is passed via `-backend-config` at `terraform init` time (see step 3), so you do not need to edit `versions.tf`.

## 2. Configure variables

```sh
cp iac/aws/terraform.tfvars.example iac/aws/terraform.tfvars
cp iac/aws/ephemeral/terraform.tfvars.example iac/aws/ephemeral/terraform.tfvars
```

Edit `iac/aws/terraform.tfvars`:

- `aws_region` — your AWS region (default: `us-east-1`)

Edit `iac/aws/ephemeral/terraform.tfvars`:

- `aws_region` — your AWS region (default: `us-east-1`)
- `backend_image` / `web_image` — placeholder values are fine for the first run (ECR is created first)
- `database_password`, `jwt_secret`, `jwt_refresh_secret`, `session_secret` — generate with `openssl rand -base64 32`
- `frontend_url` / `backend_base_url` — use placeholder values for the first apply, then update after getting ECS Express URLs

## 3. Create persistent infrastructure and push images

```sh
docker compose --profile=iac run --rm iac terraform -chdir=aws init \
  -backend-config="bucket=YOUR_BUCKET_NAME"
docker compose --profile=iac run --rm iac terraform -chdir=aws apply -var-file=terraform.tfvars
```

Then build and push the production images:

```sh
# Authenticate Docker with ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build and push backend
docker build \
  -f Dockerfiles.d/backend-production/Dockerfile \
  -t ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/oauth2-app-backend:latest \
  backend
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/oauth2-app-backend:latest

# Build and push web
docker build \
  -f Dockerfiles.d/web-production/Dockerfile \
  -t ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/oauth2-app-web:latest \
  web/app
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/oauth2-app-web:latest
```

Update `backend_image` and `web_image` in `iac/aws/ephemeral/terraform.tfvars` with the full image URIs.

## 4. Deploy ephemeral infrastructure

```sh
docker compose --profile=iac run --rm iac terraform -chdir=aws/ephemeral init \
  -backend-config="bucket=YOUR_BUCKET_NAME"
docker compose --profile=iac run --rm iac terraform -chdir=aws/ephemeral apply -var-file=terraform.tfvars
```

After the first apply, get the ECS Express service URLs:

```sh
docker compose --profile=iac run --rm iac terraform -chdir=aws/ephemeral output
```

Copy the `backend_url` and `web_url` values into `iac/aws/ephemeral/terraform.tfvars` as `backend_base_url` and `frontend_url`, then apply again:

```sh
docker compose --profile=iac run --rm iac terraform -chdir=aws/ephemeral apply -var-file=terraform.tfvars
```

## 5. Tear down (after testing)

```sh
docker compose --profile=iac run --rm iac terraform -chdir=aws/ephemeral destroy -var-file=terraform.tfvars
```

Persistent ECR repositories remain — images are available for the next test cycle.

## Resources created

| Layer | Resource | Description |
|-------|----------|-------------|
| Persistent | ECR | Docker image repositories (backend + web) |
| Persistent | VPC | Custom VPC with public + private subnets across 2 AZs |
| Persistent | Internet Gateway | Public subnet internet access |
| Persistent | Security Groups | Backend (4000), Web (3000), RDS (5432) |
| Persistent | IAM Roles | ECS task execution role + ECS Express infrastructure role |
| Ephemeral | NAT Gateway | Private subnet outbound access (ECR image pull) |
| Ephemeral | RDS (PostgreSQL 17) | Database instance (`db.t4g.micro`) in private subnet |
| Ephemeral | ECS Express (backend) | NestJS API on port 4000, auto-scaling 1-2 tasks |
| Ephemeral | ECS Express (web) | Static site + reverse proxy on port 3000, auto-scaling 1-2 tasks |

> **Note:** RDS has `skip_final_snapshot = true` and NAT Gateway incurs cost even when idle. Adjust for production use.
