//
//  ContentView.swift
//  app
//
//  Created by user on 2026/02/23.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var shaLabel = BuildConfig.gitSHA

    var body: some View {
        Group {
            if auth.isAuthenticated {
                TabView {
                    NavigationStack {
                        DashboardView()
                    }
                    .tabItem {
                        Label("Dashboard", systemImage: "person.circle")
                    }

                    NavigationStack {
                        ItemsView()
                    }
                    .tabItem {
                        Label("Items", systemImage: "list.bullet")
                    }

                    NavigationStack {
                        SettingsView()
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                }
            } else {
                NavigationStack {
                    SignInView()
                }
            }
        }
        .animation(.default, value: auth.isAuthenticated)
        .overlay(alignment: .bottomTrailing) {
            Text(shaLabel)
                .font(.system(size: 9))
                .foregroundStyle(.secondary.opacity(0.5))
                .padding(.trailing, 8)
                .padding(.bottom, 4)
                .allowsHitTesting(false)
                    .accessibilityIdentifier("gitShaLabel")
        }
        .task {
            let front = BuildConfig.gitSHA
            guard let url = URL(string: "\(APIClient.shared.baseURL)/health"),
                  let (data, response) = try? await URLSession.shared.data(from: url),
                  let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let back = json["gitSha"] as? String else { return }
            shaLabel = front == back ? "f/b: \(front)" : "f: \(front), b: \(back)"
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
}
