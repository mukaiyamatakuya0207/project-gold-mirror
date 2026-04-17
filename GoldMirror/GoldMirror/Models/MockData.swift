// MARK: - MockData.swift
// Gold Mirror – Preview & development mock data.
// All amounts are fictional and for UI demonstration only.

import Foundation

struct MockData {

    // ─────────────────────────────────────────
    // MARK: Bank Accounts
    // ─────────────────────────────────────────
    static let bankAccounts: [BankAccount] = [
        BankAccount(
            name: "メイン生活口座",
            bankName: "三菱UFJ銀行",
            balance: 3_280_000,
            accountNumber: "****4521",
            iconName: "building.columns.fill"
        ),
        BankAccount(
            name: "緊急予備口座",
            bankName: "楽天銀行",
            balance: 1_500_000,
            accountNumber: "****8830",
            iconName: "shield.fill"
        ),
        BankAccount(
            name: "旅行・趣味口座",
            bankName: "ソニー銀行",
            balance: 420_000,
            accountNumber: "****2274",
            iconName: "airplane"
        )
    ]

    // ─────────────────────────────────────────
    // MARK: Securities Accounts
    // ─────────────────────────────────────────
    static let securitiesAccounts: [SecuritiesAccount] = [
        SecuritiesAccount(
            name: "NISA（成長投資枠）",
            brokerageName: "SBI証券",
            evaluationAmount: 4_820_000,
            purchaseAmount: 3_600_000,
            iconName: "chart.line.uptrend.xyaxis"
        ),
        SecuritiesAccount(
            name: "つみたて NISA",
            brokerageName: "SBI証券",
            evaluationAmount: 1_350_000,
            purchaseAmount: 1_080_000,
            iconName: "arrow.triangle.2.circlepath"
        ),
        SecuritiesAccount(
            name: "特定口座（米国株）",
            brokerageName: "楽天証券",
            evaluationAmount: 2_130_000,
            purchaseAmount: 2_400_000,
            iconName: "globe.americas.fill"
        )
    ]

    // ─────────────────────────────────────────
    // MARK: Credit Cards
    // ─────────────────────────────────────────
    static let creditCards: [CreditCard] = [
        CreditCard(
            cardName: "楽天カード Platinum",
            issuerName: "楽天カード株式会社",
            billingDay: 27,
            nextBillingAmount: 128_400,
            creditLimit: 3_000_000,
            currentUsage: 128_400,
            cardLastFour: "4821",
            iconName: "creditcard.fill",
            accentColorHex: "#D4AF37"
        ),
        CreditCard(
            cardName: "SBI プラチナ",
            issuerName: "三井住友カード",
            billingDay: 10,
            nextBillingAmount: 64_800,
            creditLimit: 5_000_000,
            currentUsage: 64_800,
            cardLastFour: "9034",
            iconName: "creditcard.fill",
            accentColorHex: "#A0A0A0"
        ),
        CreditCard(
            cardName: "Amex Gold",
            issuerName: "American Express",
            billingDay: 22,
            nextBillingAmount: 215_600,
            creditLimit: 10_000_000,
            currentUsage: 215_600,
            cardLastFour: "1005",
            iconName: "creditcard.fill",
            accentColorHex: "#CFB53B"
        )
    ]

    // ─────────────────────────────────────────
    // MARK: Computed Summary
    // ─────────────────────────────────────────
    static var portfolioSummary: PortfolioSummary {
        let bankTotal = bankAccounts.reduce(0) { $0 + $1.balance }
        let secTotal  = securitiesAccounts.reduce(0) { $0 + $1.evaluationAmount }
        let cardTotal = creditCards.reduce(0) { $0 + $1.nextBillingAmount }
        return PortfolioSummary(
            totalBankBalance: bankTotal,
            totalSecuritiesValue: secTotal,
            totalMonthlyBilling: cardTotal
        )
    }

