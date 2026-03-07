resource "google_compute_network" "main" {
  name                    = "${var.app_unique_id}-vpc"
  auto_create_subnetworks = false

  depends_on = [google_project_service.apis["compute.googleapis.com"]]
}

resource "google_compute_subnetwork" "main" {
  name          = "${var.app_unique_id}-subnet"
  ip_cidr_range = "10.1.0.0/24"
  region        = var.gcp_region
  network       = google_compute_network.main.id
}

# Private IP range for Cloud SQL
resource "google_compute_global_address" "private_ip" {
  name          = "${var.app_unique_id}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = "10.8.0.0"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]

  depends_on = [google_project_service.apis["servicenetworking.googleapis.com"]]
}

# Dedicated subnet for VPC connector (requires /28)
resource "google_compute_subnetwork" "connector" {
  name          = "${var.app_unique_id}-connector-subnet"
  ip_cidr_range = "10.9.0.0/28"
  region        = var.gcp_region
  network       = google_compute_network.main.id
}
