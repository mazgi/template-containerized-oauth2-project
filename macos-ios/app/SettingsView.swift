import SwiftUI

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var showDeleteConfirmation = false

    private let providers: [(key: String, label: String)] = [
        ("apple", "Apple"),
        ("discord", "Discord"),
        ("github", "GitHub"),
        ("google", "Google"),
        ("twitter", "X (Twitter)"),
    ]

    var body: some View {
        List {
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
