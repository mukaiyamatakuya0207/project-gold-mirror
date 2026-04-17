// MARK: - NotificationHistoryView.swift
// Gold Mirror – Notification history sheet triggered from bell icon.

import SwiftUI

struct NotificationHistoryView: View {
    @StateObject private var nm = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gmBackground.ignoresSafeArea()

                if nm.history.isEmpty {
                    VStack(spacing: GMSpacing.lg) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.gmGoldDim)
                        Text("通知はありません")
                            .font(GMFont.heading(16, weight: .medium))
                            .foregroundStyle(Color.gmTextSecondary)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: GMSpacing.sm) {
                            ForEach(nm.history) { item in
                                NotificationRow(item: item)
                            }
                        }
                        .padding(.horizontal, GMSpacing.md)
                        .padding(.top, GMSpacing.sm)
                        .padding(.bottom, GMSpacing.xl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: GMSpacing.xs) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.gmGold)
                        Text("通知")
                            .font(GMFont.heading(16, weight: .semibold))
                            .foregroundStyle(GMGradient.goldHorizontal)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { nm.markAllRead() } label: {
                        Text("全既読")
                            .font(GMFont.caption(12))
                            .foregroundStyle(Color.gmGold)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.gmTextTertiary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.gmBackground)
        .onAppear { nm.markAllRead() }
    }
}

// ─────────────────────────────────────────
// MARK: Notification Row
// ─────────────────────────────────────────
struct NotificationRow: View {
    let item: GMNotificationItem

    var body: some View {
        HStack(alignment: .top, spacing: GMSpacing.md) {
            // Unread indicator
            Circle()
                .fill(item.isRead ? Color.clear : Color.gmGold)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(GMFont.body(14, weight: item.isRead ? .regular : .semibold))
                    .foregroundStyle(item.isRead ? Color.gmTextSecondary : Color.gmTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.body)
                    .font(GMFont.caption(12))
                    .foregroundStyle(Color.gmTextTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.timeAgoString)
                    .font(GMFont.caption(11))
                    .foregroundStyle(Color.gmGold.opacity(0.6))
            }
        }
        .padding(GMSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: GMRadius.md)
                .fill(item.isRead ? Color.gmSurface : Color(hex: "#1A1500"))
                .overlay(
                    RoundedRectangle(cornerRadius: GMRadius.md)
                        .strokeBorder(
                            item.isRead ? Color.gmGoldDim.opacity(0.15) : Color.gmGold.opacity(0.35),
                            lineWidth: 0.8
                        )
                )
        )
    }
}

#Preview {
    NotificationHistoryView()
}
