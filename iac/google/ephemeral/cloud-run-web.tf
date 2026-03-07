data "google_artifact_registry_docker_image" "web" {
  location      = local.gcp_region
  repository_id = var.app_unique_id
  image_name    = "web:${var.image_tag}"
  project       = var.gcp_project_id
}

resource "google_cloud_run_v2_service" "web" {
  name     = "${var.app_unique_id}-web"
  location = local.gcp_region

  deletion_protection = false

  scaling {}

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    containers {
      image = data.google_artifact_registry_docker_image.web.self_link

      ports {
        container_port = 3000
      }

      # PORT is reserved by Cloud Run — set automatically from container_port.
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

resource "google_cloud_run_domain_mapping" "web" {
  location = local.gcp_region
  name     = "web.${var.app_unique_id}-google.${var.base_domain_name}"

  metadata {
    namespace = var.gcp_project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.web.name
  }
}

resource "google_cloud_run_v2_service_iam_member" "web_public" {
  name     = google_cloud_run_v2_service.web.name
  location = local.gcp_region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
