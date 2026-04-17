// MARK: - OCRReviewView.swift
// Gold Mirror – OCR result confirmation and manual correction screen.

import SwiftUI

struct OCRReviewView: View {
    @EnvironmentObject var ocrVM: OCRViewModel
    @Environment(\.dismiss) var dismiss

    let result: OCRScanResult
    let onConfirm: (OCRScanResult) -> Void

    // Editable copies
    @State private var annualIncome:    String = ""
    @State private var deductionTotal:  String = ""
    @State private var withholdingTax:  String = ""
    @State private var socialInsurance: String = ""
    @State private var taxableIncome:   String = ""
    @State private var lifeInsurance:   String = ""
    @State private var showRawText:     Bool   = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gmBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: GMSpacing.lg) {

                        // ── Confidence Banner ──
                        ConfidenceBanner(result: editedResult)

                        // ── Editable Fields ──
                        OCRFieldsCard(
                            annualIncome:    $annualIncome,
                            deductionTotal:  $deductionTotal,
                            withholdingTax:  $withholdingTax,
                            socialInsurance: $socialInsurance,
                            taxableIncome:   $taxableIncome,
                            lifeInsurance:   $lifeInsurance
                        )
                        .padding(.horizontal, GMSpacing.md)

                        // ── Income Rank Preview ──
                        if let income = Double(annualIncome.filter { $0.isNumber }), income > 0 {
                            IncomeRankPreviewCard(annualIncome: income)
                                .padding(.horizontal, GMSpacing.md)
                        }

                        // ── Effective Tax Rate ──
                        TaxSummaryCard(
                            income:        Double(annualIncome.filter { $0.isNumber }),
                            withholding:   Double(withholdingTax.filter { $0.isNumber }),
                            deduction:     Double(deductionTotal.filter { $0.isNumber })
                        )
                        .padding(.horizontal, GMSpacing.md)

                        // ── Raw Text Toggle ──
                        DisclosureGroup(
                            isExpanded: $showRawText,
                            content: {
                                ScrollView {
                                    Text(result.rawText.isEmpty
                                         ? "（認識されたテキストなし）"
                                         : result.rawText)
                                        .font(GMFont.caption(11))
                                        .foregroundStyle(Color.gmTextTertiary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(GMSpacing.sm)
                                }
                                .frame(maxHeight: 200)
                            },
                            label: {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundStyle(Color.gmGold)
                                    Text("認識した生テキストを表示")
                                        .font(GMFont.caption(12))
                                        .foregroundStyle(Color.gmTextSecondary)
                                }
                            }
                        )
                        .padding(GMSpacing.md)
                        .gmCardStyle()
                        .padding(.horizontal, GMSpacing.md)

                        // ── Save Button ──
                        Button {
                            onConfirm(editedResult)
                        } label: {
                            HStack(spacing: GMSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("確認して保存")
                                    .font(GMFont.heading(16, weight: .bold))
                            }
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, GMSpacing.md)
                            .background(GMGradient.goldHorizontal)
                            .clipShape(RoundedRectangle(cornerRadius: GMRadius.lg))
                        }
                        .gmGoldGlow(radius: 16, opacity: 0.4)
                        .padding(.horizontal, GMSpacing.md)

                        Spacer().frame(height: 60)
                    }
                    .padding(.top, GMSpacing.md)
                }
            }
            .navigationTitle("スキャン結果を確認")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(Color.gmTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text(result.documentType.rawValue)
                        .font(GMFont.caption(11, weight: .semibold))
                        .foregroundStyle(Color.gmGold)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.gmGold.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .preferredColorScheme(.dark)
        }
        .onAppear { populate() }
    }

    // ── Helpers ──
    private func populate() {
        annualIncome    = result.annualIncome.map    { String(Int($0)) } ?? ""
        deductionTotal  = result.deductionTotal.map  { String(Int($0)) } ?? ""
        withholdingTax  = result.withholdingTax.map  { String(Int($0)) } ?? ""
        socialInsurance = result.socialInsurance.map { String(Int($0)) } ?? ""
        taxableIncome   = result.taxableIncome.map   { String(Int($0)) } ?? ""
        lifeInsurance   = result.lifeInsuranceDeduction.map { String(Int($0)) } ?? ""
    }

    private var editedResult: OCRScanResult {
        var r = result
        r.annualIncome             = Double(annualIncome.filter { $0.isNumber })
        r.deductionTotal           = Double(deductionTotal.filter { $0.isNumber })
        r.withholdingTax           = Double(withholdingTax.filter { $0.isNumber })
        r.socialInsurance          = Double(socialInsurance.filter { $0.isNumber })
        r.taxableIncome            = Double(taxableIncome.filter { $0.isNumber })
        r.lifeInsuranceDeduction   = Double(lifeInsurance.filter { $0.isNumber })
        return r
    }
}

