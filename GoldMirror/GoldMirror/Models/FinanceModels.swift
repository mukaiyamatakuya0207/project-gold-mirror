// MARK: - FinanceModels.swift
// Gold Mirror – Extended models: FixedCost, Subscription, ProjectionPoint

import Foundation
import SwiftUI

// ─────────────────────────────────────────
// MARK: Fixed Cost Category
// ─────────────────────────────────────────
enum FixedCostCategory: String, CaseIterable, Codable {
    case rent        = "家賃・住宅"
    case utilities   = "光熱費"
    case insurance   = "保険"
    case subscription = "サブスク"
    case loan        = "ローン"
    case education   = "教育"
    case other       = "その他"

    var icon: String {
        switch self {
        case .rent:         return "house.fill"
        case .utilities:    return "bolt.fill"
        case .insurance:    return "shield.fill"
        case .subscription: return "play.rectangle.fill"
        case .loan:         return "banknote.fill"
        case .education:    return "book.fill"
        case .other:        return "tag.fill"
        }
    }

    var color: Color {
        switch self {
        case .rent:         return Color(hex: "#D4AF37")
        case .utilities:    return Color(hex: "#4FC3F7")
        case .insurance:    return Color(hex: "#81C784")
        case .subscription: return Color(hex: "#CE93D8")
        case .loan:         return Color(hex: "#EF9A9A")
        case .education:    return Color(hex: "#FFD54F")
        case .other:        return Color(hex: "#A8A8A8")
        }
    }
}

// ─────────────────────────────────────────
// MARK: Recurring Payment Source
// ─────────────────────────────────────────
enum RecurringPaymentSourceKind: String, Codable {
    case bankAccount
    case creditCard

    var label: String {
        switch self {
        case .bankAccount: return "銀行口座"
        case .creditCard: return "クレジットカード"
        }
    }
}

struct RecurringPaymentSource: Codable, Hashable {
    var kind: RecurringPaymentSourceKind
    var id: UUID
}

// ─────────────────────────────────────────
// MARK: Fixed Cost
// ─────────────────────────────────────────
struct FixedCost: Identifiable, Codable {
    let id: UUID
    var name: String            // 費用名 e.g. "家賃"
    var amount: Double          // 金額（円）
    var billingDay: Int         // 毎月引き落とし日 (1〜31)
    var category: FixedCostCategory
    var isActive: Bool          // 有効 / 無効
    var memo: String            // メモ
    var paymentSource: RecurringPaymentSource?

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        billingDay: Int,
        category: FixedCostCategory,
        isActive: Bool = true,
        memo: String = "",
        paymentSource: RecurringPaymentSource? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.billingDay = billingDay
        self.category = category
        self.isActive = isActive
        self.memo = memo
        self.paymentSource = paymentSource
    }
}

// ─────────────────────────────────────────
// MARK: Subscription
// ─────────────────────────────────────────
struct Subscription: Identifiable, Codable {
    let id: UUID
    var name: String            // サービス名 e.g. "Netflix"
    var amount: Double          // 月額（円）
    var billingDay: Int         // 毎月引き落とし日
    var billingCycle: BillingCycle // 月払い / 年払い
    var contractEndDate: Date?  // 契約終了日（nilなら無期限）
    var iconName: String        // SF Symbol
    var accentColorHex: String  // アクセントカラー
    var isActive: Bool
    var paymentSource: RecurringPaymentSource?

    enum BillingCycle: String, CaseIterable, Codable {
        case monthly = "月払い"
        case yearly  = "年払い"

        var multiplier: Double {
            switch self {
            case .monthly: return 12.0
            case .yearly:  return 1.0
            }
        }
    }

    /// 年間コスト
    var annualCost: Double {
        switch billingCycle {
        case .monthly: return amount * 12
        case .yearly:  return amount
        }
    }

    /// 月換算コスト
    var monthlyCost: Double {
        switch billingCycle {
        case .monthly: return amount
        case .yearly:  return amount / 12
        }
    }

    /// 契約終了まで残り日数
    var daysUntilExpiry: Int? {
        guard let end = contractEndDate else { return nil }
        return Calendar.gmJapan.dateComponents([.day], from: Date(), to: end).day
    }

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        billingDay: Int = 1,
        billingCycle: BillingCycle = .monthly,
        contractEndDate: Date? = nil,
        iconName: String = "play.rectangle.fill",
        accentColorHex: String = "#CE93D8",
        isActive: Bool = true,
        paymentSource: RecurringPaymentSource? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.billingDay = billingDay
        self.billingCycle = billingCycle
        self.contractEndDate = contractEndDate
        self.iconName = iconName
        self.accentColorHex = accentColorHex
        self.isActive = isActive
        self.paymentSource = paymentSource
    }
}

// ─────────────────────────────────────────
// MARK: Projection Data Point (for Charts)
// ─────────────────────────────────────────
struct ProjectionPoint: Identifiable {
    let id = UUID()
    let date: Date
    let totalAssets: Double     // 銀行 + 証券
    let cashOnly: Double        // 銀行のみ
    let isEvent: Bool           // 引き落とし等のイベント日
    let eventLabel: String      // イベントラベル
}

// ─────────────────────────────────────────
// MARK: Next Billing Summary
// ─────────────────────────────────────────
struct NextBillingSummary {
    let daysUntil: Int          // 次の引き落としまであと何日
    let nextBillingDate: Date   // 次の引き落とし日
    let totalAmount: Double     // その日の合計引き落とし額
    let cards: [CreditCard]     // 対象カード
    var schedules: [CardPaymentSchedule] = []
}

// ─────────────────────────────────────────
// MARK: Card Payment Schedule
// ─────────────────────────────────────────
struct CardPaymentSchedule: Identifiable, Codable {
    let id: UUID
    var cardID: UUID
    var title: String
    var paymentDate: Date
    var amount: Double

    init(
        id: UUID = UUID(),
        cardID: UUID,
        title: String,
        paymentDate: Date,
        amount: Double
    ) {
        self.id = id
        self.cardID = cardID
        self.title = title
        self.paymentDate = paymentDate
        self.amount = amount
    }
}
