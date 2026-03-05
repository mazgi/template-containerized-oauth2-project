resource "azurerm_postgresql_flexible_server" "main" {
  name                          = "${var.app_unique_id}-postgres"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  administrator_login           = var.database_user
  administrator_password        = var.database_password
  sku_name                      = var.database_sku
  version                       = "17"
  storage_mb                    = 32768
  zone                          = "1"
  backup_retention_days         = 7
  delegated_subnet_id           = azurerm_subnet.postgresql.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgresql.id
  public_network_access_enabled = false

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql]
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

locals {
  database_url = "postgresql://${var.database_user}:${var.database_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.database_name}?sslmode=require"
}
