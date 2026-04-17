// MARK: - DocumentScannerView.swift
// Gold Mirror – VisionKit document scanner with gold-themed UI.
// Uses DataScannerViewController wrapped in UIViewControllerRepresentable.

import SwiftUI
import VisionKit
import Vision

// ─────────────────────────────────────────
// MARK: Main Scanner Entry View
// ─────────────────────────────────────────
struct DocumentScannerView: View {
    @EnvironmentObject var ocrVM: OCRViewModel
    @State private var showImagePicker = false
    @State private var showLiveScanner = false
    @State private var selectedDocType: TaxDocumentType = .withholdingSlip
    @State private var animatePulse = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gmBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: GMSpacing.lg) {

                        // ── Header ──
                        ScannerPageHeader()

                        // ── Document Type Picker ──
                        DocTypePicker(selected: $selectedDocType)
                            .padding(.horizontal, GMSpacing.md)

                        // ── Scan Zone ──
                        ScanZoneView(
                            animatePulse: $animatePulse,
                            isProcessing: ocrVM.isProcessing,
                            progress: ocrVM.recognitionProgress,
                            onCamera: {
                                if ocrVM.isScannerAvailable {
                                    showLiveScanner = true
                                } else {
                                    showImagePicker = true
                                }
                            },
                            onLibrary: {
                                showImagePicker = true
                            }
                        )
                        .padding(.horizontal, GMSpacing.md)
                        .onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever()) { animatePulse = true } }

                        // ── Extraction Guide ──
                        ExtractionGuideCard()
                            .padding(.horizontal, GMSpacing.md)

                        // ── Scan History ──
                        if !ocrVM.userProfile.scanHistory.isEmpty {
                            ScanHistoryCard(
                                history: ocrVM.userProfile.scanHistory,
                                profile: ocrVM.userProfile
                            )
                            .padding(.horizontal, GMSpacing.md)
                        }

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, GMSpacing.md)
                }
            }
            .navigationBarHidden(true)
            // Image picker
            .sheet(isPresented: $showImagePicker) {
                GMImagePicker(onSelect: { image in
                    ocrVM.recognizeText(from: image, documentType: selectedDocType)
                })
            }
            // Live scanner
            .fullScreenCover(isPresented: $showLiveScanner) {
                LiveDocumentScanner(
                    docType: selectedDocType,
                    onCapture: { image in
                        showLiveScanner = false
                        ocrVM.recognizeText(from: image, documentType: selectedDocType)
                    }
                )
            }
            // Review sheet
            .sheet(isPresented: $ocrVM.showReviewSheet) {
                if let result = ocrVM.scanResult {
                    OCRReviewView(
                        result: result,
                        onConfirm: { confirmed in
                            ocrVM.confirmAndSave(result: confirmed)
                        }
                    )
                    .environmentObject(ocrVM)
                }
            }
            // Error alert
            .alert("スキャンエラー", isPresented: .init(
                get: { ocrVM.errorMessage != nil },
                set: { if !$0 { ocrVM.errorMessage = nil } }
            )) {
                Button("OK") { ocrVM.errorMessage = nil }
            } message: {
                Text(ocrVM.errorMessage ?? "")
            }
        }
    }
}

// ─────────────────────────────────────────
// MARK: Scanner Page Header
// ─────────────────────────────────────────
struct ScannerPageHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SMART SCAN")
                    .font(GMFont.caption(11, weight: .bold))
                    .foregroundStyle(Color.gmGold.opacity(0.7)).tracking(3)
                Text("書類スキャナー")
                    .font(GMFont.heading(22, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
            }
            Spacer()
            Image(systemName: "doc.viewfinder.fill")
                .font(.system(size: 24)).foregroundStyle(Color.gmGold)
        }
        .padding(.horizontal, GMSpacing.md)
    }
}

