# Read outputs from the google persistent layer to get VPC network IDs.
# The backend configuration must match the google persistent layer's backend.

data "terraform_remote_state" "persistent" {
  backend = "gcs"
  config = {
    bucket = var.google_tf_state_bucket
    prefix = "terraform/state"
  }
}

locals {
  persistent       = data.terraform_remote_state.persistent.outputs
  gcp_region       = local.persistent.gcp_region
  gcp_zone         = local.persistent.gcp_zone
  frontend_url     = "https://web.${var.app_unique_id}-google.${var.base_domain_name}"
  backend_base_url = "https://backend.${var.app_unique_id}-google.${var.base_domain_name}"
}
