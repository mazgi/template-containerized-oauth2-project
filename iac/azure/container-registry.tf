locals {
  # ACR name must be alphanumeric only — strip non-alphanumeric chars from app_unique_id
  acr_name = join("", regexall("[a-zA-Z0-9]+", var.app_unique_id))
}

resource "azurerm_container_registry" "main" {
  name                = local.acr_name
  location            = azurerm_resource_group.persistent.location
  resource_group_name = azurerm_resource_group.persistent.name
  sku                 = "Basic"
  admin_enabled       = true
}
