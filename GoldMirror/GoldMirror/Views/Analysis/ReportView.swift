// MARK: - ReportView.swift
// Gold Mirror – Category-based income/expense analytics.

import SwiftUI
import Charts

enum ReportViewMode: Equatable {
    case full
    case monthly
    case income
}

struct ReportView: View {
    @EnvironmentObject var dm: DataManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var includeReimbursableExpenses = false
    let mode: ReportViewMode

    init(mode: ReportViewMode = .full) {
        self.mode = mode
    }

    private var categoryItems: [DataManager.ExpenseCategoryReportItem] {
        dm.expenseCategoryReport(includeReimbursable: includeReimbursableExpenses)
    }

    private var fixedVariable: DataManager.FixedVariableReport {
        dm.fixedVariableExpenseReport(includeReimbursable: includeReimbursableExpenses)
    }

    private var expenseTrendItems: [DataManager.MonthlyExpenseTrendItem] {
        dm.monthlyExpenseTrendReport(months: 6, includeReimbursable: includeReimbursableExpenses)
    }

    private var incomeBreakdownItems: [DataManager.IncomeBreakdownReportItem] {
        dm.incomeBreakdownReport()
    }

    private var monthlyIncomeItems: [DataManager.MonthlyIncomeReportItem] {
        dm.monthlyIncomeReport(months: 6)
    }

    private var incomeProjection: DataManager.AnnualIncomeProjectionReport {
        dm.annualIncomeProjectionReport(months: 6)
    }

    private var columns: [GridItem] {
        horizontalSizeClass == .regular
            ? [GridItem(.flexible(), spacing: GMSpacing.md), GridItem(.flexible(), spacing: GMSpacing.md)]
            : [GridItem(.flexible(), spacing: GMSpacing.md)]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: GMSpacing.lg) {
                ReportHeader(mode: mode)
                    .padding(.horizontal, GMSpacing.md)
                    .padding(.top, GMSpacing.md)

                if mode != .income {
                    ReportExpenseToggle(includeReimbursableExpenses: $includeReimbursableExpenses)
                        .padding(.horizontal, GMSpacing.md)
                }

                LazyVGrid(columns: columns, alignment: .center, spacing: GMSpacing.md) {
                    if mode != .income {
                        ReportDonutCard(items: categoryItems)
                        ReportFixedVariableCard(report: fixedVariable)
                        ReportExpenseTrendCard(items: expenseTrendItems)
                        ReportCategoryComparisonCard(items: categoryItems)
                    }

                    if mode != .monthly {
                        ReportIncomeAnalysisCard(
                            breakdownItems: incomeBreakdownItems,
                            monthlyItems: monthlyIncomeItems,
                            projection: incomeProjection
                        )
                    }
                }
                .padding(.horizontal, GMSpacing.md)

                Spacer().frame(height: 96)
            }
            .frame(maxWidth: horizontalSizeClass == .regular ? 1120 : .infinity)
            .frame(maxWidth: .infinity)
        }
        .background(Color.gmBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ReportHeader: View {
    let mode: ReportViewMode

    private var title: String {
        switch mode {
        case .full, .monthly: return "カテゴリ別収支分析"
        case .income: return "収入分析"
        }
    }

    private var icon: String {
        switch mode {
        case .full, .monthly: return "chart.pie.fill"
        case .income: return "yensign.circle.fill"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("REPORT")
                    .font(GMFont.caption(11, weight: .bold))
                    .foregroundStyle(Color.gmGold.opacity(0.7))
                    .tracking(3)
                Text(title)
                    .font(GMFont.heading(22, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
            }
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.gmGold)
        }
    }
}

private struct ReportExpenseToggle: View {
    @Binding var includeReimbursableExpenses: Bool

    var body: some View {
        Toggle(isOn: $includeReimbursableExpenses) {
            VStack(alignment: .leading, spacing: 2) {
                Text("経費（立替金）を分析に含める")
                    .font(GMFont.body(14, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
                Text("精算予定の大きな支出を生活費分析から分離")
                    .font(GMFont.caption(11))
                    .foregroundStyle(Color.gmTextTertiary)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color.gmGold))
        .padding(GMSpacing.md)
        .background(Color.gmSurface)
        .clipShape(RoundedRectangle(cornerRadius: GMRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: GMRadius.md)
                .strokeBorder(Color.gmGoldDim.opacity(0.25), lineWidth: 0.7)
        )
    }
}

private struct ReportDonutCard: View {
    let items: [DataManager.ExpenseCategoryReportItem]

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.md) {
            ReportCardTitle(icon: "chart.pie.fill", title: "支出カテゴリ円グラフ", subtitle: "今月の生活費構成")

            if items.isEmpty {
                ReportEmptyState(text: "支出データがありません")
            } else {
                Chart(items.prefix(8)) { item in
                    SectorMark(
                        angle: .value("支出", item.amount),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .foregroundStyle(itemColor(item))
                }
                .chartBackground { proxy in
                    GeometryReader { geo in
                        if let frame = proxy.plotFrame {
                            let rect = geo[frame]
                            VStack(spacing: 2) {
                                Text(totalExpense.jpyCompact)
                                    .font(GMFont.mono(18, weight: .bold))
                                    .foregroundStyle(Color.gmGold)
                                Text("支出合計")
                                    .font(GMFont.caption(10))
                                    .foregroundStyle(Color.gmTextTertiary)
                            }
                            .position(x: rect.midX, y: rect.midY)
                        }
                    }
                }
                .frame(height: 230)

                VStack(spacing: GMSpacing.xs) {
                    ForEach(items.prefix(5)) { item in
                        ReportLegendRow(item: item)
                    }
                }
            }
        }
        .reportCardStyle()
    }

    private var totalExpense: Double {
        items.reduce(0) { $0 + $1.amount }
    }

    private func itemColor(_ item: DataManager.ExpenseCategoryReportItem) -> Color {
        Color(hex: item.colorHex)
    }
}

private struct ReportIncomeAnalysisCard: View {
    let breakdownItems: [DataManager.IncomeBreakdownReportItem]
    let monthlyItems: [DataManager.MonthlyIncomeReportItem]
    let projection: DataManager.AnnualIncomeProjectionReport

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.md) {
            ReportCardTitle(icon: "yensign.circle.fill", title: "収入分析", subtitle: "内訳・推移・年収予測")

            if breakdownItems.isEmpty && monthlyItems.allSatisfy({ $0.total <= 0 }) && projection.projectedAnnualIncome <= 0 {
                ReportEmptyState(text: "収入データまたはプロフィール給与情報がありません")
            } else {
                HStack(alignment: .center, spacing: GMSpacing.md) {
                    IncomeBreakdownDonut(items: breakdownItems)
                    IncomeProjectionSummary(projection: projection)
                }

                IncomeMonthlyBarChart(items: monthlyItems)

                VStack(spacing: GMSpacing.xs) {
                    ForEach(breakdownItems.prefix(5)) { item in
                        IncomeLegendRow(item: item)
                    }
                }
            }
        }
        .reportCardStyle(minHeight: 430)
    }
}

