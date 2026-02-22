//
//  DashboardView.swift
//  app
//
//  Created by user on 2026/02/21.
//

import SwiftUI

struct DashboardView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.green)

                VStack(spacing: 8) {
                    Text("Signed In")
                        .font(.title)
                        .fontWeight(.bold)

                    if let user = authService.currentUser {
                        Text("Welcome, \(user.name ?? user.email)")
                            .foregroundStyle(.secondary)
                        Text(user.email)
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                Button(role: .destructive) {
                    authService.signOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Dashboard")
        }
    }
}

#Preview {
    DashboardView()
        .environment(AuthService())
}
