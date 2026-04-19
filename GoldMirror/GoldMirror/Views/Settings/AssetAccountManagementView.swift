// MARK: - AssetAccountManagementView.swift
// Gold Mirror – Bank and securities account management.

import SwiftUI

struct AssetAccountManagementView: View {
    @EnvironmentObject var dm: DataManager
    @State private var showBankForm = false
    @State private var showSecuritiesForm = false
    @State private var showBankTransfer = false
    @State private var showTransferCompleteAlert = false
    @State private var editingBank: BankAccount?
    @State private var editingSecurities: SecuritiesAccount?

    var body: some View {
        ZStack {
            Color.gmBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: GMSpacing.lg) {
                    AssetAccountHeader()

                    BankTransferActionCard(
                        isEnabled: !dm.bankAccounts.isEmpty && (dm.bankAccounts.count + dm.securitiesAccounts.count) >= 2,
                        onTap: { showBankTransfer = true }
                    )
                    .padding(.horizontal, GMSpacing.md)

                    AssetAccountSection(
                        title: "銀行口座",
                        icon: "building.columns.fill",
                        total: dm.totalBankBalance,
                        addTitle: "銀行を追加",
                        onAdd: { showBankForm = true }
                    ) {
                        if dm.bankAccounts.isEmpty {
                            EmptyAssetRow(text: "銀行口座が未登録です")
                        } else {
                            ForEach(dm.bankAccounts) { account in
                                BankManagementRow(
                                    account: account,
                                    onEdit: { editingBank = account },
                                    onDelete: { deleteBank(account) }
                                )
                            }
                        }
                    }

                    AssetAccountSection(
                        title: "証券口座",
                        icon: "chart.line.uptrend.xyaxis",
                        total: dm.totalSecuritiesValue,
                        addTitle: "証券を追加",
                        onAdd: { showSecuritiesForm = true }
                    ) {
                        if dm.securitiesAccounts.isEmpty {
                            EmptyAssetRow(text: "証券口座が未登録です")
                        } else {
                            ForEach(dm.securitiesAccounts) { account in
                                SecuritiesManagementRow(
                                    account: account,
                                    onEdit: { editingSecurities = account },
                                    onDelete: { deleteSecurities(account) }
                                )
                            }
                        }
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.top, GMSpacing.md)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.gmBackground, for: .navigationBar)
        .sheet(isPresented: $showBankForm) {
            BankAccountFormSheet(account: nil) { dm.addBankAccount($0) }
        }
        .sheet(isPresented: $showBankTransfer) {
            BankTransferSheet { sourceKind, sourceID, destinationID, amount in
                if dm.transferToBankAccount(from: sourceKind, sourceID: sourceID, toBankAccountID: destinationID, amount: amount) {
                    showTransferCompleteAlert = true
                    return true
                }
                return false
            }
            .environmentObject(dm)
        }
        .sheet(item: $editingBank) { account in
            BankAccountFormSheet(account: account) { dm.updateBankAccount($0) }
        }
        .sheet(isPresented: $showSecuritiesForm) {
            SecuritiesAccountFormSheet(account: nil) { dm.addSecuritiesAccount($0) }
        }
        .sheet(item: $editingSecurities) { account in
            SecuritiesAccountFormSheet(account: account) { dm.updateSecuritiesAccount($0) }
        }
        .alert("振替が完了しました", isPresented: $showTransferCompleteAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("銀行口座の残高を更新しました。")
        }
    }

    private func deleteBank(_ account: BankAccount) {
        guard let idx = dm.bankAccounts.firstIndex(where: { $0.id == account.id }) else { return }
        dm.deleteBankAccount(at: IndexSet(integer: idx))
    }

    private func deleteSecurities(_ account: SecuritiesAccount) {
        guard let idx = dm.securitiesAccounts.firstIndex(where: { $0.id == account.id }) else { return }
        dm.deleteSecuritiesAccount(at: IndexSet(integer: idx))
    }
}