// ─────────────────────────────────────────
// MARK: Confidence Banner
// ─────────────────────────────────────────
struct ConfidenceBanner: View {
    let result: OCRScanResult

    private var filledCount: Int {
        [result.annualIncome, result.withholdingTax,
         result.deductionTotal, result.socialInsurance]
            .compactMap { $0 }.count
    }
    private var confidence: Double { Double(filledCount) / 4.0 }

    var body: some View {
        HStack(spacing: GMSpacing.md) {
            // Progress ring
            ZStack {
                Circle().stroke(Color.gmGoldDim.opacity(0.3), lineWidth: 3)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: CGFloat(confidence))
                    .stroke(confidence >= 0.75 ? Color.gmPositive : Color.gmGold,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)
                Text("\(Int(confidence * 100))%")
                    .font(GMFont.mono(13, weight: .bold))
                    .foregroundStyle(Color.gmGold)
            }
            VStack(alignment: .leading, spacing: GMSpacing.xs) {
                Text(confidence >= 0.75 ? "高精度で認識しました" : "一部の項目を確認してください")
                    .font(GMFont.heading(14, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
                Text("\(filledCount)/4 項目を自動抽出 • 内容を確認・修正してから保存してください")
                    .font(GMFont.caption(11))
                    .foregroundStyle(Color.gmTextTertiary)
                    .lineSpacing(3)
            }
        }
        .padding(GMSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .fill(LinearGradient(colors:[Color(hex:"#0F1A00"), Color(hex:"#0F0F0F")],
                                     startPoint:.topLeading, endPoint:.bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: GMRadius.lg)
                    .strokeBorder(Color.gmGold.opacity(0.25), lineWidth: 0.8))
        )
        .padding(.horizontal, GMSpacing.md)
    }
}

// ─────────────────────────────────────────
// MARK: OCR Fields Card
// ─────────────────────────────────────────
struct OCRFieldsCard: View {
    @Binding var annualIncome:    String
    @Binding var deductionTotal:  String
    @Binding var withholdingTax:  String
    @Binding var socialInsurance: String
    @Binding var taxableIncome:   String
    @Binding var lifeInsurance:   String

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .foregroundStyle(Color.gmGold)
                Text("抽出された数値（タップして修正）")
                    .font(GMFont.heading(14, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
            }

            OCRFieldRow(icon: "yensign.circle.fill",
                        label: "支払金額（年収）",
                        color: .gmGold,
                        value: $annualIncome)

            OCRFieldRow(icon: "minus.circle.fill",
                        label: "所得控除の合計額",
                        color: Color(hex: "#4FC3F7"),
                        value: $deductionTotal)

            OCRFieldRow(icon: "building.columns.fill",
                        label: "源泉徴収税額",
                        color: Color(hex: "#EF9A9A"),
                        value: $withholdingTax)

            OCRFieldRow(icon: "cross.circle.fill",
                        label: "社会保険料等の金額",
                        color: Color(hex: "#81C784"),
                        value: $socialInsurance)

            OCRFieldRow(icon: "doc.text.fill",
                        label: "給与所得控除後の金額",
                        color: Color(hex: "#CE93D8"),
                        value: $taxableIncome)

            OCRFieldRow(icon: "heart.circle.fill",
                        label: "生命保険料の控除額",
                        color: Color(hex: "#FF8C00"),
                        value: $lifeInsurance)
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

struct OCRFieldRow: View {
    let icon: String
    let label: String
    let color: Color
    @Binding var value: String

    var body: some View {
        HStack(spacing: GMSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(GMFont.caption(11, weight: .medium))
                    .foregroundStyle(Color.gmTextTertiary)

                TextField("未検出", text: $value)
                    .keyboardType(.numberPad)
                    .font(GMFont.mono(15, weight: .bold))
                    .foregroundStyle(value.isEmpty ? Color.gmTextTertiary : Color.gmTextPrimary)
            }

            Spacer()

            // Auto-format preview
            if let v = Double(value.filter { $0.isNumber }), v > 0 {
                Text(v.jpyCompact)
                    .font(GMFont.caption(10, weight: .medium))
                    .foregroundStyle(color.opacity(0.8))
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(color.opacity(0.1))
                    .clipShape(Capsule())
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.gmTextTertiary.opacity(0.5))
            }
        }
        .padding(.vertical, GMSpacing.xs)

        Divider().background(Color.gmGoldDim.opacity(0.3))
    }
}

// ─────────────────────────────────────────
// MARK: Income Rank Preview Card
// ─────────────────────────────────────────
struct IncomeRankPreviewCard: View {
    let annualIncome: Double
    private var rank: IncomeRank { IncomeRank.rank(for: annualIncome) }