// ─────────────────────────────────────────
// MARK: Document Type Picker
// ─────────────────────────────────────────
struct DocTypePicker: View {
    @Binding var selected: TaxDocumentType
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GMSpacing.sm) {
                ForEach(TaxDocumentType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selected = type
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.system(size: 13, weight: .semibold))
                            Text(type.rawValue)
                                .font(GMFont.caption(12, weight: .semibold))
                        }
                        .foregroundStyle(selected == type ? Color.black : Color.gmTextSecondary)
                        .padding(.horizontal, GMSpacing.md)
                        .padding(.vertical, GMSpacing.sm)
                        .background(
                            selected == type
                            ? AnyShapeStyle(GMGradient.goldHorizontal)
                            : AnyShapeStyle(Color.gmSurface)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(
                                selected == type ? Color.clear : Color.gmGoldDim.opacity(0.4),
                                lineWidth: 0.5
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

// ─────────────────────────────────────────
// MARK: Scan Zone View
// ─────────────────────────────────────────
struct ScanZoneView: View {
    @Binding var animatePulse: Bool
    let isProcessing: Bool
    let progress: Double
    let onCamera: () -> Void
    let onLibrary: () -> Void

    var body: some View {
        ZStack {
            // Border frame
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .stroke(
                    animatePulse && !isProcessing
                    ? Color.gmGold.opacity(0.7) : Color.gmGoldDim.opacity(0.4),
                    style: StrokeStyle(lineWidth: isProcessing ? 2 : 1.5, dash: isProcessing ? [] : [10, 6])
                )
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                           value: animatePulse)

            // Background
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .fill(isProcessing
                      ? Color.gmGold.opacity(0.04)
                      : Color.gmSurface)

            if isProcessing {
                // Processing state
                VStack(spacing: GMSpacing.lg) {
                    ZStack {
                        Circle()
                            .stroke(Color.gmGoldDim.opacity(0.3), lineWidth: 4)
                            .frame(width: 80, height: 80)
                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(Color.gmGold,
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 80, height: 80)
                            .animation(.linear(duration: 0.3), value: progress)
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.gmGold)
                    }
                    .gmGoldGlow(radius: 16, opacity: 0.4)

                    VStack(spacing: GMSpacing.xs) {
                        Text("テキストを認識中...")
                            .font(GMFont.heading(16, weight: .semibold))
                            .foregroundStyle(Color.gmTextPrimary)
                        Text("\(Int(progress * 100))% 完了")
                            .font(GMFont.caption(12))
                            .foregroundStyle(Color.gmGold)
                    }
                }
            } else {
                // Idle state
                VStack(spacing: GMSpacing.lg) {
                    ZStack {
                        Circle()
                            .fill(Color.gmGold.opacity(0.1))
                            .frame(width: 90, height: 90)
                        Image(systemName: "viewfinder")
                            .font(.system(size: 42, weight: .thin))
                            .foregroundStyle(Color.gmGold)
                    }
                    .gmGoldGlow(radius: 16, opacity: 0.25)

                    VStack(spacing: GMSpacing.xs) {
                        Text("書類をスキャン")
                            .font(GMFont.heading(18, weight: .bold))
                            .foregroundStyle(Color.gmTextPrimary)
                        Text("源泉徴収票・確定申告書に対応")
                            .font(GMFont.body(13))
                            .foregroundStyle(Color.gmTextTertiary)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: GMSpacing.md) {
                        // Camera button
                        Button(action: onCamera) {
                            HStack(spacing: GMSpacing.xs) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("カメラで撮影")
                                    .font(GMFont.body(14, weight: .semibold))
                            }
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, GMSpacing.lg)
                            .padding(.vertical, GMSpacing.sm)
                            .background(GMGradient.goldHorizontal)
                            .clipShape(Capsule())
                        }
                        .gmGoldGlow(radius: 12, opacity: 0.4)

                        // Library button
                        Button(action: onLibrary) {
                            HStack(spacing: GMSpacing.xs) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 14))
                                Text("ライブラリ")
                                    .font(GMFont.body(14, weight: .medium))
                            }
                            .foregroundStyle(Color.gmGold)
                            .padding(.horizontal, GMSpacing.md)
                            .padding(.vertical, GMSpacing.sm)
                            .background(Color.gmGold.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.gmGold.opacity(0.4), lineWidth: 0.8))
                        }
                    }
                }
                .padding(GMSpacing.xl)
            }
        }
        .frame(height: 300)
    }
}