struct BankTransferActionCard: View {
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: GMSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: GMRadius.sm)
                        .fill(Color.gmGold.opacity(0.14))
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.gmGold)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("銀行間振替")
                        .font(GMFont.body(15, weight: .semibold))
                        .foregroundStyle(Color.gmTextPrimary)
                    Text(isEnabled ? "銀行・証券口座から銀行口座へ資金を移動" : "銀行口座と振替元口座が必要です")
                        .font(GMFont.caption(11))
                        .foregroundStyle(Color.gmTextTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.gmGold)
            }
            .padding(GMSpacing.md)
            .gmCardStyle(elevated: true)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

struct AssetAccountHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ASSET ACCOUNTS")
                    .font(GMFont.caption(11, weight: .bold))
                    .foregroundStyle(Color.gmGold.opacity(0.7))
                    .tracking(3)
                Text("口座管理")
                    .font(GMFont.heading(22, weight: .bold))
                    .foregroundStyle(GMGradient.goldHorizontal)
            }
            Spacer()
            Image(systemName: "building.columns.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.gmGold)
        }
        .padding(.horizontal, GMSpacing.md)
    }
}

struct AssetAccountSection<Content: View>: View {
    let title: String
    let icon: String
    let total: Double
    let addTitle: String
    let onAdd: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.gmGold)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(GMFont.heading(15, weight: .semibold))
                        .foregroundStyle(Color.gmTextPrimary)
                    Text(total.jpyFormatted)
                        .font(GMFont.caption(11, weight: .semibold))
                        .foregroundStyle(Color.gmGold)
                }
                Spacer()
                Button(action: onAdd) {
                    Label(addTitle, systemImage: "plus")
                        .font(GMFont.caption(12, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, GMSpacing.sm)
                        .padding(.vertical, 7)
                        .background(GMGradient.goldHorizontal)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, GMSpacing.md)

            VStack(spacing: GMSpacing.sm) {
                content()
            }
            .padding(.horizontal, GMSpacing.md)
        }
    }
}

struct BankManagementRow: View {
    let account: BankAccount
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ManagementRowShell(
            icon: account.iconName,
            iconColor: .gmGold,
            title: account.bankName,
            subtitle: "\(account.name) / \(account.accountNumber)",
            amount: account.balance,
            onEdit: onEdit,
            onDelete: onDelete
        )
    }
}

struct SecuritiesManagementRow: View {
    let account: SecuritiesAccount
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ManagementRowShell(
            icon: account.iconName,
            iconColor: account.profitLoss >= 0 ? .gmPositive : .gmNegative,
            title: account.brokerageName,
            subtitle: "\(account.name) / 損益 \(account.profitLoss.jpyFormatted)",
            amount: account.evaluationAmount,
            onEdit: onEdit,
            onDelete: onDelete
        )
    }
}

struct ManagementRowShell: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let amount: Double
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: GMSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: GMRadius.sm)
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(GMFont.body(14, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
                Text(subtitle)
                    .font(GMFont.caption(11))
                    .foregroundStyle(Color.gmTextTertiary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(amount.jpyFormatted)
                    .font(GMFont.mono(14, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.gmGold)
                    }
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.gmNegative)
                    }
                }
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

struct EmptyAssetRow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(GMFont.caption(12, weight: .medium))
            .foregroundStyle(Color.gmTextTertiary)
            .frame(maxWidth: .infinity)
            .padding(GMSpacing.lg)
            .gmCardStyle()
    }
}

struct BankAccountFormSheet: View {
    let account: BankAccount?
    let onSave: (BankAccount) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var bankName = ""
    @State private var balanceText = ""
    @State private var accountNumber = ""

    var body: some View {
        NavigationStack {
            GMFormContainer(title: account == nil ? "銀行口座を追加" : "銀行口座を編集") {
                Section {
                    GMFormField(label: "銀行名", placeholder: "銀行名", text: $bankName)
                    GMFormField(label: "口座名", placeholder: "生活費口座", text: $name)
                    GMFormField(label: "残高（円）", placeholder: "0", text: $balanceText)
                        .keyboardType(.numberPad)
                    GMFormField(label: "口座番号メモ", placeholder: "****", text: $accountNumber)
                } header: {
                    Text("基本情報").font(GMFont.caption(12)).foregroundStyle(Color.gmGold)
                }
            } onCancel: {
                dismiss()
            } onSave: {
                save()
            }
        }
        .onAppear { populate() }
    }

