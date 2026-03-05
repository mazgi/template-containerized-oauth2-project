resource "azurerm_container_app" "backend" {
  name                         = "${var.app_unique_id}-backend"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.backend.id]
  }

  registry {
    server               = local.persistent.container_registry_login_server
    username             = local.persistent.container_registry_admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = local.persistent.container_registry_admin_password
  }

  # --- Sensitive values from Key Vault ---
  # DATABASE_URL is managed by Terraform (depends on PostgreSQL endpoint).
  # All other secrets are populated externally (CI or manual).
  secret {
    name                = "database-url"
    identity            = azurerm_user_assigned_identity.backend.id
    key_vault_secret_id = azurerm_key_vault_secret.backend_database_url.versionless_id
  }
  secret {
    name                = "jwt-secret"
    identity            = azurerm_user_assigned_identity.backend.id
    key_vault_secret_id = "${local.persistent.key_vault_uri}secrets/jwt-secret"
  }
  secret {
    name                = "jwt-refresh-secret"
    identity            = azurerm_user_assigned_identity.backend.id
    key_vault_secret_id = "${local.persistent.key_vault_uri}secrets/jwt-refresh-secret"
  }
  secret {
    name                = "session-secret"
    identity            = azurerm_user_assigned_identity.backend.id
    key_vault_secret_id = "${local.persistent.key_vault_uri}secrets/session-secret"
  }
  secret {
    name                = "apple-private-key"
    identity            = azurerm_user_assigned_identity.backend.id
    key_vault_secret_id = "${local.persistent.key_vault_uri}secrets/apple-private-key"
  }
  secret {
    name                = "discord-client-secret"
    identity            = azurerm_user_assigned_identity.backend.id
    key_vault_secret_id = "${local.persistent.key_vault_uri}secrets/discord-client-secret"
  }
  secret {
    name                = "gh-client-secret"
    identity            = azurerm_user_assigned_identity.backend.id
    key_vault_secret_id = "${local.persistent.key_vault_uri}secrets/gh-client-secret"
  }
  secret {
    name                = "google-client-secret"
    identity            = azurerm_user_assigned_identity.backend.id
    key_vault_secret_id = "${local.persistent.key_vault_uri}secrets/google-client-secret"
  }
  secret {
    name                = "twitter-client-secret"
    identity            = azurerm_user_assigned_identity.backend.id
    key_vault_secret_id = "${local.persistent.key_vault_uri}secrets/twitter-client-secret"
  }

  ingress {
    external_enabled = true
    target_port      = 4000

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 1
    max_replicas = 2

    container {
      name   = "backend"
      image  = "${local.persistent.container_registry_login_server}/backend:${var.image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      # App
      env {
        name  = "PORT"
        value = "4000"
      }
      env {
        name  = "CORS_ORIGIN"
        value = local.frontend_url
      }
      env {
        name  = "FRONTEND_URL"
        value = local.frontend_url
      }
      env {
        name  = "NATIVE_APP_URL_SCHEME"
        value = var.native_app_url_scheme
      }

      # JWT
      env {
        name  = "AUTH_JWT_ACCESS_EXPIRATION"
        value = var.jwt_access_expiration
      }
      env {
        name  = "AUTH_JWT_REFRESH_EXPIRATION"
        value = var.jwt_refresh_expiration
      }

      # OAuth2 — Apple
      env {
        name  = "AUTH_APPLE_CLIENT_ID"
        value = var.apple_client_id
      }
      env {
        name  = "AUTH_APPLE_TEAM_ID"
        value = var.apple_team_id
      }
      env {
        name  = "AUTH_APPLE_KEY_ID"
        value = var.apple_key_id
      }
      env {
        name  = "AUTH_APPLE_CALLBACK_URL"
        value = "${local.backend_base_url}/auth/apple/callback"
      }
      env {
        name  = "AUTH_APPLE_NATIVE_CALLBACK_URL"
        value = "${local.backend_base_url}/auth/apple/native/callback"
      }

      # OAuth2 — Discord
      env {
        name  = "AUTH_DISCORD_CLIENT_ID"
        value = var.discord_client_id
      }
      env {
        name  = "AUTH_DISCORD_CALLBACK_URL"
        value = "${local.backend_base_url}/auth/discord/callback"
      }
      env {
        name  = "AUTH_DISCORD_NATIVE_CALLBACK_URL"
        value = "${local.backend_base_url}/auth/discord/native/callback"
      }

      # OAuth2 — GitHub
      env {
        name  = "AUTH_GITHUB_CLIENT_ID"
        value = var.gh_client_id
      }
      env {
        name  = "AUTH_GITHUB_CALLBACK_URL"
        value = "${local.backend_base_url}/auth/github/callback"
      }
      env {
        name  = "AUTH_GITHUB_NATIVE_CALLBACK_URL"
        value = "${local.backend_base_url}/auth/github/native/callback"
      }

      # OAuth2 — Google
      env {
        name  = "AUTH_GOOGLE_CLIENT_ID"
        value = var.google_oauth_client_id
      }
      env {
        name  = "AUTH_GOOGLE_CALLBACK_URL"
        value = "${local.backend_base_url}/auth/google/callback"
      }
      env {
        name  = "AUTH_GOOGLE_NATIVE_CALLBACK_URL"
        value = "${local.backend_base_url}/auth/google/native/callback"
      }

      # OAuth2 — X (Twitter)
      env {
        name  = "AUTH_TWITTER_CLIENT_ID"
        value = var.twitter_client_id
      }
      env {
        name  = "AUTH_TWITTER_CALLBACK_URL"
        value = "${local.backend_base_url}/auth/twitter/callback"
      }
      env {
        name  = "AUTH_TWITTER_NATIVE_CALLBACK_URL"
        value = "${local.backend_base_url}/auth/twitter/native/callback"
      }

      # --- Sensitive values from Key Vault ---
      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }
      env {
        name        = "AUTH_JWT_SECRET"
        secret_name = "jwt-secret"
      }
      env {
        name        = "AUTH_JWT_REFRESH_SECRET"
        secret_name = "jwt-refresh-secret"
      }
      env {
        name        = "AUTH_SESSION_SECRET"
        secret_name = "session-secret"
      }
      env {
        name        = "AUTH_APPLE_PRIVATE_KEY"
        secret_name = "apple-private-key"
      }
      env {
        name        = "AUTH_DISCORD_CLIENT_SECRET"
        secret_name = "discord-client-secret"
      }
      env {
        name        = "AUTH_GITHUB_CLIENT_SECRET"
        secret_name = "gh-client-secret"
      }
      env {
        name        = "AUTH_GOOGLE_CLIENT_SECRET"
        secret_name = "google-client-secret"
      }
      env {
        name        = "AUTH_TWITTER_CLIENT_SECRET"
        secret_name = "twitter-client-secret"
      }
    }
  }

  depends_on = [
    azurerm_key_vault_access_policy.backend,
  ]
}
