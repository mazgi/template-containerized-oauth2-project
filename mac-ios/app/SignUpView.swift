//
//  SignUpView.swift
//  app
//
//  Created by user on 2026/02/21.
//

import SwiftUI

struct SignUpView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Sign up to get started")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                TextField("Full Name", text: $name)
                    .textContentType(.name)
                    .textFieldStyle(.roundedBorder)

                TextField("Email", text: $email)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    #endif
                    .textContentType(.emailAddress)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password (min. 8 characters)", text: $password)
                    .textContentType(.newPassword)
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

            Button(action: handleSignUp) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .disabled(isLoading || name.isEmpty || email.isEmpty || password.count < 8)

            Button("Already have an account? Sign In") {
                dismiss()
            }
            .foregroundStyle(.secondary)

            Spacer()
        }
        .navigationTitle("Sign Up")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func handleSignUp() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.signUp(name: name, email: email, password: password)
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
    NavigationStack {
        SignUpView()
            .environment(AuthService())
    }
}
