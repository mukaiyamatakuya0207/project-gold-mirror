// MARK: - NotificationManager.swift
// Gold Mirror – UserNotifications scheduling for credit card billing reminders.

import SwiftUI
import Combine
import UserNotifications

// ─────────────────────────────────────────
// MARK: Notification Settings
// ─────────────────────────────────────────
struct NotificationSettings: Codable {
    var enabled: Bool         = true
    var sevenDaysBefore: Bool = true
    var threeDaysBefore: Bool = true
    var oneDayBefore: Bool    = true

    static let key = "gmNotificationSettings"

    static func load() -> NotificationSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data)
        else { return NotificationSettings() }
        return decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: NotificationSettings.key)
        }
    }
}

// ─────────────────────────────────────────
// MARK: Notification Item (for history UI)
// ─────────────────────────────────────────
struct GMNotificationItem: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let date: Date
    var isRead: Bool = false

    var timeAgoString: String {
        let diff = Date().timeIntervalSince(date)
        switch diff {
        case ..<60:          return "今"
        case ..<3600:        return "\(Int(diff / 60))分前"
        case ..<86400:       return "\(Int(diff / 3600))時間前"
        default:             return "\(Int(diff / 86400))日前"
        }
    }
}

// ─────────────────────────────────────────
// MARK: Notification Manager (ObservableObject)
// ─────────────────────────────────────────
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var settings   = NotificationSettings.load()
    @Published var history: [GMNotificationItem] = []
    @Published var unreadCount: Int = 0

    init() {
        loadMockHistory()
    }

    // ── Permission ──
    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    // ── Schedule notifications for all cards ──
    func scheduleAllBillingNotifications(cards: [CreditCard]) async {
        guard settings.enabled else { return }
        let center = UNUserNotificationCenter.current()
        // Remove all previously scheduled billing notifications
        center.removePendingNotificationRequests(withIdentifiers:
            cards.flatMap { notificationIDs(for: $0) }
        )

        for card in cards {
            await scheduleBillingNotifications(for: card, center: center)
        }
    }

    private func scheduleBillingNotifications(for card: CreditCard, center: UNUserNotificationCenter) async {
        let billingDay = card.billingDay
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: Date())
        comps.day = billingDay
        comps.hour = 9
        comps.minute = 0

        guard let billingDate = calendar.date(from: comps) else { return }

        let offsets: [(days: Int, label: String, flag: Bool)] = [
            (7, "1週間前", settings.sevenDaysBefore),
            (3, "3日前",   settings.threeDaysBefore),
            (1, "前日",    settings.oneDayBefore)
        ]

        for offset in offsets where offset.flag {
            guard let notifyDate = calendar.date(byAdding: .day, value: -offset.days, to: billingDate),
                  notifyDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "💳 \(card.cardName) 引き落とし\(offset.label)"
            content.body  = "\(offset.days)日後に ¥\(Int(card.nextBillingAmount).formatted()) の引き落としがあります。残高を確認してください。"
            content.sound = .default
            content.categoryIdentifier = "BILLING_REMINDER"

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notifyDate),
                repeats: false
            )

            let id = "billing-\(card.id)-\(offset.days)d"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    private func notificationIDs(for card: CreditCard) -> [String] {
        [7, 3, 1].map { "billing-\(card.id)-\($0)d" }
    }

    // ── Persist settings ──
    func saveSettings() {
        settings.save()
        unreadCount = history.filter { !$0.isRead }.count
    }

    func markAllRead() {
        for i in history.indices { history[i].isRead = true }
        unreadCount = 0
    }

    // ── Mock history data ──
    private func loadMockHistory() {
        history = [
            GMNotificationItem(
                title: "💳 楽天カード引き落とし3日前",
                body: "3日後に ¥89,540 の引き落としがあります。残高を確認してください。",
                date: Date().addingTimeInterval(-3600 * 2)
            ),
            GMNotificationItem(
                title: "📊 今月の資産更新",
                body: "今月の総資産が ¥4,820,000 になりました。先月比 +2.3%",
                date: Date().addingTimeInterval(-86400),
                isRead: true
            ),
            GMNotificationItem(
                title: "💳 三井住友カード引き落とし1週間前",
                body: "7日後に ¥54,200 の引き落としがあります。",
                date: Date().addingTimeInterval(-86400 * 3),
                isRead: true
            ),
            GMNotificationItem(
                title: "✅ サブスク更新のお知らせ",
                body: "Netflixが明日更新されます。¥1,490",
                date: Date().addingTimeInterval(-86400 * 5),
                isRead: true
            ),
        ]
        unreadCount = history.filter { !$0.isRead }.count
    }
}
