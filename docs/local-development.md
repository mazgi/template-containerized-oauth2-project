# Local Development

## 1. Set up environment variables

```sh
cp .secrets.example.env .secrets.env
```

Edit `.secrets.env` and replace the placeholder values.

**Container user** — on Linux, set `UID` and `GID` to your host user's IDs so that files written to bind-mounted volumes (`node_modules`, `.pnpm-store`, etc.) are owned by you rather than root. The command is a no-op on macOS:

```sh
test $(uname -s) = 'Linux' && {
  echo "GID=$(id -g)"
  echo "UID=$(id -u)"
} >> .secrets.env || :
```

These values are baked into the container image at build time. Run `docker compose build` after changing them.

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
5. Copy the **Team ID**, **Key ID**, **Services ID**, and `.p8` file contents into `.secrets.env` (replace newlines with `\n`)

**Discord OAuth2** — create an application in the [Discord Developer Portal](https://discord.com/developers/applications):

1. Create a new application (or select an existing one)
2. Go to **OAuth2** > **Redirects** and add both callback URLs:
   - `http://localhost:4000/auth/discord/callback` (web)
   - `http://localhost:4000/auth/discord/native/callback` (native apps)
3. Copy the **Client ID** and **Client Secret** into `.secrets.env`

**GitHub OAuth2** — create an OAuth App in [GitHub Developer Settings](https://github.com/settings/developers):

1. Click **New OAuth App** (use **OAuth Apps**, not GitHub Apps)
2. Set **Authorization callback URL** to `http://localhost:4000/auth/github/callback`
3. Copy the **Client ID** and generate a **Client Secret**, paste both into `.secrets.env`
4. To support native apps (iOS/macOS/Android), register a **second OAuth App** with callback URL `http://localhost:4000/auth/github/native/callback` and use its credentials for `GH_NATIVE_CALLBACK_URL` (the `GH_CLIENT_ID` and `GH_CLIENT_SECRET` can be shared between both apps if you prefer a single app with one registered callback)

> **Scope note:** The backend uses `read:user` scope (not `user:email`). This avoids a separate `/user/emails` API call that can return 403 on some OAuth App configurations. Users with a public GitHub email will have it stored; others get a `github_{id}@github.invalid` placeholder.

**Google OAuth2** — create an OAuth 2.0 Client ID in [Google Cloud Console](https://console.cloud.google.com/):

1. Go to **APIs & Services > Credentials > Create credentials > OAuth 2.0 Client ID**
2. Application type: **Web application**
3. Add **all** URLs to **Authorized redirect URIs**:
   - `http://localhost:4000/auth/google/callback` (web)
   - `http://localhost:4000/auth/google/native/callback` (iOS/macOS and Android native apps)
4. Copy the **Client ID** and **Client Secret** into `.secrets.env`

**X (Twitter) OAuth2** — create an OAuth 2.0 app in the [Twitter Developer Portal](https://developer.twitter.com/):

1. Go to your project > **App Settings > User authentication settings**
2. Enable **OAuth 2.0**, set Type of App to **Web App, Automated App or Bot**
3. Add **all** URLs to **Callback URI / Redirect URL**:
   - `http://localhost:4000/auth/twitter/callback` (web)
   - `http://localhost:4000/auth/twitter/native/callback` (iOS/macOS and Android native apps)
4. Copy the **Client ID** and **Client Secret** into `.secrets.env`

See [.secrets.example.env](../.secrets.example.env) for descriptions of all variables.

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

## 3. Run E2E tests

### Web (Playwright)

```sh
# Run tests (one-shot, container removed after exit)
docker compose --profile=web-e2e-tests run --rm web-e2e-tests

# Stop and clean up all containers
docker compose --profile=web-e2e-tests down --remove-orphans
```

### Android (Espresso)

Start the backend, then run the instrumented tests on a connected emulator or device:

```sh
docker compose up backend
cd android
./gradlew connectedAndroidTest
```

The tests connect to the backend at `http://10.0.2.2:4000` (the standard Android emulator loopback to the host machine). No `adb reverse` is needed for the E2E tests themselves — it is only required when testing OAuth2 sign-in flows interactively.

### iOS/macOS (XCUITest)

Start the backend, then run the UI tests in Xcode or via the command line:

```sh
docker compose up backend

# Run on an iOS simulator (adjust the simulator name as needed)
xcodebuild test \
  -project macos-ios/app.xcodeproj \
  -scheme app \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:appUITests
```

The tests connect to the backend at `http://localhost:4000`. Ensure the backend is running and reachable from the simulator before running the tests.

### Windows (Appium)

Start the backend, build and deploy the WinUI app, then run the Appium tests:

```powershell
docker compose up backend -d

# Build and deploy the app as MSIX
dotnet build windows/app/app.csproj -c Debug -p:Platform=x64
Add-AppxPackage -Register "windows\app\bin\x64\Debug\net8.0-windows10.0.19041.0\win-x64\AppxManifest.xml"

# Get the Package Family Name and update test.runsettings
$pkg = Get-AppxPackage | Where-Object { $_.Name -like "*f0af5309*" }
echo "$($pkg.PackageFamilyName)!App"

# Start Appium server (in a separate terminal)
appium

# Run tests
cd windows/e2e-tests
dotnet test --settings test.runsettings
```

Prerequisites: Windows 10/11 with Developer Mode enabled, .NET 8 SDK, Node.js (for `npm install -g appium` + `appium driver install --source=npm appium-windows-driver`), and [WinAppDriver v1.2.1](https://github.com/microsoft/WinAppDriver/releases).
