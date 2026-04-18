// MARK: - MainTabView.swift
// Gold Mirror – Root tab container.
// Standard TabView + fully opaque custom tab bar with centre FAB.

import SwiftUI

// ─────────────────────────────────────────
// MARK: Tab Enum  (4 real tabs + FAB centre slot)
// ─────────────────────────────────────────
enum GMTab: Int, CaseIterable {
    case dashboard = 0
    case calendar  = 1
    // index 2 is the FAB slot (no content tab)
    case analysis  = 3
    case settings  = 4

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .calendar:  return "Calendar"
        case .analysis:  return "Analysis"
        case .settings:  return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .calendar:  return "calendar"
        case .analysis:  return "chart.bar.xaxis"
        case .settings:  return "gearshape.fill"
        }
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

            // ── TabView: 4 real tabs (tags 0,1,3,4) ──
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
            .tabViewStyle(.page(indexDisplayMode: .never))
            // Reserve space so scroll content never hides behind tab bar
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: GMTabBarConstants.totalHeight)
            }
            .ignoresSafeArea(edges: .bottom)

            // ── Custom Tab Bar ──
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
// MARK: Layout Constants
// ─────────────────────────────────────────
enum GMTabBarConstants {
    static let barContentHeight: CGFloat = 60   // icon + label area
    static let fabDiameter:      CGFloat = 58   // FAB circle size
    static let fabLift:          CGFloat = 20   // how far FAB rises above bar top edge

    // safeAreaBottom is device-specific; read at runtime
    static var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }

    // Total height reserved at bottom of screen
    static var totalHeight: CGFloat {
        barContentHeight + safeAreaBottom
    }
}

// ─────────────────────────────────────────
// MARK: GMCustomTabBar
// ─────────────────────────────────────────
struct GMCustomTabBar: View {
    @Binding var selectedTab: Int
    let onFABTap: () -> Void
    @Namespace private var pill

    private let leftTabs:  [(Int, String, String)] = [
        (0, "square.grid.2x2.fill", "Dashboard"),
        (1, "calendar",             "Calendar")
    ]
    private let rightTabs: [(Int, String, String)] = [
        (3, "chart.bar.xaxis",  "Analysis"),
        (4, "gearshape.fill",   "Settings")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // ── Top gold hairline ──
            LinearGradient(
                colors: [Color.gmGoldDim.opacity(0.6), Color.gmGold, Color.gmGoldDim.opacity(0.6)],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 0.5)

            // ── Bar body + FAB overlay ──
            ZStack(alignment: .top) {

                // Solid opaque background that also covers home-indicator area
                Color.gmTabBackground
                    .frame(height: GMTabBarConstants.barContentHeight
                           + GMTabBarConstants.safeAreaBottom)

                // Tab items row
                HStack(alignment: .center, spacing: 0) {
                    ForEach(leftTabs, id: \.0) { tabItem($0, $1, $2) }

                    // Centre slot – same width as one tab item, reserved for FAB
                    Color.clear.frame(maxWidth: .infinity)

                    ForEach(rightTabs, id: \.0) { tabItem($0, $1, $2) }
                }
                .frame(height: GMTabBarConstants.barContentHeight)
                .padding(.top, 6)

                // FAB – positioned at horizontal centre, lifted above bar top
                fabButton
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, -(GMTabBarConstants.fabDiameter / 2
                                     + GMTabBarConstants.fabLift))
            }
        }
        // Shadow upward only
        .shadow(color: Color.black.opacity(0.7), radius: 12, x: 0, y: -4)
    }

    // ── Single tab item ──
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

    // ── FAB ──
    private var fabButton: some View {
        Button(action: onFABTap) {
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(Color.gmTabBackground)
                    .frame(width: GMTabBarConstants.fabDiameter + 8,
                           height: GMTabBarConstants.fabDiameter + 8)

                Circle()
                    .fill(LinearGradient(
                        colors: [Color.gmGoldLight, Color.gmGold, Color.gmGoldDim],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: GMTabBarConstants.fabDiameter,
                           height: GMTabBarConstants.fabDiameter)
                    .shadow(color: Color.gmGold.opacity(0.55), radius: 10, x: 0, y: 3)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
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
