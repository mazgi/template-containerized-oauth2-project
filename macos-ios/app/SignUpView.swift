import SwiftUI

struct SignUpView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirm = ""

    private var passwordMismatch: Bool {
        !passwordConfirm.isEmpty && password != passwordConfirm
    }

    private var canSubmit: Bool {
        !auth.isLoading
            && !email.isEmpty
            && password.count >= 8
            && !passwordMismatch
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(Color.accentColor)

            Text("Create Account")
                .font(.largeTitle)
                .bold()

            if let error = auth.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .accessibilityIdentifier("signup_errorMessage")
            }

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    #endif
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("signup_emailTextField")

                SecureField("Password (min 8 characters)", text: $password)
                    // .oneTimeCode disables iOS Password AutoFill. Without this, iOS detects
                    // two adjacent SecureFields as a "create password" pattern and auto-fills
                    // both with a generated password, breaking XCUITest typeText() input.
                    .textContentType(.oneTimeCode)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("signup_passwordTextField")

                SecureField("Confirm Password", text: $passwordConfirm)
                    .textContentType(.oneTimeCode) // same reason as above
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("signup_passwordConfirmTextField")

                if passwordMismatch {
                    Text("Passwords do not match")
                        .foregroundStyle(.red)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("signup_passwordMismatchError")
                }
            }

            Button {
                Task { await auth.signUp(email: email, password: password) }
            } label: {
                Group {
                    if auth.isLoading {
                        ProgressView()
                    } else {
                        Text("Create Account")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 20)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSubmit)
            .accessibilityIdentifier("signup_submitButton")

            Button("Already have an account? Sign In") {
                dismiss()
            }
            .font(.callout)
            .accessibilityIdentifier("signup_goToSignInButton")

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: 400)
        .frame(maxWidth: .infinity)
        .onChange(of: auth.isAuthenticated) { _, isAuth in
            if isAuth { dismiss() }
        }
    }
}

#Preview {
    SignUpView()
        .environment(AuthViewModel())
}
