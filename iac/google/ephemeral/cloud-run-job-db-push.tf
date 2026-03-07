# -----------------------------------------------------------------------------
# Cloud Run Job — prisma db push
# Applies the Prisma schema to Cloud SQL without generating migration files.
# Triggered by CI after deploying a new backend image.
# -----------------------------------------------------------------------------

data "google_artifact_registry_docker_image" "backend_db_push" {
  location      = local.gcp_region
  repository_id = var.app_unique_id
  image_name    = "backend-db-push:${var.image_tag}"
  project       = var.gcp_project_id
}

resource "google_cloud_run_v2_job" "db_push" {
  name     = "${var.app_unique_id}-db-push"
  location = local.gcp_region

  deletion_protection = false

  template {
    template {
      vpc_access {
        connector = google_vpc_access_connector.main.id
        egress    = "PRIVATE_RANGES_ONLY"
      }

      containers {
        image = data.google_artifact_registry_docker_image.backend_db_push.self_link

        env {
          name = "DATABASE_URL"
          value_source {
            secret_key_ref {
              secret  = local.persistent.secret_database_url_id
              version = "latest"
            }
          }
        }
      }

      timeout     = "300s"
      max_retries = 1
    }
  }

  depends_on = [
    google_sql_database.main,
    google_sql_user.main,
    google_secret_manager_secret_version.backend_database_url,
    google_secret_manager_secret_iam_member.backend_accessor,
  ]
}
