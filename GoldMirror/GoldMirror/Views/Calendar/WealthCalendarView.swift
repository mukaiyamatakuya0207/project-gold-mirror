// MARK: - WealthCalendarView.swift
// Gold Mirror – Upgraded Wealth Calendar with daily asset snapshots.

import SwiftUI

struct WealthCalendarView: View {
    @EnvironmentObject var dm: DataManager
    @State private var displayedMonth: Date = Date()
    @State private var selectedDay: Int?    = nil
    @State private var showDayDetail: Bool  = false

    private let calendar   = Calendar.current
    private let weekLabels = ["日","月","火","水","木","金","土"]
    private let columns    = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    // ─── helpers ───
    private var monthTitle: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年 M月"; return f.string(from: displayedMonth)
    }
    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
    }
    private var firstWeekday: Int {
        var c = calendar.dateComponents([.year,.month], from: displayedMonth)
        c.day = 1
        return (calendar.date(from: c).map { calendar.component(.weekday, from: $0) } ?? 1) - 1
    }
    private var todayDay: Int {
        let tc = calendar.dateComponents([.year,.month,.day], from: Date())
        let dc = calendar.dateComponents([.year,.month], from: displayedMonth)
        return (tc.year == dc.year && tc.month == dc.month) ? (tc.day ?? -1) : -1
    }
    private func snapshot(for day: Int) -> DayFinancialSnapshot {
        dm.daySnapshot(day: day, month: displayedMonth)
    }
    private func changeMonth(_ v: Int) {
        if let d = calendar.date(byAdding: .month, value: v, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.25)) { displayedMonth = d; selectedDay = nil }
        }
    }

    var body: some View {
        ZStack {
            Color.gmBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: GMSpacing.lg) {
                    CalendarPageHeaderV2()
                    MonthlyOutflowBanner()
                        .padding(.horizontal, GMSpacing.md)
                    calendarCard
                    if let day = selectedDay {
                        DayDetailPopup(snapshot: snapshot(for: day))
                            .padding(.horizontal, GMSpacing.md)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .id(day)
                    }
                    MonthCashflowSummary(month: displayedMonth)
                        .padding(.horizontal, GMSpacing.md)
                    // Bottom clearance for tab bar + FAB
                    Spacer().frame(height: 50)  // FAB overhang clearance only; safeAreaInset handles tab bar
                }
                .padding(.top, GMSpacing.md)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // ─── Calendar Card ───
    private var calendarCard: some View {
        VStack(spacing: GMSpacing.md) {
            // Navigator
            HStack {
                Button { changeMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.gmGold)
                        .frame(width: 36, height: 36)
                        .background(Color.gmSurface).clipShape(Circle())
                }
                Spacer()
                Text(monthTitle)
                    .font(GMFont.heading(18, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
                Spacer()
                Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.gmGold)
                        .frame(width: 36, height: 36)
                        .background(Color.gmSurface).clipShape(Circle())
                }
            }

            // Weekday header
            HStack(spacing: 4) {
                ForEach(Array(weekLabels.enumerated()), id: \.offset) { i, sym in
                    Text(sym)
                        .font(GMFont.caption(11, weight: .semibold))
                        .foregroundStyle(i==0 ? Color.gmNegative.opacity(0.8)
                                       : i==6 ? Color.gmGold.opacity(0.8)
                                       : Color.gmTextTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(0..<firstWeekday, id: \.self) { _ in Color.clear.frame(height: 54) }
                ForEach(1...daysInMonth, id: \.self) { day in
                    WealthCalendarDayCell(
                        day: day,
                        isToday: day == todayDay,
                        isSelected: selectedDay == day,
                        snapshot: snapshot(for: day),
                        weekdayIndex: (firstWeekday + day - 1) % 7
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDay = selectedDay == day ? nil : day
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: GMSpacing.md) {
                CalLegendItem(color: .gmNegative,  label: "大きな支出")
                CalLegendItem(color: .gmGold,      label: "カード引き落とし")
                CalLegendItem(color: Color(hex: "#CE93D8"), label: "サブスク")
            }
            .padding(.top, GMSpacing.xs)
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
        .padding(.horizontal, GMSpacing.md)
    }
}

private struct CalLegendItem: View {
    let color: Color; let label: String
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(GMFont.caption(10)).foregroundStyle(Color.gmTextTertiary)
        }
    }
}

// ─────────────────────────────────────────
// MARK: Calendar Page Header V2
// ─────────────────────────────────────────
struct CalendarPageHeaderV2: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("WEALTH CALENDAR")
                    .font(GMFont.caption(11, weight: .bold))
                    .foregroundStyle(Color.gmGold.opacity(0.7)).tracking(3)
                Text("資産カレンダー")
                    .font(GMFont.heading(22, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
            }
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 22)).foregroundStyle(Color.gmGold)
        }
        .padding(.horizontal, GMSpacing.md)
    }
}

