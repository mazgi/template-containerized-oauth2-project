# Before running `terraform init`, create a state backend:
#
# GCS:
#   gsutil mb -p <PROJECT_ID> -l <REGION> gs://<BUCKET_NAME>
#   gsutil versioning set on gs://<BUCKET_NAME>
#
# Then update the backend block below.

terraform {
  required_version = ">= 1.5"

  backend "gcs" {
    bucket = "REPLACE_WITH_YOUR_BUCKET_NAME"
    prefix = "terraform/state/ephemeral"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = local.gcp_region
  zone    = local.gcp_zone
}
