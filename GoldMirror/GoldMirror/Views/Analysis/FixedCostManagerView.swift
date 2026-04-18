// MARK: - FixedCostManagerView.swift
// Gold Mirror – Subscription & fixed cost manager.

import SwiftUI

struct FixedCostManagerView: View {
    @EnvironmentObject var dm: DataManager
    @State private var showAddSubscription = false
    @State private var showAddFixedCost    = false
    @State private var editingSub: Subscription? = nil
    @State private var editingCost: FixedCost?   = nil
    @State private var selectedSegment: Int = 0   // 0=サブスク, 1=固定費

    var body: some View {
        ZStack {
            Color.gmBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: GMSpacing.lg) {

                    // ── Header ──
                    FixedCostPageHeader()

                    // ── Annual Summary ──
                    AnnualSummaryCard()
                        .padding(.horizontal, GMSpacing.md)

                    // ── Segment Switch ──
                    GMSegmentPicker(
                        options: ["サブスク", "固定費"],
                        selected: $selectedSegment
                    )
                    .padding(.horizontal, GMSpacing.md)

                    // ── Content ──
                    if selectedSegment == 0 {
                        SubscriptionListSection(editingSub: $editingSub) {
                            showAddSubscription = true
                        }
                    } else {
                        FixedCostListSection(editingCost: $editingCost) {
                            showAddFixedCost = true
                        }
                    }

                    // ── Waste Analysis ──
                    WasteAnalysisCard()
                        .padding(.horizontal, GMSpacing.md)

                    Spacer().frame(height: 100)
                }
                .padding(.top, GMSpacing.md)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.gmBackground, for: .navigationBar)
        .sheet(isPresented: $showAddSubscription) {
            SubscriptionFormSheet(sub: nil) { dm.addSubscription($0) }
        }
        .sheet(isPresented: $showAddFixedCost) {
            FixedCostFormSheet(cost: nil) { dm.addFixedCost($0) }
        }
        .sheet(item: $editingSub) { sub in
            SubscriptionFormSheet(sub: sub) { dm.updateSubscription($0) }
        }
        .sheet(item: $editingCost) { cost in
            FixedCostFormSheet(cost: cost) { dm.updateFixedCost($0) }
        }
    }
}

// ─────────────────────────────────────────
// MARK: Page Header
// ─────────────────────────────────────────
struct FixedCostPageHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("FIXED COSTS")
                    .font(GMFont.caption(11, weight: .bold))
                    .foregroundStyle(Color.gmGold.opacity(0.7))
                    .tracking(3)
                Text("サブスク・固定費")
                    .font(GMFont.heading(22, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
            }
            Spacer()
            Image(systemName: "scissors")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.gmGold)
        }
        .padding(.horizontal, GMSpacing.md)
    }
}

// ─────────────────────────────────────────
// MARK: Annual Summary Card
// ─────────────────────────────────────────
struct AnnualSummaryCard: View {
    @EnvironmentObject var dm: DataManager

    private var monthlyTotal: Double {
        dm.totalMonthlySubscriptions + dm.totalMonthlyFixedCosts
    }
    private var annualTotal: Double {
        dm.totalAnnualSubscriptions + dm.totalMonthlyFixedCosts * 12
    }

    var body: some View {
        VStack(spacing: GMSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: GMSpacing.xs) {
                    Text("月間固定支出合計")
                        .font(GMFont.caption(11, weight: .medium))
                        .foregroundStyle(Color.gmTextTertiary)
                        .tracking(1)
                    Text(monthlyTotal.jpyFormatted)
                        .font(GMFont.display(28, weight: .bold))
                        .foregroundStyle(GMGradient.goldHorizontal)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: GMSpacing.xs) {
                    Text("年換算")
                        .font(GMFont.caption(11))
                        .foregroundStyle(Color.gmTextTertiary)
                    Text(annualTotal.jpyCompact)
                        .font(GMFont.mono(18, weight: .bold))
                        .foregroundStyle(Color.gmNegative)
                }
            }

            // Bar breakdown
            GeometryReader { geo in
                HStack(spacing: 2) {
                    let subRatio = monthlyTotal > 0 ?
                        CGFloat(dm.totalMonthlySubscriptions / monthlyTotal) : 0.5
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#CE93D8"))
                        .frame(width: max(geo.size.width * subRatio - 2, 0))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GMGradient.goldHorizontal)
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 8)
            }
            .frame(height: 8)

            HStack {
                LegendDot(color: Color(hex: "#CE93D8"),
                          label: "サブスク \(dm.totalMonthlySubscriptions.jpyCompact)/月")
                Spacer()
                LegendDot(color: .gmGold,
                          label: "固定費 \(dm.totalMonthlyFixedCosts.jpyCompact)/月")
            }
        }
        .padding(GMSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .fill(LinearGradient(
                    colors: [Color(hex: "#1A0D00"), Color(hex: "#0F0F0F")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: GMRadius.lg)
                        .strokeBorder(Color.gmGold.opacity(0.3), lineWidth: 0.8)
                )
        )
    }
}

