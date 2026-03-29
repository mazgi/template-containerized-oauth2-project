import Foundation
import Observation
import SwiftUI

enum ThemeMode: String, CaseIterable {
    case system, light, dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum MfaStep {
    case idle, setup, recovery, disable, regenerate
}

@Observable
@MainActor
final class AuthViewModel {
    private(set) var user: UserProfile?
    private(set) var isAuthenticated = false
    private(set) var accessToken: String?
    private(set) var themeMode: ThemeMode = .system
    var isLoading = false
    var errorMessage: String?
    private(set) var verificationSentEmail: String?
    private(set) var mfaToken: String?
    private(set) var totpSetupUri: String?
    private(set) var totpSetupSecret: String?
    private(set) var recoveryCodes: [String]?
    private(set) var mfaStep: MfaStep = .idle
    private(set) var passwordResetSent = false

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
            let result = try await self.api.signIn(email: email, password: password)
            switch result {
            case .success(let res):
                self.mfaToken = nil
                self.store(res)
            case .mfaRequired(let token):
                self.mfaToken = token
            }
        }
    }

    func signUp(email: String, password: String) async {
        await perform {
            _ = try await self.api.signUp(email: email, password: password)
            self.verificationSentEmail = email
        }
    }

    func resendVerification(email: String) async {
        await perform {
            _ = try await self.api.resendVerification(email: email)
        }
    }

    func clearVerificationSent() {
        verificationSentEmail = nil
    }

    func signInWithTwitter() async {
        await signInWithOAuth(provider: "twitter")
    }

    func signInWithGithub() async {
        await signInWithOAuth(provider: "github")
    }

    func signInWithGoogle() async {
        await signInWithOAuth(provider: "google")
    }

    func signInWithApple() async {
        await signInWithOAuth(provider: "apple")
    }

    func signInWithDiscord() async {
        await signInWithOAuth(provider: "discord")
    }

    private func signInWithOAuth(provider: String) async {
        guard let url = URL(string: "\(api.baseURL)/auth/\(provider)/native") else { return }
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

    func updateEmail(_ newEmail: String) async {
        guard let token = accessToken else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let updatedUser = try await api.updateEmail(accessToken: token, email: newEmail)
            user = updatedUser
        } catch let e as APIError {
            errorMessage = e.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resendVerificationFromSettings() async {
        guard let email = user?.email else { return }
        await perform {
            _ = try await self.api.resendVerification(email: email)
        }
    }

    func requestPasswordReset() async {
        guard let email = user?.email else { return }
        await perform {
            _ = try await self.api.forgotPassword(email: email)
        }
    }

    func requestPasswordResetFromSignIn(email: String) async {
        await perform {
            _ = try await self.api.forgotPassword(email: email)
            self.passwordResetSent = true
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

    func setTheme(_ mode: ThemeMode) async {
        themeMode = mode
        guard let token = accessToken else { return }
        do {
            let updated = try await api.updatePreferences(
                accessToken: token,
                preferences: UserPreferences(theme: mode.rawValue)
            )
            user = updated
        } catch {
            // Theme already applied locally; ignore network errors
        }
    }

    // MARK: - MFA

    func verifyMfa(code: String) async {
        guard let token = mfaToken else { return }
        await perform {
            let res = try await self.api.totpVerify(mfaToken: token, code: code)
            self.mfaToken = nil
            self.store(res)
        }
    }

    func setupTotp() async {
        guard let token = accessToken else { return }
        await perform {
            let res = try await self.api.totpSetup(accessToken: token)
            self.totpSetupUri = res.uri
            self.totpSetupSecret = res.secret
            self.mfaStep = .setup
        }
    }

    func enableTotp(code: String) async {
        guard let token = accessToken else { return }
        await perform {
            let res = try await self.api.totpEnable(accessToken: token, code: code)
            self.recoveryCodes = res.recoveryCodes
            self.totpSetupUri = nil
            self.totpSetupSecret = nil
            self.mfaStep = .recovery
            // Refresh user profile to reflect totpEnabled
            if let profile = try? await self.api.me(accessToken: token) {
                self.user = profile
            }
        }
    }

    func disableTotp(code: String) async {
        guard let token = accessToken else { return }
        await perform {
            _ = try await self.api.totpDisable(accessToken: token, code: code)
            self.mfaStep = .idle
            // Refresh user profile to reflect totpEnabled
            if let profile = try? await self.api.me(accessToken: token) {
                self.user = profile
            }
        }
    }

    func regenerateRecoveryCodes(code: String) async {
        guard let token = accessToken else { return }
        await perform {
            let res = try await self.api.totpRegenerateRecoveryCodes(accessToken: token, code: code)
            self.recoveryCodes = res.recoveryCodes
            self.mfaStep = .recovery
        }
    }

    func clearMfaStep() {
        mfaStep = .idle
        totpSetupUri = nil
        totpSetupSecret = nil
        recoveryCodes = nil
    }

    func beginDisableTotp() {
        mfaStep = .disable
    }

    func beginRegenerateRecoveryCodes() {
        mfaStep = .regenerate
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: tokensKey)
        user = nil
        accessToken = nil
        isAuthenticated = false
        themeMode = .system
        mfaToken = nil
        mfaStep = .idle
        totpSetupUri = nil
        totpSetupSecret = nil
        recoveryCodes = nil
        passwordResetSent = false
    }

    // MARK: - Session restore

    private func restoreSession() async {
        guard let tokens = loadTokens() else { return }
        do {
            let profile = try await api.me(accessToken: tokens.accessToken)
            user = profile
            accessToken = tokens.accessToken
            isAuthenticated = true
            syncTheme(from: profile)
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
        syncTheme(from: res.user)
    }

    private func syncTheme(from profile: UserProfile) {
        if let raw = profile.preferences?.theme, let mode = ThemeMode(rawValue: raw) {
            themeMode = mode
        } else {
            themeMode = .system
        }
    }

    private func loadTokens() -> StoredTokens? {
        guard let data = UserDefaults.standard.data(forKey: tokensKey) else { return nil }
        return try? JSONDecoder().decode(StoredTokens.self, from: data)
    }
}
