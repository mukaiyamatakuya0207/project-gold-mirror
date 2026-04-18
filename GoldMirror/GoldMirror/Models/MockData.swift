// MARK: - MockData.swift
// Gold Mirror – Preview & development seed data.
// Keep values empty/zero so manual testing starts from a clean state.

import Foundation

struct MockData {

    // ─────────────────────────────────────────
    // MARK: Bank Accounts
    // ─────────────────────────────────────────
    static let bankAccounts: [BankAccount] = [
        BankAccount(
            name: "現金・預金",
            bankName: "未設定",
            balance: 0,
            accountNumber: "****",
            iconName: "banknote.fill"
        )
    ]

    // ─────────────────────────────────────────
    // MARK: Securities Accounts
    // ─────────────────────────────────────────
    static let securitiesAccounts: [SecuritiesAccount] = []

    // ─────────────────────────────────────────
    // MARK: Credit Cards
    // ─────────────────────────────────────────
    static let creditCards: [CreditCard] = []

    // ─────────────────────────────────────────
    // MARK: Computed Summary
    // ─────────────────────────────────────────
    static var portfolioSummary: PortfolioSummary {
        let bankTotal = bankAccounts.reduce(0) { $0 + $1.balance }
        let secTotal  = securitiesAccounts.reduce(0) { $0 + $1.evaluationAmount }
        let cardTotal = creditCards.reduce(0) { $0 + $1.nextBillingAmount }
        return PortfolioSummary(
            totalBankBalance: bankTotal,
            totalSecuritiesValue: secTotal,
            totalMonthlyBilling: cardTotal
        )
    }

    // ─────────────────────────────────────────
    // MARK: SNS Mirror Posts (Mock)
    // ─────────────────────────────────────────
    static let mirrorPosts: [MirrorPost] = []

    // ─────────────────────────────────────────
    // MARK: Fixed Costs
    // ─────────────────────────────────────────
    static let fixedCosts: [FixedCost] = []

    // ─────────────────────────────────────────
    // MARK: Subscriptions
    // ─────────────────────────────────────────
    static let subscriptions: [Subscription] = []
}

// SNS投稿モデル
struct MirrorPost: Identifiable {
    let id = UUID()
    var username: String
    var displayName: String
    var avatarInitials: String
    var timeAgo: String
    var netWorthChange: Double   // 今月の資産変動
    var savingsRate: Int         // 貯蓄率 (%)
    var message: String
    var likes: Int
    var comments: Int
    var tagline: String
}
