import SwiftUI

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var showDeleteConfirmation = false
    @State private var emailInput = ""
    @State private var showEmailMenu = false
    @State private var passwordResetSent = false

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
