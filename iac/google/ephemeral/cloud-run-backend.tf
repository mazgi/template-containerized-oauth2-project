locals {
  database_url = "postgresql://${var.database_user}:${var.database_password}@${google_sql_database_instance.main.private_ip_address}:5432/${var.database_name}"
}

data "google_artifact_registry_docker_image" "backend" {
  location      = local.gcp_region
  repository_id = var.app_unique_id
  image_name    = "backend:${var.image_tag}"
  project       = var.gcp_project_id
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
      image = data.google_artifact_registry_docker_image.backend.self_link

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

      # SMTP
      env {
        name  = "SMTP_HOST"
        value = var.smtp_host
      }
      env {
        name  = "SMTP_PORT"
        value = var.smtp_port
      }
      env {
        name  = "SMTP_SECURE"
        value = var.smtp_secure
      }
      env {
        name  = "SMTP_USER"
        value = var.smtp_user
      }
      env {
        name  = "SMTP_FROM"
        value = var.smtp_from
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
      # Web callback base URL uses the frontend proxy (frontend_url/backend)
      # so the session cookie stays on the same domain throughout the OAuth flow.
      # Native callback base URL uses the backend directly (native apps connect to the backend).
      env {
        name  = "AUTH_CALLBACK_BASE_URL"
        value = "${local.frontend_url}/backend"
      }
      env {
        name  = "AUTH_NATIVE_CALLBACK_BASE_URL"
        value = local.backend_base_url
      }

      # OAuth2 — Discord
      env {
        name  = "AUTH_DISCORD_CLIENT_ID"
        value = var.discord_client_id
      }

      # OAuth2 — GitHub
      env {
        name  = "AUTH_GITHUB_CLIENT_ID"
        value = var.gh_client_id
      }

      # OAuth2 — Google
      env {
        name  = "AUTH_GOOGLE_CLIENT_ID"
        value = var.google_oauth_client_id
      }

      # OAuth2 — X (Twitter)
      env {
        name  = "AUTH_TWITTER_CLIENT_ID"
        value = var.twitter_client_id
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
      env {
        name = "SMTP_PASS"
        value_source {
          secret_key_ref {
            secret  = local.persistent.secret_smtp_pass_id
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
