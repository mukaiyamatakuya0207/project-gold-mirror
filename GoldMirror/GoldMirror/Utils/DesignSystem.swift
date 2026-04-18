// MARK: - DesignSystem.swift
// Gold Mirror – Single source of truth for all design tokens.
// Import this file wherever colors, fonts, or spacing are needed.

import SwiftUI

// ─────────────────────────────────────────
// MARK: Color Palette
// ─────────────────────────────────────────
extension Color {
    // Backgrounds
    static let gmBackground     = Color(hex: "#0A0A0A")  // リッチブラック
    static let gmSurface        = Color(hex: "#141414")  // カード背景
    static let gmSurfaceElevated = Color(hex: "#1E1E1E") // 少し浮き上がったサーフェス

    // Gold Accents
    static let gmGold           = Color(hex: "#D4AF37")  // メインゴールド
    static let gmGoldLight      = Color(hex: "#F0D060")  // ハイライトゴールド
    static let gmGoldDim        = Color(hex: "#8B7320")  // ダークゴールド / ボーダー

    // Text
    static let gmTextPrimary    = Color(hex: "#FFFFFF")
    static let gmTextSecondary  = Color(hex: "#A8A8A8")
    static let gmTextTertiary   = Color(hex: "#5A5A5A")

    // Semantic
    static let gmPositive       = Color(hex: "#4CAF50")  // 利益 / プラス
    static let gmNegative       = Color(hex: "#EF5350")  // 損失 / マイナス
    static let gmNeutral        = Color(hex: "#7E7E7E")

    // Tab Bar
    static let gmTabBackground  = Color(hex: "#0F0F0F")
    static let gmTabActive      = Color.gmGold
    static let gmTabInactive    = Color(hex: "#4A4A4A")
}

// Hex initializer for Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// ─────────────────────────────────────────
// MARK: Gold Gradient Definitions
// ─────────────────────────────────────────
struct GMGradient {
    /// ゴールドの水平グラデーション
    static let goldHorizontal = LinearGradient(
        colors: [Color.gmGoldDim, Color.gmGold, Color.gmGoldLight, Color.gmGold],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// ゴールドの対角グラデーション（カード用）
    static let goldDiagonal = LinearGradient(
        colors: [Color(hex: "#8B7320"), Color.gmGold, Color(hex: "#F0D060"), Color.gmGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 背景のサトルなグラデーション
    static let backgroundSubtle = LinearGradient(
        colors: [Color.gmBackground, Color(hex: "#0F0D05")],
        startPoint: .top,
        endPoint: .bottom
    )

    /// 資産サマリーカード背景
    static let summaryCard = LinearGradient(
        colors: [Color(hex: "#1A1500"), Color(hex: "#0F0F0F")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// ─────────────────────────────────────────
// MARK: Typography
// ─────────────────────────────────────────
struct GMFont {
    // Display
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    // Heading
    static func heading(_ size: CGFloat = 20, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    // Body
    static func body(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    // Caption
    static func caption(_ size: CGFloat = 12, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    // Mono (金額表示用)
    static func mono(_ size: CGFloat = 24, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// ─────────────────────────────────────────
// MARK: Spacing & Corner Radius
// ─────────────────────────────────────────
struct GMSpacing {
    static let xs:   CGFloat = 4
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 16
    static let lg:   CGFloat = 24
    static let xl:   CGFloat = 32
    static let xxl:  CGFloat = 48
}

struct GMRadius {
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 12
    static let lg:   CGFloat = 20
    static let xl:   CGFloat = 28
    static let pill: CGFloat = 999
}

// ─────────────────────────────────────────
// MARK: Reusable View Modifiers
// ─────────────────────────────────────────

/// ゴールドボーダー付きカード背景
struct GMCardStyle: ViewModifier {
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: GMRadius.lg)
                    .fill(elevated ? Color.gmSurfaceElevated : Color.gmSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: GMRadius.lg)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.gmGoldDim.opacity(0.6),
                                        Color.gmGold.opacity(0.2),
                                        Color.gmGoldDim.opacity(0.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    )
            )
    }
}

/// ゴールドのグロー効果（シャドウ）
struct GMGoldGlow: ViewModifier {
    var radius: CGFloat = 12
    var opacity: Double = 0.3

    func body(content: Content) -> some View {
        content
            .shadow(color: Color.gmGold.opacity(opacity), radius: radius, x: 0, y: 4)
    }
}

extension View {
    func gmCardStyle(elevated: Bool = false) -> some View {
        modifier(GMCardStyle(elevated: elevated))
    }

    func gmGoldGlow(radius: CGFloat = 12, opacity: Double = 0.3) -> some View {
        modifier(GMGoldGlow(radius: radius, opacity: opacity))
    }
}

// ─────────────────────────────────────────
// MARK: Number Formatting
// ─────────────────────────────────────────
extension Double {
    /// 日本円フォーマット: ¥1,234,567
    var jpyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "¥0"
    }

    /// コンパクト表示: ¥1.2M, ¥500K
    var jpyCompact: String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""
        switch absValue {
        case 1_000_000_000...:
            return "\(sign)¥\(String(format: "%.1f", absValue / 1_000_000_000))B"
        case 1_000_000...:
            return "\(sign)¥\(String(format: "%.1f", absValue / 1_000_000))M"
        case 1_000...:
            return "\(sign)¥\(String(format: "%.0f", absValue / 1_000))K"
        default:
            return "\(sign)¥\(Int(absValue))"
        }
    }

    /// 符号付きパーセント: +12.34% / -5.67%
    var signedPercent: String {
        let sign = self >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", self))%"
    }
}

extension Date {
    var japaneseDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "yyyy年M月d日(EEE)"
        return formatter.string(from: self)
    }
}

extension Calendar {
    static var gmJapan: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        calendar.firstWeekday = 1
        return calendar
    }
}
