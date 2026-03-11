output "backend_url" {
  description = "Backend Cloud Run service URL"
  value       = google_cloud_run_v2_service.backend.uri
}

output "web_url" {
  description = "Web Cloud Run service URL"
  value       = google_cloud_run_v2_service.web.uri
}

output "database_instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.main.name
}

output "database_connection_name" {
  description = "Cloud SQL connection name (project:region:instance)"
  value       = google_sql_database_instance.main.connection_name
}

output "database_private_ip" {
  description = "Cloud SQL private IP address"
  value       = google_sql_database_instance.main.private_ip_address
}

# -----------------------------------------------------------------------------
# DNS
# -----------------------------------------------------------------------------

output "backend_fqdn" {
  description = "Backend DNS FQDN"
  value       = trimsuffix(values(google_dns_record_set.backend)[0].name, ".")
}

output "web_fqdn" {
  description = "Web DNS FQDN"
  value       = trimsuffix(values(google_dns_record_set.web)[0].name, ".")
}
