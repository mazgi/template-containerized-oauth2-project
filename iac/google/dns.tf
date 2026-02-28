# -----------------------------------------------------------------------------
# Cloud DNS — DNS zone for google.{app_unique_id}.{base_domain_name}
# -----------------------------------------------------------------------------

resource "google_dns_managed_zone" "main" {
  name     = "${var.app_unique_id}-zone"
  dns_name = "google.${var.app_unique_id}.${var.base_domain_name}."

  depends_on = [google_project_service.apis]
}