    private func populate() {
        guard let account else { return }
        name = account.name
        bankName = account.bankName
        balanceText = "\(Int(account.balance))"
        accountNumber = account.accountNumber
    }

    private func save() {
        let account = BankAccount(
            id: account?.id ?? UUID(),
            name: name,
            bankName: bankName,
            balance: Double(balanceText) ?? 0,
            accountNumber: accountNumber.isEmpty ? "****" : accountNumber
        )
        onSave(account)
        dismiss()
    }
}

struct SecuritiesAccountFormSheet: View {
    let account: SecuritiesAccount?
    let onSave: (SecuritiesAccount) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brokerageName = ""
    @State private var evaluationText = ""
    @State private var purchaseText = ""

    var body: some View {
        NavigationStack {
            GMFormContainer(title: account == nil ? "証券口座を追加" : "証券口座を編集") {
                Section {
                    GMFormField(label: "証券会社名", placeholder: "証券会社名", text: $brokerageName)
                    GMFormField(label: "口座名", placeholder: "NISA口座", text: $name)
                    GMFormField(label: "現在の評価額（円）", placeholder: "0", text: $evaluationText)
                        .keyboardType(.numberPad)
                    GMFormField(label: "取得額（円）", placeholder: "0", text: $purchaseText)
                        .keyboardType(.numberPad)
                } header: {
                    Text("基本情報").font(GMFont.caption(12)).foregroundStyle(Color.gmGold)
                }
            } onCancel: {
                dismiss()
            } onSave: {
                save()
            }
        }
        .onAppear { populate() }
    }

    private func populate() {
        guard let account else { return }
        name = account.name
        brokerageName = account.brokerageName
        evaluationText = "\(Int(account.evaluationAmount))"
        purchaseText = "\(Int(account.purchaseAmount))"
    }

    private func save() {
        let account = SecuritiesAccount(
            id: account?.id ?? UUID(),
            name: name,
            brokerageName: brokerageName,
            evaluationAmount: Double(evaluationText) ?? 0,
            purchaseAmount: Double(purchaseText) ?? 0
        )
        onSave(account)
        dismiss()
    }
}

struct BankTransferSheet: View {
    @EnvironmentObject var dm: DataManager
    @Environment(\.dismiss) private var dismiss
    let onTransfer: (AssetAccountKind, UUID, UUID, Double) -> Bool

    @State private var sourceKind: AssetAccountKind = .bank
    @State private var sourceID: UUID?
    @State private var destinationID: UUID?
    @State private var amountText = ""
    @State private var showValidationAlert = false

    private var sourceBalance: Double? {
        guard let sourceID else { return nil }
        switch sourceKind {
        case .bank:
            return dm.bankAccounts.first { $0.id == sourceID }?.balance
        case .securities:
            return dm.securitiesAccounts.first { $0.id == sourceID }?.balance
        }
    }

    private var destinationCandidates: [BankAccount] {
        sourceKind == .bank ? dm.bankAccounts.filter { $0.id != sourceID } : dm.bankAccounts
    }

