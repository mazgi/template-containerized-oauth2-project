# CI / GitHub Actions

## Workflows

Five workflows run on every push and pull request to `main`:

| Workflow | Runner | Description |
|----------|--------|-------------|
| `.github/workflows/backend.e2e-tests.yaml` | `ubuntu-latest` | Builds the backend image, runs NestJS E2E tests via `docker compose run` |
| `.github/workflows/web.e2e-tests.yaml` | `ubuntu-latest` | Starts the full stack via Docker Compose, runs Playwright E2E tests |
| `.github/workflows/android.e2e-tests.yaml` | `ubuntu-latest` | Starts the backend via Docker Compose, boots an API-35 emulator (KVM + AVD cache), runs Espresso E2E tests |
| `.github/workflows/macos-ios.e2e-tests.yaml` | `macos-15` | Starts PostgreSQL + backend natively, runs XCUITest E2E tests on iPhone 17 simulator |
| `.github/workflows/windows.e2e-tests.yaml` | `windows-2025` | Starts PostgreSQL + backend natively, builds and deploys WinUI app, runs Appium E2E tests |

## Required secrets

Add the following under **Settings > Secrets and variables > Actions** in the GitHub repository:

| Secret | Description |
|--------|-------------|
| `JWT_SECRET` | Signs access tokens — generate with `openssl rand -base64 32` |
| `JWT_REFRESH_SECRET` | Signs refresh tokens — must differ from `JWT_SECRET` |
| `APPLE_CLIENT_ID` | Apple Services ID |
| `APPLE_TEAM_ID` | Apple Developer Team ID |
| `APPLE_KEY_ID` | Apple Sign In key ID |
| `APPLE_PRIVATE_KEY` | Apple `.p8` private key content (newlines replaced with `\n`) |
| `DISCORD_CLIENT_ID` | Discord OAuth2 Client ID |
| `DISCORD_CLIENT_SECRET` | Discord OAuth2 Client Secret |
| `GH_CLIENT_ID` | GitHub OAuth App Client ID |
| `GH_CLIENT_SECRET` | GitHub OAuth App Client Secret |
| `GOOGLE_CLIENT_ID` | Google OAuth2 Client ID |
| `GOOGLE_CLIENT_SECRET` | Google OAuth2 Client Secret |
| `TWITTER_CLIENT_ID` | X (Twitter) OAuth2 Client ID |
| `TWITTER_CLIENT_SECRET` | X (Twitter) OAuth2 Client Secret |
| `SESSION_SECRET` | Signs session cookies for Twitter PKCE — generate with `openssl rand -base64 32` |

`JWT_SECRET` and `JWT_REFRESH_SECRET` are required by all workflows. The OAuth2 secrets (Apple, Discord, GitHub, Google, Twitter, Session) are required by the Android, macOS/iOS, and Windows workflows so the NestJS backend starts successfully — even though those E2E tests only exercise email/password auth and the items API.
