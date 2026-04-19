// MARK: - AnalysisView.swift
// Gold Mirror – Projection, monthly expense report, and income analytics.

import SwiftUI

struct AnalysisView: View {
    @EnvironmentObject var vm: AssetViewModel
    @EnvironmentObject var dm: DataManager
    @State private var selectedSection: AnalysisSection = .projection

    enum AnalysisSection: String, CaseIterable, Identifiable {
        case projection = "将来予測"
        case monthly = "月次レポート"
        case income = "収入分析"

        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Color.gmBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                AnalysisPageHeader()
                    .padding(.top, GMSpacing.md)

                Picker("分析メニュー", selection: $selectedSection) {
                    ForEach(AnalysisSection.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .tint(Color.gmGold)
                .padding(.horizontal, GMSpacing.md)
                .padding(.top, GMSpacing.sm)
                .padding(.bottom, GMSpacing.xs)

                Group {
                    switch selectedSection {
                    case .projection:
                        ProjectionView()
                            .environmentObject(dm)
                    case .monthly:
                        ReportView(mode: .monthly)
                            .environmentObject(dm)
                    case .income:
                        ReportView(mode: .income)
                            .environmentObject(dm)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

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
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.gmGold)
        }
        .padding(.horizontal, GMSpacing.md)
    }
}

#Preview {
    AnalysisView()
        .environmentObject(AssetViewModel())
        .environmentObject(DataManager())
}
