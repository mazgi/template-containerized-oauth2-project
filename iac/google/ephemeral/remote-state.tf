# Read outputs from the google persistent layer to get VPC network IDs.
# The backend configuration must match the google persistent layer's backend.

data "terraform_remote_state" "persistent" {
  backend = "gcs"
  config = {
    bucket = "REPLACE_WITH_YOUR_BUCKET_NAME"
    prefix = "terraform/state"
  }
}

locals {
  persistent       = data.terraform_remote_state.persistent.outputs
  frontend_url     = "https://web.google.${var.app_unique_id}.${var.base_domain_name}"
  backend_base_url = "https://backend.google.${var.app_unique_id}.${var.base_domain_name}"
}