    private var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var canTransfer: Bool {
        guard let sourceID,
              let destinationID,
              amount > 0 else {
            return false
        }
        guard dm.bankAccounts.contains(where: { $0.id == destinationID }) else { return false }
        switch sourceKind {
        case .bank:
            return sourceID != destinationID && dm.bankAccounts.contains { $0.id == sourceID }
        case .securities:
            return dm.securitiesAccounts.contains { $0.id == sourceID }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gmBackground.ignoresSafeArea()

                Form {
                    Section {
                        Picker("振替元種別", selection: $sourceKind) {
                            Text("銀行口座").tag(AssetAccountKind.bank)
                            Text("証券口座").tag(AssetAccountKind.securities)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: sourceKind) { _, _ in
                            sourceID = nil
                            destinationID = nil
                            ensureSelections()
                        }

                        Picker("振替元（出金）口座", selection: sourceBinding) {
                            if sourceKind == .bank {
                                ForEach(dm.bankAccounts) { account in
                                    Text("\(account.bankName)・\(account.name)")
                                        .tag(Optional(account.id))
                                }
                            } else {
                                ForEach(dm.securitiesAccounts) { account in
                                    Text("\(account.brokerageName)・\(account.name)")
                                        .tag(Optional(account.id))
                                }
                            }
                        }
                        .tint(Color.gmGold)

                        Picker("振替先（入金）口座", selection: destinationBinding) {
                            ForEach(destinationCandidates) { account in
                                Text("\(account.bankName)・\(account.name)")
                                    .tag(Optional(account.id))
                            }
                        }
                        .tint(Color.gmGold)

                        GMFormField(label: "振替金額（円）", placeholder: "0", text: $amountText)
                            .keyboardType(.numberPad)
                    } header: {
                        Text("振替内容")
                            .font(GMFont.caption(12))
                            .foregroundStyle(Color.gmGold)
                    } footer: {
                        if let sourceBalance {
                            Text("振替元残高: \(sourceBalance.jpyFormatted)")
                                .font(GMFont.caption(11))
                                .foregroundStyle(Color.gmTextTertiary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.gmBackground)
            }
            .navigationTitle("銀行間振替")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(Color.gmTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("振替実行") {
                        executeTransfer()
                    }
                    .foregroundStyle(Color.gmGold)
                    .fontWeight(.bold)
                    .disabled(!canTransfer)
                }
            }
            .alert("振替できません", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("振替元・振替先・金額を確認してください。")
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { ensureSelections() }
        .onChange(of: dm.bankAccounts.map(\.id)) { _, _ in ensureSelections() }
        .onChange(of: dm.securitiesAccounts.map(\.id)) { _, _ in ensureSelections() }
        .onChange(of: sourceID) { _, _ in ensureDestinationSelection() }
    }

    private var sourceBinding: Binding<UUID?> {
        Binding(
            get: {
                if let sourceID { return sourceID }
                return sourceKind == .bank ? dm.bankAccounts.first?.id : dm.securitiesAccounts.first?.id
            },
            set: { sourceID = $0 }
        )
    }

    private var destinationBinding: Binding<UUID?> {
        Binding(
            get: { destinationID ?? destinationCandidates.first?.id },
            set: { destinationID = $0 }
        )
    }

    private func ensureSelections() {
        guard !dm.bankAccounts.isEmpty else {
            sourceID = nil
            destinationID = nil
            return
        }

        if sourceKind == .securities && dm.securitiesAccounts.isEmpty {
            sourceKind = .bank
        }

        if sourceKind == .bank {
            if sourceID == nil || !dm.bankAccounts.contains(where: { $0.id == sourceID }) {
                sourceID = dm.bankAccounts.first?.id
            }
        } else {
            if sourceID == nil || !dm.securitiesAccounts.contains(where: { $0.id == sourceID }) {
                sourceID = dm.securitiesAccounts.first?.id
            }
        }
        ensureDestinationSelection()
    }

    private func ensureDestinationSelection() {
        if destinationID == sourceID ||
            destinationID == nil ||
            !destinationCandidates.contains(where: { $0.id == destinationID }) {
            destinationID = destinationCandidates.first?.id
        }
    }

    private func executeTransfer() {
        guard let sourceID,
              let destinationID,
              onTransfer(sourceKind, sourceID, destinationID, amount) else {
            showValidationAlert = true
            return
        }
        dismiss()
    }
}

struct GMFormContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        ZStack {
            Color.gmBackground.ignoresSafeArea()
            Form {
                content()
            }
            .scrollContentBackground(.hidden)
            .background(Color.gmBackground)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("キャンセル", action: onCancel)
                    .foregroundStyle(Color.gmTextSecondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存", action: onSave)
                    .foregroundStyle(Color.gmGold)
                    .fontWeight(.bold)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    NavigationStack {
        AssetAccountManagementView()
            .environmentObject(DataManager())
    }
}
