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
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    private func signUp(email: String) {
        let goToSignUpButton = app.buttons["signin_goToSignUpButton"]
        XCTAssertTrue(goToSignUpButton.waitForExistence(timeout: 5))
        goToSignUpButton.tap()

        let emailField = app.textFields["signup_emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(email)

        app.secureTextFields["signup_passwordTextField"].tap()
        app.secureTextFields["signup_passwordTextField"].typeText(defaultPassword)

        app.secureTextFields["signup_passwordConfirmTextField"].tap()
        app.secureTextFields["signup_passwordConfirmTextField"].typeText(defaultPassword)

        app.buttons["signup_submitButton"].tap()
        XCTAssertTrue(app.staticTexts["dashboard_userEmail"].waitForExistence(timeout: 10))
    }

    private func navigateToSettings() {
        app.tabBars.buttons["Settings"].tap()
        let themePicker = app.descendants(matching: .any)
            .matching(identifier: "settings_themePicker")
            .firstMatch
        XCTAssertTrue(themePicker.waitForExistence(timeout: 5))
    }

    // MARK: - Theme Picker Visibility

    func testThemePickerIsVisible() throws {
        signUp(email: Self.uniqueEmail("visible"))
        navigateToSettings()

        let themePicker = app.descendants(matching: .any)
            .matching(identifier: "settings_themePicker")
            .firstMatch
        XCTAssertTrue(themePicker.exists)
    }

    func testThemePickerHasThreeSegments() throws {
        signUp(email: Self.uniqueEmail("segments"))
        navigateToSettings()

        XCTAssertTrue(app.buttons["System"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Light"].exists)
        XCTAssertTrue(app.buttons["Dark"].exists)
    }

    // MARK: - Theme Switching

    func testSwitchToDarkTheme() throws {
        signUp(email: Self.uniqueEmail("dark"))
        navigateToSettings()

        let darkButton = app.buttons["Dark"]
        XCTAssertTrue(darkButton.waitForExistence(timeout: 5))
        darkButton.tap()

        XCTAssertTrue(darkButton.isSelected)
    }

    func testSwitchToLightTheme() throws {
        signUp(email: Self.uniqueEmail("light"))
        navigateToSettings()

        let lightButton = app.buttons["Light"]
        XCTAssertTrue(lightButton.waitForExistence(timeout: 5))
        lightButton.tap()

        XCTAssertTrue(lightButton.isSelected)
    }

    func testSwitchBackToSystem() throws {
        signUp(email: Self.uniqueEmail("system"))
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
        signUp(email: Self.uniqueEmail("all"))
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
