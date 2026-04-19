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
    ocrExtractReceiptFields(text: text, into: &r)
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

private nonisolated func ocrExtractReceiptFields(text: String, into r: inout OCRScanResult) {
    let lines = text
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    r.receiptDate = ocrReceiptDate(from: lines) ?? r.receiptDate
    r.totalAmount = ocrReceiptTotalAmount(from: lines) ?? r.totalAmount
    r.merchantName = ocrMerchantName(from: lines) ?? r.merchantName

    let category = ocrSuggestedExpenseCategory(merchant: r.merchantName, rawText: text)
    r.suggestedCategoryName = category.name
    r.suggestedCategoryIconName = category.iconName
    r.suggestedCategoryColorHex = category.colorHex
}

private nonisolated func ocrReceiptDate(from lines: [String]) -> Date? {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "ja_JP")
    calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
    let nowYear = calendar.component(.year, from: Date())
    let joined = lines.joined(separator: "\n")
    let patterns: [(String, Bool)] = [
        (#"((?:20)?\d{2})[./\-年]\s*(\d{1,2})[./\-月]\s*(\d{1,2})"#, true),
        (#"(\d{1,2})[./\-月]\s*(\d{1,2})日?"#, false)
    ]

    for (pattern, hasYear) in patterns {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
        let range = NSRange(joined.startIndex..., in: joined)
        guard let match = regex.firstMatch(in: joined, range: range) else { continue }
        func intAt(_ index: Int) -> Int? {
            guard let swiftRange = Range(match.range(at: index), in: joined) else { return nil }
            return Int(joined[swiftRange])
        }
        let year: Int
        let month: Int?
        let day: Int?
        if hasYear {
            guard let rawYear = intAt(1) else { continue }
            year = rawYear < 100 ? 2000 + rawYear : rawYear
            month = intAt(2)
            day = intAt(3)
        } else {
            year = nowYear
            month = intAt(1)
            day = intAt(2)
        }
        guard let month, let day else { continue }
        var comps = DateComponents()
        comps.calendar = calendar
        comps.timeZone = TimeZone(identifier: "Asia/Tokyo")
        comps.year = year
        comps.month = month
        comps.day = day
        if let date = calendar.date(from: comps) {
            return calendar.startOfDay(for: date)
        }
    }
    return nil
}

private nonisolated func ocrReceiptTotalAmount(from lines: [String]) -> Double? {
    let priorityKeywords = ["総合計", "合計", "お会計", "領収金額", "ご利用金額", "請求金額", "税込合計", "税込"]
    let ignoredKeywords = ["小計", "税", "消費税", "釣", "お釣", "預", "現金", "カード"]

    for line in lines where ocrContains(line, priorityKeywords) && !ocrContains(line, ignoredKeywords) {
        let values = ocrMoneyValues(in: line)
        if let best = values.max() {
            return best
        }
    }

    for (index, line) in lines.enumerated() where ocrContains(line, priorityKeywords) {
        let values = ocrMoneyValues(in: line)
        if let best = values.max() {
            return best
        }
        if index + 1 < lines.count, let best = ocrMoneyValues(in: lines[index + 1]).max() {
            return best
        }
    }

    return lines
        .flatMap { ocrMoneyValues(in: $0) }
        .filter { $0 >= 50 && $0 <= 10_000_000 }
        .max()
}

private nonisolated func ocrMoneyValues(in text: String) -> [Double] {
    let cleaned = text
        .replacingOccurrences(of: ",", with: "")
        .replacingOccurrences(of: "，", with: "")
        .replacingOccurrences(of: "¥", with: "")
        .replacingOccurrences(of: "￥", with: "")
    guard let regex = try? NSRegularExpression(pattern: #"(?<!\d)(\d{2,8})(?!\d)"#) else { return [] }
    return regex.matches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)).compactMap { match in
        guard let range = Range(match.range(at: 1), in: cleaned),
              let value = Double(cleaned[range]) else { return nil }
        return value
    }
}

private nonisolated func ocrMerchantName(from lines: [String]) -> String? {
    let blocked = [
        "領収", "レシート", "receipt", "合計", "小計", "消費税", "税込", "釣", "電話",
        "tel", "登録番号", "取引", "担当", "明細", "クレジット", "カード", "現金"
    ]
    return lines.first { line in
        let compact = line.replacingOccurrences(of: " ", with: "")
        guard compact.count >= 2 && compact.count <= 40 else { return false }
        guard !compact.contains(where: { $0.isNumber }) || compact.filter(\.isNumber).count < compact.count / 2 else { return false }
        return !blocked.contains { compact.localizedCaseInsensitiveContains($0) }
    }
}

private nonisolated func ocrSuggestedExpenseCategory(
    merchant: String?,
    rawText: String
) -> (name: String, iconName: String, colorHex: String) {
    let searchable = [merchant, rawText].compactMap { $0 }.joined(separator: " ")

    let rules: [([String], String, String, String)] = [
        (["タクシー", "taxi", "jr", "駅", "電鉄", "地下鉄", "バス", "高速", "駐車", "交通"], "交通費", "train.side.front.car", "#4FC3F7"),
        (["ホテル", "hotel", "宿泊", "旅館", "inn"], "特別な支出", "bed.double.fill", "#B0BEC5"),
        (["接待", "会食", "御食事", "お食事", "懇親"], "交際費", "person.2.fill", "#F06292"),
        (["レストラン", "restaurant", "居酒屋", "カフェ", "cafe", "喫茶", "弁当", "スーパー", "食品"], "食費", "fork.knife", "#FF8A65"),
        (["コンビニ", "セブン", "ローソン", "ファミリーマート", "ファミマ", "薬局", "ドラッグ"], "日用品", "basket.fill", "#A5D6A7"),
        (["文具", "コピー", "印刷", "郵便", "宅急便", "オフィス", "事務"], "その他支出", "briefcase.fill", "#A8A8A8")
    ]

    if let match = rules.first(where: { rule in
        let keywords = rule.0
        return keywords.contains { searchable.localizedCaseInsensitiveContains($0) }
    }) {
        return (match.1, match.2, match.3)
    }
    return ("その他支出", "ellipsis.circle.fill", "#A8A8A8")
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
