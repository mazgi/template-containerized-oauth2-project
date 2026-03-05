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
  # Azure auto-generates an infrastructure resource group (ME_<env>_<rg>_<location>)
  # when infrastructure_subnet_id is set. Omitting this attribute causes Terraform
  # to detect drift (auto-generated name -> null) and force-replace the environment
  # on every apply.
  infrastructure_resource_group_name = "${var.app_unique_id}-env-infra-rg"

  # Explicitly declare the Consumption workload profile to prevent
  # force-replacement on every apply. Azure automatically assigns this
  # profile when infrastructure_subnet_id is set; omitting it causes
  # Terraform to detect drift and recreate the environment.
  # See: https://github.com/hashicorp/terraform-provider-azurerm/issues/27057
  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}
