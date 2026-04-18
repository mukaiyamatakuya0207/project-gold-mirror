// MARK: - AssetModels.swift
// Gold Mirror – Core data models for all asset types.

import Foundation

// ─────────────────────────────────────────
// MARK: Bank Account
// ─────────────────────────────────────────
struct BankAccount: Identifiable, Codable {
    let id: UUID
    var name: String          // 口座名 e.g. "生活費口座"
    var bankName: String      // 銀行名 e.g. "三菱UFJ銀行"
    var balance: Double       // 残高（円）
    var accountNumber: String // 口座番号（末尾4桁などマスク済み）
    var iconName: String      // SF Symbol name

    init(
        id: UUID = UUID(),
        name: String,
        bankName: String,
        balance: Double,
        accountNumber: String = "****",
        iconName: String = "building.columns.fill"
    ) {
        self.id = id
        self.name = name
        self.bankName = bankName
        self.balance = balance
        self.accountNumber = accountNumber
        self.iconName = iconName
    }
}

// ─────────────────────────────────────────
// MARK: Securities Account
// ─────────────────────────────────────────
struct SecuritiesAccount: Identifiable, Codable {
    let id: UUID
    var name: String            // 口座名 e.g. "NISA口座"
    var brokerageName: String   // 証券会社名 e.g. "SBI証券"
    var evaluationAmount: Double // 評価額（円）
    var purchaseAmount: Double   // 取得額（円）
    var iconName: String         // SF Symbol name

    /// 損益（評価額 - 取得額）
    var profitLoss: Double {
        evaluationAmount - purchaseAmount
    }

    /// 損益率
    var profitLossRate: Double {
        guard purchaseAmount > 0 else { return 0 }
        return (profitLoss / purchaseAmount) * 100
    }

    init(
        id: UUID = UUID(),
        name: String,
        brokerageName: String,
        evaluationAmount: Double,
        purchaseAmount: Double,
        iconName: String = "chart.line.uptrend.xyaxis"
    ) {
        self.id = id
        self.name = name
        self.brokerageName = brokerageName
        self.evaluationAmount = evaluationAmount
        self.purchaseAmount = purchaseAmount
        self.iconName = iconName
    }
}

// ─────────────────────────────────────────
// MARK: Credit Card
// ─────────────────────────────────────────
struct CreditCard: Identifiable, Codable {
    let id: UUID
    var cardName: String              // カード名 e.g. "楽天カード"
    var issuerName: String            // 発行会社 e.g. "楽天カード株式会社"
    var billingDay: Int               // 引き落とし日（1〜31）
    var nextBillingAmount: Double     // 次回引き落とし予定金額（円）
    var nextPaymentDate: Date         // 次回引き落とし予定日
    var nextPaymentAmount: Double     // 次回引き落とし予定金額（円）
    var creditLimit: Double           // 利用限度額（円）
    var currentUsage: Double          // 当月利用済み金額（円）
    var cardLastFour: String          // カード番号末尾4桁
    var iconName: String              // SF Symbol name
    var accentColorHex: String        // カードのアクセントカラー (Hex)
    var linkedBankAccountID: UUID?    // 引き落とし銀行口座

    /// 利用率 (%)
    var usageRate: Double {
        guard creditLimit > 0 else { return 0 }
        return (currentUsage / creditLimit) * 100
    }

    init(
        id: UUID = UUID(),
        cardName: String,
        issuerName: String,
        billingDay: Int,
        nextBillingAmount: Double,
        nextPaymentDate: Date = Date(),
        nextPaymentAmount: Double? = nil,
        creditLimit: Double = 0,
        currentUsage: Double = 0,
        cardLastFour: String = "****",
        iconName: String = "creditcard.fill",
        accentColorHex: String = "#D4AF37",
        linkedBankAccountID: UUID? = nil
    ) {
        self.id = id
        self.cardName = cardName
        self.issuerName = issuerName
        self.billingDay = billingDay
        self.nextBillingAmount = nextPaymentAmount ?? nextBillingAmount
        self.nextPaymentDate = nextPaymentDate
        self.nextPaymentAmount = nextPaymentAmount ?? nextBillingAmount
        self.creditLimit = creditLimit
        self.currentUsage = currentUsage
        self.cardLastFour = cardLastFour
        self.iconName = iconName
        self.accentColorHex = accentColorHex
        self.linkedBankAccountID = linkedBankAccountID
    }
}

// ─────────────────────────────────────────
// MARK: Portfolio Summary (Computed)
// ─────────────────────────────────────────
struct PortfolioSummary {
    let totalBankBalance: Double
    let totalSecuritiesValue: Double
    let totalMonthlyBilling: Double

    /// 純資産（銀行 + 証券 - カード引き落とし）
    var netWorth: Double {
        totalBankBalance + totalSecuritiesValue - totalMonthlyBilling
    }

    /// 総資産（銀行 + 証券）
    var totalAssets: Double {
        totalBankBalance + totalSecuritiesValue
    }
}
