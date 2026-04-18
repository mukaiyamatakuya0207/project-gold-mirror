// MARK: - CalendarView.swift
// Gold Mirror – Credit card billing calendar.

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var vm: AssetViewModel
    @State private var displayedMonth: Date = Date()
    @State private var selectedDay: Int? = nil

    private var calendar: Calendar {
        .gmJapan
    }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    // ─────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────
    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ja_JP")
        fmt.dateFormat = "yyyy年M月"
        return fmt.string(from: displayedMonth)
    }

    private var monthStart: Date {
        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        return calendar.date(from: comps).map { calendar.startOfDay(for: $0) } ?? calendar.startOfDay(for: displayedMonth)
    }

    private var monthDays: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }

    /// 月の最初の日が何曜日か (0=日, 1=月, …)
    private var firstWeekdayOffset: Int {
        calendar.component(.weekday, from: monthStart) - 1
    }

    private var billingEvents: [Int: [CreditCard]] {
        vm.billingEventsForMonth(displayedMonth)
    }

    private var today: Int {
        let comps = calendar.dateComponents([.year, .month, .day], from: Date())
        let dispComps = calendar.dateComponents([.year, .month], from: monthStart)
        if comps.year == dispComps.year && comps.month == dispComps.month {
            return comps.day ?? -1
        }
        return -1
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.25)) {
                displayedMonth = newDate
                selectedDay = nil
            }
        }
    }

    // ─────────────────────────────────────
    // Body
    // ─────────────────────────────────────
    var body: some View {
        ZStack {
            Color.gmBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: GMSpacing.lg) {

                    // Page title
                    CalendarPageHeader()

                    // Monthly billing total
                    MonthlyBillingSummaryCard(displayedMonth: displayedMonth)

                    // Calendar grid
                    VStack(spacing: GMSpacing.md) {
                        // Month navigator
                        HStack {
                            Button { changeMonth(by: -1) } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.gmGold)
                                    .frame(width: 36, height: 36)
                                    .background(Color.gmSurface)
                                    .clipShape(Circle())
                            }

                            Spacer()

                            Text(monthTitle)
                                .font(GMFont.heading(18, weight: .bold))
                                .foregroundStyle(Color.gmTextPrimary)

                            Spacer()

                            Button { changeMonth(by: 1) } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.gmGold)
                                    .frame(width: 36, height: 36)
                                    .background(Color.gmSurface)
                                    .clipShape(Circle())
                            }
                        }

                        // Weekday header
                        HStack(spacing: 4) {
                            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { idx, sym in
                                Text(sym)
                                    .font(GMFont.caption(11, weight: .semibold))
                                    .foregroundStyle(idx == 0 ? Color.gmNegative.opacity(0.8) :
                                                     idx == 6 ? Color.gmGold.opacity(0.8) :
                                                     Color.gmTextTertiary)
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        // Day grid
                        LazyVGrid(columns: columns, spacing: 6) {
                            // Empty cells before month start
                            ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                                Color.clear.frame(height: 52)
                            }

                            // Day cells
                            ForEach(monthDays, id: \.self) { date in
                                let day = calendar.component(.day, from: date)
                                CalendarDayCell(
                                    day: day,
                                    isToday: day == today,
                                    isSelected: selectedDay == day,
                                    cards: billingEvents[day] ?? [],
                                    weekdayIndex: (firstWeekdayOffset + day - 1) % 7
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedDay = selectedDay == day ? nil : day
                                    }
                                }
                            }
                        }
                    }
                    .padding(GMSpacing.md)
                    .gmCardStyle()
                    .padding(.horizontal, GMSpacing.md)

                    // Selected day detail
                    if let day = selectedDay {
                        SelectedDayDetailView(day: day, cards: billingEvents[day] ?? [])
                            .padding(.horizontal, GMSpacing.md)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Upcoming billing list
                    UpcomingBillingList()
                        .padding(.horizontal, GMSpacing.md)

                    Spacer().frame(height: 100)
                }
                .padding(.top, GMSpacing.md)
            }
        }
    }
}

// ─────────────────────────────────────────
// MARK: Calendar Page Header
// ─────────────────────────────────────────
struct CalendarPageHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("CALENDAR")
                    .font(GMFont.caption(11, weight: .bold))
                    .foregroundStyle(Color.gmGold.opacity(0.7))
                    .tracking(3)
                Text("引き落としカレンダー")
                    .font(GMFont.heading(22, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, GMSpacing.md)
    }
}

// ─────────────────────────────────────────
// MARK: Monthly Billing Summary
// ─────────────────────────────────────────
struct MonthlyBillingSummaryCard: View {
    @EnvironmentObject var vm: AssetViewModel
    let displayedMonth: Date

