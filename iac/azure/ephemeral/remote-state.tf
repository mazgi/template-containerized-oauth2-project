# Read outputs from the azure persistent layer to get ACR credentials.
# The backend configuration must match the azure persistent layer's backend.

data "terraform_remote_state" "persistent" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.azure_tf_state_resource_group
    storage_account_name = var.azure_tf_state_storage_account
    container_name       = "tfstate"
    key                  = "terraform/state/terraform.tfstate"
  }
}

locals {
  persistent       = data.terraform_remote_state.persistent.outputs
  frontend_url     = "https://web.${var.app_unique_id}-azure.${var.base_domain_name}"
  backend_base_url = "https://backend.${var.app_unique_id}-azure.${var.base_domain_name}"
}
