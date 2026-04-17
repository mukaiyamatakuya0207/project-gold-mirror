// MARK: - GoldMirrorApp.swift
// Gold Mirror – App entry point.

import SwiftUI
import UserNotifications

@main
struct GoldMirrorApp: App {
    @StateObject private var dataManager  = DataManager()
    @StateObject private var ocrViewModel = OCRViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dataManager)
                .environmentObject(ocrViewModel)
                .preferredColorScheme(.dark)
                .tint(Color.gmGold)
                .task {
                    // Request notification permission on first launch
                    await NotificationManager.shared.requestPermission()
                }
        }
    }
}
