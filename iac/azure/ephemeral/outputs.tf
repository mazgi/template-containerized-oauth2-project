output "backend_url" {
  description = "Backend Container App URL"
  value       = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
}

output "web_url" {
  description = "Web Container App URL"
  value       = "https://${azurerm_container_app.web.ingress[0].fqdn}"
}

output "database_fqdn" {
  description = "PostgreSQL Flexible Server FQDN"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

# -----------------------------------------------------------------------------
# DNS
# -----------------------------------------------------------------------------

output "backend_fqdn" {
  description = "Backend DNS FQDN"
  value       = "${azurerm_dns_cname_record.backend.name}.${local.persistent.dns_zone_name}"
}

output "web_fqdn" {
  description = "Web DNS FQDN"
  value       = "${azurerm_dns_cname_record.web.name}.${local.persistent.dns_zone_name}"
}
