// MARK: - AnalysisView.swift
// Gold Mirror – OCR input & financial forecasting screen.

import SwiftUI

struct AnalysisView: View {
    @EnvironmentObject var vm: AssetViewModel
    @State private var selectedTab: AnalysisTab = .forecast

    enum AnalysisTab: String, CaseIterable {
        case forecast = "将来予測"
        case ocr      = "書類読み取り"
        case report   = "月次レポート"
    }

    var body: some View {
        ZStack {
            Color.gmBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: GMSpacing.lg) {

                    // Page Header
                    AnalysisPageHeader()

                    // Segmented Tabs
                    AnalysisSegmentedControl(selected: $selectedTab)
                        .padding(.horizontal, GMSpacing.md)

                    // Tab Content
                    switch selectedTab {
                    case .forecast:
                        ForecastSection()
                    case .ocr:
                        OCRSection()
                    case .report:
                        MonthlyReportSection()
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.top, GMSpacing.md)
            }
        }
    }
}

// ─────────────────────────────────────────
// MARK: Page Header
// ─────────────────────────────────────────
struct AnalysisPageHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ANALYSIS")
                    .font(GMFont.caption(11, weight: .bold))
                    .foregroundStyle(Color.gmGold.opacity(0.7))
                    .tracking(3)
                Text("分析・予測")
                    .font(GMFont.heading(22, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
            }
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.gmGold)
        }
        .padding(.horizontal, GMSpacing.md)
    }
}

