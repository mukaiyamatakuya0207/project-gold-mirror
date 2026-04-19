// MARK: - DataManager.swift
// Gold Mirror – Central ObservableObject managing all financial data,
// projection logic, and next-billing calculations.

import SwiftUI
import Combine

@MainActor
final class DataManager: ObservableObject {
    private static var jpCalendar: Calendar { .gmJapan }
    private static let expenseCategoriesStorageKey = "GoldMirror.expenseCategories.v1"
    private static let backupSchemaVersion = 1
    nonisolated static let profileDisplayNameStorageKey = "GoldMirror.profile.displayName"
    nonisolated static let profileTaglineStorageKey = "GoldMirror.profile.tagline"
    nonisolated static let profileIsPublicStorageKey = "GoldMirror.profile.isPublic"
    nonisolated static let profileGenderStorageKey = "GoldMirror.profile.gender"
    nonisolated static let profileAgeStorageKey = "GoldMirror.profile.age"
    nonisolated static let profilePrefectureStorageKey = "GoldMirror.profile.prefecture"
    nonisolated static let profileEmailStorageKey = "GoldMirror.profile.email"
    nonisolated static let profileStandardMonthlyRemunerationStorageKey = "GoldMirror.profile.standardMonthlyRemuneration"
    nonisolated static let profileDependentsCountStorageKey = "GoldMirror.profile.dependentsCount"
    nonisolated static let profileIncomeTaxCategoryStorageKey = "GoldMirror.profile.incomeTaxCategory"
    nonisolated static let profileResidentTaxAnnualStorageKey = "GoldMirror.profile.residentTaxAnnual"
    nonisolated static let profileResidentTaxMonthlyStorageKey = "GoldMirror.profile.residentTaxMonthly"
    nonisolated static let profileBaseMonthlySalaryStorageKey = "GoldMirror.profile.baseMonthlySalary"
    nonisolated static let profileFixedOvertimePayStorageKey = "GoldMirror.profile.fixedOvertimePay"
    nonisolated static let profileFixedOvertimeHoursStorageKey = "GoldMirror.profile.fixedOvertimeHours"
    nonisolated static let profileNonTaxableAllowanceStorageKey = "GoldMirror.profile.nonTaxableAllowance"

    struct GoldMirrorBackup: Codable {
        let schemaVersion: Int
        let exportedAt: Date
        var profileSettings: ProfileSettingsBackup?
        var fixedCosts: [FixedCost]
        var subscriptions: [Subscription]
        var bankAccounts: [BankAccount]
        var securitiesAccounts: [SecuritiesAccount]
        var creditCards: [CreditCard]
        var cardPaymentSchedules: [CardPaymentSchedule]
        var expenseCategories: [Category]
        var transactions: [Transaction]
    }

    struct ProfileSettingsBackup: Codable {
        var displayName: String
        var tagline: String
        var isPublicOnMirror: Bool
        var gender: String
        var age: Int
        var prefecture: String
        var email: String
        var standardMonthlyRemuneration: Double
        var dependentsCount: Int
        var incomeTaxCategory: String
        var residentTaxAnnual: Double
        var residentTaxMonthly: Double
        var baseMonthlySalary: Double
        var fixedOvertimePay: Double
        var fixedOvertimeHours: Double
        var nonTaxableAllowance: Double

        init(
            displayName: String,
            tagline: String,
            isPublicOnMirror: Bool,
            gender: String,
            age: Int,
            prefecture: String,
            email: String,
            standardMonthlyRemuneration: Double,
            dependentsCount: Int,
            incomeTaxCategory: String,
            residentTaxAnnual: Double,
            residentTaxMonthly: Double,
            baseMonthlySalary: Double,
            fixedOvertimePay: Double,
            fixedOvertimeHours: Double,
            nonTaxableAllowance: Double
        ) {
            self.displayName = displayName
            self.tagline = tagline
            self.isPublicOnMirror = isPublicOnMirror
            self.gender = gender
            self.age = age
            self.prefecture = prefecture
            self.email = email
            self.standardMonthlyRemuneration = standardMonthlyRemuneration
            self.dependentsCount = dependentsCount
            self.incomeTaxCategory = incomeTaxCategory
            self.residentTaxAnnual = residentTaxAnnual
            self.residentTaxMonthly = residentTaxMonthly
            self.baseMonthlySalary = baseMonthlySalary
            self.fixedOvertimePay = fixedOvertimePay
            self.fixedOvertimeHours = fixedOvertimeHours
            self.nonTaxableAllowance = nonTaxableAllowance
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? "Gold Mirror User"
            tagline = try container.decodeIfPresent(String.self, forKey: .tagline) ?? "資産形成を楽しもう"
            isPublicOnMirror = try container.decodeIfPresent(Bool.self, forKey: .isPublicOnMirror) ?? false
            gender = try container.decodeIfPresent(String.self, forKey: .gender) ?? "未設定"
            age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 0
            prefecture = try container.decodeIfPresent(String.self, forKey: .prefecture) ?? "未設定"
            email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
            standardMonthlyRemuneration = try container.decodeIfPresent(Double.self, forKey: .standardMonthlyRemuneration) ?? 0
            dependentsCount = try container.decodeIfPresent(Int.self, forKey: .dependentsCount) ?? 0
            incomeTaxCategory = try container.decodeIfPresent(String.self, forKey: .incomeTaxCategory) ?? "甲"
            residentTaxAnnual = try container.decodeIfPresent(Double.self, forKey: .residentTaxAnnual) ?? 0
            residentTaxMonthly = try container.decodeIfPresent(Double.self, forKey: .residentTaxMonthly) ?? 0
            baseMonthlySalary = try container.decodeIfPresent(Double.self, forKey: .baseMonthlySalary) ?? 0
            fixedOvertimePay = try container.decodeIfPresent(Double.self, forKey: .fixedOvertimePay) ?? 0
            fixedOvertimeHours = try container.decodeIfPresent(Double.self, forKey: .fixedOvertimeHours) ?? 0
            nonTaxableAllowance = try container.decodeIfPresent(Double.self, forKey: .nonTaxableAllowance) ?? 0
        }
    }

