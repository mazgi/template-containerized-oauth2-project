resource "azurerm_resource_group" "main" {
  name     = "${var.app_unique_id}-rg"
  location = var.azure_location
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.app_unique_id}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "main" {
  name                       = "${var.app_unique_id}-env"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  infrastructure_subnet_id   = azurerm_subnet.container_apps.id
}