// ─────────────────────────────────────────
// MARK: Segment Picker
// ─────────────────────────────────────────
struct GMSegmentPicker: View {
    let options: [String]
    @Binding var selected: Int
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { idx in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selected = idx
                    }
                } label: {
                    ZStack {
                        if selected == idx {
                            RoundedRectangle(cornerRadius: GMRadius.sm)
                                .fill(Color.gmGold)
                                .matchedGeometryEffect(id: "segBg", in: ns)
                                .padding(3)
                        }
                        Text(options[idx])
                            .font(GMFont.caption(12, weight: selected == idx ? .bold : .medium))
                            .foregroundStyle(selected == idx ? Color.black : Color.gmTextSecondary)
                            .padding(.vertical, 8)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: GMRadius.md)
                .fill(Color.gmSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: GMRadius.md)
                        .stroke(Color.gmGoldDim.opacity(0.4), lineWidth: 0.5)
                )
        )
        .frame(height: 40)
    }
}

// ─────────────────────────────────────────
// MARK: Subscription List Section
// ─────────────────────────────────────────
struct SubscriptionListSection: View {
    @EnvironmentObject var dm: DataManager
    @Binding var editingSub: Subscription?
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: GMSpacing.sm) {
            HStack {
                Text("サブスクリプション (\(dm.subscriptions.count)件)")
                    .font(GMFont.heading(14, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
                Spacer()
                Button(action: onAdd) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
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

            ForEach(dm.subscriptions) { sub in
                SubscriptionRow(sub: sub,
                    onToggle: { dm.toggleSubscription(sub) },
                    onEdit:   { editingSub = sub }
                )
                .padding(.horizontal, GMSpacing.md)
            }
        }
    }
}

struct SubscriptionRow: View {
    let sub: Subscription
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: GMSpacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: GMRadius.sm)
                    .fill(Color(hex: sub.accentColorHex).opacity(sub.isActive ? 0.15 : 0.05))
                    .frame(width: 44, height: 44)
                Image(systemName: sub.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        sub.isActive
                        ? Color(hex: sub.accentColorHex)
                        : Color.gmTextTertiary
                    )
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(sub.name)
                    .font(GMFont.body(14, weight: .medium))
                    .foregroundStyle(sub.isActive ? Color.gmTextPrimary : Color.gmTextTertiary)
                    .strikethrough(!sub.isActive, color: Color.gmTextTertiary)

                HStack(spacing: GMSpacing.xs) {
                    Text(sub.billingCycle.rawValue)
                        .font(GMFont.caption(10, weight: .medium))
                        .foregroundStyle(Color.gmGold.opacity(0.7))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.gmGold.opacity(0.1))
                        .clipShape(Capsule())

                    if let days = sub.daysUntilExpiry, days <= 30 {
                        Text("残り\(days)日")
                            .font(GMFont.caption(10, weight: .medium))
                            .foregroundStyle(Color.gmNegative)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.gmNegative.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            // Amount + toggle
            VStack(alignment: .trailing, spacing: 4) {
                Text(sub.monthlyCost.jpyFormatted)
                    .font(GMFont.mono(14, weight: .bold))
                    .foregroundStyle(sub.isActive ? Color.gmTextPrimary : Color.gmTextTertiary)
                Text("年 \(sub.annualCost.jpyCompact)")
                    .font(GMFont.caption(10))
                    .foregroundStyle(Color.gmTextTertiary)
            }

            Toggle("", isOn: Binding(
                get: { sub.isActive },
                set: { _ in onToggle() }
            ))
            .tint(Color.gmGold)
            .labelsHidden()
            .scaleEffect(0.8)
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
        .onLongPressGesture { onEdit() }
    }
}

