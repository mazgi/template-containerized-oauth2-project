resource "google_cloud_run_v2_service" "web" {
  name     = "${var.app_unique_id}-web"
  location = local.gcp_region

  deletion_protection = false

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    containers {
      image = "${local.persistent.artifact_registry_repository}/web:${var.image_tag}"

      ports {
        container_port = 3000
      }

      env {
        name  = "PORT"
        value = "3000"
      }
      env {
        name  = "BACKEND_URL"
        value = google_cloud_run_v2_service.backend.uri
      }

      startup_probe {
        tcp_socket {
          port = 3000
        }
        initial_delay_seconds = 3
        period_seconds        = 3
        failure_threshold     = 5
      }

      # Cloud Run does not support tcp_socket for liveness probes.
      liveness_probe {
        http_get {
          path = "/"
        }
        period_seconds = 30
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "web_public" {
  name     = google_cloud_run_v2_service.web.name
  location = local.gcp_region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
