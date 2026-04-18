// MARK: - MirrorView.swift
// Gold Mirror – SNS-style "Mirror" timeline.
// Shows anonymized peer asset snapshots as a motivational social feed.
// Now integrates OCRViewModel to display your income rank badge.

import SwiftUI

struct MirrorView: View {
    @EnvironmentObject var vm: AssetViewModel
    @EnvironmentObject var ocrVM: OCRViewModel
    @State private var showCompose = false

    var body: some View {
        ZStack {
            Color.gmBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Page Header
                    MirrorPageHeader(showCompose: $showCompose)
                        .padding(.bottom, GMSpacing.md)

                    // My Snapshot Card (pinned at top)
                    MySnapshotCard()
                        .padding(.horizontal, GMSpacing.md)
                        .padding(.bottom, GMSpacing.md)

                    // Income Rank Badge (visible if OCR scan has been confirmed)
                    if ocrVM.userProfile.annualIncome != nil {
                        IncomeRankBannerCard(profile: ocrVM.userProfile)
                            .padding(.horizontal, GMSpacing.md)
                            .padding(.bottom, GMSpacing.lg)
                    }

                    // Divider with label
                    HStack(spacing: GMSpacing.sm) {
                        Rectangle()
                            .fill(Color.gmGoldDim.opacity(0.4))
                            .frame(height: 0.5)
                        Text("みんなの資産状況")
                            .font(GMFont.caption(11, weight: .medium))
                            .foregroundStyle(Color.gmTextTertiary)
                            .fixedSize()
                        Rectangle()
                            .fill(Color.gmGoldDim.opacity(0.4))
                            .frame(height: 0.5)
                    }
                    .padding(.horizontal, GMSpacing.md)
                    .padding(.bottom, GMSpacing.lg)

                    // Timeline Posts
                    ForEach(vm.mirrorPosts) { post in
                        MirrorPostCard(post: post)
                            .padding(.horizontal, GMSpacing.md)
                            .padding(.bottom, GMSpacing.md)
                    }

                    Spacer().frame(height: 50)  // FAB overhang clearance only; safeAreaInset handles tab bar
                }
                .padding(.top, GMSpacing.md)
            }

            // Floating compose button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showCompose = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(GMGradient.goldDiagonal)
                                .frame(width: 56, height: 56)
                                .gmGoldGlow(radius: 16, opacity: 0.5)

                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color.black)
                        }
                    }
                    .padding(.trailing, GMSpacing.lg)
                    .padding(.bottom, 20) // small margin; safeAreaInset handles tab bar
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showCompose) {
            ComposePostView()
                .environmentObject(ocrVM)
        }
    }
}

// ─────────────────────────────────────────
// MARK: Income Rank Banner Card
// ─────────────────────────────────────────
struct IncomeRankBannerCard: View {
    let profile: UserProfile

    var body: some View {
        HStack(spacing: GMSpacing.md) {
            // Badge emoji
            Text(profile.incomeRank.badge)
                .font(.system(size: 40))

            VStack(alignment: .leading, spacing: GMSpacing.xs) {
                Text("あなたの年収ランク")
                    .font(GMFont.caption(11, weight: .medium))
                    .foregroundStyle(Color.gmTextTertiary)
                Text(profile.incomeRank.rawValue)
                    .font(GMFont.heading(18, weight: .bold))
                    .foregroundStyle(profile.incomeRank.color)
                Text(profile.incomeRank.topPercent)
                    .font(GMFont.caption(11))
                    .foregroundStyle(Color.gmTextTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: GMSpacing.xs) {
                if let income = profile.annualIncome {
                    Text("年収")
                        .font(GMFont.caption(10))
                        .foregroundStyle(Color.gmTextTertiary)
                    Text(income.jpyCompact)
                        .font(GMFont.mono(16, weight: .bold))
                        .foregroundStyle(Color.gmTextPrimary)
                }
                // Confirmed badge
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.gmPositive)
                    Text("OCR確認済み")
                        .font(GMFont.caption(10))
                        .foregroundStyle(Color.gmPositive)
                }
            }
        }
        .padding(GMSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [profile.incomeRank.color.opacity(0.10), Color(hex: "#0F0F0F")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GMRadius.lg)
                        .strokeBorder(profile.incomeRank.color.opacity(0.35), lineWidth: 0.8)
                )
        )
        .gmGoldGlow(radius: 12, opacity: 0.15)
    }
}

