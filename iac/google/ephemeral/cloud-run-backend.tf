locals {
  database_url = "postgresql://${var.database_user}:${var.database_password}@${google_sql_database_instance.main.private_ip_address}:5432/${var.database_name}"
}

resource "google_cloud_run_v2_service" "backend" {
  name     = "${var.app_unique_id}-backend"
  location = local.gcp_region

  deletion_protection = false

  scaling {}

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    vpc_access {
      connector = google_vpc_access_connector.main.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    containers {
      image = "${local.persistent.artifact_registry_repository}/backend:${var.image_tag}"

      ports {
        container_port = 4000
      }

      # PORT is reserved by Cloud Run — set automatically from container_port.
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

      # --- Sensitive values from Secret Manager ---
      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = local.persistent.secret_database_url_id
            version = "latest"
          }
        }
      }
      env {
        name  = "AUTH_JWT_SECRET"
        value_source {
          secret_key_ref {
            secret  = local.persistent.secret_jwt_secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "AUTH_JWT_REFRESH_SECRET"
        value_source {
          secret_key_ref {
            secret  = local.persistent.secret_jwt_refresh_secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "AUTH_SESSION_SECRET"
        value_source {
          secret_key_ref {
            secret  = local.persistent.secret_session_secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "AUTH_APPLE_PRIVATE_KEY"
        value_source {
          secret_key_ref {
            secret  = local.persistent.secret_apple_private_key_id
            version = "latest"
          }
        }
      }
      env {
        name  = "AUTH_DISCORD_CLIENT_SECRET"
        value_source {
          secret_key_ref {
            secret  = local.persistent.secret_discord_client_secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "AUTH_GITHUB_CLIENT_SECRET"
        value_source {
          secret_key_ref {
            secret  = local.persistent.secret_gh_client_secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "AUTH_GOOGLE_CLIENT_SECRET"
        value_source {
          secret_key_ref {
            secret  = local.persistent.secret_google_client_secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "AUTH_TWITTER_CLIENT_SECRET"
        value_source {
          secret_key_ref {
            secret  = local.persistent.secret_twitter_client_secret_id
            version = "latest"
          }
        }
      }

      startup_probe {
        tcp_socket {
          port = 4000
        }
        initial_delay_seconds = 10
        period_seconds        = 5
        failure_threshold     = 12
      }

      # Cloud Run does not support tcp_socket for liveness probes.
      liveness_probe {
        http_get {
          path = "/api"
        }
        period_seconds = 30
      }
    }
  }

  depends_on = [
    google_sql_database.main,
    google_sql_user.main,
    google_secret_manager_secret_version.backend_database_url,
    google_secret_manager_secret_iam_member.backend_accessor,
  ]
}

resource "google_cloud_run_domain_mapping" "backend" {
  location = local.gcp_region
  name     = "backend.${var.app_unique_id}-google.${var.base_domain_name}"

  metadata {
    namespace = var.gcp_project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.backend.name
  }
}

resource "google_cloud_run_v2_service_iam_member" "backend_public" {
  name     = google_cloud_run_v2_service.backend.name
  location = local.gcp_region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
