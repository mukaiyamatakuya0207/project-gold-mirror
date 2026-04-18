// MARK: - CreditCardTrackerView.swift
// Gold Mirror – Credit card billing tracker with add/edit sheet.

import SwiftUI

struct CreditCardTrackerView: View {
    @EnvironmentObject var dm: DataManager
    @State private var showAddSheet = false
    @State private var editingCard: CreditCard? = nil

    var body: some View {
        ZStack {
            Color.gmBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: GMSpacing.lg) {

                    // ── Next Billing Banner ──
                    if let summary = dm.nextBillingSummary {
                        NextBillingBanner(summary: summary)
                            .padding(.horizontal, GMSpacing.md)
                    }

                    // ── Total Summary ──
                    CardBillingSummaryCard()
                        .padding(.horizontal, GMSpacing.md)

                    // ── Card List ──
                    VStack(spacing: GMSpacing.sm) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundStyle(Color.gmGold)
                            Text("登録カード")
                                .font(GMFont.heading(15, weight: .semibold))
                                .foregroundStyle(Color.gmTextPrimary)
                            Spacer()
                            Button {
                                showAddSheet = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("追加")
                                        .font(GMFont.caption(12, weight: .semibold))
                                }
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, GMSpacing.sm)
                                .padding(.vertical, 6)
                                .background(GMGradient.goldHorizontal)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, GMSpacing.md)

                        ForEach(dm.creditCards) { card in
                            CreditCardDetailRow(card: card) {
                                editingCard = card
                            }
                            .padding(.horizontal, GMSpacing.md)
                        }
                    }

                    PaymentScheduleSection()
                        .padding(.horizontal, GMSpacing.md)

                    // ── Billing Calendar Preview ──
                    BillingDayHeatmap()
                        .padding(.horizontal, GMSpacing.md)

                    Spacer().frame(height: 100)
                }
                .padding(.top, GMSpacing.md)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.gmBackground, for: .navigationBar)
        .sheet(isPresented: $showAddSheet) {
            CreditCardFormSheet(card: nil) { newCard in
                dm.addCreditCard(newCard)
            }
            .environmentObject(dm)
        }
        .sheet(item: $editingCard) { card in
            CreditCardFormSheet(card: card) { updated in
                dm.updateCreditCard(updated)
            }
            .environmentObject(dm)
        }
    }
}

// ─────────────────────────────────────────
// MARK: Next Billing Banner
// ─────────────────────────────────────────
struct NextBillingBanner: View {
    let summary: NextBillingSummary

