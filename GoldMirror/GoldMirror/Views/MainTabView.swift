// MARK: - MainTabView.swift
// Gold Mirror – Root tab container with NavigationStack-per-tab and custom gold tab bar.

import SwiftUI

// ─────────────────────────────────────────
// MARK: Tab Enum
// ─────────────────────────────────────────
enum GMTab: Int, CaseIterable {
    case dashboard = 0
    case calendar
    case mirror
    case analysis
    case settings

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .calendar:  return "Calendar"
        case .mirror:    return "Mirror"
        case .analysis:  return "Analysis"
        case .settings:  return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .calendar:  return "calendar"
        case .mirror:    return "person.2.fill"
        case .analysis:  return "chart.bar.xaxis"
        case .settings:  return "gearshape.fill"
        }
    }
}

// ─────────────────────────────────────────
// MARK: MainTabView
// ─────────────────────────────────────────
struct MainTabView: View {
    @StateObject private var viewModel    = AssetViewModel()
    @EnvironmentObject var dataManager:   DataManager
    @EnvironmentObject var ocrViewModel:  OCRViewModel
    @State private var selectedTab: GMTab = .dashboard
    @Namespace private var tabAnimation
    @State private var showIncomeExpenseSheet = false

    // Tab bar height constant used by child views to add bottom padding
    static let tabBarHeight: CGFloat = 83

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.gmBackground.ignoresSafeArea()

            // ── Per-tab NavigationStack content ──
            Group {
                switch selectedTab {
                case .dashboard:
                    NavigationStack {
                        DashboardView()
                            .environmentObject(viewModel)
                            .environmentObject(dataManager)
                    }
                case .calendar:
                    NavigationStack {
                        WealthCalendarView()
                            .environmentObject(dataManager)
                    }
                case .mirror:
                    NavigationStack {
                        MirrorView()
                            .environmentObject(viewModel)
                            .environmentObject(ocrViewModel)
                    }
                case .analysis:
                    NavigationStack {
                        AnalysisView()
                            .environmentObject(viewModel)
                            .environmentObject(dataManager)
                            .environmentObject(ocrViewModel)
                    }
                case .settings:
                    NavigationStack {
                        SettingsView()
                            .environmentObject(dataManager)
                            .environmentObject(viewModel)
                    }
                }
            }
            // Push content above tab bar
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: MainTabView.tabBarHeight)
            }

            // ── Custom Gold Tab Bar (always on top, opaque) ──
            VStack(spacing: 0) {
                // Top hairline separator
                Rectangle()
                    .fill(GMGradient.goldHorizontal)
                    .frame(height: 0.5)

                HStack(spacing: 0) {
                    // Left tabs (dashboard, calendar)
                    ForEach([GMTab.dashboard, GMTab.calendar], id: \.rawValue) { tab in
                        GMTabBarItem(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            namespace: tabAnimation
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                                selectedTab = tab
                            }
                        }
                    }

                    // Centre FAB placeholder
                    Color.clear.frame(width: 72)

                    // Right tabs (mirror, analysis, settings)
                    ForEach([GMTab.mirror, GMTab.analysis, GMTab.settings], id: \.rawValue) { tab in
                        GMTabBarItem(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            namespace: tabAnimation
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                                selectedTab = tab
                            }
                        }
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 28)
                .background(Color.gmTabBackground)
            }
            .shadow(color: Color.black.opacity(0.6), radius: 16, x: 0, y: -4)

            // ── Floating Action Button (centred, elevated above tab bar) ──
            Button {
                showIncomeExpenseSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.gmGoldLight, Color.gmGold, Color.gmGoldDim],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .shadow(color: Color.gmGold.opacity(0.55), radius: 14, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.gmBackground)
                }
            }
            .offset(y: -(MainTabView.tabBarHeight - 28))
            .sheet(isPresented: $showIncomeExpenseSheet) {
                IncomeExpenseInputView()
                    .environmentObject(dataManager)
            }
        }
        .environmentObject(viewModel)
        .ignoresSafeArea(edges: .bottom)
    }
}

// ─────────────────────────────────────────
// MARK: Individual Tab Bar Item
// ─────────────────────────────────────────
struct GMTabBarItem: View {
    let tab: GMTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(Color.gmGold.opacity(0.15))
                            .frame(width: 48, height: 30)
                            .matchedGeometryEffect(id: "tabBG", in: namespace)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.gmGold : Color.gmTabInactive)
                        .frame(width: 48, height: 30)
                        .scaleEffect(isSelected ? 1.08 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }

                Text(tab.title)
                    .font(GMFont.caption(9, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.gmGold : Color.gmTabInactive)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────
// MARK: Preview
// ─────────────────────────────────────────
#Preview {
    MainTabView()
        .environmentObject(DataManager())
        .environmentObject(OCRViewModel())
}
