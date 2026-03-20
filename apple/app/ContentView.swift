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
    @State private var selectedTab = 0
    #if DEBUG
    @State private var showDebugSettings = false
    #endif

    private var isUITesting: Bool {
        CommandLine.arguments.contains("--uitesting")
    }

    var body: some View {
        Group {
            if auth.isAuthenticated {
                VStack(spacing: 0) {
                    if isUITesting {
                        // Test-only segmented picker for XCUITest tab navigation.
                        // iOS 26 Liquid Glass tab bar doesn't respond to
                        // XCUITest synthesized taps, so this picker provides
                        // a reliable programmatic alternative.
                        Picker("Tab", selection: $selectedTab) {
                            Text(verbatim: "Dashboard").tag(0)
                            Text(verbatim: "Items").tag(1)
                            Text(verbatim: "Settings").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("test_tabPicker")
                        .padding(.horizontal, 16)
                        .frame(height: 28)
                        .opacity(0.15)
                    }

                    TabView(selection: $selectedTab) {
                        NavigationStack {
                            DashboardView()
                        }
                        .tabItem {
                            Label("Dashboard", systemImage: "person.circle")
                        }
                        .tag(0)
                        .accessibilityIdentifier("tab_dashboard")

                        NavigationStack {
                            ItemsView()
                        }
                        .tabItem {
                            Label("Items", systemImage: "list.bullet")
                        }
                        .tag(1)
                        .accessibilityIdentifier("tab_items")

                        NavigationStack {
                            SettingsView()
                        }
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                        .tag(2)
                        .accessibilityIdentifier("tab_settings")
                    }
                }
            } else {
                NavigationStack {
                    SignInView()
                }
            }
        }
        .preferredColorScheme(auth.themeMode.colorScheme)
        .animation(.default, value: auth.isAuthenticated)
        #if DEBUG
        .overlay(alignment: .topTrailing) {
            Button("Debug") { showDebugSettings = true }
                .font(.caption2)
                .buttonStyle(.bordered)
                .padding(.trailing, 8)
                .padding(.top, 52)
        }
        .sheet(isPresented: $showDebugSettings) {
            DebugSettingsView()
        }
        #endif
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
