// MARK: - ProjectionView.swift
// Gold Mirror – 3-month asset projection with Swift Charts line graph.

import SwiftUI
import Charts

struct ProjectionView: View {
    @EnvironmentObject var dm: DataManager
    @State private var monthlyIncome: Double = 0
    @State private var showSettings = false
    @State private var selectedPoint: ProjectionPoint? = nil

    private var projectionData: [ProjectionPoint] {
        dm.generateProjection(monthlyIncome: monthlyIncome)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gmBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: GMSpacing.lg) {

                        // ── Header ──
                        ProjectionPageHeader(showSettings: $showSettings)

                        // ── Summary Cards ──
                        ProjectionSummaryRow(
                            projectionData: projectionData,
                            monthlyIncome: monthlyIncome
                        )
                        .padding(.horizontal, GMSpacing.md)

                        // ── Main Chart ──
                        ProjectionChartCard(
                            data: projectionData,
                            selectedPoint: $selectedPoint
                        )
                        .padding(.horizontal, GMSpacing.md)

                        // ── Event Timeline ──
                        EventTimelineCard(data: projectionData)
                            .padding(.horizontal, GMSpacing.md)

                        // ── Monthly Outflow Breakdown ──
                        OutflowBreakdownCard()
                            .padding(.horizontal, GMSpacing.md)

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, GMSpacing.md)
                }
            }
            .sheet(isPresented: $showSettings) {
                ProjectionSettingsSheet(monthlyIncome: $monthlyIncome)
            }
            .navigationBarHidden(true)
        }
    }
}

// ─────────────────────────────────────────
// MARK: Page Header
// ─────────────────────────────────────────
struct ProjectionPageHeader: View {
    @Binding var showSettings: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("PROJECTION")
                    .font(GMFont.caption(11, weight: .bold))
                    .foregroundStyle(Color.gmGold.opacity(0.7))
                    .tracking(3)
                Text("3ヶ月資産予測")
                    .font(GMFont.heading(22, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.gmGold)
                    .frame(width: 40, height: 40)
                    .background(Color.gmSurface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gmGoldDim.opacity(0.5), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, GMSpacing.md)
    }
}

// ─────────────────────────────────────────
// MARK: Projection Summary Row
// ─────────────────────────────────────────
struct ProjectionSummaryRow: View {
    let projectionData: [ProjectionPoint]
    let monthlyIncome: Double
    @EnvironmentObject var dm: DataManager

    private var endAssets: Double {
        projectionData.last?.totalAssets ?? 0
    }
    private var startAssets: Double {
        projectionData.first?.totalAssets ?? 0
    }
    private var change: Double { endAssets - startAssets }

    var body: some View {
        HStack(spacing: GMSpacing.sm) {
            // 3ヶ月後予測
            VStack(alignment: .leading, spacing: GMSpacing.xs) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.gmGold)
                    Text("90日後の予測")
                        .font(GMFont.caption(11))
                        .foregroundStyle(Color.gmTextTertiary)
                }
                Text(endAssets.jpyCompact)
                    .font(GMFont.mono(20, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
                HStack(spacing: 3) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    Text(change.jpyCompact)
                        .font(GMFont.caption(11, weight: .semibold))
                }
                .foregroundStyle(change >= 0 ? Color.gmPositive : Color.gmNegative)
            }
            .padding(GMSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .gmCardStyle()

            // 月間支出合計
            VStack(alignment: .leading, spacing: GMSpacing.xs) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.gmNegative)
                    Text("月間支出合計")
                        .font(GMFont.caption(11))
                        .foregroundStyle(Color.gmTextTertiary)
                }
                Text((dm.totalMonthlyOutflow + dm.currentMonthTransactionExpense).jpyCompact)
                    .font(GMFont.mono(20, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
                Text("収入比 \(Int(((dm.totalMonthlyOutflow + dm.currentMonthTransactionExpense) / max(monthlyIncome, 1)) * 100))%")
                    .font(GMFont.caption(11))
                    .foregroundStyle(Color.gmTextTertiary)
            }
            .padding(GMSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .gmCardStyle()
        }
    }
}

