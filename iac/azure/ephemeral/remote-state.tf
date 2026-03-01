# Read outputs from the azure persistent layer to get ACR credentials.
# The backend configuration must match the azure persistent layer's backend.

data "terraform_remote_state" "persistent" {
  backend = "azurerm"
  config = {
    resource_group_name  = "REPLACE_WITH_YOUR_RESOURCE_GROUP"
    storage_account_name = "REPLACE_WITH_YOUR_STORAGE_ACCOUNT"
    container_name       = "tfstate"
    key                  = "terraform/state/terraform.tfstate"
  }
}

locals {
  persistent       = data.terraform_remote_state.persistent.outputs
  frontend_url     = "https://web.azure.${var.app_unique_id}.${var.base_domain_name}"
  backend_base_url = "https://backend.azure.${var.app_unique_id}.${var.base_domain_name}"
}