// ─────────────────────────────────────────
// MARK: Fixed Cost List Section
// ─────────────────────────────────────────
struct FixedCostListSection: View {
    @EnvironmentObject var dm: DataManager
    @Binding var editingCost: FixedCost?
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: GMSpacing.sm) {
            HStack {
                Text("固定費 (\(dm.fixedCosts.count)件)")
                    .font(GMFont.heading(14, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
                Spacer()
                Button(action: onAdd) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
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

            ForEach(dm.fixedCosts) { cost in
                FixedCostRow(cost: cost,
                    onToggle: { dm.toggleFixedCost(cost) },
                    onEdit:   { editingCost = cost }
                )
                .padding(.horizontal, GMSpacing.md)
            }
        }
    }
}

struct FixedCostRow: View {
    let cost: FixedCost
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: GMSpacing.md) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: GMRadius.sm)
                    .fill(cost.category.color.opacity(cost.isActive ? 0.15 : 0.05))
                    .frame(width: 44, height: 44)
                Image(systemName: cost.category.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(cost.isActive ? cost.category.color : Color.gmTextTertiary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(cost.name)
                    .font(GMFont.body(14, weight: .medium))
                    .foregroundStyle(cost.isActive ? Color.gmTextPrimary : Color.gmTextTertiary)
                    .strikethrough(!cost.isActive, color: Color.gmTextTertiary)

                HStack(spacing: GMSpacing.xs) {
                    Text(cost.category.rawValue)
                        .font(GMFont.caption(10))
                        .foregroundStyle(cost.category.color)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(cost.category.color.opacity(0.1))
                        .clipShape(Capsule())
                    Text("毎月\(cost.billingDay)日")
                        .font(GMFont.caption(10))
                        .foregroundStyle(Color.gmTextTertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(cost.amount.jpyFormatted)
                    .font(GMFont.mono(14, weight: .bold))
                    .foregroundStyle(cost.isActive ? Color.gmTextPrimary : Color.gmTextTertiary)
                Text("年 \((cost.amount * 12).jpyCompact)")
                    .font(GMFont.caption(10))
                    .foregroundStyle(Color.gmTextTertiary)
            }

            Toggle("", isOn: Binding(
                get: { cost.isActive },
                set: { _ in onToggle() }
            ))
            .tint(Color.gmGold)
            .labelsHidden()
            .scaleEffect(0.8)
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
        .onLongPressGesture { onEdit() }
    }
}

// ─────────────────────────────────────────
// MARK: Waste Analysis Card
// ─────────────────────────────────────────
struct WasteAnalysisCard: View {
    @EnvironmentObject var dm: DataManager

    private var inactiveSubscriptions: [Subscription] {
        dm.subscriptions.filter { !$0.isActive }
    }
    private var wasteSavings: Double {
        inactiveSubscriptions.reduce(0) { $0 + $1.monthlyCost }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.md) {
            HStack {
                Image(systemName: "scissors.circle.fill")
                    .foregroundStyle(Color.gmGold)
                    .font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text("無駄遣い可視化")
                        .font(GMFont.heading(15, weight: .semibold))
                        .foregroundStyle(Color.gmTextPrimary)
                    Text("オフにしたサービスで削減できる月額")
                        .font(GMFont.caption(11))
                        .foregroundStyle(Color.gmTextTertiary)
                }
            }

            if inactiveSubscriptions.isEmpty {
                Text("現在オフのサービスはありません\nサブスクのトグルをオフにして削減効果を確認しましょう")
                    .font(GMFont.body(13))
                    .foregroundStyle(Color.gmTextTertiary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: GMSpacing.xs) {
                        Text("削減可能額（月）")
                            .font(GMFont.caption(11))
                            .foregroundStyle(Color.gmTextTertiary)
                        Text(wasteSavings.jpyFormatted)
                            .font(GMFont.display(24, weight: .bold))
                            .foregroundStyle(Color.gmPositive)
                        Text("年間 \((wasteSavings * 12).jpyCompact) の節約")
                            .font(GMFont.caption(12))
                            .foregroundStyle(Color.gmPositive.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.gmPositive.opacity(0.3))
                }

                ForEach(inactiveSubscriptions.prefix(3)) { sub in
                    HStack {
                        Image(systemName: sub.iconName)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: sub.accentColorHex).opacity(0.5))
                        Text(sub.name)
                            .font(GMFont.body(13))
                            .foregroundStyle(Color.gmTextTertiary)
                            .strikethrough(true)
                        Spacer()
                        Text("-\(sub.monthlyCost.jpyFormatted)")
                            .font(GMFont.mono(12, weight: .semibold))
                            .foregroundStyle(Color.gmPositive)
                    }
                }
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Subscription Form Sheet
// ─────────────────────────────────────────
struct SubscriptionFormSheet: View {
    let sub: Subscription?
    let onSave: (Subscription) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var billingDayText: String = "1"
    @State private var cycle: Subscription.BillingCycle = .monthly
    @State private var hasEndDate = false
    @State private var endDate: Date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gmBackground.ignoresSafeArea()
                Form {
                    Section {
                        GMFormField(label: "サービス名", placeholder: "サービス名", text: $name)
                        GMFormField(label: "金額（円）", placeholder: "0", text: $amountText)
                            .keyboardType(.numberPad)
                        GMFormField(label: "引き落とし日", placeholder: "1", text: $billingDayText)
                            .keyboardType(.numberPad)
                    } header: {
                        Text("基本情報").font(GMFont.caption(12)).foregroundStyle(Color.gmGold)
                    }
                    Section {
                        Picker("支払いサイクル", selection: $cycle) {
                            ForEach(Subscription.BillingCycle.allCases, id: \.self) { c in
                                Text(c.rawValue).tag(c)
                            }
                        }
                        .foregroundStyle(Color.gmTextPrimary)
                        Toggle("契約終了日あり", isOn: $hasEndDate)
                            .tint(Color.gmGold)
                            .foregroundStyle(Color.gmTextPrimary)
                        if hasEndDate {
                            DatePicker("終了日", selection: $endDate, displayedComponents: .date)
                                .foregroundStyle(Color.gmTextPrimary)
                                .tint(Color.gmGold)
                        }
                    } header: {
                        Text("契約情報").font(GMFont.caption(12)).foregroundStyle(Color.gmGold)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.gmBackground)
            }
            .navigationTitle(sub == nil ? "サブスクを追加" : "サブスクを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(Color.gmTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .foregroundStyle(Color.gmGold).fontWeight(.bold)
                        .disabled(name.isEmpty)
                }
            }
            .preferredColorScheme(.dark)
        }
        .onAppear { if let s = sub { populate(s) } }
    }

    private func populate(_ s: Subscription) {
        name           = s.name
        amountText     = "\(Int(s.amount))"
        billingDayText = "\(s.billingDay)"
        cycle          = s.billingCycle
        if let end = s.contractEndDate { hasEndDate = true; endDate = end }
    }

    private func save() {
        let updated = Subscription(
            id: sub?.id ?? UUID(),
            name: name,
            amount: Double(amountText) ?? 0,
            billingDay: Int(billingDayText) ?? 1,
            billingCycle: cycle,
            contractEndDate: hasEndDate ? endDate : nil
        )
        onSave(updated)
        dismiss()
    }
}

