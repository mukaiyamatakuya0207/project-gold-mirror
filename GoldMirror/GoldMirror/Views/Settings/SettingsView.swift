// MARK: - SettingsView.swift
// Gold Mirror – Settings screen: notifications, profile, display, privacy.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dm: DataManager
    @EnvironmentObject var vm: AssetViewModel
    @EnvironmentObject var ocrVM: OCRViewModel
    @EnvironmentObject var securityManager: SecurityManager
    @StateObject private var nm = NotificationManager.shared

    @State private var showProfileEdit = false
    @AppStorage(DataManager.profileDisplayNameStorageKey) private var displayName = "Gold Mirror User"
    @AppStorage(DataManager.profileTaglineStorageKey) private var tagline = "資産形成を楽しもう"
    @AppStorage(DataManager.profileIsPublicStorageKey) private var isPublic = false
    @AppStorage(DataManager.profileGenderStorageKey) private var gender = "未設定"
    @AppStorage(DataManager.profileAgeStorageKey) private var age = 0
    @AppStorage(DataManager.profilePrefectureStorageKey) private var prefecture = "未設定"
    @AppStorage(DataManager.profileEmailStorageKey) private var email = ""
    @AppStorage(DataManager.profileStandardMonthlyRemunerationStorageKey) private var standardMonthlyRemuneration = 0.0
    @AppStorage(DataManager.profileDependentsCountStorageKey) private var dependentsCount = 0
    @AppStorage(DataManager.profileIncomeTaxCategoryStorageKey) private var incomeTaxCategory = "甲"
    @AppStorage(DataManager.profileResidentTaxAnnualStorageKey) private var residentTaxAnnual = 0.0
    @AppStorage(DataManager.profileResidentTaxMonthlyStorageKey) private var residentTaxMonthly = 0.0
    @AppStorage(DataManager.profileBaseMonthlySalaryStorageKey) private var baseMonthlySalary = 0.0
    @AppStorage(DataManager.profileFixedOvertimePayStorageKey) private var fixedOvertimePay = 0.0
    @AppStorage(DataManager.profileFixedOvertimeHoursStorageKey) private var fixedOvertimeHours = 0.0
    @AppStorage(DataManager.profileNonTaxableAllowanceStorageKey) private var nonTaxableAllowance = 0.0
    @State private var showDataExporter = false
    @State private var showDataImporter = false
    @State private var exportDocument = GoldMirrorDataDocument()
    @State private var pendingImportData: Data?
    @State private var showImportConfirm = false
    @State private var dataTransferMessage: String?

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

                    // ── Asset Management ──
                    SettingsSection(title: "資産管理", icon: "slider.horizontal.3") {
                        SettingsLinkRow(
                            icon: "building.columns.fill",
                            iconColor: .gmGold,
                            title: "銀行口座・証券口座",
                            subtitle: "残高・評価額を登録、編集、削除"
                        ) {
                            AssetAccountManagementView()
                                .environmentObject(dm)
                        }

                        GMSettingsDivider()

                        SettingsLinkRow(
                            icon: "creditcard.fill",
                            iconColor: .gmGold,
                            title: "カード管理",
                            subtitle: "カード引き落とし・締め日を管理"
                        ) {
                            CreditCardTrackerView()
                                .environmentObject(dm)
                                .environmentObject(vm)
                        }

                        GMSettingsDivider()

                        SettingsLinkRow(
                            icon: "play.rectangle.fill",
                            iconColor: Color(hex: "#CE93D8"),
                            title: "サブスク・固定費",
                            subtitle: "サブスク・毎月の支出を整理"
                        ) {
                            FixedCostManagerView()
                                .environmentObject(dm)
                        }

                        GMSettingsDivider()

                        SettingsLinkRow(
                            icon: "tag.fill",
                            iconColor: Color(hex: "#F0D060"),
                            title: "カテゴリ管理",
                            subtitle: "支出カテゴリの追加・編集・並び替え"
                        ) {
                            CategoryManagementView()
                                .environmentObject(dm)
                        }
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
                        SettingsToggleRow(
                            icon: "lock.fill",
                            iconColor: Color.gmGold,
                            title: "セキュリティ",
                            subtitle: "\(securityManager.biometryLabel)でアプリをロック",
                            isOn: Binding(
                                get: { securityManager.isBiometricEnabled },
                                set: { isEnabled in
                                    if isEnabled {
                                        securityManager.enableBiometricLock()
                                    } else {
                                        securityManager.disableBiometricLock()
                                    }
                                }
                            )
                        ) {}

                        GMSettingsDivider()

                        SettingsLinkRow(
                            icon: "doc.viewfinder.fill",
                            iconColor: Color.gmGold,
                            title: "書類スキャン",
                            subtitle: "レシート・税務書類をOCRで読み取り"
                        ) {
                            DocumentScannerView()
                                .environmentObject(ocrVM)
                                .environmentObject(dm)
                        }

                        GMSettingsDivider()

                        SettingsNavigationRow(
                            icon: "icloud.fill",
                            iconColor: Color(hex: "#4FC3F7"),
                            title: "データ書き出し",
                            subtitle: ".gmdataファイルとして保存"
                        ) {
                            exportCurrentData()
                        }

                        GMSettingsDivider()

                        SettingsNavigationRow(
                            icon: "square.and.arrow.down.fill",
                            iconColor: Color(hex: "#4FC3F7"),
                            title: "データ読み込み",
                            subtitle: ".gmdataファイルから復元"
                        ) {
                            showDataImporter = true
                        }

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

                    Spacer().frame(height: 28)  // FAB overhang above bar top edge
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showProfileEdit) {
            ProfileEditSheet(
                displayName: $displayName,
                tagline: $tagline,
                gender: $gender,
                age: $age,
                prefecture: $prefecture,
                email: $email,
                standardMonthlyRemuneration: $standardMonthlyRemuneration,
                dependentsCount: $dependentsCount,
                incomeTaxCategory: $incomeTaxCategory,
                residentTaxAnnual: $residentTaxAnnual,
                residentTaxMonthly: $residentTaxMonthly,
                baseMonthlySalary: $baseMonthlySalary,
                fixedOvertimePay: $fixedOvertimePay,
                fixedOvertimeHours: $fixedOvertimeHours,
                nonTaxableAllowance: $nonTaxableAllowance
            )
            .environmentObject(dm)
        }
        .overlay(alignment: .top) {
            SettingsPageHeader()
        }
        .alert("セキュリティエラー", isPresented: .init(
            get: { securityManager.errorMessage != nil },
            set: { if !$0 { securityManager.errorMessage = nil } }
        )) {
            Button("OK") { securityManager.errorMessage = nil }
        } message: {
            Text(securityManager.errorMessage ?? "")
        }
        .fileExporter(
            isPresented: $showDataExporter,
            document: exportDocument,
            contentType: .goldMirrorData,
            defaultFilename: defaultExportFilename
        ) { result in
            switch result {
            case .success:
                dataTransferMessage = "データを書き出しました。"
            case .failure(let error):
                dataTransferMessage = "書き出しに失敗しました: \(error.localizedDescription)"
            }
        }
        .fileImporter(
            isPresented: $showDataImporter,
            allowedContentTypes: [.goldMirrorData],
            allowsMultipleSelection: false
        ) { result in
            handleImportSelection(result)
        }
        .alert("現在のデータは上書きされますがよろしいですか？", isPresented: $showImportConfirm) {
            Button("キャンセル", role: .cancel) {
                pendingImportData = nil
            }
            Button("読み込む", role: .destructive) {
                importPendingData()
            }
        } message: {
            Text("銀行・証券口座、カード、収支履歴、カテゴリ設定などが.gmdataファイルの内容に置き換わります。")
        }
        .alert("データ移行", isPresented: .init(
            get: { dataTransferMessage != nil },
            set: { if !$0 { dataTransferMessage = nil } }
        )) {
            Button("OK") { dataTransferMessage = nil }
        } message: {
            Text(dataTransferMessage ?? "")
        }
    }

    private var defaultExportFilename: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return "GoldMirror-\(formatter.string(from: Date())).gmdata"
    }

    private func exportCurrentData() {
        do {
            exportDocument = GoldMirrorDataDocument(data: try dm.exportGMData())
            showDataExporter = true
        } catch {
            dataTransferMessage = "書き出しデータの作成に失敗しました: \(error.localizedDescription)"
        }
    }

    private func handleImportSelection(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let canAccess = url.startAccessingSecurityScopedResource()
            defer {
                if canAccess { url.stopAccessingSecurityScopedResource() }
            }
            pendingImportData = try Data(contentsOf: url)
            showImportConfirm = true
        } catch {
            dataTransferMessage = "読み込みに失敗しました: \(error.localizedDescription)"
        }
    }

    private func importPendingData() {
        guard let pendingImportData else { return }
        do {
            try dm.importGMData(pendingImportData)
            self.pendingImportData = nil
            dataTransferMessage = "データを読み込みました。"
        } catch {
            self.pendingImportData = nil
            dataTransferMessage = "データの解析に失敗しました: \(error.localizedDescription)"
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
                .contentShape(Circle())
            }
            .contentShape(Rectangle())
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, GMSpacing.xs)
        .contentShape(Rectangle())
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, GMSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SettingsLinkRow<Destination: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, GMSpacing.xs)
            .contentShape(Rectangle())
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
    @EnvironmentObject var dm: DataManager
    @Binding var displayName: String
    @Binding var tagline: String
    @Binding var gender: String
    @Binding var age: Int
    @Binding var prefecture: String
    @Binding var email: String
    @Binding var standardMonthlyRemuneration: Double
    @Binding var dependentsCount: Int
    @Binding var incomeTaxCategory: String
    @Binding var residentTaxAnnual: Double
    @Binding var residentTaxMonthly: Double
    @Binding var baseMonthlySalary: Double
    @Binding var fixedOvertimePay: Double
    @Binding var fixedOvertimeHours: Double
    @Binding var nonTaxableAllowance: Double
    @Environment(\.dismiss) private var dismiss

    @State private var localName: String    = ""
    @State private var localTagline: String = ""
    @State private var localGender: String = "未設定"
    @State private var localAgeText: String = ""
    @State private var localPrefecture: String = "未設定"
    @State private var localEmail: String = ""
    @State private var localStandardMonthlyRemunerationText: String = ""
    @State private var localDependentsCountText: String = ""
    @State private var localIncomeTaxCategory: String = "甲"
    @State private var localResidentTaxAnnualText: String = ""
    @State private var localResidentTaxMonthlyText: String = ""
    @State private var localBaseMonthlySalaryText: String = ""
    @State private var localFixedOvertimePayText: String = ""
    @State private var localFixedOvertimeHoursText: String = ""
    @State private var localNonTaxableAllowanceText: String = ""

    private let genders = ["未設定", "女性", "男性", "その他", "回答しない"]
    private let incomeTaxCategories = ["甲", "乙"]
    private let prefectures = [
        "未設定", "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県",
        "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県",
        "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県", "岐阜県",
        "静岡県", "愛知県", "三重県", "滋賀県", "京都府", "大阪府", "兵庫県",
        "奈良県", "和歌山県", "鳥取県", "島根県", "岡山県", "広島県", "山口県",
        "徳島県", "香川県", "愛媛県", "高知県", "福岡県", "佐賀県", "長崎県",
        "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県"
    ]

    private var salaryPreview: DataManager.SalaryCalculationResult {
        dm.salaryEstimate(
            baseMonthlySalary: doubleValue(localBaseMonthlySalaryText),
            fixedOvertimePay: doubleValue(localFixedOvertimePayText),
            fixedOvertimeHours: doubleValue(localFixedOvertimeHoursText),
            nonTaxableAllowance: doubleValue(localNonTaxableAllowanceText),
            standardMonthlyRemuneration: doubleValue(localStandardMonthlyRemunerationText),
            dependentsCount: intValue(localDependentsCountText),
            incomeTaxCategory: localIncomeTaxCategory,
            residentTaxAnnual: doubleValue(localResidentTaxAnnualText),
            residentTaxMonthly: doubleValue(localResidentTaxMonthlyText),
            prefecture: localPrefecture,
            overtimeHours: doubleValue(localFixedOvertimeHoursText),
            lateNightHours: 0
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gmBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: GMSpacing.lg) {
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

                            GMInputSection(title: "自己紹介", icon: "text.quote") {
                                TextField("一言メッセージ", text: $localTagline)
                                    .font(GMFont.body(15))
                                    .foregroundStyle(Color.gmTextPrimary)
                                    .tint(Color.gmGold)
                            }

                            GMInputSection(title: "性別", icon: "person.2.fill") {
                                Picker("性別", selection: $localGender) {
                                    ForEach(genders, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu)
                                .tint(Color.gmGold)
                            }

                            GMInputSection(title: "年齢", icon: "calendar") {
                                TextField("年齢", text: $localAgeText)
                                    .font(GMFont.body(15))
                                    .foregroundStyle(Color.gmTextPrimary)
                                    .keyboardType(.numberPad)
                                    .tint(Color.gmGold)
                            }

                            GMInputSection(title: "居住地", icon: "mappin.and.ellipse") {
                                Picker("都道府県", selection: $localPrefecture) {
                                    ForEach(prefectures, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu)
                                .tint(Color.gmGold)
                            }

                            GMInputSection(title: "メールアドレス", icon: "envelope.fill") {
                                TextField("name@example.com", text: $localEmail)
                                    .font(GMFont.body(15))
                                    .foregroundStyle(Color.gmTextPrimary)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .tint(Color.gmGold)
                            }

                            GMInputSection(title: "月給（基本給）", icon: "briefcase.fill") {
                                TextField("0", text: $localBaseMonthlySalaryText)
                                    .font(GMFont.body(15))
                                    .foregroundStyle(Color.gmTextPrimary)
                                    .keyboardType(.numberPad)
                                    .tint(Color.gmGold)
                            }

                            GMInputSection(title: "固定残業代", icon: "clock.badge.fill") {
                                TextField("0", text: $localFixedOvertimePayText)
                                    .font(GMFont.body(15))
                                    .foregroundStyle(Color.gmTextPrimary)
                                    .keyboardType(.numberPad)
                                    .tint(Color.gmGold)
                            }

                            GMInputSection(title: "固定残業時間", icon: "timer") {
                                TextField("例：40", text: $localFixedOvertimeHoursText)
                                    .font(GMFont.body(15))
                                    .foregroundStyle(Color.gmTextPrimary)
                                    .keyboardType(.decimalPad)
                                    .tint(Color.gmGold)
                            }

                            GMInputSection(title: "非課税手当", icon: "tram.fill") {
                                TextField("通勤手当など", text: $localNonTaxableAllowanceText)
                                    .font(GMFont.body(15))
                                    .foregroundStyle(Color.gmTextPrimary)
                                    .keyboardType(.numberPad)
                                    .tint(Color.gmGold)
                            }

                            GMInputSection(title: "標準報酬月額", icon: "yensign.circle.fill") {
                                TextField("健康保険・厚生年金の標準報酬月額", text: $localStandardMonthlyRemunerationText)
                                    .font(GMFont.body(15))
                                    .foregroundStyle(Color.gmTextPrimary)
                                    .keyboardType(.numberPad)
                                    .tint(Color.gmGold)
                            }

                            GMInputSection(title: "扶養親族の数", icon: "person.3.fill") {
                                TextField("0", text: $localDependentsCountText)
                                    .font(GMFont.body(15))
                                    .foregroundStyle(Color.gmTextPrimary)
                                    .keyboardType(.numberPad)
                                    .tint(Color.gmGold)
                            }

                            GMInputSection(title: "所得税区分", icon: "doc.text.fill") {
                                Picker("所得税区分", selection: $localIncomeTaxCategory) {
                                    ForEach(incomeTaxCategories, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.segmented)
                                .tint(Color.gmGold)
                            }

                            GMInputSection(title: "住民税（年額）", icon: "building.columns.fill") {
                                TextField("0", text: $localResidentTaxAnnualText)
                                    .font(GMFont.body(15))
                                    .foregroundStyle(Color.gmTextPrimary)
                                    .keyboardType(.numberPad)
                                    .tint(Color.gmGold)
                            }

                            GMInputSection(title: "住民税（月額）", icon: "calendar.badge.clock") {
                                TextField("0", text: $localResidentTaxMonthlyText)
                                    .font(GMFont.body(15))
                                    .foregroundStyle(Color.gmTextPrimary)
                                    .keyboardType(.numberPad)
                                    .tint(Color.gmGold)
                            }

                            ProfileSalaryPreviewCard(result: salaryPreview)
                        }
                        .padding(.horizontal, GMSpacing.md)

                        Button {
                            save()
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
                .scrollDismissesKeyboard(.interactively)
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
            populate()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.gmBackground)
    }

    private func populate() {
        localName = displayName
        localTagline = tagline
        localGender = gender
        localAgeText = age > 0 ? "\(age)" : ""
        localPrefecture = prefecture
        localEmail = email
        localStandardMonthlyRemunerationText = standardMonthlyRemuneration > 0 ? "\(Int(standardMonthlyRemuneration))" : ""
        localDependentsCountText = dependentsCount > 0 ? "\(dependentsCount)" : ""
        localIncomeTaxCategory = incomeTaxCategory
        localResidentTaxAnnualText = residentTaxAnnual > 0 ? "\(Int(residentTaxAnnual))" : ""
        localResidentTaxMonthlyText = residentTaxMonthly > 0 ? "\(Int(residentTaxMonthly))" : ""
        localBaseMonthlySalaryText = baseMonthlySalary > 0 ? "\(Int(baseMonthlySalary))" : ""
        localFixedOvertimePayText = fixedOvertimePay > 0 ? "\(Int(fixedOvertimePay))" : ""
        localFixedOvertimeHoursText = fixedOvertimeHours > 0 ? decimalText(fixedOvertimeHours) : ""
        localNonTaxableAllowanceText = nonTaxableAllowance > 0 ? "\(Int(nonTaxableAllowance))" : ""
    }

    private func save() {
        displayName = localName.trimmingCharacters(in: .whitespacesAndNewlines)
        tagline = localTagline.trimmingCharacters(in: .whitespacesAndNewlines)
        gender = localGender
        age = Int(localAgeText.replacingOccurrences(of: ",", with: "")) ?? 0
        prefecture = localPrefecture
        email = localEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        standardMonthlyRemuneration = Double(localStandardMonthlyRemunerationText.replacingOccurrences(of: ",", with: "")) ?? 0
        dependentsCount = Int(localDependentsCountText.replacingOccurrences(of: ",", with: "")) ?? 0
        incomeTaxCategory = localIncomeTaxCategory
        residentTaxAnnual = Double(localResidentTaxAnnualText.replacingOccurrences(of: ",", with: "")) ?? 0
        residentTaxMonthly = Double(localResidentTaxMonthlyText.replacingOccurrences(of: ",", with: "")) ?? 0
        baseMonthlySalary = doubleValue(localBaseMonthlySalaryText)
        fixedOvertimePay = doubleValue(localFixedOvertimePayText)
        fixedOvertimeHours = doubleValue(localFixedOvertimeHoursText)
        nonTaxableAllowance = doubleValue(localNonTaxableAllowanceText)
        dismiss()
    }

    private func doubleValue(_ text: String) -> Double {
        Double(text.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private func intValue(_ text: String) -> Int {
        Int(text.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private func decimalText(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : "\(value)"
    }
}

private struct ProfileSalaryPreviewCard: View {
    let result: DataManager.SalaryCalculationResult

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Image(systemName: "function")
                    .foregroundStyle(Color.gmGold)
                Text("給与・控除プレビュー")
                    .font(GMFont.heading(14, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
                Spacer()
            }

            ProfileSalaryPreviewRow(label: "想定総支給", value: result.grossPay.jpyFormatted, highlight: true)
            ProfileSalaryPreviewRow(label: "時間単価", value: result.hourlyRate.jpyFormatted)
            ProfileSalaryPreviewRow(label: "健康保険料", value: result.healthInsurancePremium.jpyFormatted)
            ProfileSalaryPreviewRow(label: "厚生年金保険料", value: result.welfarePensionPremium.jpyFormatted)
            ProfileSalaryPreviewRow(label: "所得税（概算）", value: result.estimatedIncomeTax.jpyFormatted)
            ProfileSalaryPreviewRow(label: "住民税（月額）", value: result.residentTaxMonthly.jpyFormatted)

            Divider()
                .background(Color.gmGoldDim.opacity(0.35))

            ProfileSalaryPreviewRow(label: "推定手取り", value: result.estimatedNetPay.jpyFormatted, highlight: true)
        }
        .padding(GMSpacing.md)
        .background(Color.gmSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GMRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: GMRadius.md)
                .strokeBorder(Color.gmGoldDim.opacity(0.35), lineWidth: 0.7)
        )
    }
}

private struct ProfileSalaryPreviewRow: View {
    let label: String
    let value: String
    var highlight = false

    var body: some View {
        HStack {
            Text(label)
                .font(GMFont.caption(11, weight: .medium))
                .foregroundStyle(Color.gmTextTertiary)
            Spacer()
            Text(value)
                .font(GMFont.mono(highlight ? 15 : 13, weight: .bold))
                .foregroundStyle(highlight ? Color.gmGold : Color.gmTextPrimary)
        }
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
            .environmentObject(OCRViewModel())
            .environmentObject(SecurityManager())
    }
}
