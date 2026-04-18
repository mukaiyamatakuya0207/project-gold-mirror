// MARK: - DashboardView.swift
// Gold Mirror – Rich black-and-gold asset dashboard.

import SwiftUI

// ─────────────────────────────────────────
// MARK: DashboardView
// ─────────────────────────────────────────
struct DashboardView: View {
    @EnvironmentObject var vm: AssetViewModel
    @EnvironmentObject var dm: DataManager
    @State private var showAllBankAccounts = false
    @State private var showAllSecurities   = false
    @State private var showNotifications   = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.gmBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 1. Custom Hero Header – fills behind status bar
                        DashboardHeaderView(
                            topInset: proxy.safeAreaInsets.top,
                            showNotifications: $showNotifications
                        )

                        // 2. Net Worth Summary Card  (20pt breathing room below header)
                        NetWorthSummaryCard()
                            .padding(.horizontal, GMSpacing.md)
                            .padding(.top, 20)
                            .padding(.bottom, GMSpacing.lg)

                        // 3. Next Billing Countdown Banner
                        if let summary = dm.nextBillingSummary {
                            NextBillingCountdownBanner(summary: summary)
                                .padding(.horizontal, GMSpacing.md)
                                .padding(.bottom, GMSpacing.lg)
                        }

                        // 4. Asset Allocation Bar
                        AssetAllocationBar()
                            .padding(.horizontal, GMSpacing.md)
                            .padding(.bottom, GMSpacing.lg)

                        // 5. Bank Accounts Section
                        SectionHeader(
                            title: "現金・預金",
                            icon: "building.columns.fill",
                            accentColor: .gmGold
                        ) { withAnimation { showAllBankAccounts.toggle() } }
                        .padding(.horizontal, GMSpacing.md)
                        .padding(.bottom, GMSpacing.sm)

                        ForEach(showAllBankAccounts ? dm.bankAccounts : Array(dm.bankAccounts.prefix(2))) { acct in
                            BankAccountRow(account: acct)
                                .padding(.horizontal, GMSpacing.md)
                                .padding(.bottom, GMSpacing.sm)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // 6. Securities Section
                        SectionHeader(
                            title: "証券・投資",
                            icon: "chart.line.uptrend.xyaxis",
                            accentColor: .gmGold
                        ) { withAnimation { showAllSecurities.toggle() } }
                        .padding(.horizontal, GMSpacing.md)
                        .padding(.top, GMSpacing.md)
                        .padding(.bottom, GMSpacing.sm)

                        ForEach(showAllSecurities ? dm.securitiesAccounts : Array(dm.securitiesAccounts.prefix(2))) { acct in
                            SecuritiesAccountRow(account: acct)
                                .padding(.horizontal, GMSpacing.md)
                                .padding(.bottom, GMSpacing.sm)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // 7. Credit Card Section
                        SectionHeader(
                            title: "今月の引き落とし",
                            icon: "creditcard.fill",
                            accentColor: .gmGold
                        ) { }
                        .padding(.horizontal, GMSpacing.md)
                        .padding(.top, GMSpacing.md)
                        .padding(.bottom, GMSpacing.sm)

                        CreditCardSummaryCard()
                            .padding(.horizontal, GMSpacing.md)
                            .padding(.bottom, GMSpacing.sm)

                        ForEach(dm.creditCards.prefix(2)) { card in
                            CreditCardRow(card: card)
                                .padding(.horizontal, GMSpacing.md)
                                .padding(.bottom, GMSpacing.sm)
                        }

                        Spacer().frame(height: 100)
                    }
                }
                .ignoresSafeArea(.container, edges: .top)
            }
        }
        // ── Hide system navigation bar + its reserved space ──
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        // ── Notification sheet ──
        .sheet(isPresented: $showNotifications) {
            NotificationHistoryView()
        }
    }
}

// ─────────────────────────────────────────
// MARK: Dashboard Header
// ─────────────────────────────────────────
struct DashboardHeaderView: View {
    let topInset: CGFloat
    @Binding var showNotifications: Bool

    private var greeting: String {
        let h = Calendar.gmJapan.component(.hour, from: Date())
        switch h {
        case 5..<12:  return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default:      return "Good Night"
        }
    }

    private var dateStr: String {
        Date().japaneseDateString
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "#0F0D03"), Color.gmBackground],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: GMSpacing.xs) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting)
                            .font(GMFont.caption(13, weight: .medium))
                            .foregroundStyle(Color.gmGold.opacity(0.8))
                        Text("Gold Mirror")
                            .font(GMFont.display(30, weight: .bold))
                            .foregroundStyle(GMGradient.goldHorizontal)
                    }
                    Spacer()
                    Button { showNotifications = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.gmTextSecondary)
                                .frame(width: 44, height: 44)
                                .background(Color.gmSurface)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gmGoldDim.opacity(0.4),
                                                         lineWidth: 0.5))
                            Circle()
                                .fill(Color.gmGold)
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                Text(dateStr)
                    .font(GMFont.caption(12))
                    .foregroundStyle(Color.gmTextTertiary)
            }
            .padding(.horizontal, GMSpacing.md)
            .padding(.top, max(topInset, 0) + GMSpacing.sm)
            .padding(.bottom, GMSpacing.sm)
        }
        .frame(height: max(topInset, 0) + 86)
    }
}

