//
//  LoginView.swift
//  app
//
//  Created by user on 2026/02/21.
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var authService

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Sign in to your account")
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                        .textContentType(.emailAddress)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button(action: handleSignIn) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(isLoading || email.isEmpty || password.isEmpty)

                Button("Don't have an account? Sign Up") {
                    showSignUp = true
                }
                .foregroundStyle(.secondary)

                Spacer()
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }

    private func handleSignIn() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch let error as AuthError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "An unexpected error occurred."
            }
            isLoading = false
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthService())
}
