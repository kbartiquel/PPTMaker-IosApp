//
//  PPTMakerApp.swift
//  PPTMaker
//
//  Created with Claude Code
//  Copyright © 2024 KimBytes. All rights reserved.
//

import SwiftUI
import Aptabase

@main
struct PPTMakerApp: App {

    init() {
        // Initialize Aptabase analytics
        Aptabase.shared.initialize(appKey: "A-US-3752431340")

        // Configure RevenueCat immediately (must be done synchronously before any RevenueCat calls)
        RevenueCatService.shared.configure()

        // Initialize paywall services asynchronously
        Task {
            // Fetch paywall settings from API
            await PaywallSettingsService.shared.initialize()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    Aptabase.shared.trackEvent("app_launched")
                }
        }
    }
}
