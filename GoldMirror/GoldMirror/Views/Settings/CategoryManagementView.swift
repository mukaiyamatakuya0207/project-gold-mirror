// MARK: - CategoryManagementView.swift
// Gold Mirror – Expense category management.

import SwiftUI

struct CategoryManagementView: View {
    @EnvironmentObject var dm: DataManager
    @State private var showForm = false
    @State private var editingCategory: Category?
    @State private var showResetAlert = false

    var body: some View {
        ZStack {
            Color.gmBackground.ignoresSafeArea()

            VStack(spacing: GMSpacing.md) {
                CategoryManagementHeader(
                    onAdd: { showForm = true },
                    onReset: { showResetAlert = true }
                )
                .padding(.horizontal, GMSpacing.md)
                .padding(.top, GMSpacing.md)

                List {
                    ForEach(dm.expenseCategories) { category in
                        CategoryManagementRow(category: category) {
                            editingCategory = category
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: GMSpacing.md, bottom: 5, trailing: GMSpacing.md))
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            dm.deleteExpenseCategory(dm.expenseCategories[index])
                        }
                    }
                    .onMove { source, destination in
                        dm.moveExpenseCategories(from: source, to: destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.gmBackground)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.gmBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
                    .foregroundStyle(Color.gmGold)
            }
        }
        .sheet(isPresented: $showForm) {
            CategoryFormSheet(category: nil) { dm.addExpenseCategory($0) }
        }
        .sheet(item: $editingCategory) { category in
            CategoryFormSheet(category: category) { dm.updateExpenseCategory($0) }
        }
        .alert("カテゴリを初期状態に戻しますか？", isPresented: $showResetAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("リセット", role: .destructive) {
                dm.resetExpenseCategoriesToDefault()
            }
        } message: {
            Text("追加・編集した支出カテゴリの設定が初期データに戻ります。")
        }
    }
}

struct CategoryManagementHeader: View {
    let onAdd: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("CATEGORIES")
                    .font(GMFont.caption(11, weight: .bold))
                    .foregroundStyle(Color.gmGold.opacity(0.7))
                    .tracking(3)
                Text("カテゴリ管理")
                    .font(GMFont.heading(22, weight: .bold))
                    .foregroundStyle(GMGradient.goldHorizontal)
            }
            Spacer()
            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.gmGold)
                    .frame(width: 36, height: 36)
                    .background(Color.gmGold.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            Button(action: onAdd) {
                Label("追加", systemImage: "plus")
                    .font(GMFont.caption(12, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, GMSpacing.sm)
                    .padding(.vertical, 8)
                    .background(GMGradient.goldHorizontal)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

struct CategoryManagementRow: View {
    let category: Category
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: GMSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: GMRadius.sm)
                        .fill(category.color.opacity(0.16))
                        .frame(width: 44, height: 44)
                    Image(systemName: category.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(category.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(category.name)
                        .font(GMFont.body(14, weight: .semibold))
                        .foregroundStyle(Color.gmTextPrimary)
                }
                Spacer()
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.gmGold)
            }
            .padding(GMSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .gmCardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct CategoryFormSheet: View {
    let category: Category?
    let onSave: (Category) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var iconName = "tag.fill"
    @State private var colorHex = "#D4AF37"

    private let icons = [
        "fork.knife", "train.side.front.car", "basket.fill", "gamecontroller.fill",
        "person.2.fill", "tshirt.fill", "pawprint.fill", "cross.fill",
        "car.fill", "book.fill", "bolt.fill", "house.fill",
        "antenna.radiowaves.left.and.right", "sparkles", "doc.text.fill", "shield.fill",
        "banknote.fill", "chart.line.downtrend.xyaxis", "ellipsis.circle.fill", "tag.fill"
    ]

    private let colors = [
        "#D4AF37", "#F0D060", "#FF8A65", "#4FC3F7", "#A5D6A7",
        "#CE93D8", "#F06292", "#EF9A9A", "#FFD54F", "#4CAF50",
        "#B86BFF", "#90A4AE", "#A8A8A8", "#8D6E63"
    ]

    private var semantic: CategorySemantic {
        category?.semantic ?? .normal
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gmBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: GMSpacing.lg) {
                        preview

                        GMInputSection(title: "カテゴリ名", icon: "textformat") {
                            TextField("カテゴリ名", text: $name)
                                .font(GMFont.body(15))
                                .foregroundStyle(Color.gmTextPrimary)
                                .tint(Color.gmGold)
                        }
                        .padding(.horizontal, GMSpacing.md)

                        iconPicker
                        colorPicker
                    }
                    .padding(.top, GMSpacing.lg)
                    .padding(.bottom, GMSpacing.xl)
                }
            }
            .navigationTitle(category == nil ? "カテゴリを追加" : "カテゴリを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(Color.gmTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .foregroundStyle(Color.gmGold)
                        .fontWeight(.bold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { populate() }
    }

    private var preview: some View {
        VStack(spacing: GMSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color(hex: colorHex).opacity(0.18))
                    .frame(width: 76, height: 76)
                Image(systemName: iconName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color(hex: colorHex))
            }
            Text(name.isEmpty ? "カテゴリ名" : name)
                .font(GMFont.heading(16, weight: .bold))
                .foregroundStyle(Color.gmTextPrimary)
        }
    }

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            Text("アイコン")
                .font(GMFont.caption(12, weight: .semibold))
                .foregroundStyle(Color.gmTextTertiary)
                .padding(.horizontal, GMSpacing.md)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: GMSpacing.sm), count: 5), spacing: GMSpacing.sm) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        iconName = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(iconName == icon ? Color.black : Color(hex: colorHex))
                            .frame(width: 46, height: 46)
                            .background(iconName == icon ? Color(hex: colorHex) : Color.gmSurface)
                            .clipShape(RoundedRectangle(cornerRadius: GMRadius.sm))
                            .overlay(
                                RoundedRectangle(cornerRadius: GMRadius.sm)
                                    .strokeBorder(Color(hex: colorHex).opacity(iconName == icon ? 0.8 : 0.25), lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, GMSpacing.md)
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            Text("カラー")
                .font(GMFont.caption(12, weight: .semibold))
                .foregroundStyle(Color.gmTextTertiary)
                .padding(.horizontal, GMSpacing.md)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: GMSpacing.sm), count: 7), spacing: GMSpacing.sm) {
                ForEach(colors, id: \.self) { hex in
                    Button {
                        colorHex = hex
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .strokeBorder(colorHex == hex ? Color.gmTextPrimary : Color.gmGoldDim.opacity(0.25), lineWidth: colorHex == hex ? 2 : 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, GMSpacing.md)
        }
    }

    private func populate() {
        guard let category else { return }
        name = category.name
        iconName = category.iconName
        colorHex = category.colorHex
    }

    private func save() {
        let category = Category(
            id: category?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            iconName: iconName,
            colorHex: colorHex,
            semantic: semantic
        )
        onSave(category)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        CategoryManagementView()
            .environmentObject(DataManager())
            .environmentObject(SecurityManager())
    }
}
