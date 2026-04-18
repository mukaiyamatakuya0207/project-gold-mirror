// MARK: - MainTabView.swift
// Gold Mirror – Root tab container.
// Standard TabView with 5 real tabs + floating central FAB above tab bar.

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
    static let barContentHeight: CGFloat = 60   // icon + label row height
    static let fabDiameter:      CGFloat = 62   // gold + circle diameter
    static let fabLift:          CGFloat = 16   // how far FAB rises above bar top edge

    static var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }

    /// Total vertical space reserved at the bottom (bar + home indicator)
    static var totalHeight: CGFloat {
        barContentHeight + safeAreaBottom
    }
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

    var body: some View {
        ZStack(alignment: .bottom) {

            // ── TabView: 5 real tabs ──────────────────────────────────────
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
            // Use default tab style but hide the native tab bar
            .tabViewStyle(.automatic)
            // Hide the built-in iOS tab bar – we draw our own GMCustomTabBar
            .toolbar(.hidden, for: .tabBar)
            // Reserve space so scroll content is never hidden by our custom tab bar
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: GMTabBarConstants.totalHeight)
            }

            // ── Custom Tab Bar ────────────────────────────────────────────
            GMCustomTabBar(
                selectedTab: $selectedTab,
                onFABTap: { showIncomeSheet = true }
            )
        }
        .environmentObject(viewModel)
        .ignoresSafeArea(edges: .bottom)
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

    // Left side: Dashboard (0), Calendar (1)
    private let leftTabs:  [(Int, String, String)] = [
        (0, "square.grid.2x2.fill", "Dashboard"),
        (1, "calendar",             "Calendar")
    ]
    // Right side: Analysis (3), Settings (4)
    private let rightTabs: [(Int, String, String)] = [
        (3, "chart.bar.xaxis",  "Analysis"),
        (4, "gearshape.fill",   "Settings")
    ]
    // Centre real tab: Mirror (2)
    // The FAB floats ABOVE this tab item; it is NOT a tab replacement.

    var body: some View {
        VStack(spacing: 0) {

            // ── Gold hairline separator ──
            LinearGradient(
                colors: [Color.gmGoldDim.opacity(0.5), Color.gmGold, Color.gmGoldDim.opacity(0.5)],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 0.5)

            // ── Bar body ──────────────────────────────────────────────────
            ZStack(alignment: .top) {

                // Solid opaque background – covers both bar content + home indicator
                Color.gmTabBackground
                    .frame(height: GMTabBarConstants.barContentHeight
                           + GMTabBarConstants.safeAreaBottom)

                // Tab items: left + centre (Mirror) + right
                HStack(alignment: .center, spacing: 0) {

                    ForEach(leftTabs, id: \.0) { tabItem($0, $1, $2) }

                    // Centre: Mirror tab – sits underneath the FAB overlay
                    tabItem(2, "person.2.fill", "Mirror")

                    ForEach(rightTabs, id: \.0) { tabItem($0, $1, $2) }
                }
                .frame(height: GMTabBarConstants.barContentHeight)
                .padding(.top, 6)

                // ── FAB: floats above the center of the bar ───────────────
                fabButton
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .offset(y: -(GMTabBarConstants.fabDiameter / 2 + GMTabBarConstants.fabLift))
            }
        }
        .shadow(color: Color.black.opacity(0.75), radius: 14, x: 0, y: -5)
    }

    // ── Single tab item ──────────────────────────────────────────────────
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
                            .fill(Color.gmGold.opacity(0.16))
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

    // ── Floating Action Button (+ income / expense entry) ────────────────
    private var fabButton: some View {
        Button(action: onFABTap) {
            ZStack {
                // Outer halo ring to visually lift FAB above bar
                Circle()
                    .fill(Color.gmTabBackground)
                    .frame(width: GMTabBarConstants.fabDiameter + 10,
                           height: GMTabBarConstants.fabDiameter + 10)

                // Gold gradient circle
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.gmGoldLight, Color.gmGold, Color.gmGoldDim],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: GMTabBarConstants.fabDiameter,
                           height: GMTabBarConstants.fabDiameter)
                    .shadow(color: Color.gmGold.opacity(0.6), radius: 12, x: 0, y: 4)

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
