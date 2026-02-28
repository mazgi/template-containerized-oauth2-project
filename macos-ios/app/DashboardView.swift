import SwiftUI

struct DashboardView: View {
    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(Color.accentColor)

            if let user = auth.user {
                VStack(spacing: 6) {
                    Text(user.email)
                        .font(.title2)
                        .bold()
                        .accessibilityIdentifier("dashboard_userEmail")

                    if let name = user.name {
                        Text(name)
                            .foregroundStyle(.secondary)
                    }

                    Text("ID: \(user.id)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                VStack(spacing: 4) {
                    labeledDate("Created", iso: user.createdAt)
                    labeledDate("Updated", iso: user.updatedAt)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }

            Spacer()

            Button("Sign Out", role: .destructive) {
                auth.signOut()
            }
            .buttonStyle(.bordered)
            .padding(.bottom, 32)
            .accessibilityIdentifier("dashboard_signOutButton")
        }
        .padding()
        .navigationTitle("Dashboard")
        #if os(macOS)
        .frame(minWidth: 300)
        #endif
    }

    private func labeledDate(_ label: String, iso: String) -> some View {
        HStack {
            Text("\(label):")
                .fontWeight(.medium)
            Text(formatISO(iso))
        }
    }

    private func formatISO(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: iso) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return iso
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .environment(AuthViewModel())
}
