import Foundation

// MARK: - Request models

struct SignInRequest: Encodable {
    let email: String
    let password: String
}

struct SignUpRequest: Encodable {
    let email: String
    let password: String
}

struct RefreshRequest: Encodable {
    let refreshToken: String
}

struct CreateItemRequest: Encodable {
    let name: String
}

struct UpdateEmailRequest: Encodable {
    let email: String
}

private struct EmptyBody: Encodable {}

// MARK: - Response models

struct UserPreferences: Codable {
    var theme: String?
}

struct UserProfile: Decodable, Identifiable {
    let id: String
    let email: String
    let emailVerified: Bool
    let name: String?
    let appleId: String?
    let githubId: String?
    let googleId: String?
    let twitterId: String?
    let discordId: String?
    let hasPassword: Bool?
    let totpEnabled: Bool?
    let socialEmails: [String]?
    let preferences: UserPreferences?
    let createdAt: String
    let updatedAt: String
}

struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: UserProfile
}

struct MessageResponse: Decodable {
    let message: String
}

// MARK: - MFA models

struct MfaRequiredResponse: Decodable {
    let requiresMfa: Bool
    let mfaToken: String
}

struct TotpSetupResponse: Decodable {
    let secret: String
    let uri: String
}

struct TotpEnableResponse: Decodable {
    let recoveryCodes: [String]
}

struct TotpVerifyRequest: Encodable {
    let mfaToken: String
    let code: String
}

struct TotpCodeRequest: Encodable {
    let code: String
}

enum SignInResult {
    case success(AuthResponse)
    case mfaRequired(String) // mfaToken
}

// MARK: - Error

struct APIError: Error, LocalizedError {
    let statusCode: Int
    let message: String

    var errorDescription: String? { message }

    // NestJS can return message as String or [String]
    private struct RawBody: Decodable {
        let statusCode: Int?
        let message: MessageValue?
        let error: String?

        enum MessageValue: Decodable {
            case string(String)
            case array([String])

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let str = try? container.decode(String.self) {
                    self = .string(str)
                } else {
                    self = .array((try? container.decode([String].self)) ?? [])
                }
            }

            var text: String {
                switch self {
                case .string(let s): return s
                case .array(let a): return a.joined(separator: "\n")
                }
            }
        }
    }

    static func from(data: Data, statusCode: Int) -> APIError {
        if let raw = try? JSONDecoder().decode(RawBody.self, from: data) {
            return APIError(
                statusCode: raw.statusCode ?? statusCode,
                message: raw.message?.text ?? "HTTP \(statusCode)"
            )
        }
        return APIError(statusCode: statusCode, message: "HTTP \(statusCode)")
    }
}

// MARK: - Client

final class APIClient {
    static let shared = APIClient()

    private let defaultBaseURL: String
    var baseURL: String {
        #if DEBUG
        if let override = UserDefaults.standard.string(forKey: "debug_api_base_url"), !override.isEmpty {
            return override
        }
        #endif
        return defaultBaseURL
    }
    private let session: URLSession

    init(baseURL: String = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String ?? "http://localhost:4000") {
        self.defaultBaseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    func signIn(email: String, password: String) async throws -> SignInResult {
        guard let url = URL(string: baseURL + "/auth/signin") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(SignInRequest(email: email, password: password))
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: http.statusCode)
        }
        if let mfa = try? JSONDecoder().decode(MfaRequiredResponse.self, from: data), mfa.requiresMfa {
            return .mfaRequired(mfa.mfaToken)
        }
        let authRes = try JSONDecoder().decode(AuthResponse.self, from: data)
        return .success(authRes)
    }

    func signUp(email: String, password: String) async throws -> MessageResponse {
        try await post("/auth/signup", body: SignUpRequest(email: email, password: password))
    }

    func verifyEmail(token: String) async throws -> MessageResponse {
        try await post("/auth/verify-email", body: ["token": token])
    }

    func resendVerification(email: String) async throws -> MessageResponse {
        try await post("/auth/resend-verification", body: ["email": email])
    }

    func refresh(refreshToken: String) async throws -> AuthResponse {
        try await post("/auth/refresh", body: RefreshRequest(refreshToken: refreshToken))
    }

    func me(accessToken: String) async throws -> UserProfile {
        try await get("/auth/me", token: accessToken)
    }

    func getItems(accessToken: String) async throws -> [ItemResponse] {
        try await get("/items", token: accessToken)
    }

    func createItem(accessToken: String, name: String) async throws -> ItemResponse {
        try await post("/items", body: CreateItemRequest(name: name), token: accessToken)
    }

    func deleteItem(accessToken: String, id: String) async throws {
        try await delete("/items/\(id)", token: accessToken)
    }

    func unlinkProvider(accessToken: String, provider: String) async throws -> UserProfile {
        try await deleteWithResponse("/auth/link/\(provider)", token: accessToken)
    }

    func updatePreferences(accessToken: String, preferences: UserPreferences) async throws -> UserProfile {
        try await patch("/users/me/preferences", body: preferences, token: accessToken)
    }

    func updateEmail(accessToken: String, email: String) async throws -> UserProfile {
        try await patch("/auth/email", body: UpdateEmailRequest(email: email), token: accessToken)
    }

    func forgotPassword(email: String) async throws -> MessageResponse {
        try await post("/auth/forgot-password", body: ["email": email])
    }

    func deleteAccount(accessToken: String) async throws {
        try await delete("/auth/account", token: accessToken)
    }

    // MARK: - TOTP

    func totpSetup(accessToken: String) async throws -> TotpSetupResponse {
        try await post("/auth/totp/setup", body: EmptyBody(), token: accessToken)
    }

    func totpEnable(accessToken: String, code: String) async throws -> TotpEnableResponse {
        try await post("/auth/totp/enable", body: TotpCodeRequest(code: code), token: accessToken)
    }

    func totpDisable(accessToken: String, code: String) async throws -> MessageResponse {
        try await post("/auth/totp/disable", body: TotpCodeRequest(code: code), token: accessToken)
    }

    func totpVerify(mfaToken: String, code: String) async throws -> AuthResponse {
        try await post("/auth/totp/verify", body: TotpVerifyRequest(mfaToken: mfaToken, code: code))
    }

    func totpRegenerateRecoveryCodes(accessToken: String, code: String) async throws -> TotpEnableResponse {
        try await post("/auth/totp/regenerate-recovery-codes", body: TotpCodeRequest(code: code), token: accessToken)
    }

    // MARK: - Helpers

    private func post<Req: Encodable, Res: Decodable>(_ path: String, body: Req) async throws -> Res {
        guard let url = URL(string: baseURL + path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }

    private func post<Req: Encodable, Res: Decodable>(_ path: String, body: Req, token: String) async throws -> Res {
        guard let url = URL(string: baseURL + path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }

    private func patch<Req: Encodable, Res: Decodable>(_ path: String, body: Req, token: String) async throws -> Res {
        guard let url = URL(string: baseURL + path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }

    private func get<Res: Decodable>(_ path: String, token: String) async throws -> Res {
        guard let url = URL(string: baseURL + path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await perform(request)
    }

    private func deleteWithResponse<Res: Decodable>(_ path: String, token: String) async throws -> Res {
        guard let url = URL(string: baseURL + path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await perform(request)
    }

    private func delete(_ path: String, token: String) async throws {
        guard let url = URL(string: baseURL + path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: http.statusCode)
        }
    }

    private func perform<Res: Decodable>(_ request: URLRequest) async throws -> Res {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: http.statusCode)
        }
        return try JSONDecoder().decode(Res.self, from: data)
    }
}