// ─────────────────────────────────────────
// MARK: Extraction Guide Card
// ─────────────────────────────────────────
struct ExtractionGuideCard: View {
    private let items = [
        ("yensign.circle.fill", "支払金額（年収）", "給与収入の総額"),
        ("arrow.down.circle.fill", "所得控除の合計額", "各種控除の合算"),
        ("banknote.fill", "源泉徴収税額", "天引きされた所得税"),
        ("cross.circle.fill", "社会保険料等", "健康保険・厚生年金"),
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Image(systemName: "text.magnifyingglass")
                    .foregroundStyle(Color.gmGold)
                Text("自動抽出する項目")
                    .font(GMFont.heading(14, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                      spacing: GMSpacing.sm) {
                ForEach(items, id: \.1) { item in
                    HStack(spacing: GMSpacing.sm) {
                        Image(systemName: item.0)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.gmGold)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.1)
                                .font(GMFont.caption(11, weight: .medium))
                                .foregroundStyle(Color.gmTextPrimary)
                            Text(item.2)
                                .font(GMFont.caption(9))
                                .foregroundStyle(Color.gmTextTertiary)
                        }
                    }
                    .padding(GMSpacing.sm)
                    .gmCardStyle(elevated: true)
                }
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Scan History Card
// ─────────────────────────────────────────
struct ScanHistoryCard: View {
    let history: [OCRScanResult]
    let profile: UserProfile
    private var confirmed: [OCRScanResult] { history.filter { $0.isConfirmed }.reversed() }
    private let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy/MM/dd HH:mm"; return f
    }()
    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(Color.gmGold)
                Text("スキャン履歴")
                    .font(GMFont.heading(14, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
            }
            ForEach(confirmed.prefix(3)) { result in
                HStack(spacing: GMSpacing.sm) {
                    Image(systemName: result.documentType.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.gmGold)
                        .frame(width: 36, height: 36)
                        .background(Color.gmGold.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: GMRadius.sm))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.documentType.rawValue)
                            .font(GMFont.body(13, weight: .medium))
                            .foregroundStyle(Color.gmTextPrimary)
                        Text(dateFmt.string(from: result.scannedAt))
                            .font(GMFont.caption(10))
                            .foregroundStyle(Color.gmTextTertiary)
                    }
                    Spacer()
                    if let income = result.annualIncome {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(income.jpyCompact)
                                .font(GMFont.mono(13, weight: .bold))
                                .foregroundStyle(Color.gmTextPrimary)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.gmPositive)
                        }
                    }
                }
            }
            // Income rank badge
            if let income = profile.annualIncome {
                HStack(spacing: GMSpacing.sm) {
                    Text(profile.incomeRank.badge)
                        .font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("年収ランク: \(profile.incomeRank.rawValue)")
                            .font(GMFont.body(14, weight: .bold))
                            .foregroundStyle(profile.incomeRank.color)
                        Text(profile.incomeRank.topPercent)
                            .font(GMFont.caption(11))
                            .foregroundStyle(Color.gmTextTertiary)
                    }
                    Spacer()
                    Text(income.jpyCompact)
                        .font(GMFont.mono(14, weight: .bold))
                        .foregroundStyle(Color.gmTextPrimary)
                }
                .padding(GMSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: GMRadius.md)
                        .fill(profile.incomeRank.color.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: GMRadius.md)
                            .stroke(profile.incomeRank.color.opacity(0.3), lineWidth: 0.6))
                )
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Live Document Scanner (VisionKit)
// ─────────────────────────────────────────
struct LiveDocumentScanner: UIViewControllerRepresentable {
    let docType: TaxDocumentType
    let onCapture: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    func makeUIViewController(context: Context) -> UIViewController {
        guard DataScannerViewController.isSupported && DataScannerViewController.isAvailable else {
            // フォールバック：シンプルなカメラピッカー
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = context.coordinator
            return picker
        }

        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator

        // ゴールドテーマのオーバーレイ
        scanner.overlayContainerView.subviews.forEach { $0.removeFromSuperview() }
        let overlay = ScannerOverlayView()
        overlay.frame = scanner.overlayContainerView.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scanner.overlayContainerView.addSubview(overlay)

        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, DataScannerViewControllerDelegate,
                       UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }

        // DataScanner: アイテムタップ時にビューをスナップショット撮影
        func dataScanner(_ dataScanner: DataScannerViewController,
                         didTapOn item: RecognizedItem) {
            // DataScannerViewController のビューをレンダリングして UIImage に変換
            let view = dataScanner.view
            let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
            let image = renderer.image { _ in
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            }
            DispatchQueue.main.async { self.onCapture(image) }
        }

        // UIImagePicker fallback
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                picker.dismiss(animated: true) { self.onCapture(image) }
            }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// ─────────────────────────────────────────
// MARK: Scanner Overlay View (Gold UI)
// ─────────────────────────────────────────
class ScannerOverlayView: UIView {
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        // 半透明の暗い背景
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.35).cgColor)
        ctx.fill(rect)

        // ガイド枠
        let inset: CGFloat = 32
        let guideRect = CGRect(x: inset, y: rect.height * 0.15,
                               width: rect.width - inset * 2,
                               height: rect.height * 0.55)
        ctx.clear(guideRect)

        // ゴールドのコーナー
        let gold = UIColor(red: 212/255, green: 175/255, blue: 55/255, alpha: 1)
        ctx.setStrokeColor(gold.cgColor)
        ctx.setLineWidth(2.5)
        ctx.setLineCap(.round)
        let corner: CGFloat = 24
        let len: CGFloat = 36
        // 四隅を描画
        for (x, y, sx, sy) in [
            (guideRect.minX, guideRect.minY, 1, 1),
            (guideRect.maxX, guideRect.minY, -1, 1),
            (guideRect.minX, guideRect.maxY, 1, -1),
            (guideRect.maxX, guideRect.maxY, -1, -1),
        ] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
            ctx.move(to: CGPoint(x: x, y: y + sy * corner))
            ctx.addLine(to: CGPoint(x: x, y: y))
            ctx.addLine(to: CGPoint(x: x + sx * len, y: y))
            ctx.strokePath()
        }

        // ラベル
        let label = "書類全体を枠内に収めてください" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: gold,
            .font: UIFont.systemFont(ofSize: 13, weight: .medium)
        ]
        let size = label.size(withAttributes: attrs)
        label.draw(at: CGPoint(x: (rect.width - size.width) / 2,
                               y: guideRect.maxY + 16),
                   withAttributes: attrs)
    }
}

// ─────────────────────────────────────────
// MARK: Image Picker (PhotoLibrary)
// ─────────────────────────────────────────
struct GMImagePicker: UIViewControllerRepresentable {
    let onSelect: (UIImage) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onSelect: onSelect) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onSelect: (UIImage) -> Void
        init(onSelect: @escaping (UIImage) -> Void) { self.onSelect = onSelect }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage {
                picker.dismiss(animated: true) { self.onSelect(img) }
            } else { picker.dismiss(animated: true) }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    DocumentScannerView()
        .environmentObject(OCRViewModel())
}
