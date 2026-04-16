// MARK: - GoldMirrorApp.swift
// Gold Mirror – App entry point.

import SwiftUI

@main
struct GoldMirrorApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .tint(Color.gmGold)  // Global tint for system controls
        }
    }
}
