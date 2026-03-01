# -----------------------------------------------------------------------------
# Key Vault — DATABASE_URL depends on the PostgreSQL endpoint so it must be
# managed here. All other secrets are populated externally (CI or manual).
# The Key Vault itself is created in the persistent layer.
# -----------------------------------------------------------------------------

# Managed identity for Container Apps to access Key Vault
resource "azurerm_user_assigned_identity" "backend" {
  name                = "${var.app_unique_id}-backend-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Grant the managed identity read access to Key Vault secrets
resource "azurerm_key_vault_access_policy" "backend" {
  key_vault_id = local.persistent.key_vault_id
  tenant_id    = local.persistent.key_vault_tenant_id
  object_id    = azurerm_user_assigned_identity.backend.principal_id

  secret_permissions = [
    "Get",
  ]
}

resource "azurerm_key_vault_secret" "backend_database_url" {
  name         = "database-url"
  value        = local.database_url
  key_vault_id = local.persistent.key_vault_id
}