// ─────────────────────────────────────────
// MARK: Main Chart Card
// ─────────────────────────────────────────
struct ProjectionChartCard: View {
    let data: [ProjectionPoint]
    @Binding var selectedPoint: ProjectionPoint?

    // 週次間引きでグラフを軽くする
    private var chartData: [ProjectionPoint] {
        data.enumerated().filter { $0.offset % 3 == 0 }.map { $0.element }
    }

    private var minValue: Double {
        (data.map { $0.cashOnly }.min() ?? 0) * 0.95
    }
    private var maxValue: Double {
        (data.map { $0.totalAssets }.max() ?? 0) * 1.05
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.md) {
            // Title
            HStack {
                Image(systemName: "waveform.path.ecg.rectangle.fill")
                    .foregroundStyle(Color.gmGold)
                Text("資産推移グラフ（90日）")
                    .font(GMFont.heading(15, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
                Spacer()
                // Legend
                HStack(spacing: GMSpacing.sm) {
                    LegendDot(color: .gmGold, label: "総資産")
                    LegendDot(color: Color(hex: "#4FC3F7"), label: "現金")
                }
            }

            // Chart
            Chart {
                // ── 総資産ライン ──
                ForEach(chartData) { point in
                    LineMark(
                        x: .value("日付", point.date),
                        y: .value("総資産", point.totalAssets)
                    )
                    .foregroundStyle(Color.gmGold)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                }

                // ── 現金ライン ──
                ForEach(chartData) { point in
                    LineMark(
                        x: .value("日付", point.date),
                        y: .value("現金", point.cashOnly)
                    )
                    .foregroundStyle(Color(hex: "#4FC3F7"))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .interpolationMethod(.catmullRom)
                }

                // ── エリア塗りつぶし（総資産）──
                ForEach(chartData) { point in
                    AreaMark(
                        x: .value("日付", point.date),
                        yStart: .value("Base", minValue),
                        yEnd: .value("総資産", point.totalAssets)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.gmGold.opacity(0.25), Color.gmGold.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                // ── イベントマーカー ──
                ForEach(data.filter { $0.isEvent }) { point in
                    RuleMark(x: .value("日付", point.date))
                        .foregroundStyle(Color.gmGoldDim.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .annotation(position: .top, alignment: .center) {
                            Text(point.eventLabel)
                                .font(GMFont.caption(8))
                                .foregroundStyle(Color.gmGold.opacity(0.7))
                                .lineLimit(1)
                        }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.gmGoldDim.opacity(0.2))
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(v.jpyCompact)
                                .font(GMFont.caption(9))
                                .foregroundStyle(Color.gmTextTertiary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine().foregroundStyle(Color.gmGoldDim.opacity(0.2))
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .foregroundStyle(Color.gmTextTertiary)
                }
            }
            .chartYScale(domain: minValue...maxValue)
            .frame(height: 220)
            .chartBackground { _ in
                Color.clear
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Event Timeline Card
// ─────────────────────────────────────────
struct EventTimelineCard: View {
    let data: [ProjectionPoint]

    private var upcomingEvents: [ProjectionPoint] {
        Array(data.filter { $0.isEvent && $0.date >= Date() }.prefix(5))
    }

    private let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d (E)"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .foregroundStyle(Color.gmGold)
                Text("直近のお金イベント")
                    .font(GMFont.heading(15, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
            }

            ForEach(upcomingEvents) { event in
                HStack(spacing: GMSpacing.md) {
                    // Date badge
                    Text(dateFmt.string(from: event.date))
                        .font(GMFont.caption(11, weight: .bold))
                        .foregroundStyle(Color.gmGold)
                        .frame(width: 72, alignment: .leading)

                    // Event label
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.gmGold)
                            .frame(width: 6, height: 6)
                        Text(event.eventLabel)
                            .font(GMFont.body(13))
                            .foregroundStyle(Color.gmTextSecondary)
                    }

                    Spacer()

                    // Projected total after event
                    Text(event.totalAssets.jpyCompact)
                        .font(GMFont.mono(13, weight: .bold))
                        .foregroundStyle(Color.gmTextPrimary)
                }
                .padding(.vertical, 4)

                if event.id != upcomingEvents.last?.id {
                    Divider().background(Color.gmGoldDim.opacity(0.3))
                }
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Outflow Breakdown Card
// ─────────────────────────────────────────
struct OutflowBreakdownCard: View {
    @EnvironmentObject var dm: DataManager

    private struct OutflowItem {
        let label: String
        let amount: Double
        let color: Color
        let icon: String
    }

    private var items: [OutflowItem] {
        [
            OutflowItem(label: "カード引き落とし", amount: dm.totalMonthlyCardBilling,
                        color: .gmGold, icon: "creditcard.fill"),
            OutflowItem(label: "固定費",           amount: dm.totalMonthlyFixedCosts,
                        color: Color(hex: "#4FC3F7"), icon: "house.fill"),
            OutflowItem(label: "サブスク",         amount: dm.totalMonthlySubscriptions,
                        color: Color(hex: "#CE93D8"), icon: "play.rectangle.fill"),
            OutflowItem(label: "手入力支出",       amount: dm.currentMonthTransactionExpense,
                        color: .gmNegative, icon: "pencil.and.list.clipboard"),
        ]
        .filter { $0.amount > 0 }
    }

    private var total: Double { dm.totalMonthlyOutflow + dm.currentMonthTransactionExpense }

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.md) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(Color.gmGold)
                Text("月間支出の内訳")
                    .font(GMFont.heading(15, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
                Spacer()
                Text(total.jpyFormatted)
                    .font(GMFont.mono(14, weight: .bold))
                    .foregroundStyle(Color.gmGold)
            }

            // Stacked bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(items, id: \.label) { item in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.color)
                            .frame(width: total > 0
                                   ? max(geo.size.width * CGFloat(item.amount / total) - 2, 0)
                                   : 0)
                    }
                }
                .frame(height: 10)
            }
            .frame(height: 10)

            // Legend rows
            ForEach(items, id: \.label) { item in
                HStack(spacing: GMSpacing.sm) {
                    Image(systemName: item.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(item.color)
                        .frame(width: 24)
                    Text(item.label)
                        .font(GMFont.body(13))
                        .foregroundStyle(Color.gmTextSecondary)
                    Spacer()
                    Text(item.amount.jpyFormatted)
                        .font(GMFont.mono(13, weight: .bold))
                        .foregroundStyle(Color.gmTextPrimary)
                    Text("\(Int((item.amount / total) * 100))%")
                        .font(GMFont.caption(11))
                        .foregroundStyle(item.color)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Projection Settings Sheet
// ─────────────────────────────────────────
struct ProjectionSettingsSheet: View {
    @Binding var monthlyIncome: Double
    @Environment(\.dismiss) var dismiss
    @State private var incomeText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gmBackground.ignoresSafeArea()

                Form {
                    Section {
                        HStack {
                            Text("月収（手取り）")
                                .foregroundStyle(Color.gmTextPrimary)
                            Spacer()
                            TextField("0", text: $incomeText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(Color.gmGold)
                                .font(GMFont.mono(16, weight: .bold))
                        }
                    } header: {
                        Text("シミュレーション設定")
                            .font(GMFont.caption(12, weight: .semibold))
                            .foregroundStyle(Color.gmGold)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.gmBackground)
            }
            .navigationTitle("予測設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(Color.gmTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("適用") {
                        if let v = Double(incomeText) { monthlyIncome = v }
                        dismiss()
                    }
                    .foregroundStyle(Color.gmGold)
                    .fontWeight(.bold)
                }
            }
            .preferredColorScheme(.dark)
        }
        .onAppear {
            incomeText = String(Int(monthlyIncome))
        }
    }
}

// ─────────────────────────────────────────
// MARK: Preview
// ─────────────────────────────────────────
#Preview {
    ProjectionView()
        .environmentObject(DataManager())
}
