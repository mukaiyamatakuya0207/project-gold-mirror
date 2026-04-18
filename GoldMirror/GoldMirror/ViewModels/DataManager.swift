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

    var totalAssets: Double {
        totalBankBalance + totalSecuritiesValue
    }

    var netWorth: Double {
        totalAssets - totalMonthlyCardBilling
    }

    var bankRatio: Double {
        guard totalAssets > 0 else { return 0.5 }
        return totalBankBalance / totalAssets
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

    var currentMonthTransactionIncome: Double {
        transactionTotals(in: Date()).income
    }

    var currentMonthTransactionExpense: Double {
        transactionTotals(in: Date()).expense
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
        monthlyIncome: Double = 0,
        securitiesGrowthRate: Double = 0.005
    ) -> [ProjectionPoint] {
        let calendar = Calendar.current
        let today = Date()
        let todayStart = calendar.startOfDay(for: today)
        var points: [ProjectionPoint] = []

        var cashBalance = totalBankBalance - transactionDelta(after: todayStart)
        var securitiesValue = totalSecuritiesValue
        let recurringIncome = projectedRecurringIncome(fallbackMonthlyIncome: monthlyIncome)
        let variableDailyDelta = averageDailyVariableTransactionDelta()

        for dayOffset in 0..<91 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let dateStart = calendar.startOfDay(for: date)
            let dayOfMonth = calendar.component(.day, from: date)
            let isFirstOfMonth = dayOfMonth == 1
            var isEvent = false
            var eventLabels: [String] = []

            if dateStart > todayStart {
                let futureTransactions = transactions.filter { calendar.isDate($0.date, inSameDayAs: date) }
                for transaction in futureTransactions {
                    cashBalance += transaction.delta
                    isEvent = true
                    eventLabels.append(transaction.category.rawValue)
                }

                cashBalance += variableDailyDelta
            }

            // 月初：収入入金 + 証券成長
            if isFirstOfMonth && dayOffset > 0 {
                if recurringIncome.day == 1 {
                    cashBalance += recurringIncome.amount
                    eventLabels.append(recurringIncome.label)
                }
                securitiesValue *= (1 + securitiesGrowthRate)
                isEvent = true
                if recurringIncome.day != 1 {
                    eventLabels.append("証券成長")
                }
            }

            if dayOffset > 0 && dayOfMonth == recurringIncome.day && recurringIncome.day != 1 {
                cashBalance += recurringIncome.amount
                isEvent = true
                eventLabels.append(recurringIncome.label)
            }

            // カード引き落とし日
            for card in creditCards {
                if card.billingDay == dayOfMonth {
                    cashBalance -= card.nextBillingAmount
                    isEvent = true
                    eventLabels.append(card.cardName)
                }
            }

            // 固定費引き落とし日
            for cost in fixedCosts where cost.isActive {
                if cost.billingDay == dayOfMonth {
                    cashBalance -= cost.amount
                    isEvent = true
                    eventLabels.append(cost.name)
                }
            }

            // サブスク引き落とし日
            for sub in subscriptions where sub.isActive {
                if sub.billingDay == dayOfMonth && sub.billingCycle == .monthly {
                    cashBalance -= sub.monthlyCost
                    isEvent = true
                    eventLabels.append(sub.name)
                }
            }

            points.append(ProjectionPoint(
                date: date,
                totalAssets: max(cashBalance + securitiesValue, 0),
                cashOnly: max(cashBalance, 0),
                isEvent: isEvent,
                eventLabel: eventLabels.prefix(2).joined(separator: " / ")
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
    // MARK: Transactions (income / expense records)
    // ─────────────────────────────────────────
    @Published var transactions: [Transaction] = []

    func addTransaction(_ t: Transaction) {
        transactions.insert(t, at: 0)
        // Reflect income/expense on bank balance (first account as default)
        guard !bankAccounts.isEmpty else { return }
        bankAccounts[0].balance += t.delta
    }

    func transactions(on date: Date) -> [Transaction] {
        transactions.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func transactionTotals(in month: Date) -> (income: Double, expense: Double) {
        let calendar = Calendar.current
        return transactions.reduce(into: (income: 0.0, expense: 0.0)) { totals, transaction in
            guard calendar.isDate(transaction.date, equalTo: month, toGranularity: .month) else { return }
            switch transaction.type {
            case .income:
                totals.income += transaction.amount
            case .expense:
                totals.expense += transaction.amount
            }
        }
    }

    func transactionDelta(after date: Date) -> Double {
        transactions
            .filter { Calendar.current.startOfDay(for: $0.date) > date }
            .reduce(0) { $0 + $1.delta }
    }

    private func projectedRecurringIncome(fallbackMonthlyIncome: Double) -> (day: Int, amount: Double, label: String) {
        let salaryTransactions = transactions
            .filter { $0.type == .income && ($0.category == .salary || $0.category == .bonus) }
            .sorted { $0.date > $1.date }

        guard let latestSalary = salaryTransactions.first else {
            return (1, fallbackMonthlyIncome, "給与入金")
        }

        let day = Calendar.current.component(.day, from: latestSalary.date)
        return (min(max(day, 1), 28), latestSalary.amount, latestSalary.category.rawValue)
    }

    private func averageDailyVariableTransactionDelta() -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -90, to: today) else { return 0 }

        let variableTransactions = transactions.filter { transaction in
            let day = calendar.startOfDay(for: transaction.date)
            let isRecurringIncome = transaction.type == .income &&
                (transaction.category == .salary || transaction.category == .bonus)
            return day >= start && day < today && !isRecurringIncome
        }

        guard !variableTransactions.isEmpty else { return 0 }
        let totalDelta = variableTransactions.reduce(0) { $0 + $1.delta }
        return totalDelta / 90.0
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

extension Transaction {
    var delta: Double {
        type == .income ? amount : -amount
    }
}