// ─────────────────────────────────────────
// MARK: Monthly Outflow Banner
// ─────────────────────────────────────────
struct MonthlyOutflowBanner: View {
    @EnvironmentObject var dm: DataManager
    var body: some View {
        HStack(spacing: GMSpacing.md) {
            VStack(alignment: .leading, spacing: GMSpacing.xs) {
                Text("今月の予定支出合計")
                    .font(GMFont.caption(11)).foregroundStyle(Color.gmTextTertiary)
                Text(dm.totalMonthlyOutflow.jpyFormatted)
                    .font(GMFont.display(26, weight: .bold))
                    .foregroundStyle(GMGradient.goldHorizontal)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: GMSpacing.xs) {
                HStack(spacing: 4) {
                    Circle().fill(Color.gmGold).frame(width: 7, height: 7)
                    Text("カード \(dm.totalMonthlyCardBilling.jpyCompact)")
                        .font(GMFont.caption(10)).foregroundStyle(Color.gmTextTertiary)
                }
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: "#4FC3F7")).frame(width: 7, height: 7)
                    Text("固定費 \(dm.totalMonthlyFixedCosts.jpyCompact)")
                        .font(GMFont.caption(10)).foregroundStyle(Color.gmTextTertiary)
                }
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: "#CE93D8")).frame(width: 7, height: 7)
                    Text("サブスク \(dm.totalMonthlySubscriptions.jpyCompact)")
                        .font(GMFont.caption(10)).foregroundStyle(Color.gmTextTertiary)
                }
            }
        }
        .padding(GMSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .fill(LinearGradient(colors:[Color(hex:"#1A0F00"),Color(hex:"#0F0F0F")],
                                     startPoint:.topLeading, endPoint:.bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: GMRadius.lg)
                    .strokeBorder(Color.gmGold.opacity(0.25), lineWidth: 0.8))
        )
    }
}

// ─────────────────────────────────────────
// MARK: Wealth Calendar Day Cell
// ─────────────────────────────────────────
struct WealthCalendarDayCell: View {
    let day: Int
    let isToday: Bool
    let isSelected: Bool
    let snapshot: DayFinancialSnapshot
    let weekdayIndex: Int
    let onTap: () -> Void

    private var dotColor: Color {
        let total = snapshot.totalExpenses
        if total > 100_000  { return .gmNegative }
        if total > 0        { return .gmGold }
        return .clear
    }

    private var subDotColor: Color? {
        let hasSub = snapshot.scheduledExpenses.contains { $0.category == .subscription }
        return hasSub ? Color(hex: "#CE93D8") : nil
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack {
                    if isSelected {
                        Circle().fill(Color.gmGold).frame(width: 32, height: 32)
                    } else if isToday {
                        Circle().stroke(Color.gmGold, lineWidth: 1.5).frame(width: 32, height: 32)
                    }
                    Text("\(day)")
                        .font(GMFont.body(13, weight: isToday || isSelected ? .bold : .regular))
                        .foregroundStyle(
                            isSelected ? Color.black
                            : weekdayIndex == 0 ? Color.gmNegative.opacity(0.8)
                            : weekdayIndex == 6 ? Color.gmGold.opacity(0.8)
                            : Color.gmTextSecondary
                        )
                }
                .frame(width: 32, height: 32)

                // Dot row
                HStack(spacing: 2) {
                    if snapshot.hasExpenses {
                        Circle().fill(dotColor).frame(width: 4, height: 4)
                    }
                    if let sc = subDotColor {
                        Circle().fill(sc).frame(width: 4, height: 4)
                    }
                    if !snapshot.hasExpenses { Color.clear.frame(width: 4, height: 4) }
                }
                .frame(height: 5)
            }
            .frame(height: 54)
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────
// MARK: Day Detail Popup
// ─────────────────────────────────────────
struct DayDetailPopup: View {
    let snapshot: DayFinancialSnapshot

