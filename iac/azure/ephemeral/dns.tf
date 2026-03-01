# -----------------------------------------------------------------------------
# Azure DNS — DNS records for backend and web services
# Zone is created in the persistent layer.
# -----------------------------------------------------------------------------

resource "azurerm_dns_cname_record" "backend" {
  name                = "backend"
  zone_name           = local.persistent.dns_zone_name
  resource_group_name = local.persistent.dns_zone_resource_group_name
  ttl                 = 300
  record              = azurerm_container_app.backend.ingress[0].fqdn
}

resource "azurerm_dns_cname_record" "web" {
  name                = "web"
  zone_name           = local.persistent.dns_zone_name
  resource_group_name = local.persistent.dns_zone_resource_group_name
  ttl                 = 300
  record              = azurerm_container_app.web.ingress[0].fqdn
}