private struct ReportExpenseTrendCard: View {
    let items: [DataManager.MonthlyExpenseTrendItem]

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.md) {
            ReportCardTitle(icon: "chart.xyaxis.line", title: "支出推移グラフ", subtitle: "直近6ヶ月の総支出")

            if items.allSatisfy({ $0.expense <= 0 }) {
                ReportEmptyState(text: "支出推移データがありません")
            } else {
                Chart(items) { item in
                    BarMark(
                        x: .value("月", monthLabel(item.month)),
                        y: .value("支出", item.expense)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.gmGoldLight, Color.gmGoldDim],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                    LineMark(
                        x: .value("月", monthLabel(item.month)),
                        y: .value("支出", item.expense)
                    )
                    .foregroundStyle(Color.gmGold)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    PointMark(
                        x: .value("月", monthLabel(item.month)),
                        y: .value("支出", item.expense)
                    )
                    .foregroundStyle(Color.gmGoldLight)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(Color.gmGoldDim.opacity(0.18))
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(amount.jpyCompact)
                                    .font(GMFont.caption(10, weight: .bold))
                                    .foregroundStyle(Color.gmTextTertiary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(GMFont.caption(10, weight: .bold))
                                    .foregroundStyle(Color.gmTextSecondary)
                            }
                        }
                    }
                }
                .frame(height: 240)

                HStack {
                    ReportMiniMetric(label: "平均支出", value: averageExpense.jpyCompact)
                    Divider().background(Color.gmGoldDim.opacity(0.3))
                    ReportMiniMetric(label: "最大月", value: maxExpense.jpyCompact)
                }
                .padding(GMSpacing.sm)
                .background(Color.gmBackground.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: GMRadius.sm))
            }
        }
        .reportCardStyle()
    }

    private var activeItems: [DataManager.MonthlyExpenseTrendItem] {
        items.filter { $0.expense > 0 }
    }

    private var averageExpense: Double {
        guard !activeItems.isEmpty else { return 0 }
        return activeItems.reduce(0) { $0 + $1.expense } / Double(activeItems.count)
    }

    private var maxExpense: Double {
        activeItems.map(\.expense).max() ?? 0
    }
}

private struct IncomeBreakdownDonut: View {
    let items: [DataManager.IncomeBreakdownReportItem]

