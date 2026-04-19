// MARK: - MainTabView.swift
// Gold Mirror – Root tab container.
//
// ┌─────────────────────────────────────────┐
// │  VStack (fills entire screen)           │
// │  ┌───────────────────────────────────┐  │
// │  │  TabView (weight: 1, flexible)    │  │
// │  │  - DashboardView                  │  │
// │  │  - WealthCalendarView             │  │
// │  │  - MirrorView                     │  │
// │  │  - AnalysisView                   │  │
// │  │  - SettingsView                   │  │
// │  └───────────────────────────────────┘  │
// │  ┌───────────────────────────────────┐  │
// │  │  GMCustomTabBar (fixed height)    │  │  ← 常に画面最下部
// │  └───────────────────────────────────┘  │
// └─────────────────────────────────────────┘
//
// Why VStack instead of ZStack / safeAreaInset:
//  - ZStack(alignment:.bottom) + ignoresSafeArea → tab bar jumps to top
//  - safeAreaInset(edge:.bottom)                 → tab bar jumps to top
//  - VStack { TabView; Bar }                     → ALWAYS correct on device
//
// The native UITabBar is hidden via UITabBar.appearance().isHidden = true
// so only our custom bar is visible.

import SwiftUI

// ─────────────────────────────────────────
// MARK: Tab Enum
// ─────────────────────────────────────────
enum GMTab: Int, CaseIterable {
    case dashboard = 0
    case calendar  = 1
    case mirror    = 2
    case analysis  = 3
    case settings  = 4

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
        case .analysis:  return "chart.pie.fill"
        case .settings:  return "gearshape.fill"
        }
    }

    var japaneseTitle: String {
        switch self {
        case .dashboard: return "ダッシュボード"
        case .calendar:  return "カレンダー"
        case .mirror:    return "ミラー"
        case .analysis:  return "分析"
        case .settings:  return "設定"
        }
    }

    var sidebarTitle: String { title }
}

// ─────────────────────────────────────────
// MARK: Constants
// ─────────────────────────────────────────
enum GMTabBarConstants {
    static let barHeight:   CGFloat = 60
    static let fabDiameter: CGFloat = 56
    static let floatingActionBottomPadding: CGFloat = 20
    static let iPadSidebarMinWidth: CGFloat = 350
    static let iPadSidebarWidth: CGFloat = 380
    static let iPadSidebarMaxWidth: CGFloat = 400
}

// ─────────────────────────────────────────
// MARK: MainTabView
// ─────────────────────────────────────────
struct MainTabView: View {
    @StateObject private var viewModel  = AssetViewModel()
    @EnvironmentObject var dataManager:  DataManager
    @EnvironmentObject var ocrViewModel: OCRViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedTab: Int = 0
    @State private var showIncome       = false
    @State private var dashboardPath = NavigationPath()
    @State private var calendarPath = NavigationPath()
    @State private var mirrorPath = NavigationPath()
    @State private var analysisPath = NavigationPath()
    @State private var settingsPath = NavigationPath()
    @State private var iPadDetailPath = NavigationPath()
    @State private var dashboardRootID = UUID()
    @State private var calendarRootID = UUID()
    @State private var mirrorRootID = UUID()
    @State private var analysisRootID = UUID()
    @State private var settingsRootID = UUID()
    @State private var iPadDetailRootID = UUID()
    @State private var iPadSplitRootID = UUID()
    @State private var iPadColumnVisibility: NavigationSplitViewVisibility = .all

    private var shouldShowIncomeButton: Bool {
        selectedTab == GMTab.dashboard.rawValue || selectedTab == GMTab.calendar.rawValue
    }

