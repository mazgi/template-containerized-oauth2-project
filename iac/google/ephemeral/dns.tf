# -----------------------------------------------------------------------------
# Cloud DNS — DNS records for backend and web services
# Zone is created in the persistent layer.
# -----------------------------------------------------------------------------

resource "google_dns_record_set" "backend" {
  managed_zone = local.persistent.dns_zone_name
  name         = "backend.${local.persistent.dns_zone_dns_name}"
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["${trimprefix(google_cloud_run_v2_service.backend.uri, "https://")}."]
}

resource "google_dns_record_set" "web" {
  managed_zone = local.persistent.dns_zone_name
  name         = "web.${local.persistent.dns_zone_dns_name}"
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["${trimprefix(google_cloud_run_v2_service.web.uri, "https://")}."]
}