    private var total: Double {
        items.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        Group {
            if items.isEmpty {
                ReportEmptyState(text: "内訳なし")
                    .frame(height: 160)
            } else {
                Chart(items) { item in
                    SectorMark(
                        angle: .value("収入", item.amount),
                        innerRadius: .ratio(0.64),
                        angularInset: 1.4
                    )
                    .foregroundStyle(Color(hex: item.colorHex))
                }
                .chartBackground { proxy in
                    GeometryReader { geo in
                        if let frame = proxy.plotFrame {
                            let rect = geo[frame]
                            VStack(spacing: 2) {
                                Text(total.jpyCompact)
                                    .font(GMFont.mono(16, weight: .bold))
                                    .foregroundStyle(Color.gmGold)
                                Text("月収内訳")
                                    .font(GMFont.caption(9))
                                    .foregroundStyle(Color.gmTextTertiary)
                            }
                            .position(x: rect.midX, y: rect.midY)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 170)
            }
        }
    }
}

private struct IncomeProjectionSummary: View {
    let projection: DataManager.AnnualIncomeProjectionReport

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            Text("年収予測")
                .font(GMFont.caption(11, weight: .semibold))
                .foregroundStyle(Color.gmTextTertiary)
            Text(projection.projectedAnnualIncome.jpyCompact)
                .font(GMFont.mono(20, weight: .bold))
                .foregroundStyle(Color.gmGold)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Divider().background(Color.gmGoldDim.opacity(0.3))
            ReportMiniMetric(label: "平均月収", value: projection.averageMonthlyIncome.jpyCompact)
            ReportMiniMetric(label: "賞与反映", value: projection.bonusIncluded.jpyCompact)
            ReportMiniMetric(label: "分析月数", value: "\(projection.monthsAnalyzed)ヶ月")
        }
        .padding(GMSpacing.sm)
        .frame(width: 150, alignment: .leading)
        .background(Color.gmBackground.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: GMRadius.sm))
    }
}

private struct IncomeMonthlyBarChart: View {
    let items: [DataManager.MonthlyIncomeReportItem]

    var body: some View {
        Chart {
            ForEach(items) { item in
                BarMark(
                    x: .value("月", monthLabel(item.month)),
                    y: .value("給与", item.salary)
                )
                .foregroundStyle(Color.gmGold)
                .position(by: .value("種別", "給与"))

                BarMark(
                    x: .value("月", monthLabel(item.month)),
                    y: .value("賞与・その他", item.bonus + item.investment + item.other)
                )
                .foregroundStyle(Color.gmTextSecondary)
                .position(by: .value("種別", "賞与・その他"))
            }
        }
        .chartForegroundStyleScale([
            "給与": Color.gmGold,
            "賞与・その他": Color.gmTextSecondary
        ])
        .chartLegend(position: .bottom, alignment: .center)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Color.gmGoldDim.opacity(0.18))
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(amount.jpyCompact)
                            .font(GMFont.caption(10))
                            .foregroundStyle(Color.gmTextTertiary)
                    }
                }
            }
        }
        .frame(height: 180)
    }
}

private struct IncomeLegendRow: View {
    let item: DataManager.IncomeBreakdownReportItem

    var body: some View {
        HStack(spacing: GMSpacing.sm) {
            Image(systemName: item.iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: item.colorHex))
                .frame(width: 24)
            Text(item.name)
                .font(GMFont.caption(11, weight: .medium))
                .foregroundStyle(Color.gmTextSecondary)
                .lineLimit(1)
            Spacer()
            Text("\(Int(item.percentOfTotal * 100))%")
                .font(GMFont.mono(11, weight: .bold))
                .foregroundStyle(Color.gmGold)
            Text(item.amount.jpyCompact)
                .font(GMFont.mono(11, weight: .bold))
                .foregroundStyle(Color.gmTextPrimary)
                .frame(width: 78, alignment: .trailing)
        }
    }
}

private struct ReportMiniMetric: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(GMFont.caption(10))
                .foregroundStyle(Color.gmTextTertiary)
            Spacer()
            Text(value)
                .font(GMFont.mono(11, weight: .bold))
                .foregroundStyle(Color.gmTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

private struct ReportFixedVariableCard: View {
    let report: DataManager.FixedVariableReport

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.md) {
            ReportCardTitle(icon: "slider.horizontal.3", title: "固定費 vs 変動費", subtitle: "削れない支出と調整可能支出")

            if report.total <= 0 {
                ReportEmptyState(text: "支出データがありません")
            } else {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: GMRadius.sm)
                            .fill(GMGradient.goldHorizontal)
                            .frame(width: geo.size.width * report.fixedRatio)
                        RoundedRectangle(cornerRadius: GMRadius.sm)
                            .fill(Color.gmTextSecondary.opacity(0.65))
                    }
                }
                .frame(height: 18)
                .clipShape(RoundedRectangle(cornerRadius: GMRadius.sm))

                HStack(spacing: GMSpacing.sm) {
                    ReportRatioPill(title: "固定費", amount: report.fixedExpense, ratio: report.fixedRatio, color: Color.gmGold)
                    ReportRatioPill(title: "変動費", amount: report.variableExpense, ratio: report.variableRatio, color: Color.gmTextSecondary)
                }
            }
        }
        .reportCardStyle()
    }
}

