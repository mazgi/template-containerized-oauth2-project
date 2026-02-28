import AuthenticationServices
import Foundation

/// Wraps ASWebAuthenticationSession for use with async/await.
/// Returns nil when the user cancels the flow.
@MainActor
final class WebAuthSession: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(macOS)
        return NSApp.windows.first { $0.isKeyWindow } ?? NSApp.windows.first ?? NSWindow()
        #else
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
        #endif
    }

    /// Opens the given URL in an in-app browser and waits for a redirect to `callbackURLScheme`.
    /// Returns the full callback URL, or nil if the user cancelled.
    func authenticate(url: URL, callbackURLScheme: String) async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURLScheme
            ) { callbackURL, error in
                if let url = callbackURL {
                    continuation.resume(returning: url)
                } else if let error = error as? ASWebAuthenticationSessionError,
                          error.code == .canceledLogin {
                    continuation.resume(returning: nil)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: URLError(.unknown))
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            self.session = session
            session.start()
        }
    }
}
