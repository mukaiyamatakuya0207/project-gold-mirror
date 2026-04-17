// MARK: - OCRViewModel.swift
// Gold Mirror – Vision OCR engine.
// Swift 6 safe: OCRViewModel is @MainActor; heavy Vision work runs in a
// nonisolated async helper that returns a plain value (no self capture).

import SwiftUI
import Vision
import VisionKit
import Combine

// ─────────────────────────────────────────
// MARK: Notification names for OCR result delivery
// ─────────────────────────────────────────
extension Notification.Name {
    static let ocrDidFinish = Notification.Name("com.goldmirror.ocrDidFinish")
    static let ocrDidFail   = Notification.Name("com.goldmirror.ocrDidFail")
}

// ─────────────────────────────────────────
// MARK: Free-function helpers (nonisolated – safe from any context)
// ─────────────────────────────────────────

/// Run VNRecognizeTextRequest on a background thread and return the result.
/// This function is completely nonisolated (no actor boundary crossing).
private nonisolated func performOCR(
    cgImage: CGImage,
    documentType: TaxDocumentType
) throws -> OCRScanResult {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel       = .accurate
    request.recognitionLanguages   = ["ja-JP", "en-US"]
    request.usesLanguageCorrection = true
    request.minimumTextHeight      = 0.01

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try handler.perform([request])

    let obs  = request.results ?? []
    let text = obs.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    let now  = Date()

    var r = OCRScanResult(
        id: UUID(),
        documentType: documentType,
        scannedAt: now,
        rawText: text,
        isConfirmed: false
    )
    ocrExtractFields(text: text, into: &r)
    return r
}

private nonisolated func ocrExtractFields(text: String, into r: inout OCRScanResult) {
    let lines = text.components(separatedBy: "\n")
    for (i, line) in lines.enumerated() {
        let t = line.trimmingCharacters(in: .whitespaces)

        if ocrContains(t, ["支払金額", "支払い金額", "給与収入", "年収", "収入金額"]) {
            r.annualIncome = ocrNum(t) ?? (i + 1 < lines.count ? ocrNum(lines[i + 1]) : nil)
        }
        if ocrContains(t, ["所得控除の額の合計", "所得控除合計", "控除合計額"]) {
            r.deductionTotal = ocrNum(t) ?? (i + 1 < lines.count ? ocrNum(lines[i + 1]) : nil)
        }
        if ocrContains(t, ["源泉徴収税額", "所得税", "徴収税額", "源泉税"]) {
            r.withholdingTax = ocrNum(t) ?? (i + 1 < lines.count ? ocrNum(lines[i + 1]) : nil)
        }
        if ocrContains(t, ["社会保険料", "健康保険", "厚生年金", "雇用保険"]) {
            if let v = ocrNum(t) { r.socialInsurance = (r.socialInsurance ?? 0) + v }
        }
        if ocrContains(t, ["給与所得控除後", "控除後の金額", "課税給与所得"]) {
            if let v = ocrNum(t) { r.taxableIncome = v }
        }
        if ocrContains(t, ["生命保険料", "生保控除"]) {
            if let v = ocrNum(t) { r.lifeInsuranceDeduction = v }
        }
    }
}

private nonisolated func ocrContains(_ text: String, _ keywords: [String]) -> Bool {
    keywords.contains { text.contains($0) }
}

// Public so OCRReviewView and others can use it
nonisolated func ocrNum(_ text: String) -> Double? {
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
// MARK: OCRViewModel  (@MainActor ObservableObject)
// ─────────────────────────────────────────
@MainActor
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
    // MARK: Main entry – run Vision OCR off main thread
    // ─────────────────────────────────────────
    func recognizeText(from image: UIImage,
                       documentType: TaxDocumentType = .withholdingSlip) {
        guard let cgImage = image.cgImage else {
            errorMessage = "画像の変換に失敗しました"; return
        }
        isProcessing = true
        recognitionProgress = 0.0
        errorMessage = nil

        // Capture Sendable values before leaving MainActor
        let cg      = cgImage
        let docType = documentType

        Task {
            // Move blocking work off MainActor to a background thread
            let result = await Task.detached(priority: .userInitiated) {
                // nonisolated closure – no self capture
                try? performOCR(cgImage: cg, documentType: docType)
            }.value

            // Back on MainActor (Task inherits @MainActor from OCRViewModel)
            if let result {
                scanResult          = result
                isProcessing        = false
                recognitionProgress = 1.0
                showReviewSheet     = true
            } else {
                errorMessage = "テキストの認識に失敗しました"
                isProcessing = false
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: Confirm & Save
    // ─────────────────────────────────────────
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
