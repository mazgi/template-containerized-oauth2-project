# -----------------------------------------------------------------------------
# Cloud DNS — DNS records for backend and web services
# Zone is created in the persistent layer.
# -----------------------------------------------------------------------------

resource "google_dns_record_set" "backend" {
  managed_zone = local.persistent.dns_zone_name
  name         = "backend.${local.persistent.dns_zone_dns_name}"
  type         = google_cloud_run_domain_mapping.backend.status[0].resource_records[0].type
  ttl          = 300
  rrdatas      = [google_cloud_run_domain_mapping.backend.status[0].resource_records[0].rrdata]
}

resource "google_dns_record_set" "web" {
  managed_zone = local.persistent.dns_zone_name
  name         = "web.${local.persistent.dns_zone_dns_name}"
  type         = google_cloud_run_domain_mapping.web.status[0].resource_records[0].type
  ttl          = 300
  rrdatas      = [google_cloud_run_domain_mapping.web.status[0].resource_records[0].rrdata]
}