// ─────────────────────────────────────────
// MARK: Page Header
// ─────────────────────────────────────────
struct MirrorPageHeader: View {
    @Binding var showCompose: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("MIRROR")
                    .font(GMFont.caption(11, weight: .bold))
                    .foregroundStyle(Color.gmGold.opacity(0.7))
                    .tracking(3)
                Text("みんなの資産")
                    .font(GMFont.heading(22, weight: .bold))
                    .foregroundStyle(Color.gmTextPrimary)
            }

            Spacer()

            // Filter button
            Button { } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.gmGold)
                    .frame(width: 40, height: 40)
                    .background(Color.gmSurface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gmGoldDim.opacity(0.5), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, GMSpacing.md)
    }
}

// ─────────────────────────────────────────
// MARK: My Snapshot Card
// ─────────────────────────────────────────
struct MySnapshotCard: View {
    @EnvironmentObject var vm: AssetViewModel

    var body: some View {
        VStack(spacing: GMSpacing.md) {
            // Header row
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(GMGradient.goldDiagonal)
                        .frame(width: 48, height: 48)
                    Text("ME")
                        .font(GMFont.caption(13, weight: .bold))
                        .foregroundStyle(Color.black)
                }
                .gmGoldGlow(radius: 8, opacity: 0.4)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: GMSpacing.xs) {
                        Text("あなたの資産")
                            .font(GMFont.heading(15, weight: .semibold))
                            .foregroundStyle(Color.gmTextPrimary)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.gmGold)
                    }
                    Text("今月の状況")
                        .font(GMFont.caption(11))
                        .foregroundStyle(Color.gmTextTertiary)
                }

                Spacer()

                // Share button
                Button { } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12, weight: .semibold))
                        Text("シェア")
                            .font(GMFont.caption(12, weight: .semibold))
                    }
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, GMSpacing.sm)
                    .padding(.vertical, 6)
                    .background(GMGradient.goldHorizontal)
                    .clipShape(Capsule())
                }
            }

            // Stat row
            HStack(spacing: 0) {
                MirrorStatColumn(
                    label: "総資産",
                    value: vm.totalAssets.jpyCompact,
                    icon: "crown.fill",
                    color: .gmGold
                )
                Divider().frame(width: 0.5).background(Color.gmGoldDim.opacity(0.4))
                MirrorStatColumn(
                    label: "証券損益",
                    value: vm.totalSecuritiesProfitLoss.jpyCompact,
                    icon: vm.totalSecuritiesProfitLoss >= 0 ? "arrow.up.right" : "arrow.down.right",
                    color: vm.totalSecuritiesProfitLoss >= 0 ? .gmPositive : .gmNegative
                )
                Divider().frame(width: 0.5).background(Color.gmGoldDim.opacity(0.4))
                MirrorStatColumn(
                    label: "今月支出",
                    value: vm.totalMonthlyBilling.jpyCompact,
                    icon: "arrow.up.right.circle.fill",
                    color: .gmNegative
                )
            }
        }
        .padding(GMSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: GMRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1A1500"), Color(hex: "#0F0F0F")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GMRadius.lg)
                        .strokeBorder(GMGradient.goldHorizontal, lineWidth: 1.0)
                )
        )
        .gmGoldGlow(radius: 20, opacity: 0.25)
    }
}

struct MirrorStatColumn: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: GMSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(GMFont.mono(14, weight: .bold))
                .foregroundStyle(Color.gmTextPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(GMFont.caption(10))
                .foregroundStyle(Color.gmTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GMSpacing.sm)
    }
}

// ─────────────────────────────────────────
// MARK: Mirror Post Card
// ─────────────────────────────────────────
struct MirrorPostCard: View {
    let post: MirrorPost
    @State private var isLiked = false

