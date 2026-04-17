// MARK: - DataManager.swift
// Gold Mirror – Central ObservableObject managing all financial data,
// projection logic, and next-billing calculations.

import SwiftUI
import Combine

@MainActor
final class DataManager: ObservableObject {

    // ─────────────────────────────────────────
    // MARK: Published State
    // ─────────────────────────────────────────
    @Published var fixedCosts: [FixedCost]       = MockData.fixedCosts
    @Published var subscriptions: [Subscription] = MockData.subscriptions

    // Shared asset data (passed from AssetViewModel or owned here)
    @Published var bankAccounts: [BankAccount]             = MockData.bankAccounts
    @Published var securitiesAccounts: [SecuritiesAccount] = MockData.securitiesAccounts
    @Published var creditCards: [CreditCard]               = MockData.creditCards

    // ─────────────────────────────────────────
    // MARK: Computed – Totals
    // ─────────────────────────────────────────
    var totalBankBalance: Double {
        bankAccounts.reduce(0) { $0 + $1.balance }
    }

    var totalSecuritiesValue: Double {
        securitiesAccounts.reduce(0) { $0 + $1.evaluationAmount }
    }

    var totalAssets: Double {
        totalBankBalance + totalSecuritiesValue
    }

    var totalMonthlyFixedCosts: Double {
        fixedCosts.filter { $0.isActive }.reduce(0) { $0 + $1.amount }
    }

    var totalMonthlySubscriptions: Double {
        subscriptions.filter { $0.isActive }.reduce(0) { $0 + $1.monthlyCost }
    }

    var totalMonthlyCardBilling: Double {
        creditCards.reduce(0) { $0 + $1.nextBillingAmount }
    }

    /// 月間固定支出合計（固定費 + サブスク + カード）
    var totalMonthlyOutflow: Double {
        totalMonthlyFixedCosts + totalMonthlySubscriptions + totalMonthlyCardBilling
    }

    /// 年間サブスク合計
    var totalAnnualSubscriptions: Double {
        subscriptions.filter { $0.isActive }.reduce(0) { $0 + $1.annualCost }
    }

    // ─────────────────────────────────────────
    // MARK: Next Billing Summary
    // ─────────────────────────────────────────

    /// 最も近い次の引き落とし情報を返す
    var nextBillingSummary: NextBillingSummary? {
        let calendar = Calendar.current
        let today = Date()
        let todayDay = calendar.component(.day, from: today)

        // 今月・来月の引き落とし日を候補として収集
        var candidates: [(daysUntil: Int, day: Int, date: Date)] = []

        for card in creditCards {
            let day = card.billingDay
            // 今月の該当日
            if let thisMonthDate = dateForDay(day, inMonthOf: today) {
                let diff = calendar.dateComponents([.day], from: calendar.startOfDay(for: today),
                                                    to: calendar.startOfDay(for: thisMonthDate)).day ?? 0
                if diff >= 0 {
                    candidates.append((diff, day, thisMonthDate))
                } else {
                    // 来月
                    if let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: thisMonthDate) {
                        let diff2 = calendar.dateComponents([.day],
                                                             from: calendar.startOfDay(for: today),
                                                             to: calendar.startOfDay(for: nextMonthDate)).day ?? 0
                        candidates.append((diff2, day, nextMonthDate))
                    }
                }
            }
        }

        guard let nearest = candidates.min(by: { $0.daysUntil < $1.daysUntil }) else { return nil }

        let cardsOnDay = creditCards.filter { $0.billingDay == nearest.day }
        let total = cardsOnDay.reduce(0) { $0 + $1.nextBillingAmount }

