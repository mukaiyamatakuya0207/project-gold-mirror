// MARK: - IncomeExpenseInputView.swift
// Gold Mirror – FAB half-modal for recording income or expense transactions.

import SwiftUI

// ─────────────────────────────────────────
// MARK: Transaction Model
// ─────────────────────────────────────────
enum TransactionType: String, CaseIterable {
    case income  = "収入"
    case expense = "支出"

    var icon: String {
        switch self {
        case .income:  return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        }
    }
    var color: Color {
        switch self {
        case .income:  return Color.gmPositive
        case .expense: return Color.gmNegative
        }
    }
}

enum TransactionCategory: String, CaseIterable {
    // income
    case salary    = "給与"
    case bonus     = "ボーナス"
    case investment = "投資収益"
    case other_in  = "その他収入"
    // expense
    case food      = "食費"
    case transport = "交通費"
    case shopping  = "買い物"
    case utilities = "光熱費"
    case entertainment = "娯楽"
    case health    = "医療"
    case other_ex  = "その他支出"

    var icon: String {
        switch self {
        case .salary:       return "briefcase.fill"
        case .bonus:        return "star.fill"
        case .investment:   return "chart.line.uptrend.xyaxis"
        case .other_in:     return "plus.circle.fill"
        case .food:         return "fork.knife"
        case .transport:    return "train.side.front.car"
        case .shopping:     return "bag.fill"
        case .utilities:    return "bolt.fill"
        case .entertainment: return "gamecontroller.fill"
        case .health:       return "cross.fill"
        case .other_ex:     return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .salary, .bonus, .investment, .other_in:
            return Color.gmPositive
        case .food:        return Color(hex: "#FF8A65")
        case .transport:   return Color(hex: "#4FC3F7")
        case .shopping:    return Color(hex: "#CE93D8")
        case .utilities:   return Color(hex: "#FFD54F")
        case .entertainment: return Color(hex: "#A5D6A7")
        case .health:      return Color(hex: "#EF9A9A")
        case .other_ex:    return Color.gmTextSecondary
        }
    }

    static var incomeCategories: [TransactionCategory] {
        [.salary, .bonus, .investment, .other_in]
    }
    static var expenseCategories: [TransactionCategory] {
        [.food, .transport, .shopping, .utilities, .entertainment, .health, .other_ex]
    }
}

struct Transaction: Identifiable {
    let id = UUID()
    var type: TransactionType
    var amount: Double
    var category: TransactionCategory
    var date: Date
    var memo: String
}

// ─────────────────────────────────────────
// MARK: IncomeExpenseInputView
// ─────────────────────────────────────────
struct IncomeExpenseInputView: View {
    @EnvironmentObject var dm: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var transactionType: TransactionType = .expense
    @State private var amountText = ""
    @State private var selectedCategory: TransactionCategory = .food
    @State private var selectedDate = Date()
    @State private var memo = ""
    @State private var showDatePicker = false
    @State private var savedAnimation = false

    private var categories: [TransactionCategory] {
        transactionType == .income ? TransactionCategory.incomeCategories : TransactionCategory.expenseCategories
    }

    private var parsedAmount: Double { Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0 }

    private var formattedAmount: String {
        guard parsedAmount > 0 else { return "" }
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        return fmt.string(from: NSNumber(value: parsedAmount)) ?? amountText
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gmBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: GMSpacing.lg) {

                        // ── Type Toggle ──
                        HStack(spacing: 0) {
                            ForEach(TransactionType.allCases, id: \.rawValue) { t in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        transactionType = t
                                        // reset category to first of that type
                                        selectedCategory = categories.first ?? .food
                                    }
                                } label: {
                                    HStack(spacing: GMSpacing.xs) {
                                        Image(systemName: t.icon)
                                            .font(.system(size: 14, weight: .semibold))
                                        Text(t.rawValue)
                                            .font(GMFont.heading(14, weight: .semibold))
                                    }
                                    .foregroundStyle(transactionType == t ? Color.gmBackground : Color.gmTextTertiary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        transactionType == t
                                            ? t.color
                                            : Color.gmSurface
                                    )
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: GMRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: GMRadius.md)
                                .strokeBorder(Color.gmGoldDim.opacity(0.4), lineWidth: 0.8)
                        )
                        .padding(.horizontal, GMSpacing.md)
                        .padding(.top, GMSpacing.md)