private struct ReportCategoryComparisonCard: View {
    let items: [DataManager.ExpenseCategoryReportItem]

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.md) {
            ReportCardTitle(icon: "arrow.up.arrow.down", title: "前月比・平均比", subtitle: "増減が大きいカテゴリ")

            if items.isEmpty {
                ReportEmptyState(text: "比較できる支出がありません")
            } else {
                VStack(spacing: GMSpacing.sm) {
                    ForEach(items.prefix(7)) { item in
                        ReportComparisonRow(item: item)
                    }
                }
            }
        }
        .reportCardStyle()
    }
}

private struct ReportComparisonRow: View {
    let item: DataManager.ExpenseCategoryReportItem

    var body: some View {
        HStack(spacing: GMSpacing.sm) {
            Image(systemName: item.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: item.colorHex))
                .frame(width: 28, height: 28)
                .background(Color(hex: item.colorHex).opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: GMRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(GMFont.body(13, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
                    .lineLimit(1)
                Text("平均比 \(percentText(item.averageComparisonRate))")
                    .font(GMFont.caption(10))
                    .foregroundStyle(Color.gmTextTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.amount.jpyCompact)
                    .font(GMFont.mono(13, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
                HStack(spacing: 3) {
                    Image(systemName: item.monthOverMonthRate >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(percentText(item.monthOverMonthRate))
                }
                .font(GMFont.caption(10, weight: .bold))
                .foregroundStyle(item.monthOverMonthRate >= 0 ? Color.gmNegative : Color.gmPositive)
            }
        }
    }
}

private struct ReportLegendRow: View {
    let item: DataManager.ExpenseCategoryReportItem

    var body: some View {
        HStack(spacing: GMSpacing.sm) {
            Circle()
                .fill(Color(hex: item.colorHex))
                .frame(width: 8, height: 8)
            Text(item.name)
                .font(GMFont.caption(11, weight: .medium))
                .foregroundStyle(Color.gmTextSecondary)
                .lineLimit(1)
            Spacer()
            Text("\(Int(item.percentOfTotal * 100))%")
                .font(GMFont.mono(11, weight: .bold))
                .foregroundStyle(Color.gmGold)
            Text(item.amount.jpyCompact)
                .font(GMFont.mono(11, weight: .bold))
                .foregroundStyle(Color.gmTextPrimary)
                .frame(width: 72, alignment: .trailing)
        }
    }
}

private struct ReportRatioPill: View {
    let title: String
    let amount: Double
    let ratio: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(GMFont.caption(10, weight: .semibold))
                .foregroundStyle(Color.gmTextTertiary)
            Text(amount.jpyCompact)
                .font(GMFont.mono(14, weight: .bold))
                .foregroundStyle(color)
            Text("\(Int(ratio * 100))%")
                .font(GMFont.caption(10, weight: .bold))
                .foregroundStyle(Color.gmTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GMSpacing.sm)
        .background(Color.gmBackground.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: GMRadius.sm))
    }
}

private struct ReportCardTitle: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: GMSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.gmGold)
                .frame(width: 30, height: 30)
                .background(Color.gmGold.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: GMRadius.sm))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(GMFont.heading(15, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
                Text(subtitle)
                    .font(GMFont.caption(11))
                    .foregroundStyle(Color.gmTextTertiary)
            }
            Spacer()
        }
    }
}

private struct ReportEmptyState: View {
    let text: String

    var body: some View {
        Text(text)
            .font(GMFont.body(13, weight: .medium))
            .foregroundStyle(Color.gmTextTertiary)
            .frame(maxWidth: .infinity, minHeight: 180)
    }
}

private extension View {
    func reportCardStyle(minHeight: CGFloat = 320) -> some View {
        self
            .padding(GMSpacing.md)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#171717"), Color(hex: "#101010")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: GMRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: GMRadius.lg)
                    .strokeBorder(Color.gmGoldDim.opacity(0.28), lineWidth: 0.7)
            )
    }
}

private func monthLabel(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.dateFormat = "M月"
    return formatter.string(from: date)
}

private func percentText(_ rate: Double) -> String {
    let sign = rate > 0 ? "+" : ""
    return "\(sign)\(Int((rate * 100).rounded()))%"
}

#Preview {
    ReportView()
        .environmentObject(DataManager())
}
