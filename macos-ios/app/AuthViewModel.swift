import Foundation
import Observation

@Observable
@MainActor
final class AuthViewModel {
    private(set) var user: UserProfile?
    private(set) var isAuthenticated = false
    private(set) var accessToken: String?
    var isLoading = false
    var errorMessage: String?

    private let api: APIClient
    private let tokensKey = "auth_tokens"

    private struct StoredTokens: Codable {
        let accessToken: String
        let refreshToken: String
    }

    init(api: APIClient = .shared) {
        self.api = api
        Task { await restoreSession() }
    }

    // MARK: - Public actions

    func signIn(email: String, password: String) async {
        await perform {
            let res = try await self.api.signIn(email: email, password: password)
            self.store(res)
        }
    }

    func signUp(email: String, password: String) async {
        await perform {
            let res = try await self.api.signUp(email: email, password: password)
            self.store(res)
        }
    }

    func signInWithTwitter() async {
        guard let url = URL(string: "\(api.baseURL)/auth/twitter/native") else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let webAuth = WebAuthSession()
            guard let callbackURL = try await webAuth.authenticate(
                url: url,
                callbackURLScheme: "oauth2app"
            ) else {
                return // User cancelled
            }
            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
            let items = components?.queryItems ?? []
            guard
                let accessToken = items.first(where: { $0.name == "accessToken" })?.value,
                let refreshToken = items.first(where: { $0.name == "refreshToken" })?.value
            else {
                throw APIError(statusCode: 0, message: "Invalid OAuth callback URL")
            }
            let profile = try await api.me(accessToken: accessToken)
            store(AuthResponse(accessToken: accessToken, refreshToken: refreshToken, user: profile))
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signInWithGithub() async {
        guard let url = URL(string: "\(api.baseURL)/auth/github/native") else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let webAuth = WebAuthSession()
            guard let callbackURL = try await webAuth.authenticate(
                url: url,
                callbackURLScheme: "oauth2app"
            ) else {
                return // User cancelled
            }
            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
            let items = components?.queryItems ?? []
            guard
                let accessToken = items.first(where: { $0.name == "accessToken" })?.value,
                let refreshToken = items.first(where: { $0.name == "refreshToken" })?.value
            else {
                throw APIError(statusCode: 0, message: "Invalid OAuth callback URL")
            }
            let profile = try await api.me(accessToken: accessToken)
            store(AuthResponse(accessToken: accessToken, refreshToken: refreshToken, user: profile))
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signInWithGoogle() async {
        guard let url = URL(string: "\(api.baseURL)/auth/google/native") else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let webAuth = WebAuthSession()
            guard let callbackURL = try await webAuth.authenticate(
                url: url,
                callbackURLScheme: "oauth2app"
            ) else {
                return // User cancelled
            }
            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
            let items = components?.queryItems ?? []
            guard
                let accessToken = items.first(where: { $0.name == "accessToken" })?.value,
                let refreshToken = items.first(where: { $0.name == "refreshToken" })?.value
            else {
                throw APIError(statusCode: 0, message: "Invalid OAuth callback URL")
            }
            let profile = try await api.me(accessToken: accessToken)
            store(AuthResponse(accessToken: accessToken, refreshToken: refreshToken, user: profile))
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signInWithDiscord() async {
        guard let url = URL(string: "\(api.baseURL)/auth/discord/native") else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let webAuth = WebAuthSession()
            guard let callbackURL = try await webAuth.authenticate(
                url: url,
                callbackURLScheme: "oauth2app"
            ) else {
                return // User cancelled
            }
            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
            let items = components?.queryItems ?? []
            guard
                let accessToken = items.first(where: { $0.name == "accessToken" })?.value,
                let refreshToken = items.first(where: { $0.name == "refreshToken" })?.value
            else {
                throw APIError(statusCode: 0, message: "Invalid OAuth callback URL")
            }
            let profile = try await api.me(accessToken: accessToken)
            store(AuthResponse(accessToken: accessToken, refreshToken: refreshToken, user: profile))
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func linkProvider(_ provider: String) async {
        guard let token = accessToken,
              let url = URL(string: "\(api.baseURL)/auth/link/\(provider)/native?token=\(token)") else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let webAuth = WebAuthSession()
            guard let callbackURL = try await webAuth.authenticate(
                url: url,
                callbackURLScheme: "oauth2app"
            ) else {
                return // User cancelled
            }
            // Check if this was a link callback (has ?linked= param)
            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
            let items = components?.queryItems ?? []
            if items.first(where: { $0.name == "linked" }) != nil {
                // Refresh user profile to get updated linked accounts
                if let profile = try? await api.me(accessToken: token) {
                    user = profile
                }
            }
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func unlinkProvider(_ provider: String) async {
        guard let token = accessToken else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let updatedUser = try await api.unlinkProvider(accessToken: token, provider: provider)
            user = updatedUser
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAccount() async {
        guard let token = accessToken else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await api.deleteAccount(accessToken: token)
            signOut()
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: tokensKey)
        user = nil
        accessToken = nil
        isAuthenticated = false
    }

    // MARK: - Session restore

    private func restoreSession() async {
        guard let tokens = loadTokens() else { return }
        do {
            let profile = try await api.me(accessToken: tokens.accessToken)
            user = profile
            accessToken = tokens.accessToken
            isAuthenticated = true
        } catch {
            // Access token expired — try refresh
            do {
                let res = try await api.refresh(refreshToken: tokens.refreshToken)
                store(res)
            } catch {
                signOut()
            }
        }
    }

    // MARK: - Helpers

    private func perform(_ action: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await action()
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func store(_ res: AuthResponse) {
        let tokens = StoredTokens(accessToken: res.accessToken, refreshToken: res.refreshToken)
        if let data = try? JSONEncoder().encode(tokens) {
            UserDefaults.standard.set(data, forKey: tokensKey)
        }
        user = res.user
        accessToken = res.accessToken
        isAuthenticated = true
    }

    private func loadTokens() -> StoredTokens? {
        guard let data = UserDefaults.standard.data(forKey: tokensKey) else { return nil }
        return try? JSONDecoder().decode(StoredTokens.self, from: data)
    }
}
