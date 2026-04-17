// MARK: - MainTabView.swift
// Gold Mirror – Root tab container with custom gold tab bar.

import SwiftUI

// ─────────────────────────────────────────
// MARK: Tab Enum
// ─────────────────────────────────────────
enum GMTab: Int, CaseIterable {
    case dashboard = 0
    case calendar
    case mirror
    case analysis

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .calendar:  return "Calendar"
        case .mirror:    return "Mirror"
        case .analysis:  return "Analysis"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .calendar:  return "calendar"
        case .mirror:    return "person.2.fill"
        case .analysis:  return "chart.bar.xaxis"
        }
    }
}

// ─────────────────────────────────────────
// MARK: MainTabView
// ─────────────────────────────────────────
struct MainTabView: View {
    @StateObject private var viewModel = AssetViewModel()
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab: GMTab = .dashboard
    @Namespace private var tabAnimation

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Content Area ──
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(GMTab.dashboard)
                    .environmentObject(dataManager)

                CalendarView()
                    .tag(GMTab.calendar)
                    .environmentObject(dataManager)

                MirrorView()
                    .tag(GMTab.mirror)

                AnalysisView()
                    .tag(GMTab.analysis)
                    .environmentObject(dataManager)
            }
            // Hide default iOS tab bar – we use our custom one
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)

            // ── Custom Gold Tab Bar ──
            GMTabBar(selectedTab: $selectedTab, namespace: tabAnimation)
        }
        .environmentObject(viewModel)
        .background(Color.gmBackground)
        .preferredColorScheme(.dark)
    }
}

// ─────────────────────────────────────────
// MARK: Custom Tab Bar
// ─────────────────────────────────────────
struct GMTabBar: View {
    @Binding var selectedTab: GMTab
    var namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 0) {
            ForEach(GMTab.allCases, id: \.rawValue) { tab in
                GMTabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: namespace
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, GMSpacing.sm)
        .padding(.top, GMSpacing.md)
        .padding(.bottom, 28) // safe area padding
        .background(
            ZStack {
                Color.gmTabBackground

                // Top gold separator line
                VStack {
                    Rectangle()
                        .fill(GMGradient.goldHorizontal)
                        .frame(height: 0.5)
                    Spacer()
                }
            }
        )
        .shadow(color: Color.gmGold.opacity(0.08), radius: 20, x: 0, y: -8)
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
            VStack(spacing: GMSpacing.xs) {
                ZStack {
                    // Active background pill
                    if isSelected {
                        Capsule()
                            .fill(Color.gmGold.opacity(0.15))
                            .frame(width: 52, height: 32)
                            .matchedGeometryEffect(id: "tabBackground", in: namespace)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.gmGold : Color.gmTabInactive)
                        .frame(width: 52, height: 32)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }

                Text(tab.title)
                    .font(GMFont.caption(10, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.gmGold : Color.gmTabInactive)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
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
}
