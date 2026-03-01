output "backend_url" {
  description = "Backend ECS Express service URL"
  value       = aws_ecs_express_gateway_service.backend.dns_name
}

output "web_url" {
  description = "Web ECS Express service URL"
  value       = aws_ecs_express_gateway_service.web.dns_name
}

output "database_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.main.endpoint
}

# -----------------------------------------------------------------------------
# DNS
# -----------------------------------------------------------------------------

output "backend_fqdn" {
  description = "Backend DNS FQDN"
  value       = aws_route53_record.backend.fqdn
}

output "web_fqdn" {
  description = "Web DNS FQDN"
  value       = aws_route53_record.web.fqdn
}
