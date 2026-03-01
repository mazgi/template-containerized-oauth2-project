resource "azurerm_resource_group" "persistent" {
  name     = "${var.app_unique_id}-persistent-rg"
  location = var.azure_location
}
