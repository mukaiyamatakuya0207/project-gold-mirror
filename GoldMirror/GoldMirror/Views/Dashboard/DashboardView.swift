// MARK: - DashboardView.swift
// Gold Mirror – Rich black-and-gold asset dashboard.

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var vm: AssetViewModel
    @State private var headerParallax: CGFloat = 0
    @State private var showAllBankAccounts = false
    @State private var showAllSecurities   = false

    var body: some View {
        ZStack {
            // ── Full-screen background ──
            Color.gmBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 1. Hero Header
                    DashboardHeaderView()
                        .padding(.bottom, GMSpacing.lg)

                    // 2. Net Worth Summary Card
                    NetWorthSummaryCard()
                        .padding(.horizontal, GMSpacing.md)
                        .padding(.bottom, GMSpacing.lg)

                    // 3. Asset Allocation Bar
                    AssetAllocationBar()
                        .padding(.horizontal, GMSpacing.md)
                        .padding(.bottom, GMSpacing.lg)

                    // 4. Bank Accounts Section
                    SectionHeader(title: "現金・預金", icon: "building.columns.fill", accentColor: .gmGold) {
                        withAnimation { showAllBankAccounts.toggle() }
                    }
                    .padding(.horizontal, GMSpacing.md)
                    .padding(.bottom, GMSpacing.sm)

                    ForEach(showAllBankAccounts ? vm.bankAccounts : Array(vm.bankAccounts.prefix(2))) { account in
                        BankAccountRow(account: account)
                            .padding(.horizontal, GMSpacing.md)
                            .padding(.bottom, GMSpacing.sm)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // 5. Securities Section
                    SectionHeader(title: "証券・投資", icon: "chart.line.uptrend.xyaxis", accentColor: .gmGold) {
                        withAnimation { showAllSecurities.toggle() }
                    }
                    .padding(.horizontal, GMSpacing.md)
                    .padding(.top, GMSpacing.md)
                    .padding(.bottom, GMSpacing.sm)

                    ForEach(showAllSecurities ? vm.securitiesAccounts : Array(vm.securitiesAccounts.prefix(2))) { account in
                        SecuritiesAccountRow(account: account)
                            .padding(.horizontal, GMSpacing.md)
                            .padding(.bottom, GMSpacing.sm)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // 6. Credit Card Section
                    SectionHeader(title: "今月の引き落とし", icon: "creditcard.fill", accentColor: .gmGold) {
                        // navigate to full card list
                    }
                    .padding(.horizontal, GMSpacing.md)
                    .padding(.top, GMSpacing.md)
                    .padding(.bottom, GMSpacing.sm)

                    CreditCardSummaryCard()
                        .padding(.horizontal, GMSpacing.md)
                        .padding(.bottom, GMSpacing.sm)

                    ForEach(vm.creditCards) { card in
                        CreditCardRow(card: card)
                            .padding(.horizontal, GMSpacing.md)
                            .padding(.bottom, GMSpacing.sm)
                    }

                    // Bottom padding for tab bar
                    Spacer().frame(height: 100)
                }
            }
        }
    }
}

// ─────────────────────────────────────────
// MARK: Dashboard Header
// ─────────────────────────────────────────
struct DashboardHeaderView: View {
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default:      return "Good Night"
        }
    }

    private var dateString: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ja_JP")
        fmt.dateFormat = "yyyy年M月d日 (E)"
        return fmt.string(from: Date())
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background with subtle gold vignette
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#0F0D03"),
                            Color.gmBackground
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 140)

            // Decorative gold orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.gmGold.opacity(0.25), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .offset(x: -60, y: -40)
                .blur(radius: 20)

            VStack(alignment: .leading, spacing: GMSpacing.xs) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greetingText)
                            .font(GMFont.caption(13, weight: .medium))
                            .foregroundStyle(Color.gmGold.opacity(0.8))

                        Text("Gold Mirror")
                            .font(GMFont.display(30, weight: .bold))
                            .foregroundStyle(GMGradient.goldHorizontal)
                    }

                    Spacer()

                    // Notification bell
                    Button {
                        // notifications
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.gmTextSecondary)
                                .frame(width: 44, height: 44)
                                .background(Color.gmSurface)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color.gmGoldDim.opacity(0.5), lineWidth: 0.5)
                                )

                            Circle()
                                .fill(Color.gmGold)
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: -2)
                        }
                    }
                }

                Text(dateString)
                    .font(GMFont.caption(12))
                    .foregroundStyle(Color.gmTextTertiary)
            }
            .padding(.horizontal, GMSpacing.md)
            .padding(.bottom, GMSpacing.md)
        }
    }
}

// ─────────────────────────────────────────
// MARK: Net Worth Summary Card
// ─────────────────────────────────────────
struct NetWorthSummaryCard: View {
    @EnvironmentObject var vm: AssetViewModel
    @State private var isAmountVisible = true

