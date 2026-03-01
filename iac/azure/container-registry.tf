resource "azurerm_container_registry" "main" {
  name                = var.azure_container_registry_name
  location            = azurerm_resource_group.persistent.location
  resource_group_name = azurerm_resource_group.persistent.name
  sku                 = "Basic"
  admin_enabled       = true
}
