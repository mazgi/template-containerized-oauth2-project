output "gcp_region" {
  description = "GCP region"
  value       = var.gcp_region
}

output "gcp_zone" {
  description = "GCP zone"
  value       = var.gcp_zone
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository path for docker push"
  value       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.docker.repository_id}"
}

output "vpc_network_id" {
  description = "VPC network ID for Cloud SQL private IP"
  value       = google_compute_network.main.id
}

output "vpc_connector_subnet_name" {
  description = "Subnet name for VPC Access Connector"
  value       = google_compute_subnetwork.connector.name
}

output "private_vpc_peering_connection" {
  description = "VPC peering connection ID for Cloud SQL"
  value       = google_service_networking_connection.private_vpc.id
}

# -----------------------------------------------------------------------------
# Secret Manager IDs (referenced by ephemeral layer)
# -----------------------------------------------------------------------------

output "secret_database_url_id" {
  description = "Secret Manager secret ID for DATABASE_URL"
  value       = google_secret_manager_secret.backend_database_url.id
}

output "secret_jwt_secret_id" {
  description = "Secret Manager secret ID for AUTH_JWT_SECRET"
  value       = google_secret_manager_secret.backend_jwt_secret.id
}

output "secret_jwt_refresh_secret_id" {
  description = "Secret Manager secret ID for AUTH_JWT_REFRESH_SECRET"
  value       = google_secret_manager_secret.backend_jwt_refresh_secret.id
}

output "secret_session_secret_id" {
  description = "Secret Manager secret ID for AUTH_SESSION_SECRET"
  value       = google_secret_manager_secret.backend_session_secret.id
}

output "secret_apple_private_key_id" {
  description = "Secret Manager secret ID for AUTH_APPLE_PRIVATE_KEY"
  value       = google_secret_manager_secret.backend_apple_private_key.id
}

output "secret_discord_client_secret_id" {
  description = "Secret Manager secret ID for AUTH_DISCORD_CLIENT_SECRET"
  value       = google_secret_manager_secret.backend_discord_client_secret.id
}

output "secret_gh_client_secret_id" {
  description = "Secret Manager secret ID for AUTH_GITHUB_CLIENT_SECRET"
  value       = google_secret_manager_secret.backend_gh_client_secret.id
}

output "secret_google_client_secret_id" {
  description = "Secret Manager secret ID for AUTH_GOOGLE_CLIENT_SECRET"
  value       = google_secret_manager_secret.backend_google_client_secret.id
}

output "secret_twitter_client_secret_id" {
  description = "Secret Manager secret ID for AUTH_TWITTER_CLIENT_SECRET"
  value       = google_secret_manager_secret.backend_twitter_client_secret.id
}

output "secret_smtp_pass_id" {
  description = "Secret Manager secret ID for SMTP_PASS"
  value       = google_secret_manager_secret.backend_smtp_pass.id
}

# -----------------------------------------------------------------------------
# Cloud DNS (referenced by ephemeral layer)
# -----------------------------------------------------------------------------

output "dns_zone_name" {
  description = "Cloud DNS managed zone name (resource name)"
  value       = google_dns_managed_zone.main.name
}

output "dns_zone_dns_name" {
  description = "Cloud DNS zone DNS name (FQDN with trailing dot)"
  value       = google_dns_managed_zone.main.dns_name
}

output "dns_zone_name_servers" {
  description = "Cloud DNS zone name servers (delegate from parent zone)"
  value       = google_dns_managed_zone.main.name_servers
}