    var body: some View {
        HStack(spacing: GMSpacing.md) {
            Text(rank.badge).font(.system(size: 36))
            VStack(alignment: .leading, spacing: GMSpacing.xs) {
                Text("あなたの年収ランク")
                    .font(GMFont.caption(11)).foregroundStyle(Color.gmTextTertiary)
                Text(rank.rawValue)
                    .font(GMFont.heading(18, weight: .bold))
                    .foregroundStyle(rank.color)
                Text(rank.topPercent)
                    .font(GMFont.caption(12)).foregroundStyle(Color.gmTextTertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("年収")
                    .font(GMFont.caption(10)).foregroundStyle(Color.gmTextTertiary)
                Text(annualIncome.jpyCompact)
                    .font(GMFont.mono(18, weight: .bold)).foregroundStyle(Color.gmTextPrimary)
            }
        }
        .padding(GMSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .fill(rank.color.opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: GMRadius.lg)
                    .strokeBorder(rank.color.opacity(0.3), lineWidth: 0.8))
        )
    }
}

// ─────────────────────────────────────────
// MARK: Tax Summary Card
// ─────────────────────────────────────────
struct TaxSummaryCard: View {
    let income:      Double?
    let withholding: Double?
    let deduction:   Double?

    private var effectiveRate: Double? {
        guard let i = income, let t = withholding, i > 0 else { return nil }
        return (t / i) * 100
    }
    private var netIncome: Double? {
        guard let i = income, let t = withholding else { return nil }
        return i - t
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Image(systemName: "percent").foregroundStyle(Color.gmGold)
                Text("税務サマリー")
                    .font(GMFont.heading(14, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
            }
            HStack(spacing: 0) {
                TaxStatCol(label: "手取り（概算）",
                           value: netIncome.map { $0.jpyCompact } ?? "－",
                           color: .gmPositive)
                Divider().frame(width:0.5).background(Color.gmGoldDim.opacity(0.4))
                    .padding(.vertical, GMSpacing.sm)
                TaxStatCol(label: "実効税率",
                           value: effectiveRate.map { String(format:"%.1f%%", $0) } ?? "－",
                           color: .gmNegative)
                Divider().frame(width:0.5).background(Color.gmGoldDim.opacity(0.4))
                    .padding(.vertical, GMSpacing.sm)
                TaxStatCol(label: "控除合計",
                           value: deduction.map { $0.jpyCompact } ?? "－",
                           color: Color(hex: "#4FC3F7"))
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

private struct TaxStatCol: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: GMSpacing.xs) {
            Text(value)
                .font(GMFont.mono(15, weight: .bold))
                .foregroundStyle(Color.gmTextPrimary)
                .minimumScaleFactor(0.7).lineLimit(1)
            Text(label)
                .font(GMFont.caption(10)).foregroundStyle(Color.gmTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GMSpacing.sm)
    }
}

#Preview {
    OCRReviewView(
        result: {
            var r = OCRScanResult(
                id: UUID(),
                documentType: .withholdingSlip,
                scannedAt: Date(),
                rawText: "支払金額 6,800,000\n源泉徴収税額 510,000\n所得控除の額の合計 1,240,000",
                isConfirmed: false
            )
            r.annualIncome    = 6_800_000
            r.withholdingTax  = 510_000
            r.deductionTotal  = 1_240_000
            r.socialInsurance = 980_000
            return r
        }(),
        onConfirm: { _ in }
    )
    .environmentObject(OCRViewModel())
}
