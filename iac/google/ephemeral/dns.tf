# -----------------------------------------------------------------------------
# Cloud DNS — DNS records for backend and web services
# Zone is created in the persistent layer.
#
# Cloud Run domain mapping returns different record types depending on the
# domain configuration:
#   - Subdomain (e.g. backend.example.com) → CNAME record (1 entry)
#   - Apex domain (e.g. example.com)       → A and AAAA records (multiple entries)
#
# To handle both cases, we use var.dns_record_types as static for_each keys
# (known at plan time) and filter resource_records by type at apply time.
#   - Subdomain: dns_record_types = ["CNAME"]        (default)
#   - Apex:      dns_record_types = ["A", "AAAA"]
# -----------------------------------------------------------------------------

resource "google_dns_record_set" "backend" {
  for_each = var.dns_record_types

  managed_zone = local.persistent.dns_zone_name
  name         = "backend.${local.persistent.dns_zone_dns_name}"
  type         = each.key
  ttl          = 300
  rrdatas = [
    for r in google_cloud_run_domain_mapping.backend.status[0].resource_records :
    r.rrdata if r.type == each.key
  ]
}

resource "google_dns_record_set" "web" {
  for_each = var.dns_record_types

  managed_zone = local.persistent.dns_zone_name
  name         = "web.${local.persistent.dns_zone_dns_name}"
  type         = each.key
  ttl          = 300
  rrdatas = [
    for r in google_cloud_run_domain_mapping.web.status[0].resource_records :
    r.rrdata if r.type == each.key
  ]
}
