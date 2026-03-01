# -----------------------------------------------------------------------------
# Secret Manager — backend sensitive environment variables
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "backend_database_url" {
  secret_id = "${var.app_unique_id}-backend-database-url"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_jwt_secret" {
  secret_id = "${var.app_unique_id}-backend-jwt-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_jwt_refresh_secret" {
  secret_id = "${var.app_unique_id}-backend-jwt-refresh-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_session_secret" {
  secret_id = "${var.app_unique_id}-backend-session-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_apple_private_key" {
  secret_id = "${var.app_unique_id}-backend-apple-private-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_discord_client_secret" {
  secret_id = "${var.app_unique_id}-backend-discord-client-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_gh_client_secret" {
  secret_id = "${var.app_unique_id}-backend-gh-client-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_google_client_secret" {
  secret_id = "${var.app_unique_id}-backend-google-client-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_twitter_client_secret" {
  secret_id = "${var.app_unique_id}-backend-twitter-client-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}