// ─────────────────────────────────────────
// MARK: Fixed Cost Form Sheet
// ─────────────────────────────────────────
struct FixedCostFormSheet: View {
    let cost: FixedCost?
    let onSave: (FixedCost) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var billingDayText: String = "27"
    @State private var category: FixedCostCategory = .other
    @State private var memo: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gmBackground.ignoresSafeArea()
                Form {
                    Section {
                        GMFormField(label: "費用名", placeholder: "家賃", text: $name)
                        GMFormField(label: "金額（円）", placeholder: "148000", text: $amountText)
                            .keyboardType(.numberPad)
                        GMFormField(label: "引き落とし日", placeholder: "27", text: $billingDayText)
                            .keyboardType(.numberPad)
                    } header: {
                        Text("基本情報").font(GMFont.caption(12)).foregroundStyle(Color.gmGold)
                    }
                    Section {
                        Picker("カテゴリ", selection: $category) {
                            ForEach(FixedCostCategory.allCases, id: \.self) { c in
                                HStack {
                                    Image(systemName: c.icon)
                                    Text(c.rawValue)
                                }.tag(c)
                            }
                        }
                        .foregroundStyle(Color.gmTextPrimary)
                        GMFormField(label: "メモ", placeholder: "任意のメモ", text: $memo)
                    } header: {
                        Text("詳細").font(GMFont.caption(12)).foregroundStyle(Color.gmGold)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.gmBackground)
            }
            .navigationTitle(cost == nil ? "固定費を追加" : "固定費を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(Color.gmTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .foregroundStyle(Color.gmGold).fontWeight(.bold)
                        .disabled(name.isEmpty)
                }
            }
            .preferredColorScheme(.dark)
        }
        .onAppear { if let c = cost { populate(c) } }
    }

    private func populate(_ c: FixedCost) {
        name           = c.name
        amountText     = "\(Int(c.amount))"
        billingDayText = "\(c.billingDay)"
        category       = c.category
        memo           = c.memo
    }

    private func save() {
        let updated = FixedCost(
            id: cost?.id ?? UUID(),
            name: name,
            amount: Double(amountText) ?? 0,
            billingDay: Int(billingDayText) ?? 27,
            category: category,
            memo: memo
        )
        onSave(updated)
        dismiss()
    }
}

// ─────────────────────────────────────────
// MARK: Shared Form Field Component
// ─────────────────────────────────────────
struct GMFormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(Color.gmTextPrimary)
            Spacer()
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Color.gmGold)
                .font(GMFont.mono(15, weight: .semibold))
        }
    }
}

// ─────────────────────────────────────────
// MARK: Preview
// ─────────────────────────────────────────
#Preview {
    FixedCostManagerView()
        .environmentObject(DataManager())
}
