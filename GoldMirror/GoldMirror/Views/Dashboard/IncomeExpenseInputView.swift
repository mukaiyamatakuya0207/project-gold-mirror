// MARK: - IncomeExpenseInputView.swift
// Gold Mirror – FAB half-modal for recording income or expense transactions.

import SwiftUI

// ─────────────────────────────────────────
// MARK: Transaction Model
// ─────────────────────────────────────────
enum TransactionType: String, CaseIterable {
    case income  = "収入"
    case expense = "支出"

    var icon: String {
        switch self {
        case .income:  return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        }
    }
    var color: Color {
        switch self {
        case .income:  return Color.gmPositive
        case .expense: return Color.gmNegative
        }
    }
}

enum TransactionCategory: String, CaseIterable {
    // income
    case salary    = "給与"
    case bonus     = "ボーナス"
    case investment = "投資収益"
    case other_in  = "その他収入"
    // expense
    case food      = "食費"
    case transport = "交通費"
    case shopping  = "買い物"
    case utilities = "光熱費"
    case entertainment = "娯楽"
    case health    = "医療"
    case assetImpairment = "資産評価換え（減損）"
    case other_ex  = "その他支出"

    var icon: String {
        switch self {
        case .salary:       return "briefcase.fill"
        case .bonus:        return "star.fill"
        case .investment:   return "chart.line.uptrend.xyaxis"
        case .other_in:     return "plus.circle.fill"
        case .food:         return "fork.knife"
        case .transport:    return "train.side.front.car"
        case .shopping:     return "bag.fill"
        case .utilities:    return "bolt.fill"
        case .entertainment: return "gamecontroller.fill"
        case .health:       return "cross.fill"
        case .assetImpairment: return "chart.line.downtrend.xyaxis"
        case .other_ex:     return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .salary, .bonus, .investment, .other_in:
            return Color.gmPositive
        case .food:        return Color(hex: "#FF8A65")
        case .transport:   return Color(hex: "#4FC3F7")
        case .shopping:    return Color(hex: "#CE93D8")
        case .utilities:   return Color(hex: "#FFD54F")
        case .entertainment: return Color(hex: "#A5D6A7")
        case .health:      return Color(hex: "#EF9A9A")
        case .assetImpairment: return Color(hex: "#B86BFF")
        case .other_ex:    return Color.gmTextSecondary
        }
    }

    static var incomeCategories: [TransactionCategory] {
        [.salary, .bonus, .investment, .other_in]
    }
    static var expenseCategories: [TransactionCategory] {
        [.food, .transport, .shopping, .utilities, .entertainment, .health, .assetImpairment, .other_ex]
    }
}

enum PaymentMethod: String, CaseIterable {
    case cash = "現金"
    case creditCard = "クレジットカード"
    case electronicMoney = "電子マネー"
    case qrCode = "QRコード"
    case bankDebit = "銀行引き落とし"
    case other = "その他"

    var icon: String {
        switch self {
        case .cash:            return "banknote.fill"
        case .creditCard:      return "creditcard.fill"
        case .electronicMoney: return "iphone.gen3"
        case .qrCode:          return "qrcode"
        case .bankDebit:       return "building.columns.fill"
        case .other:           return "ellipsis.circle.fill"
        }
    }
}

enum IncomeDestinationKind {
    case bank
    case securities
}

enum AssetAccountKind {
    case bank
    case securities

    var title: String {
        switch self {
        case .bank: return "銀行口座"
        case .securities: return "証券口座"
        }
    }
}

struct Transaction: Identifiable {
    let id = UUID()
    var type: TransactionType
    var amount: Double
    var category: TransactionCategory
    var date: Date
    var memo: String
    var paymentMethod: PaymentMethod = .cash
    var creditCardID: UUID? = nil
    var creditCardName: String? = nil
    var bankAccountID: UUID? = nil
    var bankAccountName: String? = nil
    var securitiesAccountID: UUID? = nil
    var securitiesAccountName: String? = nil
    var incomeDestinationKind: IncomeDestinationKind = .bank
    var isAssetAdjustment: Bool = false
    var assetAdjustmentTargetKind: AssetAccountKind? = nil
    var categoryName: String? = nil
    var categoryIconName: String? = nil
    var categoryColorHex: String? = nil

    var displayCategoryName: String {
        categoryName ?? category.rawValue
    }

    var displayCategoryIconName: String {
        categoryIconName ?? category.icon
    }