    private var selectedTabBinding: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { selectTab($0) }
        )
    }

    init() {
        // Hide the system-provided tab bar globally
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        GeometryReader { proxy in
            if horizontalSizeClass == .regular {
                iPadSplitLayout(proxy: proxy)
            } else {
                iPhoneTabLayout(proxy: proxy)
            }
        }
        // Background fills entire screen including safe areas
        .background(Color.gmBackground.ignoresSafeArea())
        .environment(\.locale, Locale(identifier: "ja_JP"))
        .environmentObject(viewModel)
        .onChange(of: selectedTab) { _, _ in
            resetAllNavigationStacks()
        }
        .sheet(isPresented: $showIncome) {
            IncomeExpenseInputView()
                .environmentObject(dataManager)
                .environmentObject(ocrViewModel)
        }
    }

    private func iPhoneTabLayout(proxy: GeometryProxy) -> some View {
        ZStack(alignment: .bottomTrailing) {
            // VStack: content fills available space, bar is pinned at bottom
            VStack(spacing: 0) {

                // ── Tab content ──────────────────────────────────────────
                TabView(selection: selectedTabBinding) {

                    NavigationStack(path: $dashboardPath) { tabContent(.dashboard) }
                        .id(dashboardRootID)
                        .tag(GMTab.dashboard.rawValue)

                    NavigationStack(path: $calendarPath) { tabContent(.calendar) }
                        .id(calendarRootID)
                        .tag(GMTab.calendar.rawValue)

                    NavigationStack(path: $mirrorPath) { tabContent(.mirror) }
                        .id(mirrorRootID)
                        .tag(GMTab.mirror.rawValue)

                    NavigationStack(path: $analysisPath) { tabContent(.analysis) }
                        .id(analysisRootID)
                        .tag(GMTab.analysis.rawValue)

                    NavigationStack(path: $settingsPath) { tabContent(.settings) }
                        .id(settingsRootID)
                        .tag(GMTab.settings.rawValue)
                }
                // Keep iOS state restoration; hides page dots
                .tabViewStyle(.automatic)
                // TabView takes all remaining space above the bar
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ── Custom Tab Bar (always at bottom) ────────────────────
                GMCustomTabBar(
                    selectedTab: selectedTabBinding,
                    bottomSafeArea: proxy.safeAreaInsets.bottom
                )
            }
            .ignoresSafeArea(.container, edges: .bottom)

            if shouldShowIncomeButton {
                incomeFloatingButton
                    .padding(.trailing, GMSpacing.lg)
                    .padding(.bottom, GMTabBarConstants.barHeight
                             + proxy.safeAreaInsets.bottom
                             + GMTabBarConstants.floatingActionBottomPadding)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func iPadSplitLayout(proxy: GeometryProxy) -> some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationSplitView(columnVisibility: $iPadColumnVisibility) {
                GMIPadSidebar(selectedTab: selectedTab) { tab in
                    selectTab(tab.rawValue)
                }
                .frame(width: GMTabBarConstants.iPadSidebarWidth)
                .background(Color.black.ignoresSafeArea(.all, edges: .leading))
                .navigationSplitViewColumnWidth(
                    min: GMTabBarConstants.iPadSidebarMinWidth,
                    ideal: GMTabBarConstants.iPadSidebarWidth,
                    max: GMTabBarConstants.iPadSidebarMaxWidth
                )
                .toolbarBackground(Color.black, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            } detail: {
                NavigationStack(path: $iPadDetailPath) {
                    tabContent(GMTab(rawValue: selectedTab) ?? .dashboard)
                        .id(selectedTab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .id(iPadDetailRootID)
            }
            .navigationSplitViewStyle(.balanced)
            .tint(Color.gmGold)
            .background(Color.gmBackground.ignoresSafeArea())
            .id(iPadSplitRootID)
            .onAppear {
                iPadColumnVisibility = .all
            }
            .onChange(of: selectedTab) { _, _ in
                iPadColumnVisibility = .all
                resetAllNavigationStacks()
            }

            if shouldShowIncomeButton {
                incomeFloatingButton
                    .padding(.trailing, GMSpacing.xl)
                    .padding(.bottom, proxy.safeAreaInsets.bottom + GMSpacing.xl)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private func tabContent(_ tab: GMTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView()
                .environmentObject(viewModel)
                .environmentObject(dataManager)
        case .calendar:
            WealthCalendarView()
                .environmentObject(dataManager)
                .environmentObject(ocrViewModel)
        case .mirror:
            MirrorView()
                .environmentObject(viewModel)
                .environmentObject(ocrViewModel)
        case .analysis:
            AnalysisView()
                .environmentObject(viewModel)
                .environmentObject(dataManager)
                .environmentObject(ocrViewModel)
        case .settings:
            SettingsView()
                .environmentObject(dataManager)
                .environmentObject(viewModel)
                .environmentObject(ocrViewModel)
        }
    }

    private func selectTab(_ rawValue: Int) {
        guard GMTab(rawValue: rawValue) != nil else { return }
        resetAllNavigationStacks()
        if selectedTab == rawValue {
            return
        }
        selectedTab = rawValue
    }

    private func resetAllNavigationStacks() {
        dashboardPath = NavigationPath()
        calendarPath = NavigationPath()
        mirrorPath = NavigationPath()
        analysisPath = NavigationPath()
        settingsPath = NavigationPath()
        iPadDetailPath = NavigationPath()

        dashboardRootID = UUID()
        calendarRootID = UUID()
        mirrorRootID = UUID()
        analysisRootID = UUID()
        settingsRootID = UUID()
        iPadDetailRootID = UUID()
        iPadSplitRootID = UUID()
    }

    private var incomeFloatingButton: some View {
        Button { showIncome = true } label: {
            ZStack(alignment: .center) {
                Circle()
                    .fill(GMGradient.goldDiagonal)
                    .gmGoldGlow(radius: 16, opacity: 0.5)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .frame(width: GMTabBarConstants.fabDiameter,
                           height: GMTabBarConstants.fabDiameter,
                           alignment: .center)
            }
            .frame(width: GMTabBarConstants.fabDiameter,
                   height: GMTabBarConstants.fabDiameter,
                   alignment: .center)
        }
        .frame(width: GMTabBarConstants.fabDiameter,
               height: GMTabBarConstants.fabDiameter,
               alignment: .center)
        .contentShape(Circle())
        .buttonStyle(.plain)
        .zIndex(2)
    }
}

// ─────────────────────────────────────────
// MARK: iPad Sidebar
// ─────────────────────────────────────────
struct GMIPadSidebar: View {
    let selectedTab: Int
    let onSelect: (GMTab) -> Void

    var body: some View {
        ZStack(alignment: .trailing) {
            Color.black
                .frame(width: GMTabBarConstants.iPadSidebarWidth)
                .ignoresSafeArea(.all, edges: [.top, .bottom, .leading])

            VStack(alignment: .leading, spacing: GMSpacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gold Mirror")
                        .font(GMFont.display(26, weight: .bold))
                        .foregroundStyle(GMGradient.goldHorizontal)
                    Text("資産管理メニュー")
                        .font(GMFont.caption(12, weight: .semibold))
                        .foregroundStyle(Color.gmTextTertiary)
                        .tracking(1)
                }
                .padding(.horizontal, GMSpacing.md)
                .padding(.top, GMSpacing.lg)

                VStack(spacing: GMSpacing.sm) {
                    ForEach(GMTab.allCases, id: \.rawValue) { tab in
                        sidebarButton(tab)
                    }
                }

                Spacer()
            }
            .frame(width: GMTabBarConstants.iPadSidebarWidth, alignment: .topLeading)
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .padding(.vertical, GMSpacing.md)
            .ignoresSafeArea(.all, edges: .leading)

            Rectangle()
                .fill(Color.gmGold.opacity(0.32))
                .frame(width: 0.75)
                .ignoresSafeArea(edges: .vertical)
        }
        .scrollContentBackground(.hidden)
        .frame(width: GMTabBarConstants.iPadSidebarWidth)
        .frame(maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea(.all, edges: [.top, .bottom, .leading]))
    }

    private func sidebarButton(_ tab: GMTab) -> some View {
        let selected = selectedTab == tab.rawValue
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                onSelect(tab)
            }
        } label: {
            HStack(spacing: GMSpacing.sm) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .foregroundStyle(selected ? Color.black : Color.gmGold)
                    .background(selected ? Color.gmGold : Color.gmGold.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: GMRadius.sm))

                Text(tab.sidebarTitle)
                    .font(GMFont.body(15, weight: selected ? .bold : .medium))
                    .foregroundStyle(selected ? Color.gmTextPrimary : Color.gmTextSecondary)

                Spacer()
            }
            .padding(.horizontal, GMSpacing.md)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(selected ? Color.gmSurfaceElevated : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: GMRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: GMRadius.md)
                    .strokeBorder(selected ? Color.gmGold.opacity(0.35) : Color.clear, lineWidth: 0.8)
            )
            .padding(.horizontal, GMSpacing.sm)
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────
// MARK: GMCustomTabBar
// ─────────────────────────────────────────
struct GMCustomTabBar: View {
    @Binding var selectedTab: Int
    let bottomSafeArea: CGFloat
    @Namespace private var pill

    private let tabs: [(Int, String, String)] = [
        (0, "square.grid.2x2.fill", "Dashboard"),
        (1, "calendar", "Calendar"),
        (2, "person.2.fill", "Mirror"),
        (3, "chart.pie.fill", "Analysis"),
        (4, "gearshape.fill", "Settings")
    ]

    var body: some View {
        VStack(spacing: 0) {

            // Gold hairline
            LinearGradient(
                colors: [Color.gmGoldDim.opacity(0.4), Color.gmGold, Color.gmGoldDim.opacity(0.4)],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 0.5)

            // Bar + FAB
            ZStack(alignment: .top) {

                // Opaque background that also covers the home indicator area
                Color.gmTabBackground

                // Tab icon row
                HStack(alignment: .center, spacing: 0) {
                    ForEach(tabs, id: \.0) { tabItem($0, $1, $2) }
                }
                .frame(height: GMTabBarConstants.barHeight)
                .padding(.top, 4)

            }
            .frame(height: GMTabBarConstants.barHeight + bottomSafeArea)
        }
        .frame(height: GMTabBarConstants.barHeight + bottomSafeArea + 0.5)
        .shadow(color: .black.opacity(0.75), radius: 12, x: 0, y: -3)
    }

    // ── Tab item ─────────────────────────────────────────────────────────
    @ViewBuilder
    private func tabItem(_ tag: Int, _ icon: String, _ label: String) -> some View {
        let sel = selectedTab == tag
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if sel {
                        Capsule()
                            .fill(Color.gmGold.opacity(0.15))
                            .frame(width: 44, height: 26)
                            .matchedGeometryEffect(id: "pill", in: pill)
                    }
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: sel ? .semibold : .regular))
                        .foregroundStyle(sel ? Color.gmGold : Color.gmTabInactive)
                        .frame(width: 44, height: 26)
                        .scaleEffect(sel ? 1.08 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: sel)
                }
                Text(label)
                    .font(GMFont.caption(8, weight: sel ? .semibold : .regular))
                    .foregroundStyle(sel ? Color.gmGold : Color.gmTabInactive)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
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
            .environmentObject(SecurityManager())
}
