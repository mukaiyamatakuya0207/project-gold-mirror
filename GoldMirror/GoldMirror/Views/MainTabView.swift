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
        case .analysis:  return "chart.bar.xaxis"
        case .settings:  return "gearshape.fill"
        }
    }
}

// ─────────────────────────────────────────
// MARK: Constants
// ─────────────────────────────────────────
enum GMTabBarConstants {
    static let barHeight:   CGFloat = 60
    static let fabDiameter: CGFloat = 62
    static let fabLift:     CGFloat = 14
}

// ─────────────────────────────────────────
// MARK: MainTabView
// ─────────────────────────────────────────
struct MainTabView: View {
    @StateObject private var viewModel  = AssetViewModel()
    @EnvironmentObject var dataManager:  DataManager
    @EnvironmentObject var ocrViewModel: OCRViewModel

    @State private var selectedTab: Int = 0
    @State private var showIncome       = false

    init() {
        // Hide the system-provided tab bar globally
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        GeometryReader { proxy in
            // VStack: content fills available space, bar is pinned at bottom
            VStack(spacing: 0) {

                // ── Tab content ──────────────────────────────────────────
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
                // Keep iOS state restoration; hides page dots
                .tabViewStyle(.automatic)
                // TabView takes all remaining space above the bar
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ── Custom Tab Bar (always at bottom) ────────────────────
                GMCustomTabBar(
                    selectedTab: $selectedTab,
                    bottomSafeArea: proxy.safeAreaInsets.bottom,
                    onFABTap: { showIncome = true }
                )
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        // Background fills entire screen including safe areas
        .background(Color.gmBackground.ignoresSafeArea())
        .environmentObject(viewModel)
        .sheet(isPresented: $showIncome) {
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
    let bottomSafeArea: CGFloat
    let onFABTap: () -> Void
    @Namespace private var pill

    private let leftTabs: [(Int, String, String)] = [
        (0, "square.grid.2x2.fill", "Dashboard"),
        (1, "calendar",             "Calendar")
    ]
    private let rightTabs: [(Int, String, String)] = [
        (3, "chart.bar.xaxis", "Analysis"),
        (4, "gearshape.fill",  "Settings")
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
                    ForEach(leftTabs, id: \.0)  { tabItem($0, $1, $2) }
                    tabItem(2, "person.2.fill", "Mirror")   // centre (real tab)
                    ForEach(rightTabs, id: \.0) { tabItem($0, $1, $2) }
                }
                .frame(height: GMTabBarConstants.barHeight)
                .padding(.top, 4)

                // FAB – raised above bar top edge
                fabButton
                    .frame(maxWidth: .infinity, alignment: .center)
                    .offset(y: -(GMTabBarConstants.fabDiameter / 2
                                 + GMTabBarConstants.fabLift))
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
                    .font(GMFont.caption(9, weight: sel ? .semibold : .regular))
                    .foregroundStyle(sel ? Color.gmGold : Color.gmTabInactive)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // ── FAB ──────────────────────────────────────────────────────────────
    private var fabButton: some View {
        Button(action: onFABTap) {
            ZStack {
                Circle()
                    .fill(Color.gmTabBackground)
                    .frame(width: GMTabBarConstants.fabDiameter + 8,
                           height: GMTabBarConstants.fabDiameter + 8)
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.gmGoldLight, Color.gmGold, Color.gmGoldDim],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: GMTabBarConstants.fabDiameter,
                           height: GMTabBarConstants.fabDiameter)
                    .shadow(color: Color.gmGold.opacity(0.55), radius: 10, x: 0, y: 3)
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