                        // ── Amount Input ──
                        VStack(spacing: GMSpacing.sm) {
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("¥")
                                    .font(GMFont.display(28, weight: .bold))
                                    .foregroundStyle(transactionType.color)

                                TextField("0", text: $amountText)
                                    .font(GMFont.display(42, weight: .bold))
                                    .foregroundStyle(Color.gmTextPrimary)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.leading)
                                    .tint(transactionType.color)
                            }
                            .padding(.horizontal, GMSpacing.md)

                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [transactionType.color.opacity(0.8), transactionType.color.opacity(0.2)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(height: 1)
                                .padding(.horizontal, GMSpacing.md)
                        }

                        // ── Category Grid ──
                        VStack(alignment: .leading, spacing: GMSpacing.sm) {
                            Text("カテゴリ")
                                .font(GMFont.caption(12, weight: .semibold))
                                .foregroundStyle(Color.gmTextTertiary)
                                .tracking(1)
                                .padding(.horizontal, GMSpacing.md)

                            let cols = Array(repeating: GridItem(.flexible(), spacing: GMSpacing.sm), count: 4)
                            LazyVGrid(columns: cols, spacing: GMSpacing.sm) {
                                ForEach(categories, id: \.rawValue) { cat in
                                    CategoryChip(
                                        category: cat,
                                        isSelected: selectedCategory == cat
                                    ) { selectedCategory = cat }
                                }
                            }
                            .padding(.horizontal, GMSpacing.md)
                        }

                        // ── Date Picker ──
                        GMInputSection(title: "日付", icon: "calendar") {
                            Button {
                                withAnimation { showDatePicker.toggle() }
                            } label: {
                                HStack {
                                    Text(selectedDate.formatted(date: .long, time: .omitted))
                                        .font(GMFont.body(15))
                                        .foregroundStyle(Color.gmTextPrimary)
                                    Spacer()
                                    Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.gmGold)
                                }
                            }
                            .buttonStyle(.plain)

                            if showDatePicker {
                                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .tint(Color.gmGold)
                                    .preferredColorScheme(.dark)
                            }
                        }
                        .padding(.horizontal, GMSpacing.md)

                        // ── Memo ──
                        GMInputSection(title: "メモ", icon: "text.alignleft") {
                            TextField("例：ランチ、サブスク更新...", text: $memo)
                                .font(GMFont.body(15))
                                .foregroundStyle(Color.gmTextPrimary)
                                .tint(Color.gmGold)
                        }
                        .padding(.horizontal, GMSpacing.md)

                        // ── Save Button ──
                        Button {
                            saveTransaction()
                        } label: {
                            HStack(spacing: GMSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("保存する")
                                    .font(GMFont.heading(16, weight: .bold))
                            }
                            .foregroundStyle(Color.gmBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.gmGoldLight, Color.gmGold, Color.gmGoldDim],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: GMRadius.lg))
                            .shadow(color: Color.gmGold.opacity(0.4), radius: 12, x: 0, y: 4)
                        }
                        .disabled(parsedAmount <= 0)
                        .opacity(parsedAmount > 0 ? 1 : 0.45)
                        .padding(.horizontal, GMSpacing.md)
                        .padding(.bottom, GMSpacing.xl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("収支を記録")
                        .font(GMFont.heading(16, weight: .semibold))
                        .foregroundStyle(GMGradient.goldHorizontal)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.gmTextTertiary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.gmBackground)
    }

    private func saveTransaction() {
        let t = Transaction(
            type: transactionType,
            amount: parsedAmount,
            category: selectedCategory,
            date: selectedDate,
            memo: memo
        )
        // Persist via DataManager
        dm.addTransaction(t)
        // Haptic feedback
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        dismiss()
    }
}

// ─────────────────────────────────────────
// MARK: Supporting Views
// ─────────────────────────────────────────
struct CategoryChip: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? category.color.opacity(0.25) : Color.gmSurface)
                        .frame(height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    isSelected ? category.color : Color.gmGoldDim.opacity(0.2),
                                    lineWidth: isSelected ? 1.5 : 0.5
                                )
                        )

                    Image(systemName: category.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isSelected ? category.color : Color.gmTextTertiary)
                }
                Text(category.rawValue)
                    .font(GMFont.caption(9, weight: .medium))
                    .foregroundStyle(isSelected ? category.color : Color.gmTextTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

struct GMInputSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack(spacing: GMSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.gmGold)
                Text(title)
                    .font(GMFont.caption(12, weight: .semibold))
                    .foregroundStyle(Color.gmTextTertiary)
                    .tracking(1)
            }
            content()
                .padding(GMSpacing.md)
                .background(Color.gmSurface)
                .clipShape(RoundedRectangle(cornerRadius: GMRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: GMRadius.md)
                        .strokeBorder(Color.gmGoldDim.opacity(0.3), lineWidth: 0.5)
                )
        }
    }
}

// ─────────────────────────────────────────
// MARK: Preview
// ─────────────────────────────────────────
#Preview {
    IncomeExpenseInputView()
        .environmentObject(DataManager())
}