    private var dateFmt: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日 (E)"
        return f
    }

    var body: some View {
        HStack(spacing: GMSpacing.md) {
            // Countdown circle
            ZStack {
                Circle()
                    .stroke(Color.gmGoldDim.opacity(0.3), lineWidth: 3)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: CGFloat(1.0 - Double(summary.daysUntil) / 31.0))
                    .stroke(Color.gmGold, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 64, height: 64)
                VStack(spacing: 0) {
                    Text("\(summary.daysUntil)")
                        .font(GMFont.mono(20, weight: .bold))
                        .foregroundStyle(Color.gmGold)
                    Text("日後")
                        .font(GMFont.caption(9))
                        .foregroundStyle(Color.gmTextTertiary)
                }
            }
            .gmGoldGlow(radius: 10, opacity: 0.3)

            VStack(alignment: .leading, spacing: GMSpacing.xs) {
                Text("次の引き落とし")
                    .font(GMFont.caption(11, weight: .medium))
                    .foregroundStyle(Color.gmTextTertiary)
                Text(summary.totalAmount.jpyFormatted)
                    .font(GMFont.display(24, weight: .bold))
                    .foregroundStyle(GMGradient.goldHorizontal)
                Text(dateFmt.string(from: summary.nextBillingDate))
                    .font(GMFont.caption(12))
                    .foregroundStyle(Color.gmTextSecondary)
            }

            Spacer()

            // Card count badge
            VStack(spacing: 4) {
                Text("\(summary.cards.count)")
                    .font(GMFont.mono(22, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
                Text("枚")
                    .font(GMFont.caption(10))
                    .foregroundStyle(Color.gmTextTertiary)
            }
        }
        .padding(GMSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .fill(LinearGradient(
                    colors: [Color(hex: "#1A1000"), Color(hex: "#0F0F0F")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: GMRadius.lg)
                        .strokeBorder(GMGradient.goldHorizontal, lineWidth: 1.0)
                )
        )
        .gmGoldGlow(radius: 16, opacity: 0.2)
    }
}

// ─────────────────────────────────────────
// MARK: Card Billing Summary Card
// ─────────────────────────────────────────
struct CardBillingSummaryCard: View {
    @EnvironmentObject var dm: DataManager

    var body: some View {
        HStack(spacing: 0) {
            SummaryStatColumn(
                label: "今月合計",
                value: dm.totalMonthlyCardBilling.jpyCompact,
                icon: "creditcard.fill",
                color: .gmGold
            )
            Divider().frame(width: 0.5).background(Color.gmGoldDim.opacity(0.4))
                .padding(.vertical, GMSpacing.md)
            SummaryStatColumn(
                label: "登録カード数",
                value: "\(dm.creditCards.count)枚",
                icon: "rectangle.stack.fill",
                color: .gmTextSecondary
            )
            Divider().frame(width: 0.5).background(Color.gmGoldDim.opacity(0.4))
                .padding(.vertical, GMSpacing.md)
            SummaryStatColumn(
                label: "年間換算",
                value: (dm.totalMonthlyCardBilling * 12).jpyCompact,
                icon: "calendar",
                color: .gmNegative
            )
        }
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Payment Schedule Section
// ─────────────────────────────────────────
struct PaymentScheduleSection: View {
    @EnvironmentObject var dm: DataManager

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.gmGold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("引き落としスケジュール")
                        .font(GMFont.heading(15, weight: .semibold))
                        .foregroundStyle(Color.gmTextPrimary)
                    Text("カードごとに次回予定日と金額を管理")
                        .font(GMFont.caption(11))
                        .foregroundStyle(Color.gmTextTertiary)
                }
                Spacer()
            }

            if dm.creditCards.isEmpty {
                Text("カードを登録するとスケジュールを設定できます")
                    .font(GMFont.caption(12, weight: .medium))
                    .foregroundStyle(Color.gmTextTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(GMSpacing.lg)
                    .background(Color.gmSurface)
                    .clipShape(RoundedRectangle(cornerRadius: GMRadius.md))
            } else {
                ForEach(dm.creditCards) { card in
                    PaymentScheduleRow(card: card)
                }
            }
        }
    }
}

struct PaymentScheduleRow: View {
    @EnvironmentObject var dm: DataManager
    let card: CreditCard
    @State private var paymentDate: Date
    @State private var amountText: String

    init(card: CreditCard) {
        self.card = card
        _paymentDate = State(initialValue: card.nextPaymentDate)
        _amountText = State(initialValue: card.nextPaymentAmount > 0 ? "\(Int(card.nextPaymentAmount))" : "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.cardName)
                        .font(GMFont.body(14, weight: .semibold))
                        .foregroundStyle(Color.gmTextPrimary)
                    Text("現在: \(card.nextPaymentDate.japaneseDateString) / \(card.nextPaymentAmount.jpyFormatted)")
                        .font(GMFont.caption(10))
                        .foregroundStyle(Color.gmTextTertiary)
                }
                Spacer()
                Button("更新") { save() }
                    .font(GMFont.caption(12, weight: .bold))
                    .foregroundStyle(Color.gmGold)
            }

