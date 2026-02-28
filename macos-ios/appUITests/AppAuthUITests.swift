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

    private func fillSignUpForm(email: String, password: String, confirm: String) {
        let emailField = app.textFields["signup_emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(email)

        let passwordField = app.secureTextFields["signup_passwordTextField"]
        passwordField.tap()
        passwordField.typeText(password)

        let confirmField = app.secureTextFields["signup_passwordConfirmTextField"]
        confirmField.tap()
        confirmField.typeText(confirm)
    }

    private func submitSignUp() {
        app.buttons["signup_submitButton"].tap()
    }

    private func signUp(email: String) {
        openSignUp()
        fillSignUpForm(email: email, password: defaultPassword, confirm: defaultPassword)
        submitSignUp()
        XCTAssertTrue(app.staticTexts["dashboard_userEmail"].waitForExistence(timeout: 10))
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
        signUp(email: email)

        let label = app.staticTexts["dashboard_userEmail"]
        XCTAssertEqual(label.label, email)
    }

    func testSignUpPasswordMismatch() throws {
        openSignUp()
        fillSignUpForm(
            email: Self.uniqueEmail("mismatch"),
            password: defaultPassword,
            confirm: "different_password"
        )

        let mismatchError = app.staticTexts["signup_passwordMismatchError"]
        XCTAssertTrue(mismatchError.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["signup_submitButton"].isEnabled)
    }

    func testSignUpDuplicateEmail() throws {
        let email = Self.uniqueEmail("dup")
        signUp(email: email)
        signOut()

        openSignUp()
        fillSignUpForm(email: email, password: defaultPassword, confirm: defaultPassword)
        submitSignUp()

        let errorMessage = app.staticTexts["signup_errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 10))
    }

    // MARK: - Sign In

    func testSignInSuccess() throws {
        let email = Self.uniqueEmail("signin")
        signUp(email: email)
        signOut()

        signIn(email: email, password: defaultPassword)

        let label = app.staticTexts["dashboard_userEmail"]
        XCTAssertTrue(label.waitForExistence(timeout: 10))
        XCTAssertEqual(label.label, email)
    }

    func testSignInWrongPassword() throws {
        let email = Self.uniqueEmail("wrongpw")
        signUp(email: email)
        signOut()

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
        signUp(email: email)
        signOut()

        XCTAssertTrue(app.textFields["signin_emailTextField"].exists)
    }

    // MARK: - Navigation

    func testSignInHasSignUpLink() throws {
        XCTAssertTrue(app.buttons["signin_goToSignUpButton"].waitForExistence(timeout: 5))
    }
}