    private var dateStr: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日 (E)"; return f.string(from: snapshot.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.md) {

            // ─── Header ───
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(dateStr)
                        .font(GMFont.heading(16, weight: .bold))
                        .foregroundStyle(Color.gmTextPrimary)
                    Text(snapshot.hasExpenses ? "支出予定あり" : "支出予定なし")
                        .font(GMFont.caption(11))
                        .foregroundStyle(snapshot.hasExpenses ? Color.gmNegative : Color.gmPositive)
                }
                Spacer()
                // Total expenses badge
                if snapshot.hasExpenses {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("支出合計")
                            .font(GMFont.caption(10))
                            .foregroundStyle(Color.gmTextTertiary)
                        Text(snapshot.totalExpenses.jpyFormatted)
                            .font(GMFont.mono(16, weight: .bold))
                            .foregroundStyle(Color.gmNegative)
                    }
                }
            }

            // ─── Expense List ───
            if snapshot.hasExpenses {
                VStack(spacing: GMSpacing.xs) {
                    ForEach(snapshot.scheduledExpenses) { expense in
                        HStack(spacing: GMSpacing.sm) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(expense.color.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: expense.icon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(expense.color)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(expense.name)
                                    .font(GMFont.body(13, weight: .medium))
                                    .foregroundStyle(Color.gmTextPrimary)
                                Text(expense.category.rawValue)
                                    .font(GMFont.caption(10))
                                    .foregroundStyle(Color.gmTextTertiary)
                            }
                            Spacer()
                            Text(expense.amount.jpyFormatted)
                                .font(GMFont.mono(14, weight: .bold))
                                .foregroundStyle(Color.gmTextPrimary)
                        }
                    }
                }
                Divider().background(Color.gmGoldDim.opacity(0.4))
            }

            // ─── Projected Net Assets ───
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("この日の予想純資産")
                        .font(GMFont.caption(11, weight: .medium))
                        .foregroundStyle(Color.gmTextTertiary)
                    Text(snapshot.projectedNetAssets.jpyFormatted)
                        .font(GMFont.display(22, weight: .bold))
                        .foregroundStyle(GMGradient.goldHorizontal)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("予想現金")
                        .font(GMFont.caption(10))
                        .foregroundStyle(Color.gmTextTertiary)
                    Text(snapshot.projectedCash.jpyFormatted)
                        .font(GMFont.mono(14, weight: .bold))
                        .foregroundStyle(Color.gmTextSecondary)
                }
            }
            .padding(GMSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: GMRadius.md)
                    .fill(Color.gmGold.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: GMRadius.md)
                            .stroke(Color.gmGold.opacity(0.2), lineWidth: 0.5)
                    )
            )
        }
        .padding(GMSpacing.md)
        .gmCardStyle(elevated: true)
        .gmGoldGlow(radius: 12, opacity: 0.15)
    }
}

// ─────────────────────────────────────────
// MARK: Month Cashflow Summary
// ─────────────────────────────────────────
struct MonthCashflowSummary: View {
    @EnvironmentObject var dm: DataManager
    let month: Date