    // ─────────────────────────────────────────
    // MARK: SNS Mirror Posts (Mock)
    // ─────────────────────────────────────────
    static let mirrorPosts: [MirrorPost] = [
        MirrorPost(
            username: "@invest_kazu",
            displayName: "KazuMoney",
            avatarInitials: "KM",
            timeAgo: "2分前",
            netWorthChange: +340_000,
            savingsRate: 42,
            message: "今月の積立完了！S&P500が好調で含み益が過去最高に。コツコツ続けることが大事だと改めて実感。",
            likes: 128,
            comments: 14,
            tagline: "FIRE目指し中 🔥"
        ),
        MirrorPost(
            username: "@yuki_asset",
            displayName: "Yuki財テク",
            avatarInitials: "YA",
            timeAgo: "15分前",
            netWorthChange: -85_000,
            savingsRate: 28,
            message: "今月はボーナス前で少しマイナス。でも年間目標の85%は達成済み。来月取り返す！",
            likes: 89,
            comments: 7,
            tagline: "30代・都内在住"
        ),
        MirrorPost(
            username: "@mr_dividend",
            displayName: "配当王子",
            avatarInitials: "DK",
            timeAgo: "1時間前",
            netWorthChange: +1_200_000,
            savingsRate: 55,
            message: "今月の配当金が入金されました💰 高配当株ポートフォリオの威力を感じる一ヶ月でした。不労所得の最大化を目指します。",
            likes: 312,
            comments: 45,
            tagline: "配当金で家賃カバー済み"
        ),
        MirrorPost(
            username: "@satsuki_fire",
            displayName: "さつきFIRE",
            avatarInitials: "SF",
            timeAgo: "3時間前",
            netWorthChange: +520_000,
            savingsRate: 61,
            message: "FIRE達成まで残り ¥8.2M！毎月の進捗をここで共有することでモチベ維持できています。",
            likes: 204,
            comments: 31,
            tagline: "36歳・FIRE目標42歳"
        )
    ]

    // ─────────────────────────────────────────
    // MARK: Fixed Costs
    // ─────────────────────────────────────────
    static let fixedCosts: [FixedCost] = [
        FixedCost(
            name: "家賃",
            amount: 148_000,
            billingDay: 27,
            category: .rent,
            memo: "東京都港区 1LDK"
        ),
        FixedCost(
            name: "電気・ガス",
            amount: 12_000,
            billingDay: 10,
            category: .utilities,
            memo: "東京電力 + 東京ガス"
        ),
        FixedCost(
            name: "生命保険",
            amount: 24_500,
            billingDay: 1,
            category: .insurance,
            memo: "住友生命 スミセイ"
        ),
        FixedCost(
            name: "奨学金返済",
            amount: 16_000,
            billingDay: 27,
            category: .loan,
            memo: "日本学生支援機構"
        ),
        FixedCost(
            name: "英会話スクール",
            amount: 29_800,
            billingDay: 15,
            category: .education,
            memo: "オンライン英会話 毎週2回"
        )
    ]

    // ─────────────────────────────────────────
    // MARK: Subscriptions
    // ─────────────────────────────────────────
    static let subscriptions: [Subscription] = [
        Subscription(
            name: "Netflix",
            amount: 1_980,
            billingDay: 5,
            billingCycle: .monthly,
            contractEndDate: nil,
            iconName: "play.rectangle.fill",
            accentColorHex: "#E50914"
        ),
        Subscription(
            name: "Apple One",
            amount: 1_200,
            billingDay: 14,
            billingCycle: .monthly,
            contractEndDate: nil,
            iconName: "applelogo",
            accentColorHex: "#A8A8A8"
        ),
        Subscription(
            name: "Spotify",
            amount: 980,
            billingDay: 8,
            billingCycle: .monthly,
            contractEndDate: nil,
            iconName: "music.note",
            accentColorHex: "#1DB954"
        ),
        Subscription(
            name: "ChatGPT Plus",
            amount: 3_000,
            billingDay: 20,
            billingCycle: .monthly,
            contractEndDate: nil,
            iconName: "brain.head.profile",
            accentColorHex: "#10A37F"
        ),
        Subscription(
            name: "Adobe CC",
            amount: 6_480,
            billingDay: 3,
            billingCycle: .monthly,
            contractEndDate: nil,
            iconName: "paintbrush.fill",
            accentColorHex: "#FF0000"
        ),
        Subscription(
            name: "iCloud 2TB",
            amount: 1_300,
            billingDay: 22,
            billingCycle: .monthly,
            contractEndDate: nil,
            iconName: "icloud.fill",
            accentColorHex: "#4FC3F7"
        ),
        Subscription(
            name: "日経電子版",
            amount: 4_277,
            billingDay: 1,
            billingCycle: .monthly,
            contractEndDate: nil,
            iconName: "newspaper.fill",
            accentColorHex: "#D4AF37"
        )
    ]
}

// SNS投稿モデル
struct MirrorPost: Identifiable {
    let id = UUID()
    var username: String
    var displayName: String
    var avatarInitials: String
    var timeAgo: String
    var netWorthChange: Double   // 今月の資産変動
    var savingsRate: Int         // 貯蓄率 (%)
    var message: String
    var likes: Int
    var comments: Int
    var tagline: String
}
