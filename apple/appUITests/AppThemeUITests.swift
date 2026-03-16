//
//  AppThemeUITests.swift
//  appUITests
//

import XCTest

final class AppThemeUITests: XCTestCase {

    private var app: XCUIApplication!
    private static var counter = 0

    private static func uniqueEmail(_ prefix: String = "theme") -> String {
        counter += 1
        return "\(prefix).\(Int(Date().timeIntervalSince1970)).\(counter)@example.com"
    }

    private let defaultPassword = "password123"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        TestHelpers.dismissSystemAlerts()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    /// Create a verified user via API + Mailpit, then sign in via UI.
    private func createVerifiedUserAndSignIn(email: String) {
        TestHelpers.createVerifiedUser(email: email, password: defaultPassword)

        let emailField = app.textFields["signin_emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(email)

        app.secureTextFields["signin_passwordTextField"].tap()
        app.secureTextFields["signin_passwordTextField"].typeText(defaultPassword)

        app.buttons["signin_submitButton"].tap()
        TestHelpers.dismissSystemAlerts(app: app)
        XCTAssertTrue(app.staticTexts["dashboard_userEmail"].waitForExistence(timeout: 10))
        // Dismiss "Save Password?" dialog that may appear after dashboard loads
        TestHelpers.dismissSystemAlerts(app: app)
    }

    private func tapTab(_ label: String) {
        // Dismiss any lingering system dialogs before tab navigation
        TestHelpers.dismissSystemAlerts(app: app)

        // iOS 26 Liquid Glass TabView doesn't respond to XCUITest taps.
        // Use the test segmented picker bound to selectedTab.
        let indices = ["Dashboard": 0, "Items": 1, "Settings": 2]
        guard let index = indices[label] else {
            XCTFail("Unknown tab: \(label)")
            return
        }
        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "Test tab picker not found")
        let segment = picker.buttons.element(boundBy: index)
        XCTAssertTrue(segment.waitForExistence(timeout: 2), "Segment \(index) not found")
        segment.tap()
    }

    private func navigateToSettings() {
        tapTab("Settings")
        // The theme picker may be off-screen due to the Password section pushing
        // it below the fold. Swipe up until it appears in the UI tree.
        let themePicker = app.descendants(matching: .any)
            .matching(identifier: "settings_themePicker")
            .firstMatch
        for _ in 0..<5 {
            if themePicker.waitForExistence(timeout: 2) { break }
            app.swipeUp()
        }
        XCTAssertTrue(themePicker.waitForExistence(timeout: 5))
    }

    // MARK: - Theme Picker Visibility

    func testThemePickerIsVisible() throws {
        createVerifiedUserAndSignIn(email: Self.uniqueEmail("visible"))
        navigateToSettings()

        let themePicker = app.descendants(matching: .any)
            .matching(identifier: "settings_themePicker")
            .firstMatch
        XCTAssertTrue(themePicker.exists)
    }

    func testThemePickerHasThreeSegments() throws {
        createVerifiedUserAndSignIn(email: Self.uniqueEmail("segments"))
        navigateToSettings()

        XCTAssertTrue(app.buttons["System"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Light"].exists)
        XCTAssertTrue(app.buttons["Dark"].exists)
    }

    // MARK: - Theme Switching

    func testSwitchToDarkTheme() throws {
        createVerifiedUserAndSignIn(email: Self.uniqueEmail("dark"))
        navigateToSettings()

        let darkButton = app.buttons["Dark"]
        XCTAssertTrue(darkButton.waitForExistence(timeout: 5))
        darkButton.tap()

        XCTAssertTrue(darkButton.isSelected)
    }

    func testSwitchToLightTheme() throws {
        createVerifiedUserAndSignIn(email: Self.uniqueEmail("light"))
        navigateToSettings()

        let lightButton = app.buttons["Light"]
        XCTAssertTrue(lightButton.waitForExistence(timeout: 5))
        lightButton.tap()

        XCTAssertTrue(lightButton.isSelected)
    }

    func testSwitchBackToSystem() throws {
        createVerifiedUserAndSignIn(email: Self.uniqueEmail("system"))
        navigateToSettings()

        // Switch to dark first
        let darkButton = app.buttons["Dark"]
        XCTAssertTrue(darkButton.waitForExistence(timeout: 5))
        darkButton.tap()
        XCTAssertTrue(darkButton.isSelected)

        // Switch back to system
        let systemButton = app.buttons["System"]
        systemButton.tap()
        XCTAssertTrue(systemButton.isSelected)
    }

    func testSwitchBetweenAllThemes() throws {
        createVerifiedUserAndSignIn(email: Self.uniqueEmail("all"))
        navigateToSettings()

        let systemButton = app.buttons["System"]
        let lightButton = app.buttons["Light"]
        let darkButton = app.buttons["Dark"]
        XCTAssertTrue(systemButton.waitForExistence(timeout: 5))

        // System is default
        XCTAssertTrue(systemButton.isSelected)

        // Switch to dark
        darkButton.tap()
        XCTAssertTrue(darkButton.isSelected)
        XCTAssertFalse(systemButton.isSelected)
        XCTAssertFalse(lightButton.isSelected)

        // Switch to light
        lightButton.tap()
        XCTAssertTrue(lightButton.isSelected)
        XCTAssertFalse(darkButton.isSelected)
        XCTAssertFalse(systemButton.isSelected)

        // Switch back to system
        systemButton.tap()
        XCTAssertTrue(systemButton.isSelected)
        XCTAssertFalse(lightButton.isSelected)
        XCTAssertFalse(darkButton.isSelected)
    }
}
