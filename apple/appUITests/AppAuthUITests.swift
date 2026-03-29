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

    private func tapTab(_ label: String) {
        TestHelpers.dismissSystemAlerts(app: app)
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

    private func signOut() {
        let button = app.buttons["dashboard_signOutButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
        XCTAssertTrue(app.textFields["signin_emailTextField"].waitForExistence(timeout: 10))
    }

    // MARK: - Sign Up

    func testSignUpSuccess() throws {
        let email = Self.uniqueEmail("signup")
        openSignUp()
        fillSignUpForm(email: email, password: defaultPassword)
        submitSignUp()

        // After signup, the app shows "Check your email" instead of navigating to dashboard
        let checkEmailText = app.staticTexts["signup_checkYourEmail"]
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
        tapTab("Settings")

        // Verify current email is displayed with Verified badge
        XCTAssertTrue(app.staticTexts[oldEmail].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["settings_verifiedBadge"].waitForExistence(timeout: 5))

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
        XCTAssertTrue(app.staticTexts["settings_unverifiedBadge"].waitForExistence(timeout: 5))
    }

    // MARK: - Password Reset

    func testPasswordReset_SendResetLinkFromSettings() throws {
        let email = Self.uniqueEmail("pwreset")
        createVerifiedUserAndSignIn(email: email)

        // Navigate to Settings tab
        tapTab("Settings")

        // Tap "Send reset link"
        let resetButton = app.buttons["settings_passwordReset"]
        XCTAssertTrue(resetButton.waitForExistence(timeout: 10))
        resetButton.tap()

        // Wait for success message
        let successText = app.staticTexts["settings_passwordResetSuccess"]
        XCTAssertTrue(successText.waitForExistence(timeout: 15))

        // Verify reset email arrived in Mailpit
        let token = try TestHelpers.getPasswordResetToken(email: email)
        XCTAssertFalse(token.isEmpty)
    }

    func testPasswordReset_ResetAndSignInWithNewPassword() throws {
        let email = Self.uniqueEmail("pwresetlogin")
        let newPassword = "newpassword456"
        createVerifiedUserAndSignIn(email: email)

        // Request password reset via API
        try TestHelpers.postJSON(
            url: "\(TestHelpers.backendURL)/auth/forgot-password",
            body: #"{"email":"\#(email)"}"#
        )

        // Get reset token and reset password via API
        let token = try TestHelpers.getPasswordResetToken(email: email)
        try TestHelpers.postJSON(
            url: "\(TestHelpers.backendURL)/auth/reset-password",
            body: #"{"token":"\#(token)","password":"\#(newPassword)"}"#
        )

        // Sign out
        signOut()

        // Sign in with new password
        signIn(email: email, password: newPassword)
        TestHelpers.dismissSystemAlerts(app: app)

        let userEmail = app.staticTexts["dashboard_userEmail"]
        XCTAssertTrue(userEmail.waitForExistence(timeout: 10))
        XCTAssertEqual(userEmail.label, email)
    }

    func testPasswordReset_OldPasswordFailsAfterReset() throws {
        let email = Self.uniqueEmail("pwold")
        let newPassword = "newpassword789"
        createVerifiedUserAndSignIn(email: email)

        // Request password reset via API and reset
        try TestHelpers.postJSON(
            url: "\(TestHelpers.backendURL)/auth/forgot-password",
            body: #"{"email":"\#(email)"}"#
        )
        let token = try TestHelpers.getPasswordResetToken(email: email)
        try TestHelpers.postJSON(
            url: "\(TestHelpers.backendURL)/auth/reset-password",
            body: #"{"token":"\#(token)","password":"\#(newPassword)"}"#
        )

        // Sign out
        signOut()

        // Try to sign in with old password — should fail
        signIn(email: email, password: defaultPassword)

        let errorMessage = app.staticTexts["signin_errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 10))
    }

    func testPasswordReset_ButtonDisabledWhenEmailUnverified() throws {
        let oldEmail = Self.uniqueEmail("pwunverified")
        let newEmail = Self.uniqueEmail("pwunverifiednew")
        createVerifiedUserAndSignIn(email: oldEmail)

        // Navigate to Settings
        tapTab("Settings")

        // Change email to reset verification
        let emailField = app.textFields["settings_emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(newEmail)

        let saveButton = app.buttons["settings_saveEmail"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        // Wait for "Unverified" badge
        XCTAssertTrue(app.staticTexts["settings_unverifiedBadge"].waitForExistence(timeout: 10))

        // The password reset button should be disabled
        let resetButton = app.buttons["settings_passwordReset"]
        XCTAssertTrue(resetButton.waitForExistence(timeout: 5))
        XCTAssertFalse(resetButton.isEnabled)

        // Verify description text
        XCTAssertTrue(
            app.staticTexts["settings_passwordVerifyHint"]
                .waitForExistence(timeout: 5)
        )
    }

    // MARK: - Forgot Password from Sign In

    func testForgotPassword_ShowsButtonOnSignInPage() throws {
        XCTAssertTrue(app.buttons["signin_forgotPasswordButton"].waitForExistence(timeout: 5))
    }

    func testForgotPassword_ShowsErrorWithoutEmail() throws {
        let button = app.buttons["signin_forgotPasswordButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()

        let errorMessage = app.staticTexts["signin_errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 10))
    }

    func testForgotPassword_ShowsSuccessMessage() throws {
        let email = Self.uniqueEmail("forgotpw")
        TestHelpers.createVerifiedUser(email: email, password: defaultPassword)

        let emailField = app.textFields["signin_emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(email)

        app.buttons["signin_forgotPasswordButton"].tap()

        let successText = app.staticTexts["signin_resetSentMessage"]
        XCTAssertTrue(successText.waitForExistence(timeout: 15))
    }

    func testForgotPassword_FullResetFlow() throws {
        let email = Self.uniqueEmail("forgotflow")
        let newPassword = "resetfromlogin123"
        TestHelpers.createVerifiedUser(email: email, password: defaultPassword)

        // Request reset from sign-in page
        let emailField = app.textFields["signin_emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(email)

        app.buttons["signin_forgotPasswordButton"].tap()

        let successText = app.staticTexts["signin_resetSentMessage"]
        XCTAssertTrue(successText.waitForExistence(timeout: 15))

        // Get reset token from Mailpit and reset password via API
        let token = try TestHelpers.getPasswordResetToken(email: email)
        try TestHelpers.postJSON(
            url: "\(TestHelpers.backendURL)/auth/reset-password",
            body: #"{"token":"\#(token)","password":"\#(newPassword)"}"#
        )

        // Sign in with new password
        // Clear fields first
        let emailField2 = app.textFields["signin_emailTextField"]
        emailField2.tap()
        emailField2.press(forDuration: 1.0)
        app.menuItems["Select All"].tap()
        emailField2.typeText(email)

        let passwordField = app.secureTextFields["signin_passwordTextField"]
        passwordField.tap()
        passwordField.typeText(newPassword)

        app.buttons["signin_submitButton"].tap()
        TestHelpers.dismissSystemAlerts(app: app)

        let userEmail = app.staticTexts["dashboard_userEmail"]
        XCTAssertTrue(userEmail.waitForExistence(timeout: 10))
        XCTAssertEqual(userEmail.label, email)
    }

    func testForgotPassword_SuccessForNonExistentEmail() throws {
        let emailField = app.textFields["signin_emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText("nonexistent.\(Int(Date().timeIntervalSince1970))@example.com")

        app.buttons["signin_forgotPasswordButton"].tap()

        // Should still show success to prevent email enumeration
        let successText = app.staticTexts["signin_resetSentMessage"]
        XCTAssertTrue(successText.waitForExistence(timeout: 15))
    }

    // MARK: - Navigation

    func testSignInHasSignUpLink() throws {
        XCTAssertTrue(app.buttons["signin_goToSignUpButton"].waitForExistence(timeout: 5))
    }

    func testSignUpHasForgotPasswordLink() throws {
        openSignUp()
        XCTAssertTrue(app.buttons["signup_forgotPasswordButton"].waitForExistence(timeout: 5))
    }
}
