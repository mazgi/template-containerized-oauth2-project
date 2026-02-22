//
//  ContentView.swift
//  app
//
//  Created by user on 2026/02/21.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        if authService.isAuthenticated {
            DashboardView()
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthService())
}
