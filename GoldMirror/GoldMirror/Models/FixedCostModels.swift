// MARK: - FixedCostModels.swift
// Gold Mirror – Fixed costs, subscriptions, and projection data models.

import Foundation
import SwiftUI

// ─────────────────────────────────────────
// MARK: Fixed Cost Category
// ─────────────────────────────────────────
enum FixedCostCategory: String, Codable, CaseIterable {
    case rent         = "家賃・住宅"
    case utilities    = "光熱費"
    case insurance    = "保険"
    case subscription = "サブスク"
    case transport    = "交通・通信"
    case loan         = "ローン"
    case other        = "その他"

    var icon: String {
        switch self {
        case .rent:         return "house.fill"
        case .utilities:    return "bolt.fill"
        case .insurance:    return "shield.fill"
        case .subscription: return "rectangle.stack.fill"
        case .transport:    return "train.side.front.car"
        case .loan:         return "building.columns.fill"
        case .other:        return "square.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .rent:         return Color(hex: "#D4AF37")
        case .utilities:    return Color(hex: "#FF9800")
        case .insurance:    return Color(hex: "#4FC3F7")
        case .subscription: return Color(hex: "#CE93D8")
        case .transport:    return Color(hex: "#80CBC4")
        case .loan:         return Color(hex: "#EF9A9A")
        case .other:        return Color(hex: "#A8A8A8")
        }
    }
}

// ─────────────────────────────────────────
// MARK: Fixed Cost / Subscription
// ─────────────────────────────────────────
struct FixedCost: Identifiable, Codable {
    let id: UUID
    var name: String                  // 名称 e.g. "Netflix"
    var amount: Double                // 月額（円）
    var category: FixedCostCategory  // カテゴリ
    var billingDay: Int               // 引き落とし日（1〜31）
    var isSubscription: Bool          // サブスクかどうか
    var contractEndDate: Date?        // 契約終了日（任意）
    var memo: String                  // メモ
    var isActive: Bool                // 有効フラグ

    /// 年間合計
    var annualAmount: Double { amount * 12 }

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        category: FixedCostCategory = .other,
        billingDay: Int = 1,
        isSubscription: Bool = false,
        contractEndDate: Date? = nil,
        memo: String = "",
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
        self.billingDay = billingDay
        self.isSubscription = isSubscription
        self.contractEndDate = contractEndDate
        self.memo = memo
        self.isActive = isActive
    }
}

// ─────────────────────────────────────────
// MARK: Projection Data Point
// ─────────────────────────────────────────
struct ProjectionDataPoint: Identifiable {
    let id = UUID()
    var date: Date
    var totalAssets: Double    // 総資産
    var cashAssets: Double     // 現金のみ
    var event: String?         // イベントラベル（カード引き落とし等）
}

// ─────────────────────────────────────────
// MARK: Mock Fixed Costs
// ─────────────────────────────────────────
extension MockData {
    static let fixedCosts: [FixedCost] = [
        FixedCost(name: "家賃", amount: 120_000, category: .rent,
                  billingDay: 27, isSubscription: false, memo: ""),
        FixedCost(name: "電気・ガス・水道", amount: 15_000, category: .utilities,
                  billingDay: 10, isSubscription: false, memo: ""),
        FixedCost(name: "生命保険", amount: 18_000, category: .insurance,
                  billingDay: 1, isSubscription: false, memo: ""),
        FixedCost(name: "Netflix", amount: 1_980, category: .subscription,
                  billingDay: 15, isSubscription: true,
                  contractEndDate: nil, memo: "プレミアム"),
        FixedCost(name: "Apple One", amount: 1_200, category: .subscription,
                  billingDay: 12, isSubscription: true,
                  contractEndDate: nil, memo: "個人プラン"),
        FixedCost(name: "Spotify", amount: 980, category: .subscription,
                  billingDay: 8, isSubscription: true,
                  contractEndDate: nil, memo: ""),
        FixedCost(name: "ChatGPT Plus", amount: 3_000, category: .subscription,
                  billingDay: 5, isSubscription: true,
                  contractEndDate: nil, memo: ""),
        FixedCost(name: "スマホ代（docomo）", amount: 8_500, category: .transport,
                  billingDay: 10, isSubscription: false, memo: ""),
        FixedCost(name: "住宅ローン", amount: 95_000, category: .loan,
                  billingDay: 2, isSubscription: false, memo: "残り25年"),
        FixedCost(name: "Adobe CC", amount: 6_480, category: .subscription,
                  billingDay: 20, isSubscription: true,
                  contractEndDate: Calendar.current.date(
                    byAdding: .month, value: 8, to: Date()), memo: "年払い契約"),
    ]
}
