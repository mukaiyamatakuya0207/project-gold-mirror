// MARK: - OCRViewModel.swift
// Gold Mirror – Vision & VisionKit OCR engine.
// Handles document scanning, text recognition, and financial field extraction.
//
// Swift 6 concurrency fixes:
//  - buildFullText / extractFields are nonisolated (pure functions, no actor state)
//  - Task.detached uses value-type local copy of result (no inout capture)

import SwiftUI
import Vision
import VisionKit
import Combine

// ─────────────────────────────────────────
// MARK: OCR ViewModel
// ─────────────────────────────────────────
@MainActor
final class OCRViewModel: ObservableObject {

    // ── State ──
    @Published var scanResult: OCRScanResult?
    @Published var isScanning: Bool      = false
    @Published var isProcessing: Bool    = false
    @Published var errorMessage: String? = nil
    @Published var showReviewSheet: Bool = false
    @Published var showScanner: Bool     = false

    // ── User Profile ──
    @Published var userProfile: UserProfile = UserProfile()

    // ── Recognition Progress (0.0 〜 1.0) ──
    @Published var recognitionProgress: Double = 0.0

    // ─────────────────────────────────────────
    // MARK: Scan from UIImage (Vision VNRecognizeTextRequest)
    // ─────────────────────────────────────────
    func recognizeText(from image: UIImage, documentType: TaxDocumentType = .withholdingSlip) {
        guard let cgImage = image.cgImage else {
            errorMessage = "画像の変換に失敗しました"
            return
        }

        isProcessing = true
        recognitionProgress = 0.0
        errorMessage = nil

        // ── バックグラウンドタスク ──
        // NOTE: Task.detached 内では @MainActor の self を直接操作できないため
        //       await MainActor.run { } を使って UI 更新をメインスレッドに戻す。
        //       inout 引数は並行コード内でキャプチャできないため、
        //       OCRScanResult をローカル var で扱い完成後に返す。
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let request = VNRecognizeTextRequest()
            request.recognitionLevel       = .accurate
            request.recognitionLanguages   = ["ja-JP", "en-US"]
            request.usesLanguageCorrection = true
            request.minimumTextHeight      = 0.01

            // プログレス通知（weak self でキャプチャ）
            request.progressHandler = { [weak self] _, progress, _ in
                guard let self else { return }
                Task { @MainActor in
                    self.recognitionProgress = progress
                }
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                let observations = request.results ?? []

                // ── 純粋関数（nonisolated）で処理 ──
                let fullText = OCRViewModel.buildFullText(from: observations)
                let result   = OCRViewModel.buildScanResult(
                    documentType: documentType,
                    fullText: fullText
                )

                await MainActor.run {
                    self.scanResult          = result
                    self.isProcessing        = false
                    self.recognitionProgress = 1.0
                    self.showReviewSheet     = true
                }
            } catch {
                let msg = error.localizedDescription
                await MainActor.run {
                    self.errorMessage = "テキスト認識エラー: \(msg)"
                    self.isProcessing = false
                }
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: Build Full Text from Observations
    // nonisolated = MainActor の外（バックグラウンド）から呼び出し可能
    // ─────────────────────────────────────────
    nonisolated static func buildFullText(from observations: [VNRecognizedTextObservation]) -> String {
        observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }

    // ─────────────────────────────────────────
    // MARK: Build OCRScanResult (value-type, no inout)
    // ─────────────────────────────────────────
    nonisolated static func buildScanResult(
        documentType: TaxDocumentType,
        fullText: String
    ) -> OCRScanResult {
        // ローカル変数として構築し、完成後に返す（inout キャプチャを避ける）
        var result = OCRScanResult(
            documentType: documentType,
            scannedAt: Date(),
            rawText: fullText,
            isConfirmed: false
        )
        extractFields(from: fullText, into: &result)
        return result
    }

    // ─────────────────────────────────────────
    // MARK: Field Extraction Logic (nonisolated)
    // ─────────────────────────────────────────
    nonisolated static func extractFields(from text: String, into result: inout OCRScanResult) {
        let lines = text.components(separatedBy: "\n")

        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // ── 支払金額（年収）──
            if containsAny(trimmed, keywords: ["支払金額","支払い金額","給与収入","年収","収入金額"]) {
                if let amount = extractNumber(from: trimmed) {
                    result.annualIncome = amount
                } else if i + 1 < lines.count,
                          let amount = extractNumber(from: lines[i + 1]) {
                    result.annualIncome = amount
                }
            }

            // ── 所得控除の額の合計 ──
            if containsAny(trimmed, keywords: ["所得控除の額の合計","所得控除合計","控除合計額"]) {
                if let amount = extractNumber(from: trimmed) {
                    result.deductionTotal = amount
                } else if i + 1 < lines.count,
                          let amount = extractNumber(from: lines[i + 1]) {
                    result.deductionTotal = amount
                }
            }

            // ── 源泉徴収税額 ──
            if containsAny(trimmed, keywords: ["源泉徴収税額","所得税","徴収税額","源泉税"]) {
                if let amount = extractNumber(from: trimmed) {
                    result.withholdingTax = amount
                } else if i + 1 < lines.count,
                          let amount = extractNumber(from: lines[i + 1]) {
                    result.withholdingTax = amount
                }
            }

            // ── 社会保険料 ──
            if containsAny(trimmed, keywords: ["社会保険料","健康保険","厚生年金","雇用保険"]) {
                if let amount = extractNumber(from: trimmed) {
                    result.socialInsurance = (result.socialInsurance ?? 0) + amount
                }
            }

            // ── 給与所得控除後の金額 ──
            if containsAny(trimmed, keywords: ["給与所得控除後","控除後の金額","課税給与所得"]) {
                if let amount = extractNumber(from: trimmed) {
                    result.taxableIncome = amount
                }
            }

            // ── 生命保険料控除 ──
            if containsAny(trimmed, keywords: ["生命保険料","生保控除"]) {
                if let amount = extractNumber(from: trimmed) {
                    result.lifeInsuranceDeduction = amount
                }
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: Helpers (nonisolated)
    // ─────────────────────────────────────────
    nonisolated private static func containsAny(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }

    nonisolated static func extractNumber(from text: String) -> Double? {
        let cleaned = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "，", with: "")
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "￥", with: "")
            .replacingOccurrences(of: " ", with: "")

        let pattern = #"(\d{5,})"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: cleaned,
                                        range: NSRange(cleaned.startIndex..., in: cleaned)),
           let range = Range(match.range(at: 1), in: cleaned) {
            return Double(cleaned[range])
        }
        return nil
    }

    // ─────────────────────────────────────────
    // MARK: Confirm & Save to UserProfile
    // ─────────────────────────────────────────
    func confirmAndSave(result: OCRScanResult) {
        var confirmed = result
        confirmed.isConfirmed = true

        if let income    = confirmed.annualIncome    { userProfile.annualIncome    = income    }
        if let tax       = confirmed.withholdingTax  { userProfile.withholdingTax  = tax       }
        if let deduction = confirmed.deductionTotal  { userProfile.deductionTotal  = deduction }

        userProfile.scanHistory.append(confirmed)
        scanResult      = confirmed
        showReviewSheet = false
    }

    // ─────────────────────────────────────────
    // MARK: VisionKit availability check
    // ─────────────────────────────────────────
    var isScannerAvailable: Bool {
        DataScannerViewController.isSupported &&
        DataScannerViewController.isAvailable
    }
}
