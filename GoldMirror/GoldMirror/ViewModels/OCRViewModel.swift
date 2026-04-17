// MARK: - OCRViewModel.swift
// Gold Mirror – Vision OCR engine.
// Swift 6 concurrency safe: no @MainActor on class,
// background work done in a free function, UI updates via MainActor.run.

import SwiftUI
import Vision
import VisionKit
import Combine

// ─────────────────────────────────────────
// MARK: Free-function OCR helpers (no actor isolation)
// ─────────────────────────────────────────

/// Observations → joined string
private func ocrBuildText(_ obs: [VNRecognizedTextObservation]) -> String {
    obs.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
}

/// Build a fully populated OCRScanResult from raw text.
/// Pure function – safe to call from any context.
private func ocrBuildResult(
    documentType: TaxDocumentType,
    fullText: String,
    scannedAt: Date
) -> OCRScanResult {
    var r = OCRScanResult(
        id: UUID(),
        documentType: documentType,
        scannedAt: scannedAt,
        rawText: fullText,
        isConfirmed: false
    )
    ocrExtractFields(text: fullText, into: &r)
    return r
}

private func ocrExtractFields(text: String, into r: inout OCRScanResult) {
    let lines = text.components(separatedBy: "\n")
    for (i, line) in lines.enumerated() {
        let t = line.trimmingCharacters(in: .whitespaces)

        if ocrContains(t, ["支払金額","支払い金額","給与収入","年収","収入金額"]) {
            r.annualIncome = ocrNum(t) ?? (i+1 < lines.count ? ocrNum(lines[i+1]) : nil)
        }
        if ocrContains(t, ["所得控除の額の合計","所得控除合計","控除合計額"]) {
            r.deductionTotal = ocrNum(t) ?? (i+1 < lines.count ? ocrNum(lines[i+1]) : nil)
        }
        if ocrContains(t, ["源泉徴収税額","所得税","徴収税額","源泉税"]) {
            r.withholdingTax = ocrNum(t) ?? (i+1 < lines.count ? ocrNum(lines[i+1]) : nil)
        }
        if ocrContains(t, ["社会保険料","健康保険","厚生年金","雇用保険"]) {
            if let v = ocrNum(t) { r.socialInsurance = (r.socialInsurance ?? 0) + v }
        }
        if ocrContains(t, ["給与所得控除後","控除後の金額","課税給与所得"]) {
            if let v = ocrNum(t) { r.taxableIncome = v }
        }
        if ocrContains(t, ["生命保険料","生保控除"]) {
            if let v = ocrNum(t) { r.lifeInsuranceDeduction = v }
        }
    }
}

private func ocrContains(_ text: String, _ keywords: [String]) -> Bool {
    keywords.contains { text.contains($0) }
}

func ocrNum(_ text: String) -> Double? {
    let c = text
        .replacingOccurrences(of: ",", with: "")
        .replacingOccurrences(of: "，", with: "")
        .replacingOccurrences(of: "¥", with: "")
        .replacingOccurrences(of: "￥", with: "")
        .replacingOccurrences(of: " ", with: "")
    let pattern = #"(\d{5,})"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: c, range: NSRange(c.startIndex..., in: c)),
          let range = Range(match.range(at: 1), in: c) else { return nil }
    return Double(c[range])
}

// ─────────────────────────────────────────
// MARK: OCRViewModel  (ObservableObject, NOT @MainActor)
// UI-bound properties are updated via MainActor.run from background tasks.
// ─────────────────────────────────────────
final class OCRViewModel: ObservableObject {

    @Published var scanResult: OCRScanResult?
    @Published var isProcessing: Bool    = false
    @Published var errorMessage: String? = nil
    @Published var showReviewSheet: Bool = false
    @Published var userProfile: UserProfile = UserProfile()
    @Published var recognitionProgress: Double = 0.0

    // ── VisionKit availability ──
    var isScannerAvailable: Bool {
        DataScannerViewController.isSupported &&
        DataScannerViewController.isAvailable
    }

    // ─────────────────────────────────────────
    // MARK: Main entry – called from @MainActor SwiftUI views
    // ─────────────────────────────────────────
    @MainActor
    func recognizeText(from image: UIImage,
                       documentType: TaxDocumentType = .withholdingSlip) {
        guard let cgImage = image.cgImage else {
            errorMessage = "画像の変換に失敗しました"; return
        }
        isProcessing = true
        recognitionProgress = 0.0
        errorMessage = nil

        Task.detached(priority: .userInitiated) { [weak self] in
            // ── すべてバックグラウンド（nonisolated）で実行 ──
            let request = VNRecognizeTextRequest()
            request.recognitionLevel       = .accurate
            request.recognitionLanguages   = ["ja-JP", "en-US"]
            request.usesLanguageCorrection = true
            request.minimumTextHeight      = 0.01

            // progress handler – weak ref を別変数に保持してキャプチャ
            weak var weakSelf = self
            request.progressHandler = { _, progress, _ in
                Task { @MainActor in
                    weakSelf?.recognitionProgress = progress
                }
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                let obs      = request.results ?? []
                let text     = ocrBuildText(obs)
                let now      = Date()
                let result   = ocrBuildResult(
                    documentType: documentType,
                    fullText: text,
                    scannedAt: now
                )
                await MainActor.run {
                    weakSelf?.scanResult          = result
                    weakSelf?.isProcessing        = false
                    weakSelf?.recognitionProgress = 1.0
                    weakSelf?.showReviewSheet     = true
                }
            } catch {
                let msg = error.localizedDescription
                await MainActor.run {
                    weakSelf?.errorMessage = "テキスト認識エラー: \(msg)"
                    weakSelf?.isProcessing = false
                }
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: Confirm & Save
    // ─────────────────────────────────────────
    @MainActor
    func confirmAndSave(result: OCRScanResult) {
        var confirmed = result
        confirmed.isConfirmed = true
        if let v = confirmed.annualIncome   { userProfile.annualIncome   = v }
        if let v = confirmed.withholdingTax { userProfile.withholdingTax = v }
        if let v = confirmed.deductionTotal { userProfile.deductionTotal = v }
        userProfile.scanHistory.append(confirmed)
        scanResult      = confirmed
        showReviewSheet = false
    }
}
