variable "app_unique_id" {
  description = "Unique identifier used as a prefix for all resource names"
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "azure_location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

# -----------------------------------------------------------------------------
# Terraform remote state (persistent layer)
# -----------------------------------------------------------------------------

variable "azure_tf_state_resource_group" {
  description = "Azure resource group storing the persistent layer's Terraform state"
  type        = string
}

variable "azure_tf_state_storage_account" {
  description = "Azure storage account storing the persistent layer's Terraform state"
  type        = string
}

# -----------------------------------------------------------------------------
# Container image tag
# The registry URL is derived from the persistent layer's ACR login server output.
# -----------------------------------------------------------------------------

variable "image_tag" {
  description = "Container image tag (e.g. latest, sha-abc1234)"
  type        = string
  default     = "latest"
}

# -----------------------------------------------------------------------------
# PostgreSQL
# -----------------------------------------------------------------------------

variable "database_sku" {
  description = "PostgreSQL Flexible Server SKU"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "database_password" {
  description = "PostgreSQL user password"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "app"
}

variable "database_user" {
  description = "PostgreSQL user name"
  type        = string
  default     = "user"
}

# -----------------------------------------------------------------------------
# JWT
# Secrets (jwt_secret, jwt_refresh_secret) are populated externally in
# Key Vault. Only non-sensitive config is managed here.
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
}

variable "apple_team_id" {
  description = "Apple Team ID"
  type        = string
}

variable "apple_key_id" {
  description = "Apple Key ID"
  type        = string
}

# -----------------------------------------------------------------------------
# OAuth2 — Discord
# -----------------------------------------------------------------------------

variable "discord_client_id" {
  description = "Discord OAuth2 Client ID"
  type        = string
}

# -----------------------------------------------------------------------------
# OAuth2 — GitHub
# -----------------------------------------------------------------------------

variable "gh_client_id" {
  description = "GitHub OAuth App Client ID"
  type        = string
}

# -----------------------------------------------------------------------------
# OAuth2 — Google
# -----------------------------------------------------------------------------

variable "google_oauth_client_id" {
  description = "Google OAuth2 Client ID"
  type        = string
}

# -----------------------------------------------------------------------------
# OAuth2 — X (Twitter)
# -----------------------------------------------------------------------------

variable "twitter_client_id" {
  description = "X (Twitter) OAuth2 Client ID"
  type        = string
}

# -----------------------------------------------------------------------------
# SMTP
# SMTP_PASS is populated externally in Key Vault.
# Only non-sensitive config is managed here.
# -----------------------------------------------------------------------------

variable "smtp_host" {
  description = "SMTP server hostname"
  type        = string
}

variable "smtp_port" {
  description = "SMTP server port"
  type        = string
  default     = "587"
}

variable "smtp_secure" {
  description = "Use implicit TLS (true for port 465, false for STARTTLS on port 587)"
  type        = string
  default     = "false"
}

variable "smtp_user" {
  description = "SMTP username (e.g. SES IAM SMTP credential)"
  type        = string
}

variable "smtp_from" {
  description = "From address for outgoing emails"
  type        = string
}

# -----------------------------------------------------------------------------
# Native app
# -----------------------------------------------------------------------------

variable "native_app_url_scheme" {
  description = "Native app URL scheme for OAuth2 callbacks"
  type        = string
}

# -----------------------------------------------------------------------------
# DNS
# -----------------------------------------------------------------------------

variable "base_domain_name" {
  description = "Base domain name for DNS records (must match persistent layer)"
  type        = string
}
