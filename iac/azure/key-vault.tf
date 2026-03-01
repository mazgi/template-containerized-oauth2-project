# -----------------------------------------------------------------------------
# Key Vault — backend sensitive environment variables
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "${var.app_unique_id}-kv"
  location            = azurerm_resource_group.persistent.location
  resource_group_name = azurerm_resource_group.persistent.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Allow Terraform principal to manage secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover",
    ]
  }
}
