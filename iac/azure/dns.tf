# -----------------------------------------------------------------------------
# Azure DNS — DNS zone for {app_unique_id}-azure.{base_domain_name}
# -----------------------------------------------------------------------------

resource "azurerm_dns_zone" "main" {
  name                = "${var.app_unique_id}-azure.${var.base_domain_name}"
  resource_group_name = azurerm_resource_group.persistent.name
}
