// MARK: - SettingsView.swift
// Gold Mirror – Settings screen: notifications, profile, display, privacy.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dm: DataManager
    @EnvironmentObject var vm: AssetViewModel
    @StateObject private var nm = NotificationManager.shared

    @State private var showProfileEdit = false
    @State private var displayName     = "Gold Mirror User"
    @State private var tagline         = "資産形成を楽しもう"
    @State private var isPublic        = false

    var body: some View {
        ZStack {
            Color.gmBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: GMSpacing.lg) {

                    // ── Profile Card ──
                    SettingsProfileCard(
                        displayName: displayName,
                        tagline: tagline,
                        isPublic: $isPublic,
                        onEdit: { showProfileEdit = true }
                    )
                    .padding(.horizontal, GMSpacing.md)
                    .padding(.top, 100) // clearance for SettingsPageHeader overlay

                    // ── Notification Settings ──
                    SettingsSection(title: "通知設定", icon: "bell.fill") {
                        SettingsToggleRow(
                            icon: "bell.fill",
                            iconColor: .gmGold,
                            title: "プッシュ通知",
                            subtitle: "すべての通知をオン/オフ",
                            isOn: $nm.settings.enabled
                        ) { nm.saveSettings() }

                        GMSettingsDivider()

                        SettingsToggleRow(
                            icon: "calendar.badge.clock",
                            iconColor: Color(hex: "#4FC3F7"),
                            title: "1週間前に通知",
                            subtitle: "クレジットカード引き落とし7日前",
                            isOn: $nm.settings.sevenDaysBefore
                        ) { nm.saveSettings() }
                        .disabled(!nm.settings.enabled)
                        .opacity(nm.settings.enabled ? 1 : 0.45)

                        GMSettingsDivider()

                        SettingsToggleRow(
                            icon: "clock.badge.exclamationmark",
                            iconColor: Color(hex: "#FFB74D"),
                            title: "3日前に通知",
                            subtitle: "クレジットカード引き落とし3日前",
                            isOn: $nm.settings.threeDaysBefore
                        ) { nm.saveSettings() }
                        .disabled(!nm.settings.enabled)
                        .opacity(nm.settings.enabled ? 1 : 0.45)

                        GMSettingsDivider()

                        SettingsToggleRow(
                            icon: "bell.badge.fill",
                            iconColor: Color.gmNegative,
                            title: "前日に通知",
                            subtitle: "クレジットカード引き落とし前日",
                            isOn: $nm.settings.oneDayBefore
                        ) { nm.saveSettings() }
                        .disabled(!nm.settings.enabled)
                        .opacity(nm.settings.enabled ? 1 : 0.45)

                        GMSettingsDivider()

                        Button {
                            Task {
                                await nm.requestPermission()
                                await nm.scheduleAllBillingNotifications(cards: dm.creditCards)
                            }
                        } label: {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gmGold.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Color.gmGold)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("通知を再スケジュール")
                                        .font(GMFont.body(14, weight: .medium))
                                        .foregroundStyle(Color.gmTextPrimary)
                                    Text("全カードの引き落とし通知を更新")
                                        .font(GMFont.caption(11))
                                        .foregroundStyle(Color.gmTextTertiary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.gmTextTertiary)
                            }
                            .padding(.vertical, GMSpacing.xs)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, GMSpacing.md)

                    // ── Profile / SNS Settings ──
                    SettingsSection(title: "プロフィール設定", icon: "person.fill") {
                        SettingsNavigationRow(
                            icon: "pencil.circle.fill",
                            iconColor: Color(hex: "#CE93D8"),
                            title: "名前・自己紹介を編集",
                            subtitle: displayName
                        ) { showProfileEdit = true }

                        GMSettingsDivider()

                        SettingsToggleRow(
                            icon: "globe",
                            iconColor: Color(hex: "#4FC3F7"),
                            title: "Mirrorで公開",
                            subtitle: "資産情報をコミュニティに共有",
                            isOn: $isPublic
                        ) {}

                        GMSettingsDivider()

                        // Income rank display
                        HStack(spacing: GMSpacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gmGold.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.gmGold)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("収入ランク")
                                    .font(GMFont.body(14, weight: .medium))
                                    .foregroundStyle(Color.gmTextPrimary)
                                Text("OCRスキャンで自動判定")
                                    .font(GMFont.caption(11))
                                    .foregroundStyle(Color.gmTextTertiary)
                            }
                            Spacer()
                            Text("未設定")
                                .font(GMFont.caption(12, weight: .semibold))
                                .foregroundStyle(Color.gmGoldDim)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.gmGold.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, GMSpacing.xs)
                    }
                    .padding(.horizontal, GMSpacing.md)

                    // ── App Settings ──
                    SettingsSection(title: "アプリ設定", icon: "gearshape.fill") {
                        SettingsNavigationRow(
                            icon: "lock.fill",
                            iconColor: Color.gmGold,
                            title: "セキュリティ",
                            subtitle: "Face ID / Touch ID"
                        ) {}

                        GMSettingsDivider()

                        SettingsNavigationRow(
                            icon: "icloud.fill",
                            iconColor: Color(hex: "#4FC3F7"),
                            title: "データバックアップ",
                            subtitle: "iCloud に同期"
                        ) {}

                        GMSettingsDivider()

                        SettingsNavigationRow(
                            icon: "trash.fill",
                            iconColor: Color.gmNegative,
                            title: "データを削除",
                            subtitle: "すべての記録を初期化"
                        ) {}
                    }
                    .padding(.horizontal, GMSpacing.md)

                    // ── App info ──
                    VStack(spacing: 4) {
                        Text("Gold Mirror")
                            .font(GMFont.heading(14, weight: .semibold))
                            .foregroundStyle(GMGradient.goldHorizontal)
                        Text("Version 1.0.0")
                            .font(GMFont.caption(11))
                            .foregroundStyle(Color.gmTextTertiary)
                    }
                    .padding(.vertical, GMSpacing.lg)

                    Spacer().frame(height: 120)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showProfileEdit) {
            ProfileEditSheet(displayName: $displayName, tagline: $tagline)
        }
        .overlay(alignment: .top) {
            SettingsPageHeader()
        }
    }
}

