# template-containerized-oauth2-project

A multi-platform OAuth2 template project with a NestJS backend, a Next.js web client, and native client apps for Android, iOS/macOS, and Windows.

## Services

| Service | Technology | Port |
|---------|-----------|------|
| backend | NestJS 11 + PostgreSQL 17 | 4000 |
| web | Next.js 16 | 3000 |
| android | Kotlin + Jetpack Compose | — |
| mac-ios | SwiftUI + SwiftData | — |
| windows | WinUI 3 (C# / Windows App SDK 1.8) | — |

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- (Android) Android Studio
- (iOS/macOS) Xcode
- (Windows) Visual Studio 2022 with **.NET desktop development** and **Windows App SDK C# Templates** workloads

## Quick Start

```sh
cp .env.example .env   # then fill in secrets — see docs/getting-started.md
docker compose up
```

| URL | Description |
|-----|-------------|
| http://localhost:4000 | backend API |
| http://localhost:4000/api | Swagger UI |
| http://localhost:3000 | Web |

See [Getting Started](docs/getting-started.md) for detailed setup instructions (OAuth provider configuration, production builds, etc.).

## Project Structure

```
.
├── compose.yaml
├── .env.example
├── backend/               # NestJS API
├── web/
│   ├── app/               # Next.js SPA
│   └── e2e-tests/         # Playwright E2E tests
├── android/               # Kotlin + Jetpack Compose
│   └── app/src/
│       ├── main/          # App source
│       └── androidTest/   # Espresso E2E tests
├── macos-ios/             # SwiftUI
│   ├── app/               # App source
│   └── appUITests/        # XCUITest E2E tests
├── windows/               # WinUI 3 (C# / Windows App SDK)
│   ├── windows.slnx       # Solution file
│   ├── app/               # App source
│   └── e2e-tests/         # Appium E2E tests
├── Dockerfiles.d/
└── docs/
```

## Documentation

- [Getting Started](docs/getting-started.md) — environment setup, running the stack, production builds
- [E2E Tests](docs/e2e-tests.md) — running tests for Web, Android, iOS/macOS, and Windows
- [CI / GitHub Actions](docs/ci.md) — workflows, required secrets
- [Environment Variables](.env.example) — full list of configuration variables
