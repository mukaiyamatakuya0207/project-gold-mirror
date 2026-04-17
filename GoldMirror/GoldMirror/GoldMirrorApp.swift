// MARK: - GoldMirrorApp.swift
// Gold Mirror – App entry point.

import SwiftUI

@main
struct GoldMirrorApp: App {
    @StateObject private var dataManager = DataManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dataManager)
                .preferredColorScheme(.dark)
                .tint(Color.gmGold)
        }
    }
}
