//
//  appApp.swift
//  app
//
//  Created by user on 2026/02/23.
//

import SwiftUI

@main
struct appApp: App {
    @State private var auth = AuthViewModel()

    init() {
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            UserDefaults.standard.removeObject(forKey: "auth_tokens")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(auth)
        }
    }
}