// ─────────────────────────────────────────
// MARK: Segmented Control
// ─────────────────────────────────────────
struct AnalysisSegmentedControl: View {
    @Binding var selected: AnalysisView.AnalysisTab
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AnalysisView.AnalysisTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selected = tab
                    }
                } label: {
                    ZStack {
                        if selected == tab {
                            RoundedRectangle(cornerRadius: GMRadius.sm)
                                .fill(Color.gmGold)
                                .matchedGeometryEffect(id: "segBg", in: ns)
                                .padding(3)
                        }
                        Text(tab.rawValue)
                            .font(GMFont.caption(12, weight: selected == tab ? .bold : .medium))
                            .foregroundStyle(selected == tab ? Color.black : Color.gmTextSecondary)
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
// MARK: Forecast Section
// ─────────────────────────────────────────
struct ForecastSection: View {
    @EnvironmentObject var vm: AssetViewModel

    // Mock projected values
    private let projections: [(year: Int, amount: Double)] = [
        (1,  14_800_000),
        (3,  18_200_000),
        (5,  23_500_000),
        (10, 38_900_000),
        (20, 72_400_000),
        (30, 124_600_000)
    ]

    var body: some View {
        VStack(spacing: GMSpacing.md) {
            // Assumption card
            AssumptionCard()
                .padding(.horizontal, GMSpacing.md)

            // Chart placeholder
            ForecastChartView(projections: projections)
                .padding(.horizontal, GMSpacing.md)

            // Projection table
            VStack(spacing: GMSpacing.sm) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(Color.gmGold)
                    Text("将来資産シミュレーション")
                        .font(GMFont.heading(15, weight: .semibold))
                        .foregroundStyle(Color.gmTextPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, GMSpacing.md)

                ForEach(projections, id: \.year) { proj in
                    ProjectionRow(year: proj.year, amount: proj.amount, current: vm.totalAssets)
                        .padding(.horizontal, GMSpacing.md)
                }
            }
        }
    }
}

struct AssumptionCard: View {
    var body: some View {
        HStack(spacing: GMSpacing.lg) {
            AssumptionItem(label: "期待リターン", value: "7.0%", icon: "percent")
            Divider().frame(width: 0.5).background(Color.gmGoldDim.opacity(0.4)).padding(.vertical, 8)
            AssumptionItem(label: "月次積立", value: "¥80,000", icon: "arrow.down.circle.fill")
            Divider().frame(width: 0.5).background(Color.gmGoldDim.opacity(0.4)).padding(.vertical, 8)
            AssumptionItem(label: "インフレ率", value: "2.0%", icon: "chart.bar.fill")
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

struct AssumptionItem: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: GMSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.gmGold)
            Text(value)
                .font(GMFont.mono(14, weight: .bold))
                .foregroundStyle(Color.gmTextPrimary)
            Text(label)
                .font(GMFont.caption(9, weight: .medium))
                .foregroundStyle(Color.gmTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// ─────────────────────────────────────────
// MARK: Forecast Chart (Custom Bar Chart)
// ─────────────────────────────────────────
struct ForecastChartView: View {
    let projections: [(year: Int, amount: Double)]

    private var maxAmount: Double {
        projections.map { $0.amount }.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(Color.gmGold)
                Text("資産成長カーブ")
                    .font(GMFont.heading(15, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
            }

            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(projections, id: \.year) { proj in
                        VStack(spacing: 4) {
                            Text(proj.amount.jpyCompact)
                                .font(GMFont.caption(8, weight: .medium))
                                .foregroundStyle(Color.gmGold)
                                .rotationEffect(.degrees(-45))
                                .frame(width: 40)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gmGoldDim, Color.gmGold],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(
                                    width: (geo.size.width / CGFloat(projections.count)) - 8,
                                    height: max((geo.size.height - 40) * CGFloat(proj.amount / maxAmount), 4)
                                )

                            Text("\(proj.year)年後")
                                .font(GMFont.caption(9))
                                .foregroundStyle(Color.gmTextTertiary)
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

struct ProjectionRow: View {
    let year: Int
    let amount: Double
    let current: Double

    private var growth: Double {
        guard current > 0 else { return 0 }
        return ((amount - current) / current) * 100
    }

    var body: some View {
        HStack {
            Text("\(year)年後")
                .font(GMFont.caption(13, weight: .semibold))
                .foregroundStyle(Color.gmTextSecondary)
                .frame(width: 52, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gmSurfaceElevated)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(GMGradient.goldHorizontal)
                        .frame(
                            width: geo.size.width * CGFloat(min(amount / 130_000_000, 1.0)),
                            height: 6
                        )
                }
            }
            .frame(height: 6)

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(amount.jpyCompact)
                    .font(GMFont.mono(13, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
                Text("+\(Int(growth))%")
                    .font(GMFont.caption(9, weight: .medium))
                    .foregroundStyle(Color.gmPositive)
            }
        }
        .padding(GMSpacing.sm)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: OCR Section
// ─────────────────────────────────────────
struct OCRSection: View {
    @State private var isDragging = false

    var body: some View {
        VStack(spacing: GMSpacing.md) {

            // Upload zone
            ZStack {
                RoundedRectangle(cornerRadius: GMRadius.lg)
                    .stroke(
                        isDragging ? Color.gmGold : Color.gmGoldDim.opacity(0.5),
                        style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: GMRadius.lg)
                            .fill(isDragging ? Color.gmGold.opacity(0.05) : Color.gmSurface)
                    )

                VStack(spacing: GMSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.gmGold.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "doc.viewfinder.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(Color.gmGold)
                    }
                    .gmGoldGlow(radius: 12, opacity: 0.3)

                    Text("書類をタップしてスキャン")
                        .font(GMFont.heading(16, weight: .semibold))
                        .foregroundStyle(Color.gmTextPrimary)

                    Text("銀行の明細・証券残高報告書・\nクレジットカード明細に対応")
                        .font(GMFont.body(13))
                        .foregroundStyle(Color.gmTextTertiary)
                        .multilineTextAlignment(.center)

                    Button { } label: {
                        HStack(spacing: GMSpacing.xs) {
                            Image(systemName: "camera.fill")
                            Text("カメラで撮影")
                        }
                        .font(GMFont.body(14, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, GMSpacing.lg)
                        .padding(.vertical, GMSpacing.sm)
                        .background(GMGradient.goldHorizontal)
                        .clipShape(Capsule())
                    }
                    .gmGoldGlow(radius: 12, opacity: 0.4)

                    Button { } label: {
                        Text("ライブラリから選択")
                            .font(GMFont.body(14, weight: .medium))
                            .foregroundStyle(Color.gmGold)
                    }
                }
                .padding(GMSpacing.xl)
            }
            .frame(height: 340)
            .padding(.horizontal, GMSpacing.md)

            // Supported documents
            SupportedDocumentsCard()
                .padding(.horizontal, GMSpacing.md)

            // Recent scans
            RecentScansCard()
                .padding(.horizontal, GMSpacing.md)
        }
    }
}

struct SupportedDocumentsCard: View {
    let items = [
        ("building.columns.fill", "銀行明細書", "通帳・WEB明細"),
        ("chart.line.uptrend.xyaxis", "証券残高報告書", "SBI・楽天証券など"),
        ("creditcard.fill", "カード明細", "各社請求明細"),
        ("doc.text.fill", "源泉徴収票", "給与・配当")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            Text("対応書類")
                .font(GMFont.heading(14, weight: .semibold))
                .foregroundStyle(Color.gmTextPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: GMSpacing.sm) {
                ForEach(items, id: \.0) { item in
                    HStack(spacing: GMSpacing.sm) {
                        Image(systemName: item.0)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.gmGold)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.1)
                                .font(GMFont.caption(12, weight: .medium))
                                .foregroundStyle(Color.gmTextPrimary)
                            Text(item.2)
                                .font(GMFont.caption(10))
                                .foregroundStyle(Color.gmTextTertiary)
                        }
                    }
                    .padding(GMSpacing.sm)
                    .gmCardStyle(elevated: true)
                }
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

struct RecentScansCard: View {
    let scans = [
        ("三菱UFJ銀行 残高証明", "2026/04/10", "building.columns.fill"),
        ("SBI証券 月次報告書", "2026/04/08", "chart.line.uptrend.xyaxis"),
        ("楽天カード 3月明細", "2026/04/01", "creditcard.fill")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            Text("最近のスキャン")
                .font(GMFont.heading(14, weight: .semibold))
                .foregroundStyle(Color.gmTextPrimary)

            ForEach(scans, id: \.0) { scan in
                HStack(spacing: GMSpacing.sm) {
                    Image(systemName: scan.2)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.gmGold)
                        .frame(width: 36, height: 36)
                        .background(Color.gmGold.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: GMRadius.sm))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(scan.0)
                            .font(GMFont.body(13, weight: .medium))
                            .foregroundStyle(Color.gmTextPrimary)
                        Text(scan.1)
                            .font(GMFont.caption(11))
                            .foregroundStyle(Color.gmTextTertiary)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.gmPositive)
                }
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Monthly Report Section
// ─────────────────────────────────────────
struct MonthlyReportSection: View {
    @EnvironmentObject var vm: AssetViewModel

    var body: some View {
        VStack(spacing: GMSpacing.md) {
            // KPI cards
            HStack(spacing: GMSpacing.sm) {
                KPICard(
                    title: "純資産",
                    value: vm.netWorth.jpyCompact,
                    change: "+¥340K",
                    isPositive: true,
                    icon: "dollarsign.circle.fill"
                )
                KPICard(
                    title: "証券評価額",
                    value: vm.totalSecuritiesValue.jpyCompact,
                    change: vm.totalSecuritiesProfitLossRate.signedPercent,
                    isPositive: vm.totalSecuritiesProfitLoss >= 0,
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
            .padding(.horizontal, GMSpacing.md)

            HStack(spacing: GMSpacing.sm) {
                KPICard(
                    title: "現金残高",
                    value: vm.totalBankBalance.jpyCompact,
                    change: "+¥120K",
                    isPositive: true,
                    icon: "banknote.fill"
                )
                KPICard(
                    title: "今月支出",
                    value: vm.totalMonthlyBilling.jpyCompact,
                    change: "-¥18K vs 先月",
                    isPositive: true,
                    icon: "creditcard.fill"
                )
            }
            .padding(.horizontal, GMSpacing.md)

            // Coming soon placeholder
            VStack(spacing: GMSpacing.md) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.gmGold.opacity(0.3))
                Text("詳細レポート機能\n近日公開")
                    .font(GMFont.heading(16, weight: .semibold))
                    .foregroundStyle(Color.gmTextTertiary)
                    .multilineTextAlignment(.center)
                Text("収支分析・カテゴリ別支出・\n資産推移グラフなど")
                    .font(GMFont.body(13))
                    .foregroundStyle(Color.gmTextTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(GMSpacing.xl)
            .frame(maxWidth: .infinity)
            .gmCardStyle()
            .padding(.horizontal, GMSpacing.md)
        }
    }
}

struct KPICard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.gmGold)
                Spacer()
                Text(change)
                    .font(GMFont.caption(10, weight: .semibold))
                    .foregroundStyle(isPositive ? Color.gmPositive : Color.gmNegative)
            }

            Text(value)
                .font(GMFont.mono(20, weight: .bold))
                .foregroundStyle(Color.gmTextPrimary)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(GMFont.caption(11))
                .foregroundStyle(Color.gmTextTertiary)
        }
        .padding(GMSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Preview
// ─────────────────────────────────────────
#Preview {
    AnalysisView()
        .environmentObject(AssetViewModel())
}