    private var events: [(day: Int, total: Double)] {
        (1...31).compactMap { day -> (Int, Double)? in
            let snap = dm.daySnapshot(day: day, month: month)
            guard snap.hasExpenses else { return nil }
            return (day, snap.totalExpenses)
        }
        .sorted { $0.day < $1.day }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Image(systemName: "list.bullet.rectangle.fill")
                    .foregroundStyle(Color.gmGold)
                Text("今月の支払いスケジュール")
                    .font(GMFont.heading(15, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
            }
            ForEach(events, id: \.day) { event in
                HStack {
                    // Day circle
                    ZStack {
                        Circle().fill(Color.gmGold.opacity(0.12)).frame(width: 36, height: 36)
                        Text("\(event.day)")
                            .font(GMFont.mono(14, weight: .bold))
                            .foregroundStyle(Color.gmGold)
                    }
                    Text("日")
                        .font(GMFont.caption(11)).foregroundStyle(Color.gmTextTertiary)
                    let snap = dm.daySnapshot(day: event.day, month: month)
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(snap.scheduledExpenses.prefix(2)) { exp in
                            Text(exp.name).font(GMFont.caption(11))
                                .foregroundStyle(Color.gmTextSecondary).lineLimit(1)
                        }
                        if snap.scheduledExpenses.count > 2 {
                            Text("他\(snap.scheduledExpenses.count - 2)件")
                                .font(GMFont.caption(10)).foregroundStyle(Color.gmTextTertiary)
                        }
                    }
                    Spacer()
                    Text(event.total.jpyFormatted)
                        .font(GMFont.mono(13, weight: .bold)).foregroundStyle(Color.gmTextPrimary)
                }
                .padding(.vertical, GMSpacing.xs)
                if event.day != events.last?.day {
                    Divider().background(Color.gmGoldDim.opacity(0.3))
                }
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: DataManager extension – daySnapshot
// ─────────────────────────────────────────
extension DataManager {
    /// 指定した日付の財務スナップショットを生成
    func daySnapshot(day: Int, month: Date) -> DayFinancialSnapshot {
        var expenses: [ScheduledExpense] = []
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: month)
        comps.day = day
        let date = cal.date(from: comps) ?? month

        // カード
        for card in creditCards where card.billingDay == day {
            expenses.append(ScheduledExpense(
                name: card.cardName,
                amount: card.nextBillingAmount,
                category: .creditCard,
                icon: "creditcard.fill",
                color: Color(hex: card.accentColorHex)
            ))
        }
        // 固定費
        for cost in fixedCosts where cost.isActive && cost.billingDay == day {
            expenses.append(ScheduledExpense(
                name: cost.name,
                amount: cost.amount,
                category: .fixedCost,
                icon: cost.category.icon,
                color: cost.category.color
            ))
        }
        // サブスク
        for sub in subscriptions where sub.isActive && sub.billingDay == day && sub.billingCycle == .monthly {
            expenses.append(ScheduledExpense(
                name: sub.name,
                amount: sub.monthlyCost,
                category: .subscription,
                icon: sub.iconName,
                color: Color(hex: sub.accentColorHex)
            ))
        }

        // その日までに発生する累積支出を計算
        let cumulativeExpenses = (1...max(day,1)).reduce(0.0) { sum, d in
            let dCards = creditCards.filter { $0.billingDay == d }.reduce(0) { $0 + $1.nextBillingAmount }
            let dFixed = fixedCosts.filter { $0.isActive && $0.billingDay == d }.reduce(0) { $0 + $1.amount }
            let dSub   = subscriptions.filter { $0.isActive && $0.billingDay == d && $0.billingCycle == .monthly }.reduce(0) { $0 + $1.monthlyCost }
            return sum + dCards + dFixed + dSub
        }

        let projectedCash   = max(totalBankBalance - cumulativeExpenses, 0)
        let projectedAssets = max(projectedCash + totalSecuritiesValue, 0)

        return DayFinancialSnapshot(
            date: date,
            dayOfMonth: day,
            scheduledExpenses: expenses,
            projectedNetAssets: projectedAssets,
            projectedCash: projectedCash
        )
    }
}

#Preview {
    WealthCalendarView()
        .environmentObject(DataManager())
}
