# VPC connector for Cloud Run -> Cloud SQL (private IP) access.
# Name must match ^[a-z][-a-z0-9]{0,23}[a-z0-9]$ (max 25 chars), so use
# the short suffix "-conn" instead of "-connector".
resource "google_vpc_access_connector" "main" {
  name   = "${var.app_unique_id}-conn"
  region = local.gcp_region

  subnet {
    name = local.persistent.vpc_connector_subnet_name
  }

  # min_instances must be >= 2; max_instances kept low to minimise cost.
  min_instances = 2
  max_instances = 3
}
