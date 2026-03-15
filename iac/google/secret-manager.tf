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
  secret_id = "${var.app_unique_id}-backend-auth-jwt-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_jwt_refresh_secret" {
  secret_id = "${var.app_unique_id}-backend-auth-jwt-refresh-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_session_secret" {
  secret_id = "${var.app_unique_id}-backend-auth-session-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_apple_private_key" {
  secret_id = "${var.app_unique_id}-backend-auth-apple-private-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_discord_client_secret" {
  secret_id = "${var.app_unique_id}-backend-auth-discord-client-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_gh_client_secret" {
  secret_id = "${var.app_unique_id}-backend-auth-gh-client-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_google_client_secret" {
  secret_id = "${var.app_unique_id}-backend-auth-google-client-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_twitter_client_secret" {
  secret_id = "${var.app_unique_id}-backend-auth-twitter-client-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "backend_smtp_pass" {
  secret_id = "${var.app_unique_id}-backend-smtp-pass"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}
