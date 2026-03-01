output "container_registry_login_server" {
  description = "ACR login server for docker push"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_admin_username" {
  description = "ACR admin username (used by ephemeral layer via remote state)"
  value       = azurerm_container_registry.main.admin_username
}

output "container_registry_admin_password" {
  description = "ACR admin password (used by ephemeral layer via remote state)"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Key Vault (referenced by ephemeral layer)
# -----------------------------------------------------------------------------

output "key_vault_id" {
  description = "Key Vault resource ID"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "Key Vault URI for secret references"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_tenant_id" {
  description = "Key Vault tenant ID"
  value       = azurerm_key_vault.main.tenant_id
}

# -----------------------------------------------------------------------------
# DNS (referenced by ephemeral layer)
# -----------------------------------------------------------------------------

output "dns_zone_name" {
  description = "Azure DNS zone name"
  value       = azurerm_dns_zone.main.name
}

output "dns_zone_resource_group_name" {
  description = "Resource group containing the DNS zone"
  value       = azurerm_resource_group.persistent.name
}

output "dns_zone_name_servers" {
  description = "Azure DNS zone name servers (delegate from parent zone)"
  value       = azurerm_dns_zone.main.name_servers
}
