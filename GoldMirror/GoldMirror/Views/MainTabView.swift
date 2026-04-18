// MARK: - MainTabView.swift
// Gold Mirror – Root tab container.
//
// Layout contract
// ┌─────────────────────────────────┐  ← status bar (handled by each view)
// │  Tab content (scrollable)       │
// │  DashboardView / CalendarView / │
// │  MirrorView / AnalysisView /    │
// │  SettingsView                   │
// │                                 │
// │                                 │
// ├─────────────────────────────────┤  ← custom tab bar top edge
// │  [Dash] [Cal]  [+]  [Mir] [Ana] │  ← 60 pt bar
// └─────────────────────────────────┘  ← home indicator / screen bottom
//
// Key design decisions:
//  • Standard TabView with .tabViewStyle(.automatic) keeps iOS state restoration.
//  • UITabBar.appearance().isHidden = true hides the system bar globally.
//  • Custom GMCustomTabBar is attached with .safeAreaInset(edge: .bottom) so
//    each tab's scroll content automatically stops above the bar – no manual
//    bottom padding needed.
//  • The floating + FAB sits inside GMCustomTabBar, lifted with a negative
//    offset so it peeks above the bar top edge.
//  • NO .ignoresSafeArea on the outer container → content always starts from
//    the top safe-area, not from the physical screen edge.

import SwiftUI

// ─────────────────────────────────────────
// MARK: Tab Enum  (5 real tabs)
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
        case .analysis:  return "chart.bar.xaxis"
        case .settings:  return "gearshape.fill"
        }
    }
}

// ─────────────────────────────────────────
// MARK: Layout Constants
// ─────────────────────────────────────────
enum GMTabBarConstants {
    /// Visible icon+label row height
    static let barContentHeight: CGFloat = 60
    /// Gold circle diameter
    static let fabDiameter: CGFloat = 62
    /// How many points the FAB rises above the bar's top edge
    static let fabLift: CGFloat = 14
}

// ─────────────────────────────────────────
// MARK: MainTabView
// ─────────────────────────────────────────
struct MainTabView: View {
    @StateObject private var viewModel   = AssetViewModel()
    @EnvironmentObject var dataManager:  DataManager
    @EnvironmentObject var ocrViewModel: OCRViewModel

    @State private var selectedTab: Int  = 0
    @State private var showIncomeSheet   = false

    // Hide the native iOS tab bar once, before any view renders.
    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        // ── Standard TabView ──────────────────────────────────────────────
        // .safeAreaInset pushes each tab's content UP so it never hides
        // behind our custom bar. The bar itself lives in the system safe area.
        TabView(selection: $selectedTab) {

            NavigationStack {
                DashboardView()
                    .environmentObject(viewModel)
                    .environmentObject(dataManager)
            }
            .tag(0)

            NavigationStack {
                WealthCalendarView()
                    .environmentObject(dataManager)
            }
            .tag(1)

            NavigationStack {
                MirrorView()
                    .environmentObject(viewModel)
                    .environmentObject(ocrViewModel)
            }
            .tag(2)

            NavigationStack {
                AnalysisView()
                    .environmentObject(viewModel)
                    .environmentObject(dataManager)
                    .environmentObject(ocrViewModel)
            }
            .tag(3)

            NavigationStack {
                SettingsView()
                    .environmentObject(dataManager)
                    .environmentObject(viewModel)
            }
            .tag(4)
        }
        // Attach the custom tab bar as a bottom safe-area inset.
        // SwiftUI automatically adjusts scroll content to stop above it.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GMCustomTabBar(
                selectedTab: $selectedTab,
                onFABTap: { showIncomeSheet = true }
            )
        }
        .environmentObject(viewModel)
        // Income / expense entry sheet
        .sheet(isPresented: $showIncomeSheet) {
            IncomeExpenseInputView()
                .environmentObject(dataManager)
        }
    }
}

// ─────────────────────────────────────────
// MARK: GMCustomTabBar
// ─────────────────────────────────────────
struct GMCustomTabBar: View {
    @Binding var selectedTab: Int
    let onFABTap: () -> Void

    @Namespace private var pill

    // Left pair: Dashboard · Calendar
    private let leftTabs: [(Int, String, String)] = [
        (0, "square.grid.2x2.fill", "Dashboard"),
        (1, "calendar",             "Calendar")
    ]
    // Right pair: Analysis · Settings
    private let rightTabs: [(Int, String, String)] = [
        (3, "chart.bar.xaxis", "Analysis"),
        (4, "gearshape.fill",  "Settings")
    ]
    // Centre real tab: Mirror (tag 2) – the FAB floats above it.

    var body: some View {
        VStack(spacing: 0) {

            // ── Gold hairline at top of bar ─────────────────────────────
            LinearGradient(
                colors: [Color.gmGoldDim.opacity(0.4), Color.gmGold, Color.gmGoldDim.opacity(0.4)],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 0.5)

            // ── Bar body + FAB overlay ───────────────────────────────────
            ZStack(alignment: .top) {

                // Fully opaque background (covers bar row + home indicator gap)
                Color.gmTabBackground
                    .ignoresSafeArea(edges: .bottom)

                // Tab icon / label row
                HStack(alignment: .center, spacing: 0) {
                    // Left tabs
                    ForEach(leftTabs, id: \.0) { tabItem($0, $1, $2) }

                    // Centre: Mirror tab (behind the FAB visually)
                    tabItem(2, "person.2.fill", "Mirror")

                    // Right tabs
                    ForEach(rightTabs, id: \.0) { tabItem($0, $1, $2) }
                }
                .frame(height: GMTabBarConstants.barContentHeight)
                .padding(.top, 4)

                // FAB – horizontally centred, vertically lifted above bar top
                fabButton
                    .frame(maxWidth: .infinity, alignment: .center)
                    .offset(y: -(GMTabBarConstants.fabDiameter / 2
                                 + GMTabBarConstants.fabLift))
            }
        }
        // Upward shadow only
        .shadow(color: Color.black.opacity(0.8), radius: 12, x: 0, y: -3)
    }

    // ── Single tab item ─────────────────────────────────────────────────
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
                    .font(GMFont.caption(9, weight: sel ? .semibold : .regular))
                    .foregroundStyle(sel ? Color.gmGold : Color.gmTabInactive)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // ── Floating Action Button ──────────────────────────────────────────
    private var fabButton: some View {
        Button(action: onFABTap) {
            ZStack {
                // Dark halo separates FAB from bar background
                Circle()
                    .fill(Color.gmTabBackground)
                    .frame(width: GMTabBarConstants.fabDiameter + 8,
                           height: GMTabBarConstants.fabDiameter + 8)

                // Gold gradient fill
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.gmGoldLight, Color.gmGold, Color.gmGoldDim],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: GMTabBarConstants.fabDiameter,
                           height: GMTabBarConstants.fabDiameter)
                    .shadow(color: Color.gmGold.opacity(0.55), radius: 10, x: 0, y: 3)

                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.gmBackground)
            }
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
