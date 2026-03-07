# -----------------------------------------------------------------------------
# Key Vault — backend sensitive environment variables
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

resource "random_string" "kv_suffix" {
  length  = 6
  lower   = true
  upper   = false
  special = false
}

resource "azurerm_key_vault" "main" {
  name                = "kv-${random_string.kv_suffix.result}"
  location            = azurerm_resource_group.persistent.location
  resource_group_name = azurerm_resource_group.persistent.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true
}
