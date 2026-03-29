import SwiftUI

struct SignUpView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var passwordVisible = false

    private var canSubmit: Bool {
        !auth.isLoading
            && !email.isEmpty
            && password.count >= 8
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if auth.verificationSentEmail != nil {
                Image(systemName: "envelope.badge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundStyle(Color.accentColor)

                Text("Check your email")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityIdentifier("signup_checkYourEmail")

                Text("We've sent a verification link to your email address. Please check your inbox and click the link to verify your account.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    if let email = auth.verificationSentEmail {
                        Task { await auth.resendVerification(email: email) }
                    }
                } label: {
                    Group {
                        if auth.isLoading {
                            ProgressView()
                        } else {
                            Text("Resend verification email")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
                }
                .buttonStyle(.borderedProminent)
                .disabled(auth.isLoading)
                .accessibilityIdentifier("signup_resendButton")

                Button("Sign In") {
                    auth.clearVerificationSent()
                    dismiss()
                }
                .font(.callout)
                .accessibilityIdentifier("signup_goToSignInButton")
            } else {
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

                    HStack {
                        Group {
                            if passwordVisible {
                                TextField("Password (min 8 characters)", text: $password)
                                    .textContentType(.oneTimeCode)
                            } else {
                                SecureField("Password (min 8 characters)", text: $password)
                                    .textContentType(.oneTimeCode)
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("signup_passwordTextField")

                        Button {
                            passwordVisible.toggle()
                        } label: {
                            Image(systemName: passwordVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(passwordVisible ? "Hide password" : "Show password")
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

                Button("Forgot password?") {
                    dismiss()
                }
                .font(.callout)
                .accessibilityIdentifier("signup_forgotPasswordButton")
            }

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
