// MARK: - DataManager.swift
// Gold Mirror – Central ObservableObject managing all financial data,
// projection logic, and next-billing calculations.

import SwiftUI
import Combine

@MainActor
final class DataManager: ObservableObject {
    private static var jpCalendar: Calendar { .gmJapan }
    private static let expenseCategoriesStorageKey = "GoldMirror.expenseCategories.v1"

    // ─────────────────────────────────────────
    // MARK: Published State
    // ─────────────────────────────────────────
    @Published var fixedCosts: [FixedCost]       = MockData.fixedCosts
    @Published var subscriptions: [Subscription] = MockData.subscriptions

    // Shared asset data (passed from AssetViewModel or owned here)
    @Published var bankAccounts: [BankAccount]             = MockData.bankAccounts
    @Published var securitiesAccounts: [SecuritiesAccount] = MockData.securitiesAccounts
    @Published var creditCards: [CreditCard]               = MockData.creditCards
    @Published var cardPaymentSchedules: [CardPaymentSchedule] = []
    @Published var expenseCategories: [Category] = Category.defaultExpenseCategories {
        didSet { saveExpenseCategories() }
    }

    init() {
        loadExpenseCategories()
    }

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
        cardPaymentSchedules(in: Date()).reduce(0) { $0 + $1.amount }
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