    var displayCategoryColor: Color {
        categoryColorHex.map { Color(hex: $0) } ?? category.color
    }
}

// ─────────────────────────────────────────
// MARK: IncomeExpenseInputView
// ─────────────────────────────────────────
struct IncomeExpenseInputView: View {
    @EnvironmentObject var dm: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var transactionType: TransactionType = .expense
    @State private var amountText = ""
    @State private var selectedCategory: TransactionCategory = .food
    @State private var selectedDate = Date()
    @State private var memo = ""
    @State private var showDatePicker = false
    @State private var savedAnimation = false
    @State private var selectedPaymentMethod: PaymentMethod = .cash
    @State private var selectedCreditCardID: UUID?
    @State private var selectedIncomeBankAccountID: UUID?
    @State private var selectedIncomeSecuritiesAccountID: UUID?
    @State private var selectedAdjustmentTargetKind: AssetAccountKind = .securities
    @State private var selectedAdjustmentBankAccountID: UUID?
    @State private var selectedAdjustmentSecuritiesAccountID: UUID?
    @State private var selectedExpenseCategoryID: UUID?

    private var categories: [TransactionCategory] {
        TransactionCategory.incomeCategories
    }

    private var parsedAmount: Double { Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0 }

    private var needsCreditCardSelection: Bool {
        transactionType == .expense && selectedPaymentMethod == .creditCard && !isAssetAdjustment
    }

    private var isAssetAdjustment: Bool {
        transactionType == .expense && selectedExpenseCategory?.isAssetAdjustment == true
    }

    private var selectedExpenseCategory: Category? {
        selectedExpenseCategoryID.flatMap { selectedID in
            dm.expenseCategories.first { $0.id == selectedID }
        } ?? dm.expenseCategories.first
    }

    private var formattedAmount: String {
        guard parsedAmount > 0 else { return "" }
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        return fmt.string(from: NSNumber(value: parsedAmount)) ?? amountText
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gmBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: GMSpacing.lg) {

                        // ── Type Toggle ──
                        HStack(spacing: 0) {
                            ForEach(TransactionType.allCases, id: \.rawValue) { t in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        transactionType = t
                                        if t == .income {
                                            selectedCategory = TransactionCategory.incomeCategories.first ?? .salary
                                            selectedPaymentMethod = .cash
                                            ensureIncomeDestinationSelection()
                                        } else {
                                            ensureExpenseCategorySelection()
                                            selectedIncomeBankAccountID = nil
                                            selectedIncomeSecuritiesAccountID = nil
                                            ensureAssetAdjustmentSelection()
                                        }
                                    }
                                } label: {
                                    HStack(spacing: GMSpacing.xs) {
                                        Image(systemName: t.icon)
                                            .font(.system(size: 14, weight: .semibold))
                                        Text(t.rawValue)
                                            .font(GMFont.heading(14, weight: .semibold))
                                    }
                                    .foregroundStyle(transactionType == t ? Color.gmBackground : Color.gmTextTertiary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        transactionType == t
                                            ? t.color
                                            : Color.gmSurface
                                    )
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: GMRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: GMRadius.md)
                                .strokeBorder(Color.gmGoldDim.opacity(0.4), lineWidth: 0.8)
                        )
                        .padding(.horizontal, GMSpacing.md)
                        .padding(.top, GMSpacing.md)

