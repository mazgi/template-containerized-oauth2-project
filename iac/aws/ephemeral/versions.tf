# Before running `terraform init`, create a state backend:
#
# S3:
#   aws s3api create-bucket --bucket <BUCKET_NAME> --region us-east-1
#   aws s3api put-bucket-versioning --bucket <BUCKET_NAME> \
#     --versioning-configuration Status=Enabled
#
# Then update the backend block below.

terraform {
  required_version = ">= 1.5"

  backend "s3" {
    bucket = "REPLACE_WITH_YOUR_BUCKET_NAME"
    key    = "terraform/state/ephemeral/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.23"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