    var currentMonthAssetAdjustmentLoss: Double {
        assetAdjustmentTotal(in: Date())
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
        let calendar = Self.jpCalendar
        let todayStart = calendar.startOfDay(for: Date())
        let upcomingSchedules = cardPaymentSchedules.filter {
            calendar.startOfDay(for: $0.paymentDate) > todayStart && $0.amount > 0
        }

        guard let nearestDate = upcomingSchedules.map({ calendar.startOfDay(for: $0.paymentDate) }).min() else {
            return nil
        }

        let schedulesOnDay = upcomingSchedules.filter {
            calendar.isDate($0.paymentDate, inSameDayAs: nearestDate)
        }
        let total = schedulesOnDay.reduce(0) { $0 + $1.amount }
        let daysUntil = calendar.dateComponents([.day], from: todayStart, to: nearestDate).day ?? 0
        let cardsOnDay = schedulesOnDay.compactMap { schedule in
            creditCards.first { $0.id == schedule.cardID }
        }

        return NextBillingSummary(
            daysUntil: daysUntil,
            nextBillingDate: nearestDate,
            totalAmount: total,
            cards: cardsOnDay,
            schedules: schedulesOnDay
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
        let calendar = Self.jpCalendar
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
                    eventLabels.append(transaction.displayCategoryName)
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
            for schedule in cardPaymentSchedules {
                if calendar.isDate(schedule.paymentDate, inSameDayAs: date) {
                    cashBalance -= schedule.amount
                    isEvent = true
                    eventLabels.append(schedule.title)
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

    func transferBetweenBankAccounts(from sourceID: UUID, to destinationID: UUID, amount: Double) -> Bool {
        guard amount > 0,
              sourceID != destinationID,
              let sourceIndex = bankAccounts.firstIndex(where: { $0.id == sourceID }),
              let destinationIndex = bankAccounts.firstIndex(where: { $0.id == destinationID }) else {
            return false
        }

        bankAccounts[sourceIndex].balance -= amount
        bankAccounts[destinationIndex].balance += amount
        return true
    }

    func transferToBankAccount(from sourceKind: AssetAccountKind, sourceID: UUID, toBankAccountID destinationID: UUID, amount: Double) -> Bool {
        guard amount > 0,
              let destinationIndex = bankAccounts.firstIndex(where: { $0.id == destinationID }) else {
            return false
        }

        switch sourceKind {
        case .bank:
            guard sourceID != destinationID,
                  let sourceIndex = bankAccounts.firstIndex(where: { $0.id == sourceID }) else {
                return false
            }
            bankAccounts[sourceIndex].balance -= amount
        case .securities:
            guard let sourceIndex = securitiesAccounts.firstIndex(where: { $0.id == sourceID }) else {
                return false
            }
            securitiesAccounts[sourceIndex].balance -= amount
        }

        bankAccounts[destinationIndex].balance += amount
        return true
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
    // MARK: CRUD – Expense Categories
    // ─────────────────────────────────────────
    func addExpenseCategory(_ category: Category) {
        expenseCategories.append(category)
    }

    func updateExpenseCategory(_ category: Category) {
        guard let idx = expenseCategories.firstIndex(where: { $0.id == category.id }) else { return }
        expenseCategories[idx] = category
    }

    func deleteExpenseCategory(_ category: Category) {
        expenseCategories.removeAll { $0.id == category.id }
    }

    func moveExpenseCategories(from source: IndexSet, to destination: Int) {
        expenseCategories.move(fromOffsets: source, toOffset: destination)
    }

    func resetExpenseCategoriesToDefault() {
        expenseCategories = Category.defaultExpenseCategories
    }

    private func loadExpenseCategories() {
        guard let data = UserDefaults.standard.data(forKey: Self.expenseCategoriesStorageKey),
              let decoded = try? JSONDecoder().decode([Category].self, from: data),
              !decoded.isEmpty else {
            expenseCategories = Category.defaultExpenseCategories
            return
        }
        expenseCategories = decoded
    }

    private func saveExpenseCategories() {
        guard let data = try? JSONEncoder().encode(expenseCategories) else { return }
        UserDefaults.standard.set(data, forKey: Self.expenseCategoriesStorageKey)
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
        card.nextBillingAmount = currentMonthBillingAmount(for: card)
        card.currentUsage = card.nextBillingAmount
        creditCards.append(card)
    }

    func updateCreditCard(_ card: CreditCard) {
        if let idx = creditCards.firstIndex(where: { $0.id == card.id }) {
            var card = card
            card.nextBillingAmount = currentMonthBillingAmount(for: card)
            card.currentUsage = card.nextBillingAmount
            creditCards[idx] = card
        }
    }

    func updateCreditCardSchedule(cardID: UUID, nextPaymentDate: Date, nextPaymentAmount: Double) {
        let fallbackTitle = creditCards.first(where: { $0.id == cardID })?.cardName ?? "カード引き落とし"
        if let existing = cardPaymentSchedules.first(where: { $0.cardID == cardID }) {
            updateCardPaymentSchedule(
                CardPaymentSchedule(
                    id: existing.id,
                    cardID: cardID,
                    title: existing.title,
                    paymentDate: nextPaymentDate,
                    amount: nextPaymentAmount
                )
            )
        } else {
            addCardPaymentSchedule(
                CardPaymentSchedule(
                    cardID: cardID,
                    title: fallbackTitle,
                    paymentDate: nextPaymentDate,
                    amount: nextPaymentAmount
                )
            )
        }
    }

    func deleteCreditCard(at offsets: IndexSet) {
        let removedIDs = offsets.map { creditCards[$0].id }
        creditCards.remove(atOffsets: offsets)
        cardPaymentSchedules.removeAll { removedIDs.contains($0.cardID) }
    }

    // ─────────────────────────────────────────
    // MARK: CRUD – Card Payment Schedules
    // ─────────────────────────────────────────
    func addCardPaymentSchedule(_ schedule: CardPaymentSchedule) {
        cardPaymentSchedules.append(schedule)
        syncCardBillingAmount(for: schedule.cardID)
    }

    func updateCardPaymentSchedule(_ schedule: CardPaymentSchedule) {
        guard let idx = cardPaymentSchedules.firstIndex(where: { $0.id == schedule.id }) else { return }
        let previousCardID = cardPaymentSchedules[idx].cardID
        cardPaymentSchedules[idx] = schedule
        syncCardBillingAmount(for: previousCardID)
        syncCardBillingAmount(for: schedule.cardID)
    }

    func deleteCardPaymentSchedule(_ schedule: CardPaymentSchedule) {
        cardPaymentSchedules.removeAll { $0.id == schedule.id }
        syncCardBillingAmount(for: schedule.cardID)
    }

    // ─────────────────────────────────────────
    // MARK: Transactions (income / expense records)
    // ─────────────────────────────────────────
    @Published var transactions: [Transaction] = []

    func addTransaction(_ t: Transaction) {
        transactions.insert(t, at: 0)
        applyTransactionToAccountBalance(t)
    }

    func transactions(on date: Date) -> [Transaction] {
        transactions.filter { Self.jpCalendar.isDate($0.date, inSameDayAs: date) }
    }

    func estimatedBalances(for date: Date) -> EstimatedBalances {
        let calendar = Self.jpCalendar
        let todayStart = calendar.startOfDay(for: Date())
        let targetStart = calendar.startOfDay(for: date)

        var bankBalances = Dictionary(uniqueKeysWithValues: bankAccounts.map { ($0.id, $0.balance) })
        var securitiesBalances = Dictionary(uniqueKeysWithValues: securitiesAccounts.map { ($0.id, $0.balance) })

        if targetStart > todayStart {
            applyEstimatedChanges(
                fromExclusive: todayStart,
                throughInclusive: targetStart,
                direction: 1,
                calendar: calendar,
                bankBalances: &bankBalances,
                securitiesBalances: &securitiesBalances
            )
        } else if targetStart < todayStart {
            applyEstimatedChanges(
                fromExclusive: targetStart,
                throughInclusive: todayStart,
                direction: -1,
                calendar: calendar,
                bankBalances: &bankBalances,
                securitiesBalances: &securitiesBalances
            )
        }

        return EstimatedBalances(
            bankAccounts: bankAccounts.map { account in
                EstimatedAccountBalance(
                    id: account.id,
                    title: account.name,
                    subtitle: account.bankName,
                    amount: bankBalances[account.id] ?? account.balance
                )
            },
            securitiesAccounts: securitiesAccounts.map { account in
                EstimatedAccountBalance(
                    id: account.id,
                    title: account.name,
                    subtitle: account.brokerageName,
                    amount: securitiesBalances[account.id] ?? account.balance
                )
            }
        )
    }

    func transactionTotals(in month: Date) -> (income: Double, expense: Double) {
        let calendar = Self.jpCalendar
        return transactions.reduce(into: (income: 0.0, expense: 0.0)) { totals, transaction in
            guard calendar.isDate(transaction.date, equalTo: month, toGranularity: .month) else { return }
            guard !transaction.isAssetAdjustment else { return }
            switch transaction.type {
            case .income:
                totals.income += transaction.amount
            case .expense:
                totals.expense += transaction.amount
            }
        }
    }

    func assetAdjustmentTotal(in month: Date) -> Double {
        let calendar = Self.jpCalendar
        return transactions.reduce(0) { total, transaction in
            guard transaction.isAssetAdjustment,
                  calendar.isDate(transaction.date, equalTo: month, toGranularity: .month) else {
                return total
            }
            return total + transaction.amount
        }
    }

    func transactionDelta(after date: Date) -> Double {
        let calendar = Self.jpCalendar
        return transactions
            .filter { calendar.startOfDay(for: $0.date) > date }
            .reduce(0) { $0 + $1.delta }
    }

    func currentMonthBillingAmount(for card: CreditCard) -> Double {
        cardPaymentSchedules(in: Date(), cardID: card.id).reduce(0) { $0 + $1.amount }
    }

    func cardPaymentSchedules(for card: CreditCard) -> [CardPaymentSchedule] {
        cardPaymentSchedules
            .filter { $0.cardID == card.id }
            .sorted { $0.paymentDate < $1.paymentDate }
    }

    func linkedBankName(for card: CreditCard) -> String {
        guard let id = card.linkedBankAccountID,
              let account = bankAccounts.first(where: { $0.id == id }) else {
            return "未設定"
        }
        return account.name
    }

    private func applyTransactionToAccountBalance(_ transaction: Transaction) {
        switch transaction.type {
        case .income:
            if transaction.incomeDestinationKind == .securities {
                let targetID = transaction.securitiesAccountID ?? securitiesAccounts.first?.id
                guard let idx = securitiesAccounts.firstIndex(where: { $0.id == targetID }) else { return }
                securitiesAccounts[idx].balance += transaction.amount
                return
            }

            let targetID = transaction.bankAccountID ?? bankAccounts.first?.id
            guard let idx = bankAccounts.firstIndex(where: { $0.id == targetID }) else { return }
            bankAccounts[idx].balance += transaction.amount
        case .expense:
            if transaction.isAssetAdjustment {
                switch transaction.assetAdjustmentTargetKind {
                case .securities:
                    let targetID = transaction.securitiesAccountID ?? securitiesAccounts.first?.id
                    guard let idx = securitiesAccounts.firstIndex(where: { $0.id == targetID }) else { return }
                    securitiesAccounts[idx].balance -= transaction.amount
                case .bank:
                    let targetID = transaction.bankAccountID ?? bankAccounts.first?.id
                    guard let idx = bankAccounts.firstIndex(where: { $0.id == targetID }) else { return }
                    bankAccounts[idx].balance -= transaction.amount
                case .none:
                    return
                }
                return
            }

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

    private func applyEstimatedChanges(
        fromExclusive start: Date,
        throughInclusive end: Date,
        direction: Double,
        calendar: Calendar,
        bankBalances: inout [UUID: Double],
        securitiesBalances: inout [UUID: Double]
    ) {
        for transaction in transactions {
            let day = calendar.startOfDay(for: transaction.date)
            guard day > start && day <= end else { continue }
            applyEstimatedTransaction(
                transaction,
                direction: direction,
                bankBalances: &bankBalances,
                securitiesBalances: &securitiesBalances
            )
        }

        for schedule in cardPaymentSchedules {
            let day = calendar.startOfDay(for: schedule.paymentDate)
            guard day > start && day <= end,
                  let linkedBankID = creditCards.first(where: { $0.id == schedule.cardID })?.linkedBankAccountID else {
                continue
            }
            bankBalances[linkedBankID, default: 0] -= schedule.amount * direction
        }
    }

    private func applyEstimatedTransaction(
        _ transaction: Transaction,
        direction: Double,
        bankBalances: inout [UUID: Double],
        securitiesBalances: inout [UUID: Double]
    ) {
        switch transaction.type {
        case .income:
            if transaction.incomeDestinationKind == .securities {
                let targetID = transaction.securitiesAccountID ?? securitiesAccounts.first?.id
                guard let targetID else { return }
                securitiesBalances[targetID, default: 0] += transaction.amount * direction
            } else {
                let targetID = transaction.bankAccountID ?? bankAccounts.first?.id
                guard let targetID else { return }
                bankBalances[targetID, default: 0] += transaction.amount * direction
            }
        case .expense:
            if transaction.isAssetAdjustment {
                switch transaction.assetAdjustmentTargetKind {
                case .securities:
                    let targetID = transaction.securitiesAccountID ?? securitiesAccounts.first?.id
                    guard let targetID else { return }
                    securitiesBalances[targetID, default: 0] -= transaction.amount * direction
                case .bank:
                    let targetID = transaction.bankAccountID ?? bankAccounts.first?.id
                    guard let targetID else { return }
                    bankBalances[targetID, default: 0] -= transaction.amount * direction
                case .none:
                    return
                }
                return
            }

            if transaction.paymentMethod == .creditCard { return }
            let targetID = transaction.creditCardID.flatMap { cardID in
                creditCards.first(where: { $0.id == cardID })?.linkedBankAccountID
            } ?? bankAccounts.first?.id
            guard let targetID else { return }
            bankBalances[targetID, default: 0] -= transaction.amount * direction
        }
    }

    private func cardPaymentSchedules(in month: Date, cardID: UUID? = nil) -> [CardPaymentSchedule] {
        let calendar = Self.jpCalendar
        return cardPaymentSchedules.filter { schedule in
            let matchesMonth = calendar.isDate(schedule.paymentDate, equalTo: month, toGranularity: .month)
            let matchesCard = cardID.map { $0 == schedule.cardID } ?? true
            return matchesMonth && matchesCard
        }
    }

    private func syncCardBillingAmount(for cardID: UUID) {
        guard let idx = creditCards.firstIndex(where: { $0.id == cardID }) else { return }
        let amount = currentMonthBillingAmount(for: creditCards[idx])
        creditCards[idx].nextBillingAmount = amount
        creditCards[idx].currentUsage = amount
        if let next = cardPaymentSchedules(for: creditCards[idx]).first(where: {
            Self.jpCalendar.startOfDay(for: $0.paymentDate) >= Self.jpCalendar.startOfDay(for: Date())
        }) {
            creditCards[idx].nextPaymentDate = next.paymentDate
            creditCards[idx].nextPaymentAmount = next.amount
        } else {
            creditCards[idx].nextPaymentAmount = amount
        }
    }

    private func projectedRecurringIncome(fallbackMonthlyIncome: Double) -> (day: Int, amount: Double, label: String) {
        let salaryTransactions = transactions
            .filter { $0.type == .income && ($0.category == .salary || $0.category == .bonus) }
            .sorted { $0.date > $1.date }

        guard let latestSalary = salaryTransactions.first else {
            return (1, fallbackMonthlyIncome, "給与入金")
        }

        let day = Self.jpCalendar.component(.day, from: latestSalary.date)
        return (min(max(day, 1), 28), latestSalary.amount, latestSalary.category.rawValue)
    }

    private func averageDailyVariableTransactionDelta() -> Double {
        let calendar = Self.jpCalendar
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
        let calendar = Self.jpCalendar
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
        if isAssetAdjustment { return 0 }
        return type == .income ? amount : -amount
    }
}
