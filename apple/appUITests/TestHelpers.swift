//
//  TestHelpers.swift
//  appUITests
//

import Foundation
import XCTest

enum TestHelpers {

    static let backendURL = "http://localhost:4000"
    static let mailpitURL = "http://localhost:8025"

    // MARK: - HTTP (synchronous via URLSession + semaphore on background queue)

    /// Synchronous POST JSON. Uses a dedicated session to avoid main-thread deadlocks.
    @discardableResult
    static func postJSON(url urlString: String, body: String) throws -> String {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)
        request.timeoutInterval = 10
        return try synchronousRequest(request)
    }

    /// Synchronous GET. Returns response body as String.
    static func httpGet(url urlString: String) throws -> String {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        return try synchronousRequest(request)
    }

    private static func synchronousRequest(_ request: URLRequest) throws -> String {
        // Use ephemeral config to bypass any caching and with no ATS restrictions
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)

        var resultData: Data?
        var resultError: Error?

        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: request) { data, _, error in
            resultData = data
            resultError = error
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()

        if let error = resultError { throw error }
        guard let data = resultData else { throw URLError(.zeroByteResource) }
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Mailpit

    /// Poll Mailpit for the verification token sent to the given email address.
    static func getVerificationToken(email: String) throws -> String {
        for i in 0..<20 {
            if let token = try? fetchTokenFromMailpit(email: email) {
                return token
            }
            if i < 19 {
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
        throw NSError(
            domain: "TestHelpers",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Verification email not found for \(email) after 10s"]
        )
    }

    private static func fetchTokenFromMailpit(email: String) throws -> String? {
        let searchResult = try httpGet(
            url: "\(mailpitURL)/api/v1/search?query=to:\(email)"
        )
        guard let data = searchResult.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let messages = json["messages"] as? [[String: Any]],
              let first = messages.first,
              let msgId = first["ID"] as? String
        else { return nil }

        let msgResult = try httpGet(url: "\(mailpitURL)/api/v1/message/\(msgId)")
        guard let msgData = msgResult.data(using: .utf8),
              let msgJson = try? JSONSerialization.jsonObject(with: msgData) as? [String: Any]
        else { return nil }

        let html = (msgJson["HTML"] as? String ?? "") + (msgJson["Text"] as? String ?? "")
        guard let tokenRange = html.range(
            of: #"(?<=[?&]token=)[a-f0-9-]+"#,
            options: .regularExpression
        ) else { return nil }

        return String(html[tokenRange])
    }

    // MARK: - Password Reset Token

    /// Poll Mailpit for the password reset token sent to the given email address.
    static func getPasswordResetToken(email: String) throws -> String {
        for i in 0..<20 {
            if let token = try? fetchPasswordResetTokenFromMailpit(email: email) {
                return token
            }
            if i < 19 {
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
        throw NSError(
            domain: "TestHelpers",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Password reset email not found for \(email) after 10s"]
        )
    }

    private static func fetchPasswordResetTokenFromMailpit(email: String) throws -> String? {
        let searchResult = try httpGet(
            url: "\(mailpitURL)/api/v1/search?query=to:\(email)"
        )
        guard let data = searchResult.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let messages = json["messages"] as? [[String: Any]]
        else { return nil }

        for message in messages {
            guard let msgId = message["ID"] as? String else { continue }
            let msgResult = try httpGet(url: "\(mailpitURL)/api/v1/message/\(msgId)")
            guard let msgData = msgResult.data(using: .utf8),
                  let msgJson = try? JSONSerialization.jsonObject(with: msgData) as? [String: Any]
            else { continue }

            let body = (msgJson["HTML"] as? String ?? "") + (msgJson["Text"] as? String ?? "")
            guard body.contains("reset-password") || body.contains("Password Reset") else { continue }

            guard let tokenRange = body.range(
                of: #"(?<=[?&]token=)[a-f0-9-]+"#,
                options: .regularExpression
            ) else { continue }

            return String(body[tokenRange])
        }
        return nil
    }

    // MARK: - System Alert Dismissal

    /// Dismiss any lingering system alerts (e.g., "Save Password?") via springboard
    /// and optionally within the app itself (iOS 26 presents some system dialogs in-app).
    static func dismissSystemAlerts(app: XCUIApplication? = nil) {
        // Check springboard
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for buttonLabel in ["Not Now", "Dismiss", "Cancel", "OK"] {
            let button = springboard.buttons[buttonLabel]
            if button.waitForExistence(timeout: 1) {
                button.tap()
            }
        }
        // iOS 26: "Save Password?" may appear as in-app overlay.
        // Check both the app and the Passwords app process.
        if let app = app {
            for buttonLabel in ["Not Now", "Dismiss"] {
                let button = app.buttons[buttonLabel]
                if button.waitForExistence(timeout: 3) {
                    button.tap()
                }
            }
        }
        // Also check Passwords app (iOS 26+)
        let passwords = XCUIApplication(bundleIdentifier: "com.apple.Passwords")
        let notNow = passwords.buttons["Not Now"]
        if notNow.waitForExistence(timeout: 1) {
            notNow.tap()
        }
    }

    // MARK: - Verified User Creation

    /// Sign up via API, verify email via Mailpit. Calls XCTFail on error.
    static func createVerifiedUser(
        email: String,
        password: String = "password123",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        do {
            let signupResult = try postJSON(
                url: "\(backendURL)/auth/signup",
                body: #"{"email":"\#(email)","password":"\#(password)"}"#
            )

            // Check for signup errors
            if signupResult.contains("\"statusCode\"") && signupResult.contains("\"message\"") {
                XCTFail("Signup failed for \(email): \(signupResult)", file: file, line: line)
                return
            }

            let token = try getVerificationToken(email: email)

            try postJSON(
                url: "\(backendURL)/auth/verify-email",
                body: #"{"token":"\#(token)"}"#
            )
        } catch {
            XCTFail(
                "createVerifiedUser failed for \(email): \(error.localizedDescription)",
                file: file,
                line: line
            )
        }
    }
}
