// MARK: - Category.swift
// Gold Mirror – User-editable expense categories.

import SwiftUI

enum CategorySemantic: String, Codable {
    case normal
    case businessExpense
    case assetAdjustment
}

struct Category: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var semantic: CategorySemantic

    var color: Color {
        Color(hex: colorHex)
    }

    var isAssetAdjustment: Bool {
        semantic == .assetAdjustment
    }

    var isBusinessExpense: Bool {
        semantic == .businessExpense
    }

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorHex: String,
        semantic: CategorySemantic = .normal
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.semantic = semantic
    }
}

extension Category {
    static let companyExpenseCategory = Category(
        name: "会社経費",
        iconName: "briefcase.fill",
        colorHex: "#D4AF37",
        semantic: .businessExpense
    )

    static let defaultExpenseCategories: [Category] = [
        Category(name: "食費", iconName: "fork.knife", colorHex: "#FF8A65"),
        Category(name: "交通費", iconName: "train.side.front.car", colorHex: "#4FC3F7"),
        Category(name: "日用品", iconName: "basket.fill", colorHex: "#A5D6A7"),
        Category(name: "娯楽", iconName: "gamecontroller.fill", colorHex: "#CE93D8"),
        Category(name: "交際費", iconName: "person.2.fill", colorHex: "#F06292"),
        Category(name: "服飾費", iconName: "tshirt.fill", colorHex: "#BA68C8"),
        Category(name: "ペット", iconName: "pawprint.fill", colorHex: "#8D6E63"),
        Category(name: "医療", iconName: "cross.fill", colorHex: "#EF9A9A"),
        Category(name: "自動車", iconName: "car.fill", colorHex: "#90A4AE"),
        Category(name: "教育", iconName: "book.fill", colorHex: "#FFD54F"),
        Category(name: "水道光熱費", iconName: "bolt.fill", colorHex: "#4DD0E1"),
        Category(name: "住宅", iconName: "house.fill", colorHex: "#D4AF37"),
        Category(name: "通信費", iconName: "antenna.radiowaves.left.and.right", colorHex: "#64B5F6"),
        Category(name: "特別な支出", iconName: "sparkles", colorHex: "#F0D060"),
        Category(name: "税金", iconName: "doc.text.fill", colorHex: "#B0BEC5"),
        Category(name: "保険", iconName: "shield.fill", colorHex: "#81C784"),
        Category(name: "貯蓄", iconName: "banknote.fill", colorHex: "#4CAF50"),
        Category(name: "資産評価換え", iconName: "chart.line.downtrend.xyaxis", colorHex: "#B86BFF", semantic: .assetAdjustment),
        Category.companyExpenseCategory,
        Category(name: "その他支出", iconName: "ellipsis.circle.fill", colorHex: "#A8A8A8")
    ]
}