                        // ── Amount Input ──
                        VStack(spacing: GMSpacing.sm) {
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("¥")
                                    .font(GMFont.display(28, weight: .bold))
                                    .foregroundStyle(transactionType.color)

                                TextField("0", text: $amountText)
                                    .font(GMFont.display(42, weight: .bold))
                                    .foregroundStyle(Color.gmTextPrimary)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.leading)
                                    .tint(transactionType.color)
                            }
                            .padding(.horizontal, GMSpacing.md)

                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [transactionType.color.opacity(0.8), transactionType.color.opacity(0.2)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(height: 1)
                                .padding(.horizontal, GMSpacing.md)
                        }

                        // ── Category Grid ──
                        VStack(alignment: .leading, spacing: GMSpacing.sm) {
                            Text("カテゴリ")
                                .font(GMFont.caption(12, weight: .semibold))
                                .foregroundStyle(Color.gmTextTertiary)
                                .tracking(1)
                                .padding(.horizontal, GMSpacing.md)

                            let cols = Array(repeating: GridItem(.flexible(), spacing: GMSpacing.sm), count: 4)
                            LazyVGrid(columns: cols, spacing: GMSpacing.sm) {
                                if transactionType == .income {
                                    ForEach(categories, id: \.rawValue) { cat in
                                        CategoryChip(
                                            category: cat,
                                            isSelected: selectedCategory == cat
                                        ) {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                                selectedCategory = cat
                                                ensureIncomeDestinationSelection()
                                            }
                                        }
                                    }
                                } else {
                                    ForEach(dm.expenseCategories) { cat in
                                        ExpenseCategoryChip(
                                            category: cat,
                                            isSelected: selectedExpenseCategory?.id == cat.id
                                        ) {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                                selectedExpenseCategoryID = cat.id
                                                ensureAssetAdjustmentSelection()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, GMSpacing.md)
                        }

                        if transactionType == .expense && !isAssetAdjustment {
                            GMInputSection(title: "支払い方法", icon: "wallet.pass.fill") {
                                VStack(spacing: GMSpacing.sm) {
                                    Picker("支払い方法", selection: $selectedPaymentMethod) {
                                        ForEach(PaymentMethod.allCases, id: \.rawValue) { method in
                                            Label(method.rawValue, systemImage: method.icon)
                                                .tag(method)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color.gmGold)
                                    .foregroundStyle(Color.gmTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .onChange(of: selectedPaymentMethod) { _, method in
                                        guard method == .creditCard else { return }
                                        ensureCreditCardSelection()
                                    }

                                    if needsCreditCardSelection {
                                        Divider()
                                            .background(Color.gmGoldDim.opacity(0.35))

                                        if dm.creditCards.isEmpty {
                                            HStack(spacing: GMSpacing.sm) {
                                                Image(systemName: "exclamationmark.circle.fill")
                                                    .foregroundStyle(Color.gmGold)
                                                Text("登録済みカードがありません")
                                                    .font(GMFont.caption(12, weight: .medium))
                                                    .foregroundStyle(Color.gmTextTertiary)
                                                Spacer()
                                            }
                                        } else {
                                            Picker("利用カード", selection: creditCardSelectionBinding) {
                                                ForEach(dm.creditCards) { card in
                                                    Text(card.cardName)
                                                        .tag(Optional(card.id))
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .tint(Color.gmGold)
                                            .foregroundStyle(Color.gmTextPrimary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, GMSpacing.md)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        if isAssetAdjustment {
                            GMInputSection(title: "対象口座", icon: "chart.line.downtrend.xyaxis") {
                                VStack(spacing: GMSpacing.sm) {
                                    Picker("対象口座種別", selection: $selectedAdjustmentTargetKind) {
                                        Text("証券口座").tag(AssetAccountKind.securities)
                                        Text("銀行口座").tag(AssetAccountKind.bank)
                                    }
                                    .pickerStyle(.segmented)
                                    .onChange(of: selectedAdjustmentTargetKind) { _, _ in
                                        ensureAssetAdjustmentSelection()
                                    }

                                    Divider()
                                        .background(Color.gmGoldDim.opacity(0.35))

                                    if selectedAdjustmentTargetKind == .securities {
                                        if dm.securitiesAccounts.isEmpty {
                                            EmptyTargetAccountRow(text: "登録済み証券口座がありません")
                                        } else {
                                            Picker("対象の証券口座", selection: adjustmentSecuritiesSelectionBinding) {
                                                ForEach(dm.securitiesAccounts) { account in
                                                    Text("\(account.brokerageName)・\(account.name)")
                                                        .tag(Optional(account.id))
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .tint(Color.gmGold)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    } else {
                                        if dm.bankAccounts.isEmpty {
                                            EmptyTargetAccountRow(text: "登録済み銀行口座がありません")
                                        } else {
                                            Picker("対象の銀行口座", selection: adjustmentBankSelectionBinding) {
                                                ForEach(dm.bankAccounts) { account in
                                                    Text("\(account.bankName)・\(account.name)")
                                                        .tag(Optional(account.id))
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .tint(Color.gmGold)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, GMSpacing.md)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        if transactionType == .income {
                            GMInputSection(title: incomeDestinationTitle, icon: incomeDestinationIcon) {
                                if isInvestmentIncome {
                                    if dm.securitiesAccounts.isEmpty {
                                        HStack(spacing: GMSpacing.sm) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundStyle(Color.gmGold)
                                            Text("登録済み証券口座がありません")
                                                .font(GMFont.caption(12, weight: .medium))
                                                .foregroundStyle(Color.gmTextTertiary)
                                            Spacer()
                                        }
                                    } else {
                                        Picker("振込先（証券口座）", selection: incomeSecuritiesSelectionBinding) {
                                            ForEach(dm.securitiesAccounts) { account in
                                                Text("\(account.brokerageName)・\(account.name)")
                                                    .tag(Optional(account.id))
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(Color.gmGold)
                                        .foregroundStyle(Color.gmTextPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                } else if dm.bankAccounts.isEmpty {
                                    HStack(spacing: GMSpacing.sm) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundStyle(Color.gmGold)
                                        Text("登録済み口座がありません")
                                            .font(GMFont.caption(12, weight: .medium))
                                            .foregroundStyle(Color.gmTextTertiary)
                                        Spacer()
                                    }
                                } else {
                                    Picker("振込先（銀行口座）", selection: incomeBankSelectionBinding) {
                                        ForEach(dm.bankAccounts) { account in
                                            Text("\(account.bankName)・\(account.name)")
                                                .tag(Optional(account.id))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color.gmGold)
                                    .foregroundStyle(Color.gmTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.horizontal, GMSpacing.md)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // ── Date Picker ──
                        GMInputSection(title: "日付", icon: "calendar") {
                            Button {
                                withAnimation { showDatePicker.toggle() }
                            } label: {
                                HStack {
                                    Text(selectedDate.japaneseDateString)
                                        .font(GMFont.body(15))
                                        .foregroundStyle(Color.gmTextPrimary)
                                    Spacer()
                                    Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.gmGold)
                                }
                            }
                            .buttonStyle(.plain)

                            if showDatePicker {
                                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .tint(Color.gmGold)
                                    .environment(\.locale, Locale(identifier: "ja_JP"))
                                    .preferredColorScheme(.dark)
                            }
                        }
                        .padding(.horizontal, GMSpacing.md)

                        // ── Memo ──
                        GMInputSection(title: "メモ", icon: "text.alignleft") {
                            TextField("例：ランチ、サブスク更新...", text: $memo)
                                .font(GMFont.body(15))
                                .foregroundStyle(Color.gmTextPrimary)
                                .tint(Color.gmGold)
                        }
                        .padding(.horizontal, GMSpacing.md)

                        // ── Save Button ──
                        Button {
                            saveTransaction()
                        } label: {
                            HStack(spacing: GMSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("保存する")
                                    .font(GMFont.heading(16, weight: .bold))
                            }
                            .foregroundStyle(Color.gmBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.gmGoldLight, Color.gmGold, Color.gmGoldDim],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: GMRadius.lg))
                            .shadow(color: Color.gmGold.opacity(0.4), radius: 12, x: 0, y: 4)
                        }
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.45)
                        .padding(.horizontal, GMSpacing.md)
                        .padding(.bottom, GMSpacing.xl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("収支を記録")
                        .font(GMFont.heading(16, weight: .semibold))
                        .foregroundStyle(GMGradient.goldHorizontal)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.gmTextTertiary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.gmBackground)
        .onAppear {
            ensureExpenseCategorySelection()
            ensureCreditCardSelection()
            ensureIncomeDestinationSelection()
            ensureAssetAdjustmentSelection()
        }
        .onChange(of: dm.expenseCategories.map(\.id)) { _, _ in
            ensureExpenseCategorySelection()
            ensureAssetAdjustmentSelection()
        }
        .onChange(of: dm.creditCards.map(\.id)) { _, _ in
            ensureCreditCardSelection()
        }
        .onChange(of: dm.bankAccounts.map(\.id)) { _, _ in
            ensureIncomeDestinationSelection()
            ensureAssetAdjustmentSelection()
        }
        .onChange(of: dm.securitiesAccounts.map(\.id)) { _, _ in
            ensureIncomeDestinationSelection()
            ensureAssetAdjustmentSelection()
        }
        .onChange(of: selectedCategory) { _, _ in
            ensureIncomeDestinationSelection()
            ensureAssetAdjustmentSelection()
        }
        .environment(\.locale, Locale(identifier: "ja_JP"))
    }

    private var creditCardSelectionBinding: Binding<UUID?> {
        Binding(
            get: {
                selectedCreditCardID ?? dm.creditCards.first?.id
            },
            set: { newValue in
                selectedCreditCardID = newValue
            }
        )
    }

    private var incomeBankSelectionBinding: Binding<UUID?> {
        Binding(
            get: {
                selectedIncomeBankAccountID ?? dm.bankAccounts.first?.id
            },
            set: { newValue in
                selectedIncomeBankAccountID = newValue
            }
        )
    }

    private var incomeSecuritiesSelectionBinding: Binding<UUID?> {
        Binding(
            get: {
                selectedIncomeSecuritiesAccountID ?? dm.securitiesAccounts.first?.id
            },
            set: { newValue in
                selectedIncomeSecuritiesAccountID = newValue
            }
        )
    }

    private var adjustmentBankSelectionBinding: Binding<UUID?> {
        Binding(
            get: {
                selectedAdjustmentBankAccountID ?? dm.bankAccounts.first?.id
            },
            set: { newValue in
                selectedAdjustmentBankAccountID = newValue
            }
        )
    }

    private var adjustmentSecuritiesSelectionBinding: Binding<UUID?> {
        Binding(
            get: {
                selectedAdjustmentSecuritiesAccountID ?? dm.securitiesAccounts.first?.id
            },
            set: { newValue in
                selectedAdjustmentSecuritiesAccountID = newValue
            }
        )
    }

    private var selectedCreditCard: CreditCard? {
        guard needsCreditCardSelection else { return nil }
        let selectedID = creditCardSelectionBinding.wrappedValue
        return dm.creditCards.first { $0.id == selectedID }
    }

    private var isInvestmentIncome: Bool {
        transactionType == .income && selectedCategory == .investment
    }

    private var incomeDestinationTitle: String {
        isInvestmentIncome ? "振込先（証券口座）" : "振込先（銀行口座）"
    }

    private var incomeDestinationIcon: String {
        isInvestmentIncome ? "chart.line.uptrend.xyaxis" : "building.columns.fill"
    }

    private var canSave: Bool {
        guard parsedAmount > 0 else { return false }
        if transactionType == .income {
            return isInvestmentIncome
                ? incomeSecuritiesSelectionBinding.wrappedValue != nil
                : incomeBankSelectionBinding.wrappedValue != nil
        }
        if isAssetAdjustment {
            return selectedAdjustmentTargetKind == .securities
                ? adjustmentSecuritiesSelectionBinding.wrappedValue != nil
                : adjustmentBankSelectionBinding.wrappedValue != nil
        }
        if needsCreditCardSelection {
            return creditCardSelectionBinding.wrappedValue != nil
        }
        return true
    }

    private func ensureCreditCardSelection() {
        guard needsCreditCardSelection else { return }
        guard let current = selectedCreditCardID,
              dm.creditCards.contains(where: { $0.id == current }) else {
            selectedCreditCardID = dm.creditCards.first?.id
            return
        }
    }

    private func ensureExpenseCategorySelection() {
        guard transactionType == .expense else { return }
        guard let current = selectedExpenseCategoryID,
              dm.expenseCategories.contains(where: { $0.id == current }) else {
            selectedExpenseCategoryID = dm.expenseCategories.first?.id
            return
        }
    }

    private func ensureAssetAdjustmentSelection() {
        guard isAssetAdjustment else { return }
        if selectedAdjustmentTargetKind == .securities {
            guard let current = selectedAdjustmentSecuritiesAccountID,
                  dm.securitiesAccounts.contains(where: { $0.id == current }) else {
                selectedAdjustmentSecuritiesAccountID = dm.securitiesAccounts.first?.id
                return
            }
            return
        }

        guard let current = selectedAdjustmentBankAccountID,
              dm.bankAccounts.contains(where: { $0.id == current }) else {
            selectedAdjustmentBankAccountID = dm.bankAccounts.first?.id
            return
        }
    }

    private func ensureIncomeDestinationSelection() {
        guard transactionType == .income else { return }
        if isInvestmentIncome {
            guard let current = selectedIncomeSecuritiesAccountID,
                  dm.securitiesAccounts.contains(where: { $0.id == current }) else {
                selectedIncomeSecuritiesAccountID = dm.securitiesAccounts.first?.id
                return
            }
            return
        }

        guard let current = selectedIncomeBankAccountID,
              dm.bankAccounts.contains(where: { $0.id == current }) else {
            selectedIncomeBankAccountID = dm.bankAccounts.first?.id
            return
        }
    }

    private func saveTransaction() {
        let card = selectedCreditCard
        let expenseCategory = selectedExpenseCategory
        let transactionCategory: TransactionCategory
        if transactionType == .income {
            transactionCategory = selectedCategory
        } else if expenseCategory?.isAssetAdjustment == true {
            transactionCategory = .assetImpairment
        } else {
            transactionCategory = .other_ex
        }
        let bankID: UUID?
        if transactionType == .income && !isInvestmentIncome {
            bankID = incomeBankSelectionBinding.wrappedValue
        } else if isAssetAdjustment && selectedAdjustmentTargetKind == .bank {
            bankID = adjustmentBankSelectionBinding.wrappedValue
        } else {
            bankID = nil
        }
        let bankName = bankID.flatMap { id in
            dm.bankAccounts.first(where: { $0.id == id })?.name
        }
        let securitiesID: UUID?
        if transactionType == .income && isInvestmentIncome {
            securitiesID = incomeSecuritiesSelectionBinding.wrappedValue
        } else if isAssetAdjustment && selectedAdjustmentTargetKind == .securities {
            securitiesID = adjustmentSecuritiesSelectionBinding.wrappedValue
        } else {
            securitiesID = nil
        }
        let securitiesName = securitiesID.flatMap { id in
            dm.securitiesAccounts.first(where: { $0.id == id })?.name
        }
        let finalMemo: String
        if isAssetAdjustment && memo.isEmpty {
            finalMemo = "評価調整"
        } else {
            finalMemo = memo
        }
        let t = Transaction(
            type: transactionType,
            amount: parsedAmount,
            category: transactionCategory,
            date: selectedDate,
            memo: finalMemo,
            paymentMethod: transactionType == .expense ? selectedPaymentMethod : .cash,
            creditCardID: card?.id,
            creditCardName: card?.cardName,
            bankAccountID: bankID,
            bankAccountName: bankName,
            securitiesAccountID: securitiesID,
            securitiesAccountName: securitiesName,
            incomeDestinationKind: isInvestmentIncome ? .securities : .bank,
            isAssetAdjustment: isAssetAdjustment,
            assetAdjustmentTargetKind: isAssetAdjustment ? selectedAdjustmentTargetKind : nil,
            categoryName: transactionType == .expense ? expenseCategory?.name : nil,
            categoryIconName: transactionType == .expense ? expenseCategory?.iconName : nil,
            categoryColorHex: transactionType == .expense ? expenseCategory?.colorHex : nil
        )
        // Persist via DataManager
        dm.addTransaction(t)
        // Haptic feedback
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        dismiss()
    }
}

// ─────────────────────────────────────────
// MARK: Supporting Views
// ─────────────────────────────────────────
struct CategoryChip: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? category.color.opacity(0.25) : Color.gmSurface)
                        .frame(height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    isSelected ? category.color : Color.gmGoldDim.opacity(0.2),
                                    lineWidth: isSelected ? 1.5 : 0.5
                                )
                        )

                    Image(systemName: category.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isSelected ? category.color : Color.gmTextTertiary)
                }
                Text(category.rawValue)
                    .font(GMFont.caption(9, weight: .medium))
                    .foregroundStyle(isSelected ? category.color : Color.gmTextTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

struct ExpenseCategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? category.color.opacity(0.25) : Color.gmSurface)
                        .frame(height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    isSelected ? category.color : Color.gmGoldDim.opacity(0.2),
                                    lineWidth: isSelected ? 1.5 : 0.5
                                )
                        )

                    Image(systemName: category.iconName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isSelected ? category.color : Color.gmTextTertiary)
                }
                Text(category.name)
                    .font(GMFont.caption(9, weight: .medium))
                    .foregroundStyle(isSelected ? category.color : Color.gmTextTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

struct GMInputSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack(spacing: GMSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.gmGold)
                Text(title)
                    .font(GMFont.caption(12, weight: .semibold))
                    .foregroundStyle(Color.gmTextTertiary)
                    .tracking(1)
            }
            content()
                .padding(GMSpacing.md)
                .background(Color.gmSurface)
                .clipShape(RoundedRectangle(cornerRadius: GMRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: GMRadius.md)
                        .strokeBorder(Color.gmGoldDim.opacity(0.3), lineWidth: 0.5)
                )
        }
    }
}

struct EmptyTargetAccountRow: View {
    let text: String

    var body: some View {
        HStack(spacing: GMSpacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color.gmGold)
            Text(text)
                .font(GMFont.caption(12, weight: .medium))
                .foregroundStyle(Color.gmTextTertiary)
            Spacer()
        }
    }
}

// ─────────────────────────────────────────
// MARK: Preview
// ─────────────────────────────────────────
#Preview {
    IncomeExpenseInputView()
        .environmentObject(DataManager())
}
