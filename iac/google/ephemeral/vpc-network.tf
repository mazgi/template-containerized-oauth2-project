# VPC connector for Cloud Run -> Cloud SQL (private IP) access.
# Name must match ^[a-z][-a-z0-9]{0,23}[a-z0-9]$ (max 25 chars).
resource "random_id" "vpc_connector" {
  byte_length = 4
}

resource "google_vpc_access_connector" "main" {
  name   = "conn-${random_id.vpc_connector.hex}"
  region = local.gcp_region

  subnet {
    name = local.persistent.vpc_connector_subnet_name
  }

  # min_instances must be >= 2; max_instances kept low to minimise cost.
  min_instances = 2
  max_instances = 3
}