        return NextBillingSummary(
            daysUntil: nearest.daysUntil,
            nextBillingDate: nearest.date,
            totalAmount: total,
            cards: cardsOnDay
        )
    }

    // ─────────────────────────────────────────
    // MARK: 3-Month Projection Logic
    // ─────────────────────────────────────────

    /// 今日から90日間の日別資産推移を生成
    /// - Parameters:
    ///   - monthlyIncome: 月収（毎月1日に入金と仮定）
    ///   - securitiesGrowthRate: 証券の月次期待リターン（デフォルト0.5%）
    func generateProjection(
        monthlyIncome: Double = 450_000,
        securitiesGrowthRate: Double = 0.005
    ) -> [ProjectionPoint] {
        let calendar = Calendar.current
        let today = Date()
        var points: [ProjectionPoint] = []

        var cashBalance = totalBankBalance
        var securitiesValue = totalSecuritiesValue

        for dayOffset in 0..<91 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let dayOfMonth = calendar.component(.day, from: date)
            let isFirstOfMonth = dayOfMonth == 1
            var isEvent = false
            var eventLabel = ""

            // 月初：収入入金 + 証券成長
            if isFirstOfMonth && dayOffset > 0 {
                cashBalance += monthlyIncome
                securitiesValue *= (1 + securitiesGrowthRate)
                isEvent = true
                eventLabel = "給与入金"
            }

            // カード引き落とし日
            for card in creditCards {
                if card.billingDay == dayOfMonth {
                    cashBalance -= card.nextBillingAmount
                    isEvent = true
                    eventLabel = eventLabel.isEmpty ? card.cardName : eventLabel + "他"
                }
            }

            // 固定費引き落とし日
            for cost in fixedCosts where cost.isActive {
                if cost.billingDay == dayOfMonth {
                    cashBalance -= cost.amount
                    isEvent = true
                    eventLabel = eventLabel.isEmpty ? cost.name : eventLabel
                }
            }

            // サブスク引き落とし日
            for sub in subscriptions where sub.isActive {
                if sub.billingDay == dayOfMonth && sub.billingCycle == .monthly {
                    cashBalance -= sub.monthlyCost
                }
            }

            points.append(ProjectionPoint(
                date: date,
                totalAssets: max(cashBalance + securitiesValue, 0),
                cashOnly: max(cashBalance, 0),
                isEvent: isEvent,
                eventLabel: eventLabel
            ))
        }

        return points
    }

    // ─────────────────────────────────────────
    // MARK: CRUD – Fixed Costs
    // ─────────────────────────────────────────
    func addFixedCost(_ cost: FixedCost) {
        fixedCosts.append(cost)
    }

    func updateFixedCost(_ cost: FixedCost) {
        if let idx = fixedCosts.firstIndex(where: { $0.id == cost.id }) {
            fixedCosts[idx] = cost
        }
    }

    func deleteFixedCost(at offsets: IndexSet) {
        fixedCosts.remove(atOffsets: offsets)
    }

    func toggleFixedCost(_ cost: FixedCost) {
        if let idx = fixedCosts.firstIndex(where: { $0.id == cost.id }) {
            fixedCosts[idx].isActive.toggle()
        }
    }

    // ─────────────────────────────────────────
    // MARK: CRUD – Subscriptions
    // ─────────────────────────────────────────
    func addSubscription(_ sub: Subscription) {
        subscriptions.append(sub)
    }

    func updateSubscription(_ sub: Subscription) {
        if let idx = subscriptions.firstIndex(where: { $0.id == sub.id }) {
            subscriptions[idx] = sub
        }
    }

    func deleteSubscription(at offsets: IndexSet) {
        subscriptions.remove(atOffsets: offsets)
    }

    func toggleSubscription(_ sub: Subscription) {
        if let idx = subscriptions.firstIndex(where: { $0.id == sub.id }) {
            subscriptions[idx].isActive.toggle()
        }
    }

    // ─────────────────────────────────────────
    // MARK: CRUD – Credit Cards
    // ─────────────────────────────────────────
    func addCreditCard(_ card: CreditCard) {
        creditCards.append(card)
    }

    func updateCreditCard(_ card: CreditCard) {
        if let idx = creditCards.firstIndex(where: { $0.id == card.id }) {
            creditCards[idx] = card
        }
    }

    func deleteCreditCard(at offsets: IndexSet) {
        creditCards.remove(atOffsets: offsets)
    }

    // ─────────────────────────────────────────
    // MARK: Helpers
    // ─────────────────────────────────────────
    private func dateForDay(_ day: Int, inMonthOf date: Date) -> Date? {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: date)
        comps.day = day
        return calendar.date(from: comps)
    }

    /// カテゴリ別固定費集計
    func fixedCostsByCategory() -> [(category: FixedCostCategory, total: Double)] {
        let active = fixedCosts.filter { $0.isActive }
        return FixedCostCategory.allCases.compactMap { cat in
            let total = active.filter { $0.category == cat }.reduce(0) { $0 + $1.amount }
            guard total > 0 else { return nil }
            return (cat, total)
        }
    }
}
