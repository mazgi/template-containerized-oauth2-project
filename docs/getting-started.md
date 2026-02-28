# Getting Started

## 1. Set up environment variables

```sh
cp .env.example .env
```

Edit `.env` and replace the placeholder values.

**JWT secrets** — generate strong random values:

```sh
openssl rand -base64 32
```

**Apple Sign In** — configure Sign in with Apple in [Apple Developer Account](https://developer.apple.com/account/):

1. Register an **App ID** with Sign in with Apple capability enabled
2. Create a **Services ID** (this is the `APPLE_CLIENT_ID`)
3. Configure the Services ID with the web domain and return URLs:
   - `http://localhost:4000/auth/apple/callback` (web)
   - `http://localhost:4000/auth/apple/native/callback` (native apps)
4. Create a **Sign in with Apple key** and download the `.p8` file
5. Copy the **Team ID**, **Key ID**, **Services ID**, and `.p8` file contents into `.env` (replace newlines with `\n`)

**Discord OAuth2** — create an application in the [Discord Developer Portal](https://discord.com/developers/applications):

1. Create a new application (or select an existing one)
2. Go to **OAuth2** > **Redirects** and add both callback URLs:
   - `http://localhost:4000/auth/discord/callback` (web)
   - `http://localhost:4000/auth/discord/native/callback` (native apps)
3. Copy the **Client ID** and **Client Secret** into `.env`

**GitHub OAuth2** — create an OAuth App in [GitHub Developer Settings](https://github.com/settings/developers):

1. Click **New OAuth App** (use **OAuth Apps**, not GitHub Apps)
2. Set **Authorization callback URL** to `http://localhost:4000/auth/github/callback`
3. Copy the **Client ID** and generate a **Client Secret**, paste both into `.env`
4. To support native apps (iOS/macOS/Android), register a **second OAuth App** with callback URL `http://localhost:4000/auth/github/native/callback` and use its credentials for `GH_NATIVE_CALLBACK_URL` (the `GH_CLIENT_ID` and `GH_CLIENT_SECRET` can be shared between both apps if you prefer a single app with one registered callback)

> **Scope note:** The backend uses `read:user` scope (not `user:email`). This avoids a separate `/user/emails` API call that can return 403 on some OAuth App configurations. Users with a public GitHub email will have it stored; others get a `github_{id}@github.invalid` placeholder.

**Google OAuth2** — create an OAuth 2.0 Client ID in [Google Cloud Console](https://console.cloud.google.com/):

1. Go to **APIs & Services > Credentials > Create credentials > OAuth 2.0 Client ID**
2. Application type: **Web application**
3. Add **all** URLs to **Authorized redirect URIs**:
   - `http://localhost:4000/auth/google/callback` (web)
   - `http://localhost:4000/auth/google/native/callback` (iOS/macOS and Android native apps)
4. Copy the **Client ID** and **Client Secret** into `.env`

**X (Twitter) OAuth2** — create an OAuth 2.0 app in the [Twitter Developer Portal](https://developer.twitter.com/):

1. Go to your project > **App Settings > User authentication settings**
2. Enable **OAuth 2.0**, set Type of App to **Web App, Automated App or Bot**
3. Add **all** URLs to **Callback URI / Redirect URL**:
   - `http://localhost:4000/auth/twitter/callback` (web)
   - `http://localhost:4000/auth/twitter/native/callback` (iOS/macOS and Android native apps)
4. Copy the **Client ID** and **Client Secret** into `.env`

See [.env.example](../.env.example) for descriptions of all variables.

## 2. Start the backend and web

```sh
docker compose up
```

On every run, the containers will upgrade all npm dependencies to their latest versions (`npm-check-updates --upgrade`), sort `package.json` (`sort-package-json`), install them, fix known vulnerabilities (`pnpm audit --fix`), apply the database schema, and start in watch mode. No manual setup is required.

| URL | Description |
|-----|-------------|
| http://localhost:4000 | backend API |
| http://localhost:4000/api | Swagger UI |
| http://localhost:3000 | Web |

### Build a production backend image

If you need a self-contained container (for deployment to Cloud Run, Kubernetes, etc.), use the production Dockerfile:

```sh
# from workspace root
docker build \
  -f Dockerfiles.d/backend-production/Dockerfile \
  -t myregistry/backend:latest \
  backend
```

The resulting image contains the compiled `dist` output, a pruned set of dependencies and the Prisma client. Push it to your registry of choice before deploying.