    var body: some View {
        VStack(alignment: .leading, spacing: GMSpacing.md) {
            // ── User Info Row ──
            HStack(spacing: GMSpacing.sm) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.gmGoldDim.opacity(0.6),
                                    Color.gmSurfaceElevated
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Text(post.avatarInitials)
                        .font(GMFont.caption(13, weight: .bold))
                        .foregroundStyle(Color.gmGold)
                }
                .overlay(Circle().stroke(Color.gmGoldDim.opacity(0.5), lineWidth: 0.8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.displayName)
                        .font(GMFont.body(14, weight: .semibold))
                        .foregroundStyle(Color.gmTextPrimary)
                    HStack(spacing: GMSpacing.xs) {
                        Text(post.username)
                            .font(GMFont.caption(11))
                            .foregroundStyle(Color.gmTextTertiary)
                        Text("·")
                            .foregroundStyle(Color.gmTextTertiary)
                        Text(post.timeAgo)
                            .font(GMFont.caption(11))
                            .foregroundStyle(Color.gmTextTertiary)
                    }
                }

                Spacer()

                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.gmTextTertiary)
            }

            // ── Net Worth Change Badge ──
            HStack(spacing: GMSpacing.sm) {
                // Change pill
                HStack(spacing: 4) {
                    Image(systemName: post.netWorthChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 11, weight: .bold))
                    Text(post.netWorthChange >= 0 ?
                         "+\(post.netWorthChange.jpyCompact)" :
                         post.netWorthChange.jpyCompact)
                        .font(GMFont.caption(12, weight: .bold))
                }
                .foregroundStyle(post.netWorthChange >= 0 ? Color.gmPositive : Color.gmNegative)
                .padding(.horizontal, GMSpacing.sm)
                .padding(.vertical, GMSpacing.xs)
                .background(
                    Capsule().fill(
                        (post.netWorthChange >= 0 ? Color.gmPositive : Color.gmNegative).opacity(0.12)
                    )
                )

                // Savings rate pill
                HStack(spacing: 4) {
                    Image(systemName: "percent")
                        .font(.system(size: 10, weight: .bold))
                    Text("貯蓄率 \(post.savingsRate)%")
                        .font(GMFont.caption(12, weight: .bold))
                }
                .foregroundStyle(Color.gmGold)
                .padding(.horizontal, GMSpacing.sm)
                .padding(.vertical, GMSpacing.xs)
                .background(Capsule().fill(Color.gmGold.opacity(0.10)))

                Spacer()
            }

            // ── Message ──
            Text(post.message)
                .font(GMFont.body(14))
                .foregroundStyle(Color.gmTextSecondary)
                .lineSpacing(4)

            // ── Tagline ──
            Text(post.tagline)
                .font(GMFont.caption(11, weight: .medium))
                .foregroundStyle(Color.gmGold.opacity(0.7))

            // ── Action Row ──
            HStack(spacing: GMSpacing.lg) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundStyle(isLiked ? Color.gmNegative : Color.gmTextTertiary)
                            .scaleEffect(isLiked ? 1.2 : 1.0)
                        Text("\(post.likes + (isLiked ? 1 : 0))")
                            .font(GMFont.caption(12))
                            .foregroundStyle(Color.gmTextTertiary)
                    }
                }
                .buttonStyle(.plain)

                Button { } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.gmTextTertiary)
                        Text("\(post.comments)")
                            .font(GMFont.caption(12))
                            .foregroundStyle(Color.gmTextTertiary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Button { } label: {
                    Image(systemName: "bookmark")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.gmTextTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(GMSpacing.md)
        .gmCardStyle()
    }
}

// ─────────────────────────────────────────
// MARK: Compose Post Sheet
// ─────────────────────────────────────────
struct ComposePostView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ocrVM: OCRViewModel

    var body: some View {
        ZStack {
            Color.gmBackground.ignoresSafeArea()

            VStack(spacing: GMSpacing.lg) {
                HStack {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(Color.gmTextSecondary)
                    Spacer()
                    Text("資産状況をシェア")
                        .font(GMFont.heading(16, weight: .semibold))
                        .foregroundStyle(Color.gmTextPrimary)
                    Spacer()
                    Button("投稿") { dismiss() }
                        .font(GMFont.body(15, weight: .semibold))
                        .foregroundStyle(Color.gmGold)
                }
                .padding(GMSpacing.md)

                // Income rank preview if available
                if ocrVM.userProfile.annualIncome != nil {
                    IncomeRankBannerCard(profile: ocrVM.userProfile)
                        .padding(.horizontal, GMSpacing.md)
                }

                Spacer()

                Text("投稿機能は近日公開予定")
                    .font(GMFont.heading(18))
                    .foregroundStyle(Color.gmTextTertiary)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// ─────────────────────────────────────────
// MARK: Preview
// ─────────────────────────────────────────
#Preview {
    MirrorView()
        .environmentObject(AssetViewModel())
        .environmentObject(OCRViewModel())
}