    var body: some View {
        VStack(spacing: 0) {
            // ── Top: Total Assets ──
            VStack(spacing: GMSpacing.xs) {
                HStack {
                    Text("総資産")
                        .font(GMFont.caption(12, weight: .medium))
                        .foregroundStyle(Color.gmTextSecondary)
                        .tracking(2)

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isAmountVisible.toggle()
                        }
                    } label: {
                        Image(systemName: isAmountVisible ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.gmTextTertiary)
                    }
                }

                HStack(alignment: .lastTextBaseline, spacing: GMSpacing.xs) {
                    if isAmountVisible {
                        Text(vm.totalAssets.jpyFormatted)
                            .font(GMFont.display(38, weight: .bold))
                            .foregroundStyle(GMGradient.goldHorizontal)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("¥ ••••••••")
                            .font(GMFont.display(38, weight: .bold))
                            .foregroundStyle(Color.gmTextTertiary)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(GMSpacing.lg)
            .background(GMGradient.summaryCard)

            // ── Gold divider ──
            Rectangle()
                .fill(GMGradient.goldHorizontal)
                .frame(height: 0.5)

            // ── Bottom: 3-column breakdown ──
            HStack(spacing: 0) {
                SummaryStatColumn(
                    label: "現金・預金",
                    value: isAmountVisible ? vm.totalBankBalance.jpyCompact : "••••",
                    icon: "banknote.fill",
                    color: Color.gmGold
                )

                Divider()
                    .frame(width: 0.5)
                    .background(Color.gmGoldDim.opacity(0.4))
                    .padding(.vertical, GMSpacing.md)

                SummaryStatColumn(
                    label: "証券評価額",
                    value: isAmountVisible ? vm.totalSecuritiesValue.jpyCompact : "••••",
                    icon: "chart.line.uptrend.xyaxis",
                    color: vm.totalSecuritiesProfitLoss >= 0 ? .gmPositive : .gmNegative,
                    subValue: isAmountVisible ? vm.totalSecuritiesProfitLossRate.signedPercent : nil
                )

                Divider()
                    .frame(width: 0.5)
                    .background(Color.gmGoldDim.opacity(0.4))
                    .padding(.vertical, GMSpacing.md)

                SummaryStatColumn(
                    label: "今月引き落とし",
                    value: isAmountVisible ? vm.totalMonthlyBilling.jpyCompact : "••••",
                    icon: "arrow.up.right",
                    color: .gmNegative
                )
            }
            .background(Color.gmSurface)
        }
        .clipShape(RoundedRectangle(cornerRadius: GMRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.gmGold.opacity(0.5), Color.gmGoldDim.opacity(0.2), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .gmGoldGlow(radius: 16, opacity: 0.2)
    }
}

struct SummaryStatColumn: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    var subValue: String? = nil

    var body: some View {
        VStack(spacing: GMSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(GMFont.mono(16, weight: .bold))
                .foregroundStyle(Color.gmTextPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            if let sub = subValue {
                Text(sub)
                    .font(GMFont.caption(10))
                    .foregroundStyle(color)
            }

            Text(label)
                .font(GMFont.caption(10, weight: .medium))
                .foregroundStyle(Color.gmTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GMSpacing.md)
    }
}

// ─────────────────────────────────────────
// MARK: Asset Allocation Bar
// ─────────────────────────────────────────
struct AssetAllocationBar: View {
    @EnvironmentObject var vm: AssetViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Text("アセット配分")
                    .font(GMFont.caption(12, weight: .semibold))
                    .foregroundStyle(Color.gmTextSecondary)
                    .tracking(1)
                Spacer()
                Text("現金 \(Int(vm.bankRatio * 100))%  /  証券 \(Int((1 - vm.bankRatio) * 100))%")
                    .font(GMFont.caption(11))
                    .foregroundStyle(Color.gmTextTertiary)
            }

            GeometryReader { geo in
                HStack(spacing: 2) {
                    // Bank portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GMGradient.goldDiagonal)
                        .frame(width: max(geo.size.width * CGFloat(vm.bankRatio) - 2, 0))

                    // Securities portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#1A4A2A"), Color(hex: "#2E7D4F")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 8)
            }
            .frame(height: 8)

            HStack {
                LegendDot(color: .gmGold, label: "現金・預金 \(vm.totalBankBalance.jpyCompact)")
                Spacer()
                LegendDot(color: Color(hex: "#2E7D4F"), label: "証券 \(vm.totalSecuritiesValue.jpyCompact)")
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: GMSpacing.xs) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(GMFont.caption(11))
                .foregroundStyle(Color.gmTextSecondary)
        }
    }
}

// ─────────────────────────────────────────
// MARK: Section Header
// ─────────────────────────────────────────
struct SectionHeader: View {
    let title: String
    let icon: String
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: GMSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accentColor)

                Text(title)
                    .font(GMFont.heading(15, weight: .semibold))
                    .foregroundStyle(Color.gmTextPrimary)
            }

