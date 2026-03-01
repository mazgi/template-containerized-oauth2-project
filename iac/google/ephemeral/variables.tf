variable "app_unique_id" {
  description = "Unique identifier used as a prefix for all resource names"
  type        = string
  default     = "oauth2-app"
}

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

# -----------------------------------------------------------------------------
# Container image tag
# The registry URL is derived from the persistent layer's Artifact Registry output.
# -----------------------------------------------------------------------------

variable "image_tag" {
  description = "Container image tag (e.g. latest, sha-abc1234)"
  type        = string
  default     = "latest"
}

# -----------------------------------------------------------------------------
# Cloud SQL
# -----------------------------------------------------------------------------

variable "database_tier" {
  description = "Cloud SQL machine tier"
  type        = string
  default     = "db-f1-micro"
}

variable "database_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "oauth2app"
}

variable "database_user" {
  description = "PostgreSQL user name"
  type        = string
  default     = "oauth2app"
}

variable "database_password" {
  description = "PostgreSQL user password"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# JWT
# Secrets (jwt_secret, jwt_refresh_secret) are populated externally in
# Secret Manager. Only non-sensitive config is managed here.
# -----------------------------------------------------------------------------

variable "jwt_access_expiration" {
  description = "JWT access token expiration (e.g. 15m)"
  type        = string
  default     = "15m"
}

variable "jwt_refresh_expiration" {
  description = "JWT refresh token expiration (e.g. 7d)"
  type        = string
  default     = "7d"
}

# -----------------------------------------------------------------------------
# OAuth2 — Apple
# -----------------------------------------------------------------------------

variable "apple_client_id" {
  description = "Apple Services ID"
  type        = string
  default     = ""
}

variable "apple_team_id" {
  description = "Apple Team ID"
  type        = string
  default     = ""
}

variable "apple_key_id" {
  description = "Apple Key ID"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# OAuth2 — Discord
# -----------------------------------------------------------------------------

variable "discord_client_id" {
  description = "Discord OAuth2 Client ID"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# OAuth2 — GitHub
# -----------------------------------------------------------------------------

variable "gh_client_id" {
  description = "GitHub OAuth App Client ID"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# OAuth2 — Google
# -----------------------------------------------------------------------------

variable "google_oauth_client_id" {
  description = "Google OAuth2 Client ID"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# OAuth2 — X (Twitter)
# -----------------------------------------------------------------------------

variable "twitter_client_id" {
  description = "X (Twitter) OAuth2 Client ID"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Native app
# -----------------------------------------------------------------------------

variable "native_app_url_scheme" {
  description = "Native app URL scheme for OAuth2 callbacks"
  type        = string
  default     = "oauth2app"
}

# -----------------------------------------------------------------------------
# DNS
# -----------------------------------------------------------------------------

variable "base_domain_name" {
  description = "Base domain name for DNS records (must match persistent layer)"
  type        = string
}