    struct SalaryCalculationResult {
        let baseMonthlySalary: Double
        let fixedOvertimePay: Double
        let nonTaxableAllowance: Double
        let hourlyRate: Double
        let overtimeHours: Double
        let lateNightHours: Double
        let additionalOvertimePay: Double
        let lateNightAllowance: Double
        let healthInsurancePremium: Double
        let welfarePensionPremium: Double
        let estimatedIncomeTax: Double
        let residentTaxMonthly: Double
        let grossPay: Double
        let totalDeductions: Double
        let estimatedNetPay: Double
    }

    struct ExpenseCategoryReportItem: Identifiable {
        let id: String
        let name: String
        let iconName: String
        let colorHex: String
        let amount: Double
        let previousAmount: Double
        let averageAmount: Double
        let reimbursableAmount: Double
        let percentOfTotal: Double

        var monthOverMonthRate: Double {
            guard previousAmount > 0 else { return amount > 0 ? 1 : 0 }
            return (amount - previousAmount) / previousAmount
        }

        var averageComparisonRate: Double {
            guard averageAmount > 0 else { return amount > 0 ? 1 : 0 }
            return (amount - averageAmount) / averageAmount
        }
    }

    struct MonthlyCashflowReportItem: Identifiable {
        let id: Date
        let month: Date
        let income: Double
        let expense: Double
        let reimbursableExpense: Double
    }

    struct FixedVariableReport {
        let fixedExpense: Double
        let variableExpense: Double

        var total: Double { fixedExpense + variableExpense }
        var fixedRatio: Double { total > 0 ? fixedExpense / total : 0 }
        var variableRatio: Double { total > 0 ? variableExpense / total : 0 }
    }

    struct IncomeBreakdownReportItem: Identifiable {
        let id: String
        let name: String
        let iconName: String
        let colorHex: String
        let amount: Double

        var percentOfTotal: Double = 0
    }

    struct MonthlyIncomeReportItem: Identifiable {
        let id: Date
        let month: Date
        let salary: Double
        let bonus: Double
        let investment: Double
        let other: Double

        var total: Double { salary + bonus + investment + other }
    }

    struct MonthlyExpenseTrendItem: Identifiable {
        let id: Date
        let month: Date
        let expense: Double
        let reimbursableExpense: Double
    }

    struct AnnualIncomeProjectionReport {
        let averageMonthlyIncome: Double
        let projectedAnnualIncome: Double
        let bonusIncluded: Double
        let monthsAnalyzed: Int
    }

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
        creditCards.reduce(0) { $0 + currentMonthBillingAmount(for: $1) }
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
    // MARK: Salary / Tax Estimation
    // ─────────────────────────────────────────
    func additionalWagesFromProfile(
        overtimeHours: Double,
        lateNightHours: Double,
        overtimeRate: Double = 0.25,
        lateNightRate: Double = 0.25
    ) -> (additionalOvertimePay: Double, lateNightAllowance: Double) {
        let result = salaryEstimateFromProfile(
            overtimeHours: overtimeHours,
            lateNightHours: lateNightHours,
            overtimeRate: overtimeRate,
            lateNightRate: lateNightRate
        )
        return (result.additionalOvertimePay, result.lateNightAllowance)
    }

    func salaryEstimateFromProfile(
        overtimeHours: Double = 0,
        lateNightHours: Double = 0,
        overtimeRate: Double = 0.25,
        lateNightRate: Double = 0.25
    ) -> SalaryCalculationResult {
        let profile = currentProfileSettingsBackup()
        return salaryEstimate(
            baseMonthlySalary: profile.baseMonthlySalary,
            fixedOvertimePay: profile.fixedOvertimePay,
            fixedOvertimeHours: profile.fixedOvertimeHours,
            nonTaxableAllowance: profile.nonTaxableAllowance,
            standardMonthlyRemuneration: profile.standardMonthlyRemuneration,
            dependentsCount: profile.dependentsCount,
            incomeTaxCategory: profile.incomeTaxCategory,
            residentTaxAnnual: profile.residentTaxAnnual,
            residentTaxMonthly: profile.residentTaxMonthly,
            prefecture: profile.prefecture,
            overtimeHours: overtimeHours,
            lateNightHours: lateNightHours,
            overtimeRate: overtimeRate,
            lateNightRate: lateNightRate
        )
    }

    func salaryEstimate(
        baseMonthlySalary: Double,
        fixedOvertimePay: Double,
        fixedOvertimeHours: Double,
        nonTaxableAllowance: Double,
        standardMonthlyRemuneration: Double,
        dependentsCount: Int,
        incomeTaxCategory: String,
        residentTaxAnnual: Double,
        residentTaxMonthly: Double,
        prefecture: String,
        overtimeHours: Double,
        lateNightHours: Double,
        overtimeRate: Double = 0.25,
        lateNightRate: Double = 0.25
    ) -> SalaryCalculationResult {
        let assumedMonthlyWorkingHours = 160.0
        let hourlyRate = (baseMonthlySalary + fixedOvertimePay) / assumedMonthlyWorkingHours
        let excessOvertimeHours = max(0, overtimeHours - fixedOvertimeHours)
        let additionalOvertimePay = hourlyRate * (1 + overtimeRate) * excessOvertimeHours
        let lateNightAllowance = hourlyRate * lateNightRate * max(0, lateNightHours)
        let healthInsurancePremium = standardMonthlyRemuneration * healthInsuranceEmployeeRate(for: prefecture)
        let welfarePensionPremium = standardMonthlyRemuneration * 0.0915
        let monthlyResidentTax = residentTaxMonthly > 0 ? residentTaxMonthly : residentTaxAnnual / 12
        let grossPay = baseMonthlySalary + fixedOvertimePay + nonTaxableAllowance + additionalOvertimePay + lateNightAllowance
        let socialInsuranceTotal = healthInsurancePremium + welfarePensionPremium
        let taxableMonthlyPay = max(0, grossPay - nonTaxableAllowance - socialInsuranceTotal - Double(max(0, dependentsCount)) * 31_667)
        let incomeTaxRate = incomeTaxCategory == "乙" ? 0.1021 : 0.05105
        let estimatedIncomeTax = taxableMonthlyPay * incomeTaxRate
        let totalDeductions = socialInsuranceTotal + estimatedIncomeTax + monthlyResidentTax
        let estimatedNetPay = max(0, grossPay - totalDeductions)

        return SalaryCalculationResult(
            baseMonthlySalary: baseMonthlySalary,
            fixedOvertimePay: fixedOvertimePay,
            nonTaxableAllowance: nonTaxableAllowance,
            hourlyRate: hourlyRate,
            overtimeHours: overtimeHours,
            lateNightHours: lateNightHours,
            additionalOvertimePay: additionalOvertimePay,
            lateNightAllowance: lateNightAllowance,
            healthInsurancePremium: healthInsurancePremium,
            welfarePensionPremium: welfarePensionPremium,
            estimatedIncomeTax: estimatedIncomeTax,
            residentTaxMonthly: monthlyResidentTax,
            grossPay: grossPay,
            totalDeductions: totalDeductions,
            estimatedNetPay: estimatedNetPay
        )
    }

