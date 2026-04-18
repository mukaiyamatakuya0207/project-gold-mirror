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
        creditCards.reduce(0) { $0 + $1.nextPaymentAmount }
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
        let todayStart = calendar.startOfDay(for: Date())
        let upcomingCards = creditCards.filter {
            calendar.startOfDay(for: $0.nextPaymentDate) > todayStart && $0.nextPaymentAmount > 0
        }

        guard let nearestDate = upcomingCards.map({ calendar.startOfDay(for: $0.nextPaymentDate) }).min() else {
            return nil
        }

        let cardsOnDay = upcomingCards.filter {
            calendar.isDate($0.nextPaymentDate, inSameDayAs: nearestDate)
        }
        let total = cardsOnDay.reduce(0) { $0 + $1.nextPaymentAmount }
        let daysUntil = calendar.dateComponents([.day], from: todayStart, to: nearestDate).day ?? 0

        return NextBillingSummary(
            daysUntil: daysUntil,
            nextBillingDate: nearestDate,
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
                if calendar.isDate(card.nextPaymentDate, inSameDayAs: date) {
                    cashBalance -= card.nextPaymentAmount
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
    // MARK: CRUD – Bank / Securities Accounts
    // ─────────────────────────────────────────
    func addBankAccount(_ account: BankAccount) {
        bankAccounts.append(account)
    }

    func updateBankAccount(_ account: BankAccount) {
        if let idx = bankAccounts.firstIndex(where: { $0.id == account.id }) {
            bankAccounts[idx] = account
        }
    }

    func deleteBankAccount(at offsets: IndexSet) {
        let removedIDs = offsets.map { bankAccounts[$0].id }
        bankAccounts.remove(atOffsets: offsets)
        for idx in creditCards.indices {
            guard let linkedID = creditCards[idx].linkedBankAccountID,
                  removedIDs.contains(linkedID) else { continue }
            creditCards[idx].linkedBankAccountID = nil
        }
    }

    func addSecuritiesAccount(_ account: SecuritiesAccount) {
        securitiesAccounts.append(account)
    }

    func updateSecuritiesAccount(_ account: SecuritiesAccount) {
        if let idx = securitiesAccounts.firstIndex(where: { $0.id == account.id }) {
            securitiesAccounts[idx] = account
        }
    }

    func deleteSecuritiesAccount(at offsets: IndexSet) {
        securitiesAccounts.remove(atOffsets: offsets)
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
        var card = card
        card.nextBillingAmount = card.nextPaymentAmount
        card.currentUsage = card.nextPaymentAmount
        creditCards.append(card)
    }

    func updateCreditCard(_ card: CreditCard) {
        if let idx = creditCards.firstIndex(where: { $0.id == card.id }) {
            var card = card
            card.nextBillingAmount = card.nextPaymentAmount
            card.currentUsage = card.nextPaymentAmount
            creditCards[idx] = card
        }
    }

    func updateCreditCardSchedule(cardID: UUID, nextPaymentDate: Date, nextPaymentAmount: Double) {
        guard let idx = creditCards.firstIndex(where: { $0.id == cardID }) else { return }
        creditCards[idx].nextPaymentDate = nextPaymentDate
        creditCards[idx].nextPaymentAmount = nextPaymentAmount
        creditCards[idx].nextBillingAmount = nextPaymentAmount
        creditCards[idx].currentUsage = nextPaymentAmount
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
        applyTransactionToBankBalance(t)
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

    func currentMonthBillingAmount(for card: CreditCard) -> Double {
        card.nextPaymentAmount
    }

    func linkedBankName(for card: CreditCard) -> String {
        guard let id = card.linkedBankAccountID,
              let account = bankAccounts.first(where: { $0.id == id }) else {
            return "未設定"
        }
        return account.name
    }

    private func applyTransactionToBankBalance(_ transaction: Transaction) {
        guard !bankAccounts.isEmpty else { return }

        switch transaction.type {
        case .income:
            bankAccounts[0].balance += transaction.amount
        case .expense:
            if transaction.paymentMethod == .creditCard {
                return
            }

            let linkedBankID = transaction.creditCardID.flatMap { cardID in
                creditCards.first(where: { $0.id == cardID })?.linkedBankAccountID
            }
            let targetID = linkedBankID ?? bankAccounts.first?.id
            guard let idx = bankAccounts.firstIndex(where: { $0.id == targetID }) else { return }
            bankAccounts[idx].balance -= transaction.amount
        }
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
