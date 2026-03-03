# Read outputs from the aws persistent layer to get IAM role ARNs.
# The backend configuration must match the aws persistent layer's backend.

data "terraform_remote_state" "persistent" {
  backend = "s3"
  config = {
    bucket = var.aws_tf_state_bucket
    key    = "terraform/state/terraform.tfstate"
    region = var.aws_tf_state_region
  }
}

locals {
  persistent       = data.terraform_remote_state.persistent.outputs
  frontend_url     = "https://web.aws.${var.app_unique_id}.${var.base_domain_name}"
  backend_base_url = "https://backend.aws.${var.app_unique_id}.${var.base_domain_name}"
}