            DatePicker("次回引き落とし予定日", selection: $paymentDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .tint(Color.gmGold)
                .foregroundStyle(Color.gmTextPrimary)

            HStack {
                Text("次回引き落とし予定金額")
                    .font(GMFont.caption(12, weight: .medium))
                    .foregroundStyle(Color.gmTextSecondary)
                Spacer()
                TextField("0", text: $amountText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(GMFont.mono(15, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
                    .tint(Color.gmGold)
                    .frame(maxWidth: 130)
            }
        }
        .padding(GMSpacing.md)
        .background(Color.gmSurface)
        .clipShape(RoundedRectangle(cornerRadius: GMRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: GMRadius.md)
                .strokeBorder(Color.gmGoldDim.opacity(0.25), lineWidth: 0.6)
        )
        .onChange(of: card.nextPaymentDate) { _, newValue in
            paymentDate = newValue
        }
        .onChange(of: card.nextPaymentAmount) { _, newValue in
            amountText = newValue > 0 ? "\(Int(newValue))" : ""
        }
    }

    private func save() {
        dm.updateCreditCardSchedule(
            cardID: card.id,
            nextPaymentDate: paymentDate,
            nextPaymentAmount: Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0
        )
    }
}

// ─────────────────────────────────────────
// MARK: Credit Card Detail Row
// ─────────────────────────────────────────
struct CreditCardDetailRow: View {
    @EnvironmentObject var dm: DataManager
    let card: CreditCard
    let onEdit: () -> Void

    private var billingAmount: Double {
        dm.currentMonthBillingAmount(for: card)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: GMSpacing.md) {
                // Card icon
                ZStack {
                    RoundedRectangle(cornerRadius: GMRadius.sm)
                        .fill(Color(hex: card.accentColorHex).opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: card.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color(hex: card.accentColorHex))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(card.cardName)
                        .font(GMFont.body(14, weight: .semibold))
                        .foregroundStyle(Color.gmTextPrimary)
                    HStack(spacing: GMSpacing.xs) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 9))
                        Text("毎月 \(card.billingDay)日引き落とし")
                            .font(GMFont.caption(11))
                    }
                    .foregroundStyle(Color.gmTextTertiary)
                    Text("****\(card.cardLastFour)")
                        .font(GMFont.caption(10))
                        .foregroundStyle(Color.gmTextTertiary)
                    Text("引き落とし銀行: \(dm.linkedBankName(for: card))")
                        .font(GMFont.caption(10))
                        .foregroundStyle(Color.gmTextTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(billingAmount.jpyFormatted)
                        .font(GMFont.mono(15, weight: .bold))
                        .foregroundStyle(Color.gmTextPrimary)
                    Button(action: onEdit) {
                        Text("編集")
                            .font(GMFont.caption(11, weight: .medium))
                            .foregroundStyle(Color.gmGold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gmGold.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(GMSpacing.md)

            // Usage bar
            VStack(spacing: GMSpacing.xs) {
                HStack {
                    Text("利用率 \(Int(card.usageRate))%")
                        .font(GMFont.caption(10))
                        .foregroundStyle(Color.gmTextTertiary)
                    Spacer()
                    Text("限度額 \(card.creditLimit.jpyCompact)")
                        .font(GMFont.caption(10))
                        .foregroundStyle(Color.gmTextTertiary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gmSurfaceElevated)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: card.accentColorHex))
                            .frame(
                                width: geo.size.width * CGFloat(min(card.usageRate / 100, 1.0)),
                                height: 4
                            )
                    }
                }
                .frame(height: 4)
            }
            .padding(.horizontal, GMSpacing.md)
            .padding(.bottom, GMSpacing.md)
        }
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Billing Day Heatmap
// ─────────────────────────────────────────
struct BillingDayHeatmap: View {
    @EnvironmentObject var dm: DataManager

    private let days = Array(1...31)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private func amountForDay(_ day: Int) -> Double {
        let cards = dm.creditCards.filter { $0.billingDay == day }
        let costs = dm.fixedCosts.filter { $0.isActive && $0.billingDay == day }
        return cards.reduce(0) { $0 + dm.currentMonthBillingAmount(for: $1) }
             + costs.reduce(0) { $0 + $1.amount }
    }

    private var maxAmount: Double {
        days.map { amountForDay($0) }.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.gmGold)
                Text("支払日ヒートマップ")
                    .font(GMFont.heading(15, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
            }
            Text("日付の色が濃いほど引き落とし金額が大きい")
                .font(GMFont.caption(11))
                .foregroundStyle(Color.gmTextTertiary)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(days, id: \.self) { day in
                    let amount = amountForDay(day)
                    let intensity = maxAmount > 0 ? amount / maxAmount : 0
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                amount > 0
                                ? Color.gmGold.opacity(0.15 + intensity * 0.75)
                                : Color.gmSurface
                            )
                        Text("\(day)")
                            .font(GMFont.caption(10, weight: amount > 0 ? .bold : .regular))
                            .foregroundStyle(
                                amount > 0 ? Color.gmGold : Color.gmTextTertiary
                            )
                    }
                    .frame(height: 32)
                    .overlay(
                        amount > 0 ?
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gmGold.opacity(0.3), lineWidth: 0.5) : nil
                    )
                }
            }

            // Legend
            HStack {
                Text("少")
                    .font(GMFont.caption(10))
                    .foregroundStyle(Color.gmTextTertiary)
                HStack(spacing: 3) {
                    ForEach([0.2, 0.4, 0.6, 0.8, 1.0], id: \.self) { v in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gmGold.opacity(0.15 + v * 0.75))
                            .frame(width: 16, height: 10)
                    }
                }
                Text("多")
                    .font(GMFont.caption(10))
                    .foregroundStyle(Color.gmTextTertiary)
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Credit Card Form Sheet
// ─────────────────────────────────────────
struct CreditCardFormSheet: View {
    let card: CreditCard?
    let onSave: (CreditCard) -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dm: DataManager

