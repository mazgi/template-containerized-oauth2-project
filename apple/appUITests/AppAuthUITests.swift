//
//  AppAuthUITests.swift
//  appUITests
//

import XCTest

final class AppAuthUITests: XCTestCase {

    private var app: XCUIApplication!
    private static var counter = 0

    private static func uniqueEmail(_ prefix: String = "user") -> String {
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

    private func openSignUp() {
        let button = app.buttons["signin_goToSignUpButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
    }

    private func fillSignUpForm(email: String, password: String) {
        let emailField = app.textFields["signup_emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(email)

        let passwordField = app.secureTextFields["signup_passwordTextField"]
        passwordField.tap()
        passwordField.typeText(password)
    }

    private func submitSignUp() {
        app.buttons["signup_submitButton"].tap()
    }

    /// Create a verified user via API + Mailpit, then sign in via UI.
    private func createVerifiedUserAndSignIn(email: String) {
        TestHelpers.createVerifiedUser(email: email, password: defaultPassword)
        signIn(email: email, password: defaultPassword)
        // Dismiss "Save Password?" dialog if it appears after sign-in
        TestHelpers.dismissSystemAlerts(app: app)
        XCTAssertTrue(app.staticTexts["dashboard_userEmail"].waitForExistence(timeout: 10))
        TestHelpers.dismissSystemAlerts(app: app)
    }

    private func signIn(email: String, password: String) {
        let emailField = app.textFields["signin_emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(email)

        let passwordField = app.secureTextFields["signin_passwordTextField"]
        passwordField.tap()
        passwordField.typeText(password)

        app.buttons["signin_submitButton"].tap()
    }

    private func signOut() {
        let button = app.buttons["dashboard_signOutButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
        XCTAssertTrue(app.textFields["signin_emailTextField"].waitForExistence(timeout: 5))
    }

    // MARK: - Sign Up

    func testSignUpSuccess() throws {
        let email = Self.uniqueEmail("signup")
        openSignUp()
        fillSignUpForm(email: email, password: defaultPassword)
        submitSignUp()

        // After signup, the app shows "Check your email" instead of navigating to dashboard
        let checkEmailText = app.staticTexts["Check your email"]
        XCTAssertTrue(checkEmailText.waitForExistence(timeout: 10))

        // Verify the resend button is visible
        XCTAssertTrue(app.buttons["signup_resendButton"].waitForExistence(timeout: 5))

        // Verify the "Sign In" navigation button is visible
        XCTAssertTrue(app.buttons["signup_goToSignInButton"].waitForExistence(timeout: 5))
    }

    func testSignUpDuplicateEmail() throws {
        let email = Self.uniqueEmail("dup")

        // Create verified user via API
        TestHelpers.createVerifiedUser(email: email, password: defaultPassword)

        // Try to sign up with the same email via UI
        openSignUp()
        fillSignUpForm(email: email, password: defaultPassword)
        submitSignUp()

        let errorMessage = app.staticTexts["signup_errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 10))
    }

    // MARK: - Sign In

    func testSignInSuccess() throws {
        let email = Self.uniqueEmail("signin")
        createVerifiedUserAndSignIn(email: email)

        let label = app.staticTexts["dashboard_userEmail"]
        XCTAssertTrue(label.waitForExistence(timeout: 10))
        XCTAssertEqual(label.label, email)
    }

    func testSignInWrongPassword() throws {
        let email = Self.uniqueEmail("wrongpw")
        TestHelpers.createVerifiedUser(email: email, password: defaultPassword)

        signIn(email: email, password: "wrong_password")

        let errorMessage = app.staticTexts["signin_errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 10))
    }

    func testSignInNonExistentEmail() throws {
        signIn(
            email: "nonexistent.\(Int(Date().timeIntervalSince1970))@example.com",
            password: defaultPassword
        )

        let errorMessage = app.staticTexts["signin_errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 10))
    }

    // MARK: - Sign Out

    func testSignOut() throws {
        let email = Self.uniqueEmail("signout")
        createVerifiedUserAndSignIn(email: email)
        signOut()

        XCTAssertTrue(app.textFields["signin_emailTextField"].exists)
    }

    // MARK: - Change Email

    func testChangeEmail() throws {
        let oldEmail = Self.uniqueEmail("oldemail")
        let newEmail = Self.uniqueEmail("newemail")
        createVerifiedUserAndSignIn(email: oldEmail)

        // Navigate to Settings tab
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        // Verify current email is displayed with Verified badge
        XCTAssertTrue(app.staticTexts[oldEmail].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Verified"].exists)

        // Enter new email and save
        let emailField = app.textFields["settings_emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(newEmail)

        let saveButton = app.buttons["settings_saveEmail"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        // Should show new email as Unverified
        XCTAssertTrue(app.staticTexts[newEmail].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Unverified"].waitForExistence(timeout: 5))
    }

    // MARK: - Navigation

    func testSignInHasSignUpLink() throws {
        XCTAssertTrue(app.buttons["signin_goToSignUpButton"].waitForExistence(timeout: 5))
    }
}
