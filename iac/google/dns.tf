# -----------------------------------------------------------------------------
# Cloud DNS — DNS zone for {app_unique_id}-google.{base_domain_name}
# -----------------------------------------------------------------------------

resource "google_dns_managed_zone" "main" {
  name     = "${var.app_unique_id}-zone"
  dns_name = "${var.app_unique_id}-google.${var.base_domain_name}."

  depends_on = [google_project_service.apis]
}