    @State private var cardName: String = ""
    @State private var issuerName: String = ""
    @State private var billingDayText: String = "27"
    @State private var creditLimitText: String = ""
    @State private var cardLastFour: String = ""
    @State private var selectedBankID: UUID?

    var isEditing: Bool { card != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gmBackground.ignoresSafeArea()

                Form {
                    Section {
                        GMFormField(label: "カード名", placeholder: "カード名", text: $cardName)
                        GMFormField(label: "発行会社", placeholder: "発行会社", text: $issuerName)
                        GMFormField(label: "カード末尾4桁", placeholder: "1234", text: $cardLastFour)
                            .keyboardType(.numberPad)
                    } header: {
                        Text("基本情報").font(GMFont.caption(12)).foregroundStyle(Color.gmGold)
                    }

                    Section {
                        GMFormField(label: "引き落とし日", placeholder: "27", text: $billingDayText)
                            .keyboardType(.numberPad)
                        Picker("引き落とし銀行", selection: bankSelectionBinding) {
                            Text("未設定").tag(Optional<UUID>.none)
                            ForEach(dm.bankAccounts) { account in
                                Text(account.name).tag(Optional(account.id))
                            }
                        }
                        .tint(Color.gmGold)
                        GMFormField(label: "限度額（円）", placeholder: "0", text: $creditLimitText)
                            .keyboardType(.numberPad)
                    } header: {
                        Text("請求情報").font(GMFont.caption(12)).foregroundStyle(Color.gmGold)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.gmBackground)
            }
            .navigationTitle(isEditing ? "カードを編集" : "カードを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(Color.gmTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .foregroundStyle(Color.gmGold)
                        .fontWeight(.bold)
                        .disabled(cardName.isEmpty)
                }
            }
            .preferredColorScheme(.dark)
        }
        .onAppear { populate() }
    }

    private func populate() {
        guard let c = card else { return }
        cardName       = c.cardName
        issuerName     = c.issuerName
        billingDayText = "\(c.billingDay)"
        creditLimitText = "\(Int(c.creditLimit))"
        cardLastFour   = c.cardLastFour
        selectedBankID = c.linkedBankAccountID
    }

    private var bankSelectionBinding: Binding<UUID?> {
        Binding(
            get: {
                selectedBankID ?? dm.bankAccounts.first?.id
            },
            set: { selectedBankID = $0 }
        )
    }

    private func save() {
        let defaultPaymentDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let paymentDate = card?.nextPaymentDate ?? defaultPaymentDate
        let paymentAmount = card?.nextPaymentAmount ?? 0
        let updated = CreditCard(
            id: card?.id ?? UUID(),
            cardName: cardName,
            issuerName: issuerName,
            billingDay: Int(billingDayText) ?? 27,
            nextBillingAmount: card?.nextBillingAmount ?? 0,
            nextPaymentDate: paymentDate,
            nextPaymentAmount: paymentAmount,
            creditLimit: Double(creditLimitText) ?? 0,
            currentUsage: card?.currentUsage ?? 0,
            cardLastFour: cardLastFour.isEmpty ? "****" : cardLastFour,
            linkedBankAccountID: bankSelectionBinding.wrappedValue
        )
        onSave(updated)
        dismiss()
    }
}

// ─────────────────────────────────────────
// MARK: Preview
// ─────────────────────────────────────────
#Preview {
    CreditCardTrackerView()
        .environmentObject(DataManager())
}
