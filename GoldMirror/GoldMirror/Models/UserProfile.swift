// MARK: - UserProfile.swift
// Gold Mirror – User profile model: income, tax, and income rank for Mirror SNS.

import Foundation
import SwiftUI

// ─────────────────────────────────────────
// MARK: Income Rank
// ─────────────────────────────────────────
enum IncomeRank: String, CaseIterable, Codable {
    case under3M   = "〜300万"
    case rank3to5  = "300〜500万"
    case rank5to7  = "500〜700万"
    case rank7to10 = "700〜1000万"
    case rank10to15 = "1000〜1500万"
    case rank15to20 = "1500〜2000万"
    case over20M   = "2000万以上"

    static func rank(for annualIncome: Double) -> IncomeRank {
        switch annualIncome {
        case ..<3_000_000:          return .under3M
        case 3_000_000..<5_000_000: return .rank3to5
        case 5_000_000..<7_000_000: return .rank5to7
        case 7_000_000..<10_000_000: return .rank7to10
        case 10_000_000..<15_000_000: return .rank10to15
        case 15_000_000..<20_000_000: return .rank15to20
        default:                    return .over20M
        }
    }

    var color: Color {
        switch self {
        case .under3M:    return Color(hex: "#A8A8A8")
        case .rank3to5:   return Color(hex: "#81C784")
        case .rank5to7:   return Color(hex: "#4FC3F7")
        case .rank7to10:  return Color(hex: "#CE93D8")
        case .rank10to15: return Color(hex: "#D4AF37")
        case .rank15to20: return Color(hex: "#F0D060")
        case .over20M:    return Color(hex: "#FF8C00")
        }
    }

    var badge: String {
        switch self {
        case .under3M:    return "🌱"
        case .rank3to5:   return "💼"
        case .rank5to7:   return "⭐️"
        case .rank7to10:  return "🌟"
        case .rank10to15: return "💎"
        case .rank15to20: return "👑"
        case .over20M:    return "🏆"
        }
    }

    /// 国税庁データに基づく上位何%か（概算）
    var topPercent: String {
        switch self {
        case .under3M:    return "下位 40%"
        case .rank3to5:   return "中間層"
        case .rank5to7:   return "上位 30%"
        case .rank7to10:  return "上位 15%"
        case .rank10to15: return "上位 5%"
        case .rank15to20: return "上位 2%"
        case .over20M:    return "上位 1%"
        }
    }
}

// ─────────────────────────────────────────
// MARK: Tax Document Type
// ─────────────────────────────────────────
enum TaxDocumentType: String, CaseIterable, Codable {
    case withholdingSlip  = "源泉徴収票"
    case taxReturn        = "確定申告書"
    case yearEndAdjustment = "年末調整書"
    case receipt          = "レシート"
    case other            = "その他書類"

    var icon: String {
        switch self {
        case .withholdingSlip:   return "doc.text.fill"
        case .taxReturn:         return "doc.richtext.fill"
        case .yearEndAdjustment: return "doc.badge.checkmark.fill"
        case .receipt:           return "receipt.fill"
        case .other:             return "doc.fill"
        }
    }
}

// ─────────────────────────────────────────
// MARK: OCR Scan Result
// ─────────────────────────────────────────
struct OCRScanResult: Identifiable, Codable {
    let id: UUID
    var documentType: TaxDocumentType
    var scannedAt: Date
    var rawText: String                    // Vision で取得した生テキスト全文

    // 抽出された数値フィールド
    var annualIncome: Double?              // 支払金額（年収）
    var deductionTotal: Double?            // 所得控除の額の合計
    var withholdingTax: Double?            // 源泉徴収税額
    var socialInsurance: Double?           // 社会保険料等の金額
    var lifeInsuranceDeduction: Double?    // 生命保険料の控除額
    var taxableIncome: Double?             // 給与所得控除後の金額

    // レシート・経費精算用フィールド
    var receiptDate: Date?
    var merchantName: String?
    var totalAmount: Double?
    var suggestedCategoryName: String?
    var suggestedCategoryIconName: String?
    var suggestedCategoryColorHex: String?
    var isBusinessExpense: Bool?
    var reimbursementStatus: ReimbursementStatus?

    // ユーザーが確認・修正済みか
    var isConfirmed: Bool

    // デフォルト値なし・全引数明示（どのコンテキストからでも呼べる）
    nonisolated init(
        id: UUID,
        documentType: TaxDocumentType,
        scannedAt: Date,
        rawText: String,
        isConfirmed: Bool
    ) {
        self.id            = id
        self.documentType  = documentType
        self.scannedAt     = scannedAt
        self.rawText       = rawText
        self.isConfirmed   = isConfirmed
    }

    /// 実効税率
    var effectiveTaxRate: Double? {
        guard let income = annualIncome, income > 0,
              let tax = withholdingTax else { return nil }
        return (tax / income) * 100
    }
}

// ─────────────────────────────────────────
// MARK: User Profile
// ─────────────────────────────────────────
struct UserProfile: Codable {
    var displayName: String         = "あなた"
    var tagline: String             = "資産形成中"
    var annualIncome: Double?       // 年収（OCRまたは手入力）
    var withholdingTax: Double?     // 源泉徴収税額
    var deductionTotal: Double?     // 所得控除合計
    var fiscalYear: Int             = 2025          // Date() をデフォルト値に使うと Swift 6 で警告
    var scanHistory: [OCRScanResult] = []
    var isPublicOnMirror: Bool      = true

    var incomeRank: IncomeRank {
        IncomeRank.rank(for: annualIncome ?? 0)
    }

    var latestScan: OCRScanResult? {
        scanHistory.filter { $0.isConfirmed }.sorted { $0.scannedAt > $1.scannedAt }.first
    }
}

// ─────────────────────────────────────────
// MARK: Day Financial Snapshot (Calendar用)
// ─────────────────────────────────────────
struct DayFinancialSnapshot {
    let date: Date
    let dayOfMonth: Int

    // その日に予定されている支出
    var scheduledExpenses: [ScheduledExpense]

    // その日に予定されている収入
    var scheduledIncomes: [ScheduledIncome] = []

    // その日の予測純資産
    var projectedNetAssets: Double

    // その日の予測現金残高
    var projectedCash: Double

    var totalExpenses: Double {
        scheduledExpenses.reduce(0) { $0 + $1.amount }
    }

    var totalIncomes: Double {
        scheduledIncomes.reduce(0) { $0 + $1.amount }
    }

    var netCashflow: Double {
        totalIncomes - totalExpenses
    }

    var hasExpenses: Bool { !scheduledExpenses.isEmpty }
    var hasIncomes: Bool { !scheduledIncomes.isEmpty }
    var hasEvents: Bool { hasExpenses || hasIncomes }
}

struct ScheduledExpense: Identifiable {
    let id = UUID()
    var transactionID: UUID? = nil
    let name: String
    let amount: Double
    let category: ExpenseCategory
    let icon: String
    let color: Color

    enum ExpenseCategory: String {
        case creditCard  = "クレジットカード"
        case fixedCost   = "固定費"
        case subscription = "サブスク"
        case transaction  = "支出"
    }
}

struct ScheduledIncome: Identifiable {
    let id = UUID()
    var transactionID: UUID? = nil
    let name: String
    let amount: Double
    let category: IncomeCategory
    let icon: String
    let color: Color

    enum IncomeCategory: String {
        case salary      = "給与"
        case bonus       = "ボーナス"
        case investment  = "投資収益"
        case transaction = "収入"
    }
}
