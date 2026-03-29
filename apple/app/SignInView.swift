import SwiftUI

struct SignInView: View {
    @Environment(AuthViewModel.self) private var auth

    @State private var email = ""
    @State private var password = ""
    @State private var passwordVisible = false
    @State private var showSignUp = false
    @State private var mfaCode = ""

    var body: some View {
        if auth.mfaToken != nil {
            mfaChallengeView
        } else {
            signInFormView
        }
    }

    private var mfaChallengeView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(Color.accentColor)

            Text("Two-factor authentication")
                .font(.largeTitle)
                .bold()
                .accessibilityIdentifier("mfa_title")

            Text("Enter the 6-digit code from your authenticator app")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let error = auth.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .accessibilityIdentifier("mfa_errorMessage")
            }

            TextField("000000", text: $mfaCode)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .font(.title2.monospaced())
                .frame(maxWidth: 200)
                .accessibilityIdentifier("mfa_codeTextField")

            Button {
                Task { await auth.verifyMfa(code: mfaCode) }
            } label: {
                Group {
                    if auth.isLoading {
                        ProgressView()
                    } else {
                        Text("Verify")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 20)
            }
            .buttonStyle(.borderedProminent)
            .disabled(auth.isLoading || mfaCode.count < 6)
            .accessibilityIdentifier("mfa_verifyButton")

            Text("You can also use a recovery code")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: 400)
        .frame(maxWidth: .infinity)
    }

    private var signInFormView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(Color.accentColor)

            Text("Sign In")
                .font(.largeTitle)
                .bold()

            if let error = auth.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .accessibilityIdentifier("signin_errorMessage")
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
                    .accessibilityIdentifier("signin_emailTextField")

                HStack {
                    Group {
                        if passwordVisible {
                            TextField("Password", text: $password)
                                .textContentType(.oneTimeCode)
                        } else {
                            SecureField("Password", text: $password)
                                .textContentType(.oneTimeCode)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("signin_passwordTextField")

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

            HStack {
                Spacer()
                Button {
                    if email.isEmpty {
                        auth.errorMessage = "Please enter your email address first."
                    } else {
                        Task { await auth.requestPasswordResetFromSignIn(email: email) }
                    }
                } label: {
                    Text("Forgot password?")
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .disabled(auth.isLoading)
                .accessibilityIdentifier("signin_forgotPasswordButton")
            }

            if auth.passwordResetSent {
                Text("Password reset link sent. Please check your inbox.")
                    .font(.callout)
                    .foregroundStyle(.green)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("signin_resetSentMessage")
            }

            Button {
                Task { await auth.signIn(email: email, password: password) }
            } label: {
                Group {
                    if auth.isLoading {
                        ProgressView()
                    } else {
                        Text("Sign In")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 20)
            }
            .buttonStyle(.borderedProminent)
            .disabled(auth.isLoading || email.isEmpty || password.isEmpty)
            .accessibilityIdentifier("signin_submitButton")

            HStack {
                VStack { Divider() }
                Text("or").foregroundStyle(.secondary).font(.callout)
                VStack { Divider() }
            }

            Button {
                Task { await auth.signInWithApple() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                    Text("Sign in with Apple")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 20)
            }
            .buttonStyle(.bordered)
            .disabled(auth.isLoading)

            Button {
                Task { await auth.signInWithDiscord() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "message")
                    Text("Sign in with Discord")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 20)
            }
            .buttonStyle(.bordered)
            .disabled(auth.isLoading)

            Button {
                Task { await auth.signInWithGithub() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                    Text("Sign in with GitHub")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 20)
            }
            .buttonStyle(.bordered)
            .disabled(auth.isLoading)

            Button {
                Task { await auth.signInWithGoogle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                    Text("Sign in with Google")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 20)
            }
            .buttonStyle(.bordered)
            .disabled(auth.isLoading)

            Button {
                Task { await auth.signInWithTwitter() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                    Text("Sign in with X")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 20)
            }
            .buttonStyle(.bordered)
            .disabled(auth.isLoading)

            Button("Don't have an account? Sign Up") {
                showSignUp = true
            }
            .font(.callout)
            .accessibilityIdentifier("signin_goToSignUpButton")

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: 400)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
    }
}

#Preview {
    SignInView()
        .environment(AuthViewModel())
}
