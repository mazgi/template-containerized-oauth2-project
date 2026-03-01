# VPC connector for Cloud Run -> VPC access
resource "google_vpc_access_connector" "main" {
  name   = "${var.app_unique_id}-conn"
  region = local.gcp_region

  subnet {
    name = local.persistent.vpc_connector_subnet_name
  }
}
