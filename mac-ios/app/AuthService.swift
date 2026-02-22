//
//  AuthService.swift
//  app
//
//  Created by user on 2026/02/21.
//

import Foundation

struct AuthUser: Codable {
    let id: String
    let email: String
    let name: String?
}

struct AuthResponse: Codable {
    let token: String
    let user: AuthUser
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailExists
    case invalidInput
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password."
        case .emailExists:
            return "An account with this email already exists."
        case .invalidInput:
            return "Please check your input and try again."
        case .networkError(let message):
            return message
        }
    }
}

@Observable
class AuthService {
    var currentUser: AuthUser?
    var token: String?

    var isAuthenticated: Bool { token != nil }

    private let baseURL = "http://localhost:3000"

    init() {
        token = UserDefaults.standard.string(forKey: "auth_token")
        if let data = UserDefaults.standard.data(forKey: "auth_user"),
           let user = try? JSONDecoder().decode(AuthUser.self, from: data) {
            currentUser = user
        }
    }

    func signIn(email: String, password: String) async throws {
        let url = URL(string: "\(baseURL)/api/mobile/signin")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["email": email, "password": password])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response from server.")
        }

        if httpResponse.statusCode == 200 {
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            persist(authResponse)
        } else {
            let errorBody = try? JSONDecoder().decode([String: String].self, from: data)
            switch errorBody?["error"] {
            case "invalid_credentials":
                throw AuthError.invalidCredentials
            default:
                throw AuthError.networkError("Authentication failed. Please try again.")
            }
        }
    }

    func signUp(name: String, email: String, password: String) async throws {
        struct SignUpBody: Encodable {
            let name: String
            let email: String
            let password: String
        }

        let url = URL(string: "\(baseURL)/api/mobile/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            SignUpBody(name: name, email: email, password: password)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response from server.")
        }

        if httpResponse.statusCode == 200 {
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            persist(authResponse)
        } else {
            let errorBody = try? JSONDecoder().decode([String: String].self, from: data)
            switch errorBody?["error"] {
            case "email_exists":
                throw AuthError.emailExists
            case "invalid_input":
                throw AuthError.invalidInput
            default:
                throw AuthError.networkError("Registration failed. Please try again.")
            }
        }
    }

    func signOut() {
        token = nil
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults.standard.removeObject(forKey: "auth_user")
    }

    private func persist(_ response: AuthResponse) {
        token = response.token
        currentUser = response.user
        UserDefaults.standard.set(response.token, forKey: "auth_token")
        if let data = try? JSONEncoder().encode(response.user) {
            UserDefaults.standard.set(data, forKey: "auth_user")
        }
    }
}
