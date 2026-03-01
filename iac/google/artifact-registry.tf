resource "google_artifact_registry_repository" "docker" {
  location      = var.gcp_region
  repository_id = var.app_unique_id
  format        = "DOCKER"

  depends_on = [google_project_service.apis]
}