            Spacer()

            Button(action: action) {
                Text("すべて表示")
                    .font(GMFont.caption(12))
                    .foregroundStyle(Color.gmGold)
            }
        }
    }
}

// ─────────────────────────────────────────
// MARK: Bank Account Row
// ─────────────────────────────────────────
struct BankAccountRow: View {
    let account: BankAccount

    var body: some View {
        HStack(spacing: GMSpacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: GMRadius.sm)
                    .fill(Color.gmGold.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: account.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.gmGold)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(account.name)
                    .font(GMFont.body(14, weight: .medium))
                    .foregroundStyle(Color.gmTextPrimary)
                Text(account.bankName)
                    .font(GMFont.caption(11))
                    .foregroundStyle(Color.gmTextTertiary)
            }

            Spacer()

            // Balance
            VStack(alignment: .trailing, spacing: 2) {
                Text(account.balance.jpyFormatted)
                    .font(GMFont.mono(15, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
                Text(account.accountNumber)
                    .font(GMFont.caption(10))
                    .foregroundStyle(Color.gmTextTertiary)
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Securities Account Row
// ─────────────────────────────────────────
struct SecuritiesAccountRow: View {
    let account: SecuritiesAccount

    var body: some View {
        HStack(spacing: GMSpacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: GMRadius.sm)
                    .fill((account.profitLoss >= 0 ? Color.gmPositive : Color.gmNegative).opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: account.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(account.profitLoss >= 0 ? Color.gmPositive : Color.gmNegative)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(account.name)
                    .font(GMFont.body(14, weight: .medium))
                    .foregroundStyle(Color.gmTextPrimary)
                Text(account.brokerageName)
                    .font(GMFont.caption(11))
                    .foregroundStyle(Color.gmTextTertiary)
            }

            Spacer()

            // Value + P/L
            VStack(alignment: .trailing, spacing: 3) {
                Text(account.evaluationAmount.jpyFormatted)
                    .font(GMFont.mono(15, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)

                HStack(spacing: 3) {
                    Image(systemName: account.profitLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                    Text(account.profitLossRate.signedPercent)
                        .font(GMFont.caption(11, weight: .semibold))
                }
                .foregroundStyle(account.profitLoss >= 0 ? Color.gmPositive : Color.gmNegative)
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Credit Card Summary Card
// ─────────────────────────────────────────
struct CreditCardSummaryCard: View {
    @EnvironmentObject var vm: AssetViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: GMSpacing.xs) {
                Text("今月合計引き落とし予定")
                    .font(GMFont.caption(11, weight: .medium))
                    .foregroundStyle(Color.gmTextTertiary)
                    .tracking(1)

                Text(vm.totalMonthlyBilling.jpyFormatted)
                    .font(GMFont.display(26, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: GMSpacing.xs) {
                Text("\(vm.creditCards.count)枚のカード")
                    .font(GMFont.caption(11))
                    .foregroundStyle(Color.gmTextTertiary)

                HStack(spacing: -8) {
                    ForEach(vm.creditCards.prefix(3)) { _ in
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(GMGradient.goldHorizontal)
                    }
                }
            }
        }
        .padding(GMSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1A0D00"), Color(hex: "#0F0A00")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .strokeBorder(Color.gmGold.opacity(0.3), lineWidth: 0.8)
        )
    }
}

// ─────────────────────────────────────────
// MARK: Credit Card Row
// ─────────────────────────────────────────
struct CreditCardRow: View {
    let card: CreditCard

    var body: some View {
        HStack(spacing: GMSpacing.md) {
            // Card icon
            ZStack {
                RoundedRectangle(cornerRadius: GMRadius.sm)
                    .fill(Color(hex: card.accentColorHex).opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: card.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(hex: card.accentColorHex))
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(card.cardName)
                    .font(GMFont.body(14, weight: .medium))
                    .foregroundStyle(Color.gmTextPrimary)
                HStack(spacing: GMSpacing.xs) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 9))
                    Text("毎月\(card.billingDay)日引き落とし")
                        .font(GMFont.caption(11))
                }
                .foregroundStyle(Color.gmTextTertiary)
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(card.nextBillingAmount.jpyFormatted)
                    .font(GMFont.mono(14, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
                Text("****\(card.cardLastFour)")
                    .font(GMFont.caption(10))
                    .foregroundStyle(Color.gmTextTertiary)
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Preview
// ─────────────────────────────────────────
#Preview {
    DashboardView()
        .environmentObject(AssetViewModel())
}
