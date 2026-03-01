resource "google_artifact_registry_repository" "docker" {
  location      = var.gcp_region
  repository_id = var.artifact_registry_repository_id
  format        = "DOCKER"

  depends_on = [google_project_service.apis]
}
