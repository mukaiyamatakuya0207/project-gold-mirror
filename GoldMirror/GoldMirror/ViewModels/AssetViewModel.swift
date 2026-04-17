// MARK: - AssetViewModel.swift
// Gold Mirror – Observable view model that drives all asset screens.

import SwiftUI
import Combine

@MainActor
final class AssetViewModel: ObservableObject {

    // ─────────────────────────────────────────
    // MARK: Published State
    // ─────────────────────────────────────────
    @Published var bankAccounts: [BankAccount]           = MockData.bankAccounts
    @Published var securitiesAccounts: [SecuritiesAccount] = MockData.securitiesAccounts
    @Published var creditCards: [CreditCard]             = MockData.creditCards
    @Published var mirrorPosts: [MirrorPost]             = MockData.mirrorPosts

    @Published var isLoading: Bool = false
    @Published var selectedMonth: Date = Date()

    // ─────────────────────────────────────────
    // MARK: Computed Totals
    // ─────────────────────────────────────────
    var totalBankBalance: Double {
        bankAccounts.reduce(0) { $0 + $1.balance }
    }

    var totalSecuritiesValue: Double {
        securitiesAccounts.reduce(0) { $0 + $1.evaluationAmount }
    }

    var totalSecuritiesPurchase: Double {
        securitiesAccounts.reduce(0) { $0 + $1.purchaseAmount }
    }

    var totalSecuritiesProfitLoss: Double {
        totalSecuritiesValue - totalSecuritiesPurchase
    }

    var totalSecuritiesProfitLossRate: Double {
        guard totalSecuritiesPurchase > 0 else { return 0 }
        return (totalSecuritiesProfitLoss / totalSecuritiesPurchase) * 100
    }

    var totalMonthlyBilling: Double {
        creditCards.reduce(0) { $0 + $1.nextBillingAmount }
    }

    var netWorth: Double {
        totalBankBalance + totalSecuritiesValue - totalMonthlyBilling
    }

    var totalAssets: Double {
        totalBankBalance + totalSecuritiesValue
    }

    /// 銀行 vs 証券 の比率 (0.0 〜 1.0, 銀行の割合)
    var bankRatio: Double {
        guard totalAssets > 0 else { return 0.5 }
        return totalBankBalance / totalAssets
    }

    // ─────────────────────────────────────────
    // MARK: Calendar Helpers
    // ─────────────────────────────────────────

    /// 今月のカード引き落とし予定を日付 → [CreditCard] にマッピング
    func billingEventsForMonth(_ date: Date) -> [Int: [CreditCard]] {
        var result: [Int: [CreditCard]] = [:]
        for card in creditCards {
            let day = card.billingDay
            if result[day] == nil {
                result[day] = []
            }
            result[day]?.append(card)
        }
        return result
    }

    /// 指定日のカード引き落とし合計
    func totalBillingForDay(_ day: Int) -> Double {
        creditCards
            .filter { $0.billingDay == day }
            .reduce(0) { $0 + $1.nextBillingAmount }
    }

    // ─────────────────────────────────────────
    // MARK: Actions (stubs for future persistence)
    // ─────────────────────────────────────────

    func addBankAccount(_ account: BankAccount) {
        bankAccounts.append(account)
    }

    func addSecuritiesAccount(_ account: SecuritiesAccount) {
        securitiesAccounts.append(account)
    }

    func addCreditCard(_ card: CreditCard) {
        creditCards.append(card)
    }

    func deleteBankAccount(at offsets: IndexSet) {
        bankAccounts.remove(atOffsets: offsets)
    }

    func deleteSecuritiesAccount(at offsets: IndexSet) {
        securitiesAccounts.remove(atOffsets: offsets)
    }

    func deleteCreditCard(at offsets: IndexSet) {
        creditCards.remove(atOffsets: offsets)
    }
}