// ─────────────────────────────────────────
// MARK: Settings Page Header
// ─────────────────────────────────────────
struct SettingsPageHeader: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0F0D03"), Color.gmBackground],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
            .frame(height: 90)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SETTINGS")
                        .font(GMFont.caption(11, weight: .semibold))
                        .foregroundStyle(Color.gmGold.opacity(0.7))
                        .tracking(3)
                    Text("設定")
                        .font(GMFont.display(24, weight: .bold))
                        .foregroundStyle(GMGradient.goldHorizontal)
                }
                Spacer()
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.gmGold.opacity(0.5))
            }
            .padding(.horizontal, GMSpacing.md)
            .padding(.top, GMSpacing.md)
        }
        .frame(height: 90)
    }
}

// ─────────────────────────────────────────
// MARK: Profile Card
// ─────────────────────────────────────────
struct SettingsProfileCard: View {
    let displayName: String
    let tagline: String
    @Binding var isPublic: Bool
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: GMSpacing.md) {
            HStack(spacing: GMSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.gmGoldDim, Color.gmGold],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 64, height: 64)
                    Text(String(displayName.prefix(1)))
                        .font(GMFont.display(28, weight: .bold))
                        .foregroundStyle(Color.gmBackground)
                }
                .gmGoldGlow(radius: 10, opacity: 0.35)

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(GMFont.heading(17, weight: .bold))
                        .foregroundStyle(Color.gmTextPrimary)
                    Text(tagline)
                        .font(GMFont.caption(12))
                        .foregroundStyle(Color.gmTextTertiary)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(isPublic ? Color.gmPositive : Color.gmTextTertiary)
                            .frame(width: 6, height: 6)
                        Text(isPublic ? "公開中" : "非公開")
                            .font(GMFont.caption(11))
                            .foregroundStyle(isPublic ? Color.gmPositive : Color.gmTextTertiary)
                    }
                }

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.gmGold)
                        .frame(width: 36, height: 36)
                        .background(Color.gmGold.opacity(0.12))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gmGoldDim.opacity(0.4), lineWidth: 0.8))
                }
            }
        }
        .padding(GMSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .fill(LinearGradient(
                    colors: [Color(hex: "#1A1500"), Color.gmSurface],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.gmGold.opacity(0.5), Color.gmGoldDim.opacity(0.15)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .gmGoldGlow(radius: 14, opacity: 0.15)
    }
}

// ─────────────────────────────────────────
// MARK: Settings Section Container
// ─────────────────────────────────────────
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack(spacing: GMSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.gmGold)
                Text(title)
                    .font(GMFont.caption(12, weight: .semibold))
                    .foregroundStyle(Color.gmTextTertiary)
                    .tracking(1)
            }
            .padding(.leading, GMSpacing.xs)

            VStack(spacing: 0) {
                content()
                    .padding(.horizontal, GMSpacing.md)
                    .padding(.vertical, GMSpacing.sm)
            }
            .background(Color.gmSurface)
            .clipShape(RoundedRectangle(cornerRadius: GMRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: GMRadius.lg)
                    .strokeBorder(Color.gmGoldDim.opacity(0.2), lineWidth: 0.5)
            )
        }
    }
}