    private func healthInsuranceEmployeeRate(for prefecture: String) -> Double {
        let placeholderRates: [String: Double] = [
            "北海道": 0.0510, "東京都": 0.04955, "神奈川県": 0.0501,
            "愛知県": 0.0501, "大阪府": 0.0517, "福岡県": 0.0518, "沖縄県": 0.0476
        ]
        return placeholderRates[prefecture] ?? 0.05
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

        var cashBalance = totalBankBalance
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

            // 固定費・サブスクの銀行引き落とし（休日は翌営業日へ補正）
            let previousDay = calendar.date(byAdding: .day, value: -1, to: dateStart) ?? dateStart
            for withdrawal in recurringBankWithdrawals(
                fromExclusive: previousDay,
                throughInclusive: dateStart,
                calendar: calendar
            ) {
                cashBalance -= withdrawal.amount
                isEvent = true
                eventLabels.append(withdrawal.name)
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

    func exportGMData() throws -> Data {
        let backup = GoldMirrorBackup(
            schemaVersion: Self.backupSchemaVersion,
            exportedAt: Date(),
            profileSettings: currentProfileSettingsBackup(),
            fixedCosts: fixedCosts,
            subscriptions: subscriptions,
            bankAccounts: bankAccounts,
            securitiesAccounts: securitiesAccounts,
            creditCards: creditCards,
            cardPaymentSchedules: cardPaymentSchedules,
            expenseCategories: expenseCategories,
            transactions: transactions
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    func importGMData(_ data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(GoldMirrorBackup.self, from: data)

        objectWillChange.send()
        if let profileSettings = backup.profileSettings {
            restoreProfileSettings(profileSettings)
        }
        fixedCosts = backup.fixedCosts
        subscriptions = backup.subscriptions
        bankAccounts = backup.bankAccounts
        securitiesAccounts = backup.securitiesAccounts
        creditCards = backup.creditCards
        cardPaymentSchedules = backup.cardPaymentSchedules
        expenseCategories = backup.expenseCategories.isEmpty
            ? Category.defaultExpenseCategories
            : backup.expenseCategories
        transactions = backup.transactions
        saveExpenseCategories()
        syncAllCreditCardBillingAmounts()
    }

    private func currentProfileSettingsBackup() -> ProfileSettingsBackup {
        let defaults = UserDefaults.standard
        let isPublic = defaults.object(forKey: Self.profileIsPublicStorageKey) as? Bool ?? false
        return ProfileSettingsBackup(
            displayName: defaults.string(forKey: Self.profileDisplayNameStorageKey) ?? "Gold Mirror User",
            tagline: defaults.string(forKey: Self.profileTaglineStorageKey) ?? "資産形成を楽しもう",
            isPublicOnMirror: isPublic,
            gender: defaults.string(forKey: Self.profileGenderStorageKey) ?? "未設定",
            age: defaults.object(forKey: Self.profileAgeStorageKey) as? Int ?? 0,
            prefecture: defaults.string(forKey: Self.profilePrefectureStorageKey) ?? "未設定",
            email: defaults.string(forKey: Self.profileEmailStorageKey) ?? "",
            standardMonthlyRemuneration: defaults.object(forKey: Self.profileStandardMonthlyRemunerationStorageKey) as? Double ?? 0,
            dependentsCount: defaults.object(forKey: Self.profileDependentsCountStorageKey) as? Int ?? 0,
            incomeTaxCategory: defaults.string(forKey: Self.profileIncomeTaxCategoryStorageKey) ?? "甲",
            residentTaxAnnual: defaults.object(forKey: Self.profileResidentTaxAnnualStorageKey) as? Double ?? 0,
            residentTaxMonthly: defaults.object(forKey: Self.profileResidentTaxMonthlyStorageKey) as? Double ?? 0,
            baseMonthlySalary: defaults.object(forKey: Self.profileBaseMonthlySalaryStorageKey) as? Double ?? 0,
            fixedOvertimePay: defaults.object(forKey: Self.profileFixedOvertimePayStorageKey) as? Double ?? 0,
            fixedOvertimeHours: defaults.object(forKey: Self.profileFixedOvertimeHoursStorageKey) as? Double ?? 0,
            nonTaxableAllowance: defaults.object(forKey: Self.profileNonTaxableAllowanceStorageKey) as? Double ?? 0
        )
    }

    private func restoreProfileSettings(_ profile: ProfileSettingsBackup) {
        UserDefaults.standard.set(profile.displayName, forKey: Self.profileDisplayNameStorageKey)
        UserDefaults.standard.set(profile.tagline, forKey: Self.profileTaglineStorageKey)
        UserDefaults.standard.set(profile.isPublicOnMirror, forKey: Self.profileIsPublicStorageKey)
        UserDefaults.standard.set(profile.gender, forKey: Self.profileGenderStorageKey)
        UserDefaults.standard.set(profile.age, forKey: Self.profileAgeStorageKey)
        UserDefaults.standard.set(profile.prefecture, forKey: Self.profilePrefectureStorageKey)
        UserDefaults.standard.set(profile.email, forKey: Self.profileEmailStorageKey)
        UserDefaults.standard.set(profile.standardMonthlyRemuneration, forKey: Self.profileStandardMonthlyRemunerationStorageKey)
        UserDefaults.standard.set(profile.dependentsCount, forKey: Self.profileDependentsCountStorageKey)
        UserDefaults.standard.set(profile.incomeTaxCategory, forKey: Self.profileIncomeTaxCategoryStorageKey)
        UserDefaults.standard.set(profile.residentTaxAnnual, forKey: Self.profileResidentTaxAnnualStorageKey)
        UserDefaults.standard.set(profile.residentTaxMonthly, forKey: Self.profileResidentTaxMonthlyStorageKey)
        UserDefaults.standard.set(profile.baseMonthlySalary, forKey: Self.profileBaseMonthlySalaryStorageKey)
        UserDefaults.standard.set(profile.fixedOvertimePay, forKey: Self.profileFixedOvertimePayStorageKey)
        UserDefaults.standard.set(profile.fixedOvertimeHours, forKey: Self.profileFixedOvertimeHoursStorageKey)
        UserDefaults.standard.set(profile.nonTaxableAllowance, forKey: Self.profileNonTaxableAllowanceStorageKey)
    }

    private func loadExpenseCategories() {
        guard let data = UserDefaults.standard.data(forKey: Self.expenseCategoriesStorageKey),
              let decoded = try? JSONDecoder().decode([Category].self, from: data),
              !decoded.isEmpty else {
            expenseCategories = Category.defaultExpenseCategories
            return
        }
        expenseCategories = categoriesWithRequiredDefaults(decoded)
        saveExpenseCategories()
    }

    private func saveExpenseCategories() {
        guard let data = try? JSONEncoder().encode(expenseCategories) else { return }
        UserDefaults.standard.set(data, forKey: Self.expenseCategoriesStorageKey)
    }

    private func categoriesWithRequiredDefaults(_ categories: [Category]) -> [Category] {
        guard !categories.contains(where: { $0.name == Category.companyExpenseCategory.name }) else {
            return categories
        }

        var merged = categories
        if let otherIndex = merged.firstIndex(where: { $0.name == "その他支出" }) {
            merged.insert(Category.companyExpenseCategory, at: otherIndex)
        } else {
            merged.append(Category.companyExpenseCategory)
        }
        return merged
    }

    // ─────────────────────────────────────────
    // MARK: CRUD – Fixed Costs
    // ─────────────────────────────────────────
    func addFixedCost(_ cost: FixedCost) {
        fixedCosts.append(cost)
        syncAllCreditCardBillingAmounts()
    }

    func updateFixedCost(_ cost: FixedCost) {
        if let idx = fixedCosts.firstIndex(where: { $0.id == cost.id }) {
            fixedCosts[idx] = cost
            syncAllCreditCardBillingAmounts()
        }
    }

    func deleteFixedCost(at offsets: IndexSet) {
        fixedCosts.remove(atOffsets: offsets)
        syncAllCreditCardBillingAmounts()
    }

    func toggleFixedCost(_ cost: FixedCost) {
        if let idx = fixedCosts.firstIndex(where: { $0.id == cost.id }) {
            fixedCosts[idx].isActive.toggle()
            syncAllCreditCardBillingAmounts()
        }
    }

    // ─────────────────────────────────────────
    // MARK: CRUD – Subscriptions
    // ─────────────────────────────────────────
    func addSubscription(_ sub: Subscription) {
        subscriptions.append(sub)
        syncAllCreditCardBillingAmounts()
    }

    func updateSubscription(_ sub: Subscription) {
        if let idx = subscriptions.firstIndex(where: { $0.id == sub.id }) {
            subscriptions[idx] = sub
            syncAllCreditCardBillingAmounts()
        }
    }

    func deleteSubscription(at offsets: IndexSet) {
        subscriptions.remove(atOffsets: offsets)
        syncAllCreditCardBillingAmounts()
    }

    func toggleSubscription(_ sub: Subscription) {
        if let idx = subscriptions.firstIndex(where: { $0.id == sub.id }) {
            subscriptions[idx].isActive.toggle()
            syncAllCreditCardBillingAmounts()
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
        applyTransactionToAccountBalanceIfPosted(t)
    }

    func updateTransaction(_ transaction: Transaction) {
        guard let idx = transactions.firstIndex(where: { $0.id == transaction.id }) else { return }
        let previous = transactions[idx]
        reverseTransactionFromAccountBalanceIfPosted(previous)
        transactions[idx] = transaction
        applyTransactionToAccountBalanceIfPosted(transaction)
    }

    func deleteTransaction(_ transaction: Transaction) {
        guard let idx = transactions.firstIndex(where: { $0.id == transaction.id }) else { return }
        let previous = transactions[idx]
        reverseTransactionFromAccountBalanceIfPosted(previous)
        transactions.remove(at: idx)
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
                    title: account.bankName,
                    subtitle: account.name,
                    amount: bankBalances[account.id] ?? account.balance
                )
            },
            securitiesAccounts: securitiesAccounts.map { account in
                EstimatedAccountBalance(
                    id: account.id,
                    title: account.brokerageName,
                    subtitle: account.name,
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

    func businessExpenseTransactions(
        in month: Date? = nil,
        status: ReimbursementStatus? = nil
    ) -> [Transaction] {
        let calendar = Self.jpCalendar
        return transactions.filter { transaction in
            guard transaction.type == .expense,
                  transaction.isBusinessExpense == true else { return false }
            if let month,
               !calendar.isDate(transaction.date, equalTo: month, toGranularity: .month) {
                return false
            }
            if let status {
                return transaction.reimbursementStatus == status
            }
            return true
        }
    }

    func businessExpenseTotal(in month: Date? = nil, status: ReimbursementStatus? = nil) -> Double {
        businessExpenseTransactions(in: month, status: status).reduce(0) { $0 + $1.amount }
    }

    func updateReimbursementStatus(for transactionID: UUID, status: ReimbursementStatus) {
        guard let idx = transactions.firstIndex(where: { $0.id == transactionID }) else { return }
        transactions[idx].isBusinessExpense = true
        transactions[idx].reimbursementStatus = status
    }

    @discardableResult
    func markBusinessExpensesCompleted(in month: Date, matching amount: Double, tolerance: Double = 1) -> Bool {
        let candidates = businessExpenseTransactions(in: month).filter { $0.reimbursementStatus != .completed }
        let total = candidates.reduce(0) { $0 + $1.amount }
        guard abs(total - amount) <= tolerance else { return false }
        let ids = Set(candidates.map(\.id))
        for idx in transactions.indices where ids.contains(transactions[idx].id) {
            transactions[idx].isBusinessExpense = true
            transactions[idx].reimbursementStatus = .completed
        }
        return true
    }

    func expenseCategoryReport(in month: Date = Date(), includeReimbursable: Bool = false) -> [ExpenseCategoryReportItem] {
        let calendar = Self.jpCalendar
        let monthStart = Self.startOfMonth(for: month, calendar: calendar)
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
        let averageMonths = (1...3).compactMap { calendar.date(byAdding: .month, value: -$0, to: monthStart) }
        let currentTransactions = reportExpenseTransactions(in: monthStart, includeReimbursable: includeReimbursable)
        let previousTransactions = reportExpenseTransactions(in: previousMonth, includeReimbursable: includeReimbursable)
        let total = currentTransactions.reduce(0) { $0 + $1.amount }

        let currentByCategory = groupedExpenseAmounts(currentTransactions)
        let previousByCategory = groupedExpenseAmounts(previousTransactions)
        let reimbursableByCategory = groupedExpenseAmounts(reportExpenseTransactions(in: monthStart, includeReimbursable: true).filter(isReimbursableExpense))
        let averageByCategory = averageMonths.reduce(into: [String: Double]()) { partial, targetMonth in
            for (key, value) in groupedExpenseAmounts(reportExpenseTransactions(in: targetMonth, includeReimbursable: includeReimbursable)) {
                partial[key, default: 0] += value / Double(max(averageMonths.count, 1))
            }
        }

        return currentByCategory.map { key, amount in
            let sample = currentTransactions.first { expenseCategoryKey(for: $0) == key }
                ?? previousTransactions.first { expenseCategoryKey(for: $0) == key }
            return ExpenseCategoryReportItem(
                id: key,
                name: sample?.displayCategoryName ?? key,
                iconName: sample?.displayCategoryIconName ?? "tag.fill",
                colorHex: sample?.categoryColorHex ?? "#D4AF37",
                amount: amount,
                previousAmount: previousByCategory[key, default: 0],
                averageAmount: averageByCategory[key, default: 0],
                reimbursableAmount: reimbursableByCategory[key, default: 0],
                percentOfTotal: total > 0 ? amount / total : 0
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    func monthlyCashflowReport(months: Int = 6, includeReimbursable: Bool = false) -> [MonthlyCashflowReportItem] {
        let calendar = Self.jpCalendar
        let currentMonth = Self.startOfMonth(for: Date(), calendar: calendar)
        return stride(from: months - 1, through: 0, by: -1).compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: -offset, to: currentMonth) else { return nil }
            let income = transactions.reduce(0) { total, transaction in
                guard transaction.type == .income,
                      calendar.isDate(transaction.date, equalTo: month, toGranularity: .month) else { return total }
                return total + transaction.amount
            }
            let allExpenses = reportExpenseTransactions(in: month, includeReimbursable: true)
            let reimbursable = allExpenses.filter(isReimbursableExpense).reduce(0) { $0 + $1.amount }
            let expense = allExpenses.reduce(0) { partial, transaction in
                if !includeReimbursable && isReimbursableExpense(transaction) { return partial }
                return partial + transaction.amount
            }
            return MonthlyCashflowReportItem(
                id: month,
                month: month,
                income: income,
                expense: expense,
                reimbursableExpense: reimbursable
            )
        }
    }

    func monthlyExpenseTrendReport(months: Int = 6, includeReimbursable: Bool = false) -> [MonthlyExpenseTrendItem] {
        monthlyCashflowReport(months: months, includeReimbursable: includeReimbursable)
            .map {
                MonthlyExpenseTrendItem(
                    id: $0.month,
                    month: $0.month,
                    expense: $0.expense,
                    reimbursableExpense: $0.reimbursableExpense
                )
            }
    }

    func fixedVariableExpenseReport(in month: Date = Date(), includeReimbursable: Bool = false) -> FixedVariableReport {
        let expenses = reportExpenseTransactions(in: month, includeReimbursable: includeReimbursable)
        let fixedTransactions = expenses.filter(isFixedExpense)
        let variableTransactions = expenses.filter { !isFixedExpense($0) }
        let profileDeductions = salaryEstimateFromProfile().healthInsurancePremium
            + salaryEstimateFromProfile().welfarePensionPremium
            + salaryEstimateFromProfile().residentTaxMonthly
        let recurringFixed = totalMonthlyFixedCosts + totalMonthlySubscriptions
        return FixedVariableReport(
            fixedExpense: fixedTransactions.reduce(0) { $0 + $1.amount } + recurringFixed + profileDeductions,
            variableExpense: variableTransactions.reduce(0) { $0 + $1.amount }
        )
    }

    func incomeBreakdownReport(in month: Date = Date()) -> [IncomeBreakdownReportItem] {
        let calendar = Self.jpCalendar
        let profile = currentProfileSettingsBackup()
        let monthIncomes = transactions.filter {
            $0.type == .income && calendar.isDate($0.date, equalTo: month, toGranularity: .month)
        }

        let profileBase = profile.baseMonthlySalary
        let profileOvertime = profile.fixedOvertimePay
        let profileAllowance = profile.nonTaxableAllowance
        let salaryTransactions = monthIncomes
            .filter { $0.category == .salary }
            .reduce(0) { $0 + $1.amount }
        let bonus = monthIncomes
            .filter { $0.category == .bonus }
            .reduce(0) { $0 + $1.amount }
        let investment = monthIncomes
            .filter { $0.category == .investment }
            .reduce(0) { $0 + $1.amount }
        let other = monthIncomes
            .filter { $0.category == .other_in }
            .reduce(0) { $0 + $1.amount }

        var items: [IncomeBreakdownReportItem] = []
        if profileBase > 0 {
            items.append(IncomeBreakdownReportItem(id: "base", name: "基本給", iconName: "briefcase.fill", colorHex: "#D4AF37", amount: profileBase))
        } else if salaryTransactions > 0 {
            items.append(IncomeBreakdownReportItem(id: "salary", name: "給与", iconName: "briefcase.fill", colorHex: "#D4AF37", amount: salaryTransactions))
        }
        if profileOvertime > 0 {
            items.append(IncomeBreakdownReportItem(id: "overtime", name: "残業代", iconName: "clock.badge.fill", colorHex: "#F0D060", amount: profileOvertime))
        }
        if profileAllowance > 0 {
            items.append(IncomeBreakdownReportItem(id: "allowance", name: "手当", iconName: "tram.fill", colorHex: "#81C784", amount: profileAllowance))
        }
        if bonus > 0 {
            items.append(IncomeBreakdownReportItem(id: "bonus", name: "賞与", iconName: "star.fill", colorHex: "#FFB74D", amount: bonus))
        }
        if investment > 0 {
            items.append(IncomeBreakdownReportItem(id: "investment", name: "投資収益", iconName: "chart.line.uptrend.xyaxis", colorHex: "#4FC3F7", amount: investment))
        }
        if other > 0 {
            items.append(IncomeBreakdownReportItem(id: "other", name: "その他収入", iconName: "plus.circle.fill", colorHex: "#A8A8A8", amount: other))
        }

        let total = items.reduce(0) { $0 + $1.amount }
        return items.map { item in
            IncomeBreakdownReportItem(
                id: item.id,
                name: item.name,
                iconName: item.iconName,
                colorHex: item.colorHex,
                amount: item.amount,
                percentOfTotal: total > 0 ? item.amount / total : 0
            )
        }
    }

    func monthlyIncomeReport(months: Int = 6) -> [MonthlyIncomeReportItem] {
        let calendar = Self.jpCalendar
        let currentMonth = Self.startOfMonth(for: Date(), calendar: calendar)
        return stride(from: months - 1, through: 0, by: -1).compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: -offset, to: currentMonth) else { return nil }
            let monthTransactions = transactions.filter {
                $0.type == .income && calendar.isDate($0.date, equalTo: month, toGranularity: .month)
            }
            return MonthlyIncomeReportItem(
                id: month,
                month: month,
                salary: monthTransactions.filter { $0.category == .salary }.reduce(0) { $0 + $1.amount },
                bonus: monthTransactions.filter { $0.category == .bonus }.reduce(0) { $0 + $1.amount },
                investment: monthTransactions.filter { $0.category == .investment }.reduce(0) { $0 + $1.amount },
                other: monthTransactions.filter { $0.category == .other_in }.reduce(0) { $0 + $1.amount }
            )
        }
    }

    func annualIncomeProjectionReport(months: Int = 6) -> AnnualIncomeProjectionReport {
        let calendar = Self.jpCalendar
        let incomeMonths = monthlyIncomeReport(months: months)
        let monthsWithIncome = incomeMonths.filter { $0.total > 0 }
        let regularAverage: Double
        if monthsWithIncome.isEmpty {
            let profile = currentProfileSettingsBackup()
            regularAverage = profile.baseMonthlySalary + profile.fixedOvertimePay + profile.nonTaxableAllowance
        } else {
            regularAverage = monthsWithIncome.reduce(0) { $0 + $1.salary + $1.investment + $1.other } / Double(monthsWithIncome.count)
        }

        let year = calendar.component(.year, from: Date())
        let annualBonus = transactions.reduce(0) { total, transaction in
            guard transaction.type == .income,
                  transaction.category == .bonus,
                  calendar.component(.year, from: transaction.date) == year else { return total }
            return total + transaction.amount
        }

        return AnnualIncomeProjectionReport(
            averageMonthlyIncome: regularAverage,
            projectedAnnualIncome: regularAverage * 12 + annualBonus,
            bonusIncluded: annualBonus,
            monthsAnalyzed: monthsWithIncome.count
        )
    }

    func transactionDelta(after date: Date) -> Double {
        let calendar = Self.jpCalendar
        return transactions
            .filter { calendar.startOfDay(for: $0.date) > date }
            .reduce(0) { $0 + $1.delta }
    }

    func currentMonthBillingAmount(for card: CreditCard) -> Double {
        let manualSchedules = cardPaymentSchedules(in: Date(), cardID: card.id).reduce(0) { $0 + $1.amount }
        return manualSchedules + recurringCreditCardCharges(in: Date(), cardID: card.id)
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

    func paymentSourceLabel(for source: RecurringPaymentSource?) -> String {
        guard let source else { return "支払元未設定" }
        switch source.kind {
        case .bankAccount:
            guard let account = bankAccounts.first(where: { $0.id == source.id }) else {
                return "銀行口座（未登録）"
            }
            return "\(account.bankName)・\(account.name)"
        case .creditCard:
            guard let card = creditCards.first(where: { $0.id == source.id }) else {
                return "カード（未登録）"
            }
            return "\(card.cardName) ****\(card.cardLastFour)"
        }
    }

    func adjustedBusinessDate(billingDay: Int, in month: Date) -> Date {
        let calendar = Self.jpCalendar
        var comps = calendar.dateComponents([.year, .month], from: month)
        let dayRange = calendar.range(of: .day, in: .month, for: month) ?? 1..<29
        comps.day = min(max(billingDay, 1), dayRange.count)
        var date = calendar.startOfDay(for: calendar.date(from: comps) ?? month)
        while !isJapaneseBusinessDay(date) {
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        return date
    }

    func isJapaneseBusinessDay(_ date: Date) -> Bool {
        let calendar = Self.jpCalendar
        guard !calendar.isDateInWeekend(date) else { return false }
        return !isJapaneseHoliday(date)
    }

    func isRecurringPaymentDue(billingDay: Int, on date: Date) -> Bool {
        let calendar = Self.jpCalendar
        return calendar.isDate(adjustedBusinessDate(billingDay: billingDay, in: date), inSameDayAs: date)
    }

    func recurringBankWithdrawalAmount(on date: Date) -> Double {
        let calendar = Self.jpCalendar
        let dateStart = calendar.startOfDay(for: date)
        let previousDay = calendar.date(byAdding: .day, value: -1, to: dateStart) ?? dateStart
        return recurringBankWithdrawals(
            fromExclusive: previousDay,
            throughInclusive: dateStart,
            calendar: calendar
        )
        .reduce(0) { $0 + $1.amount }
    }

    private static func startOfMonth(for date: Date, calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps).map { calendar.startOfDay(for: $0) } ?? calendar.startOfDay(for: date)
    }

    private func reportExpenseTransactions(in month: Date, includeReimbursable: Bool) -> [Transaction] {
        let calendar = Self.jpCalendar
        return transactions.filter { transaction in
            guard transaction.type == .expense,
                  !transaction.isAssetAdjustment,
                  calendar.isDate(transaction.date, equalTo: month, toGranularity: .month) else {
                return false
            }
            return includeReimbursable || !isReimbursableExpense(transaction)
        }
    }

    private func groupedExpenseAmounts(_ transactions: [Transaction]) -> [String: Double] {
        transactions.reduce(into: [String: Double]()) { partial, transaction in
            partial[expenseCategoryKey(for: transaction), default: 0] += transaction.amount
        }
    }

    private func expenseCategoryKey(for transaction: Transaction) -> String {
        transaction.categoryName ?? transaction.category.rawValue
    }

    private func isReimbursableExpense(_ transaction: Transaction) -> Bool {
        if transaction.isBusinessExpense == true {
            return true
        }
        let searchable = [
            transaction.categoryName,
            transaction.memo,
            transaction.merchantName,
            transaction.category.rawValue
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        return ["経費", "立替", "立て替え", "精算", "仮払"].contains { searchable.localizedCaseInsensitiveContains($0) }
    }

    private func isFixedExpense(_ transaction: Transaction) -> Bool {
        let searchable = [
            transaction.categoryName,
            transaction.memo,
            transaction.category.rawValue
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        return [
            "住民税", "税金", "社会保険", "健康保険", "厚生年金", "保険",
            "住宅", "家賃", "通信費", "水道光熱費", "固定費", "サブスク"
        ].contains { searchable.localizedCaseInsensitiveContains($0) }
    }

    private func isPostedTransaction(_ transaction: Transaction) -> Bool {
        let calendar = Self.jpCalendar
        return calendar.startOfDay(for: transaction.date) <= calendar.startOfDay(for: Date())
    }

    private func applyTransactionToAccountBalanceIfPosted(_ transaction: Transaction) {
        guard isPostedTransaction(transaction) else { return }
        applyTransactionToAccountBalance(transaction, multiplier: 1)
    }

    private func reverseTransactionFromAccountBalanceIfPosted(_ transaction: Transaction) {
        guard isPostedTransaction(transaction) else { return }
        applyTransactionToAccountBalance(transaction, multiplier: -1)
    }

    private func applyTransactionToAccountBalance(_ transaction: Transaction, multiplier: Double) {
        switch transaction.type {
        case .income:
            if transaction.incomeDestinationKind == .securities {
                let targetID = transaction.securitiesAccountID ?? securitiesAccounts.first?.id
                guard let idx = securitiesAccounts.firstIndex(where: { $0.id == targetID }) else { return }
                securitiesAccounts[idx].balance += transaction.amount * multiplier
                return
            }

            let targetID = transaction.bankAccountID ?? bankAccounts.first?.id
            guard let idx = bankAccounts.firstIndex(where: { $0.id == targetID }) else { return }
            bankAccounts[idx].balance += transaction.amount * multiplier
        case .expense:
            if transaction.isAssetAdjustment {
                switch transaction.assetAdjustmentTargetKind {
                case .securities:
                    let targetID = transaction.securitiesAccountID ?? securitiesAccounts.first?.id
                    guard let idx = securitiesAccounts.firstIndex(where: { $0.id == targetID }) else { return }
                    securitiesAccounts[idx].balance -= transaction.amount * multiplier
                case .bank:
                    let targetID = transaction.bankAccountID ?? bankAccounts.first?.id
                    guard let idx = bankAccounts.firstIndex(where: { $0.id == targetID }) else { return }
                    bankAccounts[idx].balance -= transaction.amount * multiplier
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
            bankAccounts[idx].balance -= transaction.amount * multiplier
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

        for withdrawal in recurringBankWithdrawals(fromExclusive: start, throughInclusive: end, calendar: calendar) {
            bankBalances[withdrawal.bankAccountID, default: 0] -= withdrawal.amount * direction
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

    private struct RecurringPaymentOccurrence {
        let id: UUID
        let date: Date
        let amount: Double
        let source: RecurringPaymentSource?
        let name: String
    }

    private struct RecurringBankWithdrawal {
        let date: Date
        let amount: Double
        let bankAccountID: UUID
        let name: String
    }

    private func recurringPaymentOccurrences(in month: Date) -> [RecurringPaymentOccurrence] {
        let calendar = Self.jpCalendar
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        var occurrences: [RecurringPaymentOccurrence] = []

        for cost in fixedCosts where cost.isActive {
            occurrences.append(
                RecurringPaymentOccurrence(
                    id: cost.id,
                    date: adjustedBusinessDate(billingDay: cost.billingDay, in: monthStart),
                    amount: cost.amount,
                    source: cost.paymentSource,
                    name: cost.name
                )
            )
        }

        for sub in subscriptions where sub.isActive && sub.billingCycle == .monthly {
            occurrences.append(
                RecurringPaymentOccurrence(
                    id: sub.id,
                    date: adjustedBusinessDate(billingDay: sub.billingDay, in: monthStart),
                    amount: sub.monthlyCost,
                    source: sub.paymentSource,
                    name: sub.name
                )
            )
        }

        return occurrences
    }

    private func recurringPaymentOccurrences(
        fromExclusive start: Date,
        throughInclusive end: Date,
        calendar: Calendar
    ) -> [RecurringPaymentOccurrence] {
        guard start < end else { return [] }
        let startMonth = calendar.date(
            byAdding: .month,
            value: -1,
            to: calendar.date(from: calendar.dateComponents([.year, .month], from: start)) ?? start
        ) ?? start
        let endMonth = calendar.date(
            byAdding: .month,
            value: 1,
            to: calendar.date(from: calendar.dateComponents([.year, .month], from: end)) ?? end
        ) ?? end

        var cursor = startMonth
        var results: [RecurringPaymentOccurrence] = []
        var seen: Set<String> = []

        while cursor <= endMonth {
            for occurrence in recurringPaymentOccurrences(in: cursor) {
                let day = calendar.startOfDay(for: occurrence.date)
                guard day > start && day <= end else { continue }
                let key = "\(occurrence.id)-\(day.timeIntervalSince1970)"
                guard seen.insert(key).inserted else { continue }
                results.append(occurrence)
            }
            cursor = calendar.date(byAdding: .month, value: 1, to: cursor) ?? endMonth.addingTimeInterval(1)
        }

        return results
    }

    private func recurringBankWithdrawals(
        fromExclusive start: Date,
        throughInclusive end: Date,
        calendar: Calendar
    ) -> [RecurringBankWithdrawal] {
        recurringPaymentOccurrences(fromExclusive: start, throughInclusive: end, calendar: calendar)
            .compactMap { occurrence in
                switch occurrence.source?.kind {
                case .bankAccount, .none:
                    let bankID = occurrence.source?.id ?? bankAccounts.first?.id
                    guard let bankID else { return nil }
                    return RecurringBankWithdrawal(
                        date: occurrence.date,
                        amount: occurrence.amount,
                        bankAccountID: bankID,
                        name: occurrence.name
                    )
                case .creditCard:
                    guard let cardID = occurrence.source?.id,
                          let card = creditCards.first(where: { $0.id == cardID }),
                          let bankID = card.linkedBankAccountID else {
                        return nil
                    }
                    let withdrawalDate = adjustedBusinessDate(billingDay: card.billingDay, in: occurrence.date)
                    let withdrawalDay = calendar.startOfDay(for: withdrawalDate)
                    guard withdrawalDay > start && withdrawalDay <= end else { return nil }
                    return RecurringBankWithdrawal(
                        date: withdrawalDate,
                        amount: occurrence.amount,
                        bankAccountID: bankID,
                        name: occurrence.name
                    )
                }
            }
    }

    private func recurringCreditCardCharges(in month: Date, cardID: UUID) -> Double {
        recurringPaymentOccurrences(in: month)
            .filter { occurrence in
                occurrence.source?.kind == .creditCard && occurrence.source?.id == cardID
            }
            .reduce(0) { $0 + $1.amount }
    }

    private func isJapaneseHoliday(_ date: Date) -> Bool {
        isBaseJapaneseHoliday(date) || isSubstituteHoliday(date)
    }

    private func isBaseJapaneseHoliday(_ date: Date) -> Bool {
        let calendar = Self.jpCalendar
        let comps = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        guard let year = comps.year,
              let month = comps.month,
              let day = comps.day,
              let weekday = comps.weekday else {
            return false
        }

        switch (month, day) {
        case (1, 1), (2, 11), (2, 23), (4, 29), (5, 3), (5, 4), (5, 5), (8, 11), (11, 3), (11, 23):
            return true
        default:
            break
        }

        if month == 1 && weekday == 2 && nthWeekday(in: date, calendar: calendar) == 2 { return true }
        if month == 7 && weekday == 2 && nthWeekday(in: date, calendar: calendar) == 3 { return true }
        if month == 9 && weekday == 2 && nthWeekday(in: date, calendar: calendar) == 3 { return true }
        if month == 10 && weekday == 2 && nthWeekday(in: date, calendar: calendar) == 2 { return true }

        return vernalEquinoxDay(for: year) == day && month == 3
            || autumnEquinoxDay(for: year) == day && month == 9
    }

    private func isSubstituteHoliday(_ date: Date) -> Bool {
        let calendar = Self.jpCalendar
        guard !calendar.isDateInWeekend(date) else { return false }

        var cursor = calendar.date(byAdding: .day, value: -1, to: date)
        while let candidate = cursor {
            if !isBaseJapaneseHoliday(candidate) { return false }
            if calendar.component(.weekday, from: candidate) == 1 { return true }
            cursor = calendar.date(byAdding: .day, value: -1, to: candidate)
        }
        return false
    }

    private func nthWeekday(in date: Date, calendar: Calendar) -> Int {
        ((calendar.component(.day, from: date) - 1) / 7) + 1
    }

    private func vernalEquinoxDay(for year: Int) -> Int {
        switch year {
        case 2024, 2025, 2028, 2029: return 20
        case 2026, 2027, 2030: return 20
        default: return 20
        }
    }

    private func autumnEquinoxDay(for year: Int) -> Int {
        switch year {
        case 2024, 2028: return 22
        case 2025, 2026, 2027, 2029, 2030: return 23
        default: return 23
        }
    }

    private func syncAllCreditCardBillingAmounts() {
        for cardID in creditCards.map(\.id) {
            syncCardBillingAmount(for: cardID)
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
