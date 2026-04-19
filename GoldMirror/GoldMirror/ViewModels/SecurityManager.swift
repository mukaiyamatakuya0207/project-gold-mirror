// MARK: - SecurityManager.swift
// Gold Mirror – Biometric app lock.

import SwiftUI
import LocalAuthentication
import Combine

@MainActor
final class SecurityManager: ObservableObject {
    private let enabledKey = "GoldMirror.security.biometricEnabled"

    @Published private(set) var isBiometricEnabled: Bool
    @Published private(set) var isAuthenticated: Bool
    @Published var errorMessage: String?

    var isLocked: Bool {
        isBiometricEnabled && !isAuthenticated
    }

    var biometryLabel: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "生体認証"
        }
    }

    init() {
        let enabled = UserDefaults.standard.bool(forKey: enabledKey)
        isBiometricEnabled = enabled
        isAuthenticated = !enabled
    }

    func lockIfNeeded() {
        guard isBiometricEnabled else {
            isAuthenticated = true
            return
        }
        isAuthenticated = false
    }

    func enableBiometricLock() {
        authenticate(reason: "Gold Mirrorを保護するために生体認証を使用します。") { [weak self] success, message in
            guard let self else { return }
            if success {
                self.isBiometricEnabled = true
                self.isAuthenticated = true
                UserDefaults.standard.set(true, forKey: self.enabledKey)
            } else {
                self.isBiometricEnabled = false
                self.isAuthenticated = true
                UserDefaults.standard.set(false, forKey: self.enabledKey)
                self.errorMessage = message ?? "生体認証を有効にできませんでした。"
            }
        }
    }

    func disableBiometricLock() {
        isBiometricEnabled = false
        isAuthenticated = true
        UserDefaults.standard.set(false, forKey: enabledKey)
    }

    func unlock() {
        authenticate(reason: "Gold Mirrorを開くには認証してください。") { [weak self] success, message in
            guard let self else { return }
            if success {
                self.isAuthenticated = true
            } else {
                self.errorMessage = message ?? "認証に失敗しました。"
            }
        }
    }

    private func authenticate(
        reason: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let context = LAContext()
        context.localizedCancelTitle = "キャンセル"
        var authError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            let message = authError?.localizedDescription ?? "この端末ではFace ID / Touch IDを使用できません。"
            completion(false, message)
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                completion(success, error?.localizedDescription)
            }
        }
    }
}

struct GoldMirrorSecureRootView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var securityManager: SecurityManager
    @State private var pendingImportData: Data?
    @State private var showImportConfirm = false
    @State private var importMessage: String?

    var body: some View {
        ZStack {
            MainTabView()
                .opacity(securityManager.isLocked ? 0 : 1)
                .allowsHitTesting(!securityManager.isLocked)

            if securityManager.isLocked {
                SecurityLockView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: securityManager.isLocked)
        .onAppear {
            securityManager.lockIfNeeded()
        }
        .onOpenURL { url in
            loadExternalGMData(from: url)
        }
        .alert("現在のデータは上書きされますがよろしいですか？", isPresented: $showImportConfirm) {
            Button("キャンセル", role: .cancel) {
                pendingImportData = nil
            }
            Button("読み込む", role: .destructive) {
                importExternalData()
            }
        } message: {
            Text("開いた.gmdataファイルの内容で、現在のGold Mirrorデータを置き換えます。")
        }
        .alert("データ読み込み", isPresented: .init(
            get: { importMessage != nil },
            set: { if !$0 { importMessage = nil } }
        )) {
            Button("OK") { importMessage = nil }
        } message: {
            Text(importMessage ?? "")
        }
    }

    private func loadExternalGMData(from url: URL) {
        guard url.pathExtension.lowercased() == "gmdata" else { return }
        do {
            let canAccess = url.startAccessingSecurityScopedResource()
            defer {
                if canAccess { url.stopAccessingSecurityScopedResource() }
            }
            pendingImportData = try Data(contentsOf: url)
            showImportConfirm = true
        } catch {
            importMessage = "ファイルを読み込めませんでした: \(error.localizedDescription)"
        }
    }

    private func importExternalData() {
        guard let pendingImportData else { return }
        do {
            try dataManager.importGMData(pendingImportData)
            self.pendingImportData = nil
            importMessage = "データを読み込みました。"
        } catch {
            self.pendingImportData = nil
            importMessage = "データの解析に失敗しました: \(error.localizedDescription)"
        }
    }
}

struct SecurityLockView: View {
    @EnvironmentObject var securityManager: SecurityManager

    var body: some View {
        ZStack {
            Color.gmBackground.ignoresSafeArea()

            VStack(spacing: GMSpacing.xl) {
                Spacer()

                VStack(spacing: GMSpacing.lg) {
                    ZStack {
                        Circle()
                            .fill(Color.gmGold.opacity(0.12))
                            .frame(width: 108, height: 108)
                        Circle()
                            .strokeBorder(GMGradient.goldHorizontal, lineWidth: 1.2)
                            .frame(width: 108, height: 108)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(GMGradient.goldHorizontal)
                    }
                    .gmGoldGlow(radius: 22, opacity: 0.35)

                    VStack(spacing: GMSpacing.xs) {
                        Text("Gold Mirror Lock")
                            .font(GMFont.display(28, weight: .bold))
                            .foregroundStyle(GMGradient.goldHorizontal)
                        Text("\(securityManager.biometryLabel)で資産情報を保護しています")
                            .font(GMFont.body(14, weight: .medium))
                            .foregroundStyle(Color.gmTextTertiary)
                            .multilineTextAlignment(.center)
                    }
                }

                Button {
                    securityManager.unlock()
                } label: {
                    HStack(spacing: GMSpacing.sm) {
                        Image(systemName: "faceid")
                            .font(.system(size: 18, weight: .semibold))
                        Text("認証して開く")
                            .font(GMFont.heading(16, weight: .bold))
                    }
                    .foregroundStyle(Color.gmBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(GMGradient.goldHorizontal)
                    .clipShape(RoundedRectangle(cornerRadius: GMRadius.lg))
                    .shadow(color: Color.gmGold.opacity(0.35), radius: 14, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .padding(.horizontal, GMSpacing.xl)

                Spacer()

                Text("Gold Mirror")
                    .font(GMFont.caption(12, weight: .semibold))
                    .foregroundStyle(Color.gmGold.opacity(0.65))
                    .tracking(3)
                    .padding(.bottom, GMSpacing.lg)
            }
        }
        .alert("認証エラー", isPresented: .init(
            get: { securityManager.errorMessage != nil },
            set: { if !$0 { securityManager.errorMessage = nil } }
        )) {
            Button("OK") { securityManager.errorMessage = nil }
        } message: {
            Text(securityManager.errorMessage ?? "")
        }
    }
}