// ─────────────────────────────────────────
// MARK: Reusable Row Types
// ─────────────────────────────────────────
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: GMSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(GMFont.body(14, weight: .medium))
                    .foregroundStyle(Color.gmTextPrimary)
                Text(subtitle)
                    .font(GMFont.caption(11))
                    .foregroundStyle(Color.gmTextTertiary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Color.gmGold)
                .labelsHidden()
                .onChange(of: isOn) { _, _ in onChange() }
        }
        .padding(.vertical, GMSpacing.xs)
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: GMSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(GMFont.body(14, weight: .medium))
                        .foregroundStyle(Color.gmTextPrimary)
                    Text(subtitle)
                        .font(GMFont.caption(11))
                        .foregroundStyle(Color.gmTextTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.gmTextTertiary)
            }
            .padding(.vertical, GMSpacing.xs)
        }
        .buttonStyle(.plain)
    }
}

struct GMSettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.gmGoldDim.opacity(0.15))
            .frame(height: 0.5)
            .padding(.leading, 48)
    }
}

// ─────────────────────────────────────────
// MARK: Profile Edit Sheet
// ─────────────────────────────────────────
struct ProfileEditSheet: View {
    @Binding var displayName: String
    @Binding var tagline: String
    @Environment(\.dismiss) private var dismiss

    @State private var localName: String    = ""
    @State private var localTagline: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gmBackground.ignoresSafeArea()

                VStack(spacing: GMSpacing.lg) {
                    // Avatar preview
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.gmGoldDim, Color.gmGold],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                        Text(String(localName.prefix(1).uppercased()))
                            .font(GMFont.display(36, weight: .bold))
                            .foregroundStyle(Color.gmBackground)
                    }
                    .gmGoldGlow(radius: 14, opacity: 0.4)
                    .padding(.top, GMSpacing.xl)

                    VStack(spacing: GMSpacing.md) {
                        GMInputSection(title: "表示名", icon: "person.fill") {
                            TextField("名前を入力", text: $localName)
                                .font(GMFont.body(15))
                                .foregroundStyle(Color.gmTextPrimary)
                                .tint(Color.gmGold)
                        }
                        .padding(.horizontal, GMSpacing.md)

                        GMInputSection(title: "自己紹介", icon: "text.quote") {
                            TextField("一言メッセージ", text: $localTagline)
                                .font(GMFont.body(15))
                                .foregroundStyle(Color.gmTextPrimary)
                                .tint(Color.gmGold)
                        }
                        .padding(.horizontal, GMSpacing.md)
                    }

                    Spacer()

                    Button {
                        displayName = localName
                        tagline     = localTagline
                        dismiss()
                    } label: {
                        Text("保存する")
                            .font(GMFont.heading(16, weight: .bold))
                            .foregroundStyle(Color.gmBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient(
                                colors: [Color.gmGoldLight, Color.gmGold],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .clipShape(RoundedRectangle(cornerRadius: GMRadius.lg))
                            .shadow(color: Color.gmGold.opacity(0.4), radius: 10, x: 0, y: 4)
                    }
                    .padding(.horizontal, GMSpacing.md)
                    .padding(.bottom, GMSpacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("プロフィール編集")
                        .font(GMFont.heading(16, weight: .semibold))
                        .foregroundStyle(GMGradient.goldHorizontal)
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
        .onAppear {
            localName    = displayName
            localTagline = tagline
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.gmBackground)
    }
}

// ─────────────────────────────────────────
// MARK: Preview
// ─────────────────────────────────────────
#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(DataManager())
            .environmentObject(AssetViewModel())
    }
}
