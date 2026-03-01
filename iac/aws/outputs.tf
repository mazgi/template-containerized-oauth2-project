output "ecr_backend_repository_url" {
  description = "ECR backend repository URL for docker push"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_web_repository_url" {
  description = "ECR web repository URL for docker push"
  value       = aws_ecr_repository.web.repository_url
}

output "ecs_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_infrastructure_role_arn" {
  description = "ECS Express infrastructure role ARN"
  value       = aws_iam_role.ecs_infrastructure.arn
}

# -----------------------------------------------------------------------------
# Secrets Manager ARNs (referenced by ephemeral layer)
# -----------------------------------------------------------------------------

output "secret_database_url_arn" {
  description = "Secrets Manager ARN for DATABASE_URL"
  value       = aws_secretsmanager_secret.backend_database_url.arn
}

output "secret_jwt_secret_arn" {
  description = "Secrets Manager ARN for JWT_SECRET"
  value       = aws_secretsmanager_secret.backend_jwt_secret.arn
}

output "secret_jwt_refresh_secret_arn" {
  description = "Secrets Manager ARN for JWT_REFRESH_SECRET"
  value       = aws_secretsmanager_secret.backend_jwt_refresh_secret.arn
}

output "secret_session_secret_arn" {
  description = "Secrets Manager ARN for SESSION_SECRET"
  value       = aws_secretsmanager_secret.backend_session_secret.arn
}

output "secret_apple_private_key_arn" {
  description = "Secrets Manager ARN for APPLE_PRIVATE_KEY"
  value       = aws_secretsmanager_secret.backend_apple_private_key.arn
}

output "secret_discord_client_secret_arn" {
  description = "Secrets Manager ARN for DISCORD_CLIENT_SECRET"
  value       = aws_secretsmanager_secret.backend_discord_client_secret.arn
}

output "secret_gh_client_secret_arn" {
  description = "Secrets Manager ARN for GH_CLIENT_SECRET"
  value       = aws_secretsmanager_secret.backend_gh_client_secret.arn
}

output "secret_google_client_secret_arn" {
  description = "Secrets Manager ARN for GOOGLE_CLIENT_SECRET"
  value       = aws_secretsmanager_secret.backend_google_client_secret.arn
}

output "secret_twitter_client_secret_arn" {
  description = "Secrets Manager ARN for TWITTER_CLIENT_SECRET"
  value       = aws_secretsmanager_secret.backend_twitter_client_secret.arn
}

# -----------------------------------------------------------------------------
# Route 53 (referenced by ephemeral layer)
# -----------------------------------------------------------------------------

output "dns_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "dns_zone_name" {
  description = "Route 53 hosted zone name"
  value       = aws_route53_zone.main.name
}

output "dns_zone_name_servers" {
  description = "Route 53 hosted zone name servers (delegate from parent zone)"
  value       = aws_route53_zone.main.name_servers
}
