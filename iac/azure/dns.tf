# -----------------------------------------------------------------------------
# Azure DNS — DNS zone for azure.{app_unique_id}.{base_domain_name}
# -----------------------------------------------------------------------------

resource "azurerm_dns_zone" "main" {
  name                = "azure.${var.app_unique_id}.${var.base_domain_name}"
  resource_group_name = azurerm_resource_group.persistent.name
}
