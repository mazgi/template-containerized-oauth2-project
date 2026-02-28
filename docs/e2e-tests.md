# E2E Tests

## Web (Playwright)

```sh
# Run tests (one-shot, container removed after exit)
docker compose --profile=web-e2e-tests run --rm web-e2e-tests

# Stop and clean up all containers
docker compose --profile=web-e2e-tests down --remove-orphans
```

## Android (Espresso)

Start the backend, then run the instrumented tests on a connected emulator or device:

```sh
docker compose up backend
cd android
./gradlew connectedAndroidTest
```

The tests connect to the backend at `http://10.0.2.2:4000` (the standard Android emulator loopback to the host machine). No `adb reverse` is needed for the E2E tests themselves — it is only required when testing OAuth2 sign-in flows interactively.

## iOS/macOS (XCUITest)

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

## Windows (Appium)

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
