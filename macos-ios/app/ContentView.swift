//
//  ContentView.swift
//  app
//
//  Created by user on 2026/02/23.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var auth

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
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
}
