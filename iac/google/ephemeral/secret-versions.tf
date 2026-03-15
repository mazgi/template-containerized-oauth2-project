# -----------------------------------------------------------------------------
# Secret Manager — DATABASE_URL depends on the Cloud SQL endpoint so it must be
# managed here. All other secrets are populated externally (CI or manual).
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret_version" "backend_database_url" {
  secret      = local.persistent.secret_database_url_id
  secret_data = local.database_url
}

# -----------------------------------------------------------------------------
# IAM — grant Cloud Run default service account access to secrets
# -----------------------------------------------------------------------------

data "google_compute_default_service_account" "default" {}

locals {
  backend_secret_ids = [
    local.persistent.secret_database_url_id,
    local.persistent.secret_jwt_secret_id,
    local.persistent.secret_jwt_refresh_secret_id,
    local.persistent.secret_session_secret_id,
    local.persistent.secret_apple_private_key_id,
    local.persistent.secret_discord_client_secret_id,
    local.persistent.secret_gh_client_secret_id,
    local.persistent.secret_google_client_secret_id,
    local.persistent.secret_twitter_client_secret_id,
    local.persistent.secret_smtp_pass_id,
  ]
}

resource "google_secret_manager_secret_iam_member" "backend_accessor" {
  for_each = toset(local.backend_secret_ids)

  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}