// ─────────────────────────────────────────
// MARK: Net Worth Summary Card
// ─────────────────────────────────────────
struct NetWorthSummaryCard: View {
    @EnvironmentObject var dm: DataManager
    @State private var isVisible = true

    var body: some View {
        VStack(spacing: 0) {
            // Top section
            VStack(spacing: GMSpacing.xs) {
                HStack {
                    Text("総資産")
                        .font(GMFont.caption(12, weight: .medium))
                        .foregroundStyle(Color.gmTextSecondary)
                        .tracking(2)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { isVisible.toggle() }
                    } label: {
                        Image(systemName: isVisible ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.gmTextTertiary)
                    }
                }
                Group {
                    if isVisible {
                        Text(dm.totalAssets.jpyFormatted)
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
                .animation(.easeInOut(duration: 0.2), value: isVisible)
            }
            .padding(GMSpacing.lg)
            .background(GMGradient.summaryCard)

            Rectangle()
                .fill(GMGradient.goldHorizontal)
                .frame(height: 0.5)

            HStack(spacing: 0) {
                SummaryStatColumn(
                    label: "現金・預金",
                    value: isVisible ? dm.totalBankBalance.jpyCompact : "••••",
                    icon: "banknote.fill", color: .gmGold
                )
                Divider().frame(width: 0.5)
                    .background(Color.gmGoldDim.opacity(0.4))
                    .padding(.vertical, GMSpacing.md)
                SummaryStatColumn(
                    label: "証券評価額",
                    value: isVisible ? dm.totalSecuritiesValue.jpyCompact : "••••",
                    icon: "chart.line.uptrend.xyaxis",
                    color: dm.totalSecuritiesProfitLoss >= 0 ? .gmPositive : .gmNegative,
                    subValue: isVisible ? dm.totalSecuritiesProfitLossRate.signedPercent : nil
                )
                Divider().frame(width: 0.5)
                    .background(Color.gmGoldDim.opacity(0.4))
                    .padding(.vertical, GMSpacing.md)
                SummaryStatColumn(
                    label: "今月引き落とし",
                    value: isVisible ? dm.totalMonthlyCardBilling.jpyCompact : "••••",
                    icon: "arrow.up.right", color: .gmNegative
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
                        startPoint: .topLeading, endPoint: .bottomTrailing
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
                Text(sub).font(GMFont.caption(10)).foregroundStyle(color)
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
    @EnvironmentObject var dm: DataManager

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.sm) {
            HStack {
                Text("アセット配分")
                    .font(GMFont.caption(12, weight: .semibold))
                    .foregroundStyle(Color.gmTextSecondary)
                    .tracking(1)
                Spacer()
                Text("現金 \(Int(dm.bankRatio * 100))%  /  証券 \(Int((1 - dm.bankRatio) * 100))%")
                    .font(GMFont.caption(11))
                    .foregroundStyle(Color.gmTextTertiary)
            }
            GeometryReader { geo in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GMGradient.goldDiagonal)
                        .frame(width: max(geo.size.width * CGFloat(dm.bankRatio) - 2, 0))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [Color(hex: "#1A4A2A"), Color(hex: "#2E7D4F")],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 8)
            }
            .frame(height: 8)
            HStack {
                LegendDot(color: .gmGold, label: "現金・預金 \(dm.totalBankBalance.jpyCompact)")
                Spacer()
                LegendDot(color: Color(hex: "#2E7D4F"), label: "証券 \(dm.totalSecuritiesValue.jpyCompact)")
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

struct LegendDot: View {
    let color: Color; let label: String
    var body: some View {
        HStack(spacing: GMSpacing.xs) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(GMFont.caption(11)).foregroundStyle(Color.gmTextSecondary)
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
            ZStack {
                RoundedRectangle(cornerRadius: GMRadius.sm)
                    .fill(Color.gmGold.opacity(0.1)).frame(width: 44, height: 44)
                Image(systemName: account.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.gmGold)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(account.name).font(GMFont.body(14, weight: .medium)).foregroundStyle(Color.gmTextPrimary)
                Text(account.bankName).font(GMFont.caption(11)).foregroundStyle(Color.gmTextTertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(account.balance.jpyFormatted).font(GMFont.mono(15, weight: .bold)).foregroundStyle(Color.gmTextPrimary)
                Text(account.accountNumber).font(GMFont.caption(10)).foregroundStyle(Color.gmTextTertiary)
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
            ZStack {
                RoundedRectangle(cornerRadius: GMRadius.sm)
                    .fill((account.profitLoss >= 0 ? Color.gmPositive : Color.gmNegative).opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: account.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(account.profitLoss >= 0 ? Color.gmPositive : Color.gmNegative)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(account.name).font(GMFont.body(14, weight: .medium)).foregroundStyle(Color.gmTextPrimary)
                Text(account.brokerageName).font(GMFont.caption(11)).foregroundStyle(Color.gmTextTertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(account.evaluationAmount.jpyFormatted).font(GMFont.mono(15, weight: .bold)).foregroundStyle(Color.gmTextPrimary)
                HStack(spacing: 3) {
                    Image(systemName: account.profitLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                    Text(account.profitLossRate.signedPercent).font(GMFont.caption(11, weight: .semibold))
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
    @EnvironmentObject var dm: DataManager
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: GMSpacing.xs) {
                Text("今月合計引き落とし予定")
                    .font(GMFont.caption(11, weight: .medium))
                    .foregroundStyle(Color.gmTextTertiary).tracking(1)
                Text(dm.totalMonthlyCardBilling.jpyFormatted)
                    .font(GMFont.display(26, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: GMSpacing.xs) {
                Text("\(dm.creditCards.count)枚のカード")
                    .font(GMFont.caption(11)).foregroundStyle(Color.gmTextTertiary)
                HStack(spacing: -8) {
                    ForEach(dm.creditCards.prefix(3)) { _ in
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 22)).foregroundStyle(GMGradient.goldHorizontal)
                    }
                }
            }
        }
        .padding(GMSpacing.md)
        .background(RoundedRectangle(cornerRadius: GMRadius.lg)
            .fill(LinearGradient(colors: [Color(hex: "#1A0D00"), Color(hex: "#0F0A00")],
                                 startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(RoundedRectangle(cornerRadius: GMRadius.lg)
            .strokeBorder(Color.gmGold.opacity(0.3), lineWidth: 0.8))
    }
}

// ─────────────────────────────────────────
// MARK: Credit Card Row
// ─────────────────────────────────────────
struct CreditCardRow: View {
    let card: CreditCard
    var body: some View {
        HStack(spacing: GMSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: GMRadius.sm)
                    .fill(Color(hex: card.accentColorHex).opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: card.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(hex: card.accentColorHex))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(card.cardName).font(GMFont.body(14, weight: .medium)).foregroundStyle(Color.gmTextPrimary)
                HStack(spacing: GMSpacing.xs) {
                    Image(systemName: "clock.fill").font(.system(size: 9))
                    Text("毎月\(card.billingDay)日引き落とし").font(GMFont.caption(11))
                }
                .foregroundStyle(Color.gmTextTertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(card.nextBillingAmount.jpyFormatted).font(GMFont.mono(14, weight: .bold)).foregroundStyle(Color.gmTextPrimary)
                Text("****\(card.cardLastFour)").font(GMFont.caption(10)).foregroundStyle(Color.gmTextTertiary)
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Next Billing Countdown Banner
// ─────────────────────────────────────────
struct NextBillingCountdownBanner: View {
    let summary: NextBillingSummary
    var body: some View {
        HStack(spacing: GMSpacing.md) {
            ZStack {
                Circle().stroke(Color.gmGoldDim.opacity(0.3), lineWidth: 2.5).frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: CGFloat(1.0 - Double(summary.daysUntil) / 31.0))
                    .stroke(Color.gmGold, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90)).frame(width: 52, height: 52)
                VStack(spacing: 0) {
                    Text("\(summary.daysUntil)").font(GMFont.mono(16, weight: .bold)).foregroundStyle(Color.gmGold)
                    Text("日後").font(GMFont.caption(8)).foregroundStyle(Color.gmTextTertiary)
                }
            }
            .gmGoldGlow(radius: 8, opacity: 0.25)
            VStack(alignment: .leading, spacing: 3) {
                Text("次の引き落とし").font(GMFont.caption(11)).foregroundStyle(Color.gmTextTertiary)
                Text(summary.totalAmount.jpyFormatted).font(GMFont.mono(18, weight: .bold)).foregroundStyle(Color.gmTextPrimary)
                Text(summary.cards.map { $0.cardName }.joined(separator: " / "))
                    .font(GMFont.caption(10)).foregroundStyle(Color.gmTextTertiary).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.gmGold)
        }
        .padding(GMSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .fill(LinearGradient(colors: [Color(hex: "#1A1000"), Color(hex: "#0F0F0F")],
                                     startPoint: .leading, endPoint: .trailing))
                .overlay(RoundedRectangle(cornerRadius: GMRadius.lg)
                    .strokeBorder(GMGradient.goldHorizontal, lineWidth: 0.8))
        )
        .gmGoldGlow(radius: 10, opacity: 0.15)
    }
}

// ─────────────────────────────────────────
// MARK: Preview
// ─────────────────────────────────────────
#Preview {
    NavigationStack {
        DashboardView()
            .environmentObject(AssetViewModel())
            .environmentObject(DataManager())
    }
}