    private var monthStr: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ja_JP")
        fmt.dateFormat = "M月"
        return fmt.string(from: displayedMonth)
    }

    var body: some View {
        HStack(spacing: GMSpacing.lg) {
            VStack(alignment: .leading, spacing: GMSpacing.xs) {
                Text("\(monthStr)の引き落とし予定合計")
                    .font(GMFont.caption(11, weight: .medium))
                    .foregroundStyle(Color.gmTextTertiary)
                    .tracking(1)

                Text(vm.totalMonthlyBilling.jpyFormatted)
                    .font(GMFont.display(28, weight: .bold))
                    .foregroundStyle(GMGradient.goldHorizontal)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: GMSpacing.xs) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.gmGold.opacity(0.3))
                Text("\(vm.creditCards.count)枚")
                    .font(GMFont.caption(12, weight: .semibold))
                    .foregroundStyle(Color.gmTextSecondary)
            }
        }
        .padding(GMSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1A0F00"), Color.gmSurface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GMRadius.lg)
                        .strokeBorder(Color.gmGold.opacity(0.25), lineWidth: 0.8)
                )
        )
        .padding(.horizontal, GMSpacing.md)
    }
}

// ─────────────────────────────────────────
// MARK: Calendar Day Cell
// ─────────────────────────────────────────
struct CalendarDayCell: View {
    let day: Int
    let isToday: Bool
    let isSelected: Bool
    let cards: [CreditCard]
    let weekdayIndex: Int
    let onTap: () -> Void

    private var hasBilling: Bool { !cards.isEmpty }
    private var dayColor: Color {
        if isSelected || isToday { return .gmTextPrimary }
        if weekdayIndex == 0 { return Color.gmNegative.opacity(0.8) }
        if weekdayIndex == 6 { return Color.gmGold.opacity(0.8) }
        return .gmTextSecondary
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                ZStack {
                    // Today ring
                    if isToday {
                        Circle()
                            .stroke(Color.gmGold, lineWidth: 1.5)
                            .frame(width: 32, height: 32)
                    }
                    // Selected fill
                    if isSelected {
                        Circle()
                            .fill(Color.gmGold)
                            .frame(width: 32, height: 32)
                    }

                    Text("\(day)")
                        .font(GMFont.body(13, weight: isToday || isSelected ? .bold : .regular))
                        .foregroundStyle(dayColor)
                }
                .frame(width: 32, height: 32)

                // Billing indicator dots
                if hasBilling {
                    HStack(spacing: 2) {
                        ForEach(0..<min(cards.count, 3), id: \.self) { _ in
                            Circle()
                                .fill(Color.gmGold)
                                .frame(width: 4, height: 4)
                        }
                    }
                } else {
                    Color.clear.frame(height: 4)
                }
            }
            .frame(height: 52)
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────
// MARK: Selected Day Detail
// ─────────────────────────────────────────
struct SelectedDayDetailView: View {
    let day: Int
    let cards: [CreditCard]

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Image(systemName: "calendar.badge.exclamationmark")
                    .foregroundStyle(Color.gmGold)
                Text("\(day)日の引き落とし")
                    .font(GMFont.heading(15, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
                Spacer()
                Text(cards.reduce(0) { $0 + $1.nextBillingAmount }.jpyFormatted)
                    .font(GMFont.mono(15, weight: .bold))
                    .foregroundStyle(Color.gmGold)
            }

            if cards.isEmpty {
                Text("引き落とし予定はありません")
                    .font(GMFont.body(14))
                    .foregroundStyle(Color.gmTextTertiary)
                    .padding(.top, GMSpacing.xs)
            } else {
                ForEach(cards) { card in
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: card.accentColorHex))
                        Text(card.cardName)
                            .font(GMFont.body(13))
                            .foregroundStyle(Color.gmTextSecondary)
                        Spacer()
                        Text(card.nextBillingAmount.jpyFormatted)
                            .font(GMFont.mono(13, weight: .semibold))
                            .foregroundStyle(Color.gmTextPrimary)
                    }
                }
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle(elevated: true)
    }
}

// ─────────────────────────────────────────
// MARK: Upcoming Billing List
// ─────────────────────────────────────────
struct UpcomingBillingList: View {
    @EnvironmentObject var vm: AssetViewModel

    private var sortedCards: [CreditCard] {
        vm.creditCards.sorted { $0.billingDay < $1.billingDay }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundStyle(Color.gmGold)
                Text("引き落とし一覧")
                    .font(GMFont.heading(15, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
            }

            ForEach(sortedCards) { card in
                HStack(spacing: GMSpacing.sm) {
                    // Day badge
                    ZStack {
                        RoundedRectangle(cornerRadius: GMRadius.sm)
                            .fill(Color.gmGold.opacity(0.12))
                        Text("\(card.billingDay)")
                            .font(GMFont.mono(16, weight: .bold))
                            .foregroundStyle(Color.gmGold)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.cardName)
                            .font(GMFont.body(13, weight: .medium))
                            .foregroundStyle(Color.gmTextPrimary)
                        Text("毎月\(card.billingDay)日")
                            .font(GMFont.caption(11))
                            .foregroundStyle(Color.gmTextTertiary)
                    }

                    Spacer()

                    Text(card.nextBillingAmount.jpyFormatted)
                        .font(GMFont.mono(14, weight: .bold))
                        .foregroundStyle(Color.gmTextPrimary)
                }
                .padding(GMSpacing.sm)
                .gmCardStyle()
            }
        }
    }
}

// ─────────────────────────────────────────
// MARK: Preview
// ─────────────────────────────────────────
#Preview {
    CalendarView()
        .environmentObject(AssetViewModel())
}
