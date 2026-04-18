// MARK: - AnalysisView.swift
// Gold Mirror – OCR input & financial forecasting screen.
// Integrates DocumentScannerView (Vision/VisionKit) and ProjectionView (Charts).

import SwiftUI

struct AnalysisView: View {
    @EnvironmentObject var vm: AssetViewModel
    @EnvironmentObject var dm: DataManager
    @EnvironmentObject var ocrVM: OCRViewModel
    @State private var selectedTab: AnalysisTab = .forecast

    enum AnalysisTab: String, CaseIterable {
        case forecast = "将来予測"
        case ocr      = "書類スキャン"
        case report   = "月次レポート"
    }

    var body: some View {
        ZStack {
            Color.gmBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                // Page Header
                AnalysisPageHeader()
                    .padding(.top, GMSpacing.md)

                // Segmented Tabs
                AnalysisSegmentedControl(selected: $selectedTab)
                    .padding(.horizontal, GMSpacing.md)
                    .padding(.top, GMSpacing.sm)
                    .padding(.bottom, GMSpacing.xs)

                // Tab Content
                switch selectedTab {
                case .forecast:
                    // Full-screen ProjectionView (has its own ScrollView)
                    ProjectionView()
                        .environmentObject(dm)
                case .ocr:
                    // Full-screen DocumentScannerView (has its own ScrollView)
                    DocumentScannerView()
                        .environmentObject(ocrVM)
                case .report:
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: GMSpacing.md) {
                            MonthlyReportSection()
                            Spacer().frame(height: 28)  // FAB overhang above bar top edge
                        }
                        .padding(.top, GMSpacing.sm)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
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
// MARK: Monthly Report Section
// ─────────────────────────────────────────
struct MonthlyReportSection: View {
    @EnvironmentObject var dm: DataManager

    var body: some View {
        VStack(spacing: GMSpacing.md) {
            // KPI cards row 1
            HStack(spacing: GMSpacing.sm) {
                KPICard(
                    title: "純資産",
                    value: dm.netWorth.jpyCompact,
                    change: "±¥0",
                    isPositive: true,
                    icon: "dollarsign.circle.fill"
                )
                KPICard(
                    title: "証券評価額",
                    value: dm.totalSecuritiesValue.jpyCompact,
                    change: dm.totalSecuritiesProfitLossRate.signedPercent,
                    isPositive: dm.totalSecuritiesProfitLoss >= 0,
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
            .padding(.horizontal, GMSpacing.md)

            // KPI cards row 2
            HStack(spacing: GMSpacing.sm) {
                KPICard(
                    title: "現金残高",
                    value: dm.totalBankBalance.jpyCompact,
                    change: "±¥0",
                    isPositive: true,
                    icon: "banknote.fill"
                )
                KPICard(
                    title: "今月支出",
                    value: (dm.totalMonthlyOutflow + dm.currentMonthTransactionExpense).jpyCompact,
                    change: "±¥0 vs 先月",
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
        .environmentObject(DataManager())
        .environmentObject(OCRViewModel())
}
