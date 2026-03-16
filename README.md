# template-containerized-oauth2-project

A multi-platform OAuth2 template project with a NestJS backend, a Next.js web client, and native client apps for Android, iOS/macOS, and Windows.

## Services

| Service | Technology | Port |
|---------|-----------|------|
| backend | NestJS 11 + PostgreSQL 17 | 4000 |
| web | Next.js 16 | 3000 |
| android | Kotlin + Jetpack Compose | — |
| apple | SwiftUI | — |
| windows | WinUI 3 (C# / Windows App SDK 1.8) | — |

## Prerequisites

- Docker Engine + Docker Compose (e.g. [Docker Desktop](https://www.docker.com/products/docker-desktop/), [Podman](https://podman.io/), [Colima](https://github.com/abiosoft/colima))
- (Android) Android Studio
- (iOS/macOS) Xcode
- (Windows) Visual Studio 2022 with **.NET desktop development** and **Windows App SDK C# Templates** workloads

## Quick Start

```sh
cp .example.secrets.env .secrets.env   # then fill in secrets — see docs/local-development.md
docker compose up
```

| URL | Description |
|-----|-------------|
| http://localhost:4000 | backend API |
| http://localhost:4000/api | Swagger UI |
| http://localhost:3000 | Web |

See [Local Development](docs/local-development.md) for detailed setup instructions (OAuth provider configuration, E2E tests, etc.).

## Use This Template

After creating a repository from this template, follow these steps. Only step 1 is required — the rest are optional depending on your needs.

1. **Local development** — Copy `.example.secrets.env` → `.secrets.env`, fill in secrets, and run `docker compose up`. See [Local Development](docs/local-development.md).
2. **E2E tests on CI** — Add GitHub Actions secrets for JWT and OAuth2 providers. See [CI — Setup for E2E tests](docs/ci.md#for-e2e-tests-only).
3. **Cloud deployment via CI** — Set up OIDC authentication, configure GitHub Actions variables, and run IaC workflows. See [CI — Setup for cloud deployment](docs/ci.md#for-cloud-deployment-e2e-tests--production-builds--iac).
4. **Manual cloud deployment** — Deploy directly with Terraform. See [Cloud Deployment](docs/cloud-deployment.md).

## Project Structure

```
.
├── compose.yaml
├── .example.secrets.env
├── backend/               # NestJS API
├── web/
│   ├── app/               # Next.js SPA
│   └── e2e-tests/         # Playwright E2E tests
├── android/               # Kotlin + Jetpack Compose
│   └── app/src/
│       ├── main/          # App source
│       └── androidTest/   # Espresso E2E tests
├── apple/                 # SwiftUI (iOS, macOS, watchOS, etc.)
│   ├── app/               # App source
│   └── appUITests/        # XCUITest E2E tests
├── windows/               # WinUI 3 (C# / Windows App SDK)
│   ├── windows.slnx       # Solution file
│   ├── app/               # App source
│   └── e2e-tests/         # Appium E2E tests
├── iac/                   # Terraform IaC (AWS, Azure, GCP)
├── Dockerfiles.d/
├── .github/               # GitHub Actions workflows + custom actions
└── docs/
```

## Documentation

- [Local Development](docs/local-development.md) — environment setup, running the stack, E2E tests
- Cloud Deployment — [overview](docs/cloud-deployment.md) / [AWS](docs/cloud-deployment-aws.md) / [Azure](docs/cloud-deployment-azure.md) / [Google Cloud](docs/cloud-deployment-google.md)
- [CI / GitHub Actions](docs/ci.md) — workflows, required secrets and variables
- [Secrets Management](docs/secrets.md) — cloud provider secret stores (AWS, Azure, GCP)
- [OIDC Setup](docs/oidc-setup.md) — one-time cloud provider authentication setup
- [Git SHA Display](docs/git-sha-display.md) — per-platform build SHA injection
- [Environment Variables](.example.secrets.env) — backend config and secrets
- [GitHub Actions Variables](.example.env) — CI/CD and cloud deployment variables
