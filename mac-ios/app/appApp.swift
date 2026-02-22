//
//  appApp.swift
//  app
//
//  Created by user on 2026/02/21.
//

import SwiftUI
import SwiftData

@main
struct vibe_local_authApp: App {
    @State private var authService = AuthService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
        }
        .modelContainer(sharedModelContainer)
    }
}
