import SwiftUI

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var showDeleteConfirmation = false
    @State private var emailInput = ""
    @State private var showEmailMenu = false
    @State private var passwordResetSent = false
    @State private var totpCode = ""

    private let providers: [(key: String, label: String)] = [
        ("apple", "Apple"),
        ("discord", "Discord"),
        ("github", "GitHub"),
        ("google", "Google"),
        ("twitter", "X (Twitter)"),
    ]

    private var isInvalidEmail: Bool {
        auth.user?.email.hasSuffix(".invalid") == true
    }

    private var selectableEmails: [String] {
        (auth.user?.socialEmails ?? []).filter { $0 != auth.user?.email }
    }

    var body: some View {
        List {
            // Email section
            Section("Email") {
                HStack(spacing: 8) {
                    if isInvalidEmail {
                        Text("Not set")
                            .italic()
                            .foregroundStyle(.secondary)
                    } else {
                        Text(auth.user?.email ?? "")
                        if auth.user?.emailVerified == true {
                            Text("Verified")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.green.opacity(0.3), lineWidth: 1))
                                .accessibilityIdentifier("settings_verifiedBadge")
                        } else {
                            Text("Unverified")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.1))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.yellow.opacity(0.3), lineWidth: 1))
                                .accessibilityIdentifier("settings_unverifiedBadge")
                        }
                    }
                }

                if !isInvalidEmail && auth.user?.emailVerified == false {
                    Button("Resend verification email") {
                        Task { await auth.resendVerificationFromSettings() }
                    }
                    .disabled(auth.isLoading)
                    .accessibilityIdentifier("settings_resendVerification")
                }

                HStack {
                    TextField("Enter new email address", text: $emailInput)
                        .textContentType(.emailAddress)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        #endif
                        .accessibilityIdentifier("settings_emailTextField")

                    if !selectableEmails.isEmpty {
                        Menu {
                            ForEach(selectableEmails, id: \.self) { email in
                                Button(email) {
                                    emailInput = email
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.secondary)
                                .frame(width: 32, height: 32)
                        }
                        .accessibilityIdentifier("settings_emailDropdown")
                    }

                    Button("Save") {
                        Task { await auth.updateEmail(emailInput.trimmingCharacters(in: .whitespaces)) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        auth.isLoading
                        || emailInput.trimmingCharacters(in: .whitespaces).isEmpty
                        || emailInput.trimmingCharacters(in: .whitespaces) == auth.user?.email
                    )
                    .accessibilityIdentifier("settings_saveEmail")
                }
            }

            Section("Password") {
                if auth.user?.emailVerified != true {
                    Text("To use this feature, please verify your email address first.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("settings_passwordVerifyHint")
                } else if auth.user?.hasPassword == true {
                    Text("Send a password reset link to your email address.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Set a password so you can also sign in with email and password.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if passwordResetSent {
                    Text("Password reset link sent. Please check your inbox.")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .accessibilityIdentifier("settings_passwordResetSuccess")
                }

                Button(auth.user?.hasPassword == true ? "Send reset link" : "Send setup link") {
                    Task {
                        await auth.requestPasswordReset()
                        passwordResetSent = true
                    }
                }
                .disabled(auth.isLoading || auth.user?.emailVerified != true)
                .accessibilityIdentifier("settings_passwordReset")
            }

            Section("Two-factor authentication") {
                switch auth.mfaStep {
                case .idle:
                    if auth.user?.totpEnabled == true {
                        HStack {
                            Text("Status")
                            Spacer()
                            Text("Enabled")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.green.opacity(0.3), lineWidth: 1))
                                .accessibilityIdentifier("settings_mfaEnabledBadge")
                        }
                        Button("Disable", role: .destructive) {
                            totpCode = ""
                            auth.beginDisableTotp()
                        }
                        .accessibilityIdentifier("settings_mfaDisableButton")
                        Button("Regenerate recovery codes") {
                            totpCode = ""
                            auth.beginRegenerateRecoveryCodes()
                        }
                        .accessibilityIdentifier("settings_mfaRegenerateButton")
                    } else {
                        Text("Add an extra layer of security to your account by enabling two-factor authentication.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Enable") {
                            Task { await auth.setupTotp() }
                        }
                        .disabled(auth.isLoading)
                        .accessibilityIdentifier("settings_mfaEnableButton")
                    }
                case .setup:
                    if let secret = auth.totpSetupSecret {
                        Text("Add this secret to your authenticator app:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(secret)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .accessibilityIdentifier("settings_mfaSecret")
                    }
                    if let uri = auth.totpSetupUri {
                        Text(uri)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .accessibilityIdentifier("settings_mfaUri")
                    }
                    TextField("Enter 6-digit code", text: $totpCode)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .accessibilityIdentifier("settings_mfaSetupCodeTextField")
                    Button("Verify and enable") {
                        Task { await auth.enableTotp(code: totpCode) }
                    }
                    .disabled(auth.isLoading || totpCode.count < 6)
                    .accessibilityIdentifier("settings_mfaVerifyEnableButton")
                case .recovery:
                    if let codes = auth.recoveryCodes {
                        Text("Save these recovery codes in a safe place. Each code can only be used once.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(codes, id: \.self) { code in
                            Text(code)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                        .accessibilityIdentifier("settings_mfaRecoveryCode")
                    }
                    Button("I've saved these codes") {
                        auth.clearMfaStep()
                        totpCode = ""
                    }
                    .accessibilityIdentifier("settings_mfaSavedCodesButton")
                case .disable:
                    Text("Enter a code from your authenticator app to disable MFA.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Enter 6-digit code", text: $totpCode)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .accessibilityIdentifier("settings_mfaDisableCodeTextField")
                    Button("Disable MFA", role: .destructive) {
                        Task { await auth.disableTotp(code: totpCode) }
                    }
                    .disabled(auth.isLoading || totpCode.count < 6)
                    .accessibilityIdentifier("settings_mfaConfirmDisableButton")
                    Button("Cancel") {
                        auth.clearMfaStep()
                        totpCode = ""
                    }
                    .accessibilityIdentifier("settings_mfaCancelButton")
                case .regenerate:
                    Text("Enter a code from your authenticator app to regenerate recovery codes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Enter 6-digit code", text: $totpCode)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .accessibilityIdentifier("settings_mfaRegenerateCodeTextField")
                    Button("Regenerate") {
                        Task { await auth.regenerateRecoveryCodes(code: totpCode) }
                    }
                    .disabled(auth.isLoading || totpCode.count < 6)
                    .accessibilityIdentifier("settings_mfaConfirmRegenerateButton")
                    Button("Cancel") {
                        auth.clearMfaStep()
                        totpCode = ""
                    }
                    .accessibilityIdentifier("settings_mfaRegenCancelButton")
                }
            }

            Section("Linked Accounts") {
                ForEach(providers, id: \.key) { provider in
                    HStack {
                        Text(provider.label)
                        Spacer()
                        if isLinked(provider.key) {
                            Button("Unlink", role: .destructive) {
                                Task { await auth.unlinkProvider(provider.key) }
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("settings_unlink_\(provider.key)")
                        } else {
                            Button("Link") {
                                Task { await auth.linkProvider(provider.key) }
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("settings_link_\(provider.key)")
                        }
                    }
                }
            }

            Section("Theme") {
                Picker("Theme", selection: Binding(
                    get: { auth.themeMode },
                    set: { newMode in Task { await auth.setTheme(newMode) } }
                )) {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("settings_themePicker")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Permanently delete your account and all associated data. This action cannot be undone.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Delete Account", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .accessibilityIdentifier("settings_deleteAccount")
                }
            } header: {
                Text("Delete Account")
            }

            if let error = auth.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

        }
        .navigationTitle("Settings")
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { await auth.deleteAccount() }
            }
        } message: {
            Text("Are you sure you want to delete your account? This cannot be undone.")
        }
        #if os(macOS)
        .frame(minWidth: 300)
        #endif
    }

    private func isLinked(_ provider: String) -> Bool {
        guard let user = auth.user else { return false }
        switch provider {
        case "apple": return user.appleId != nil
        case "discord": return user.discordId != nil
        case "github": return user.githubId != nil
        case "google": return user.googleId != nil
        case "twitter": return user.twitterId != nil
        default: return false
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AuthViewModel())
}
