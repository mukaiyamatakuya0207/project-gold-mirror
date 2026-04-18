// MARK: - MainTabView.swift
// Gold Mirror – Root tab container.
// Uses standard TabView (state preservation) with a custom gold overlay tab bar.

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
    @StateObject private var viewModel   = AssetViewModel()
    @EnvironmentObject var dataManager:  DataManager
    @EnvironmentObject var ocrViewModel: OCRViewModel

    @State private var selectedTab: Int = 0
    @State private var showFAB = true
    @State private var showIncomeExpenseSheet = false

    // Height used by child views for bottom padding
    static let tabBarHeight: CGFloat = 82

    var body: some View {
        ZStack(alignment: .bottom) {

            // ── Standard TabView (keeps view state alive across tab switches) ──
            TabView(selection: $selectedTab) {

                // Tab 0 – Dashboard
                NavigationStack {
                    DashboardView()
                        .environmentObject(viewModel)
                        .environmentObject(dataManager)
                }
                .tag(0)

                // Tab 1 – Calendar
                NavigationStack {
                    WealthCalendarView()
                        .environmentObject(dataManager)
                }
                .tag(1)

                // Tab 2 – Mirror
                NavigationStack {
                    MirrorView()
                        .environmentObject(viewModel)
                        .environmentObject(ocrViewModel)
                }
                .tag(2)

                // Tab 3 – Analysis
                NavigationStack {
                    AnalysisView()
                        .environmentObject(viewModel)
                        .environmentObject(dataManager)
                        .environmentObject(ocrViewModel)
                }
                .tag(3)

                // Tab 4 – Settings
                NavigationStack {
                    SettingsView()
                        .environmentObject(dataManager)
                        .environmentObject(viewModel)
                }
                .tag(4)
            }
            // Hide the system tab bar completely
            .tabViewStyle(.page(indexDisplayMode: .never))
            // Allow content to extend behind our custom tab bar using safeAreaInset
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: MainTabView.tabBarHeight)
            }
            .ignoresSafeArea(edges: .bottom)

            // ── Custom Gold Tab Bar ──
            GMCustomTabBar(
                selectedTab: $selectedTab,
                onFABTap: { showIncomeExpenseSheet = true }
            )
        }
        .environmentObject(viewModel)
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showIncomeExpenseSheet) {
            IncomeExpenseInputView()
                .environmentObject(dataManager)
        }
    }
}

// ─────────────────────────────────────────
// MARK: Custom Gold Tab Bar
// ─────────────────────────────────────────
struct GMCustomTabBar: View {
    @Binding var selectedTab: Int
    let onFABTap: () -> Void
    @Namespace private var animation

    // Tab definitions: (tag, icon, label)
    private let leftTabs:  [(Int, String, String)] = [(0, "square.grid.2x2.fill", "Dashboard"),
                                                       (1, "calendar", "Calendar")]
    private let rightTabs: [(Int, String, String)] = [(2, "person.2.fill", "Mirror"),
                                                       (3, "chart.bar.xaxis", "Analysis"),
                                                       (4, "gearshape.fill", "Settings")]

    var body: some View {
        VStack(spacing: 0) {
            // Top gold hairline
            Rectangle()
                .fill(GMGradient.goldHorizontal)
                .frame(height: 0.5)

            ZStack {
                // Solid background (no transparency)
                Color.gmTabBackground

                HStack(alignment: .bottom, spacing: 0) {
                    // Left side tabs
                    ForEach(leftTabs, id: \.0) { tag, icon, label in
                        tabItem(tag: tag, icon: icon, label: label)
                    }

                    // FAB centre slot
                    Spacer().frame(width: 70)

                    // Right side tabs
                    ForEach(rightTabs, id: \.0) { tag, icon, label in
                        tabItem(tag: tag, icon: icon, label: label)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, safeAreaBottom())

                // FAB – centred, elevated
                fabButton()
                    .offset(y: -14)
            }
            .frame(height: MainTabView.tabBarHeight + safeAreaBottom())
        }
        .shadow(color: Color.black.opacity(0.55), radius: 20, x: 0, y: -6)
    }

    // ── Individual tab item ──
    @ViewBuilder
    private func tabItem(tag: Int, icon: String, label: String) -> some View {
        let isSelected = selectedTab == tag
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(Color.gmGold.opacity(0.18))
                            .frame(width: 46, height: 28)
                            .matchedGeometryEffect(id: "pill", in: animation)
                    }
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.gmGold : Color.gmTabInactive)
                        .frame(width: 46, height: 28)
                }
                Text(label)
                    .font(GMFont.caption(9, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.gmGold : Color.gmTabInactive)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // ── FAB button ──
    @ViewBuilder
    private func fabButton() -> some View {
        Button(action: onFABTap) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.gmGoldLight, Color.gmGold, Color.gmGoldDim],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.gmGold.opacity(0.5), radius: 12, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.gmBackground)
            }
        }
        .buttonStyle(.plain)
    }

    private func safeAreaBottom() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
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
