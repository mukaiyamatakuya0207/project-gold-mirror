# Gold Mirror – README

## プロジェクト概要

**Gold Mirror（ゴールド・ミラー）** は、資産管理にストイックな層向けのiOSアプリです。  
ブラック × ゴールドの高級感あるデザインで、現金・証券・クレジットカードを一元管理し、他ユーザーの収支状況を「鏡」のように可視化できます。

---

## ファイル構成

```
GoldMirror/
├── project.yml                          # XcodeGen 設定ファイル
└── GoldMirror/
    ├── GoldMirrorApp.swift              # @main エントリーポイント
    │
    ├── Models/
    │   ├── AssetModels.swift            # データモデル定義
    │   │   ├── BankAccount             # 銀行口座
    │   │   ├── SecuritiesAccount       # 証券口座
    │   │   ├── CreditCard              # クレジットカード
    │   │   └── PortfolioSummary        # 計算済み集計値
    │   └── MockData.swift              # プレビュー・開発用モックデータ
    │       └── MirrorPost              # SNSタイムライン投稿モデル
    │
    ├── ViewModels/
    │   └── AssetViewModel.swift        # @MainActor ObservableObject
    │
    ├── Views/
    │   ├── MainTabView.swift           # ルートタブコンテナ + カスタムTabBar
    │   │   ├── GMTab                  # タブ定義 enum
    │   │   ├── GMTabBar               # カスタムゴールドタブバー
    │   │   └── GMTabBarItem           # 個別タブアイテム
    │   │
    │   ├── Dashboard/
    │   │   └── DashboardView.swift    # メインダッシュボード
    │   │       ├── DashboardHeaderView        # ヘッダー (Greeting + 日付)
    │   │       ├── NetWorthSummaryCard        # 総資産サマリーカード
    │   │       ├── AssetAllocationBar         # 配分バー
    │   │       ├── SectionHeader              # セクションヘッダー
    │   │       ├── BankAccountRow             # 銀行口座行
    │   │       ├── SecuritiesAccountRow       # 証券口座行
    │   │       ├── CreditCardSummaryCard      # カード合計カード
    │   │       └── CreditCardRow             # クレジットカード行
    │   │
    │   ├── Calendar/
    │   │   └── CalendarView.swift     # 引き落としカレンダー
    │   │       ├── MonthlyBillingSummaryCard  # 月合計
    │   │       ├── CalendarDayCell            # カレンダーセル
    │   │       ├── SelectedDayDetailView      # 選択日詳細
    │   │       └── UpcomingBillingList        # 引き落とし一覧
    │   │
    │   ├── Mirror/
    │   │   └── MirrorView.swift       # SNS タイムライン
    │   │       ├── MySnapshotCard             # 自分のスナップショット
    │   │       ├── MirrorPostCard             # 他ユーザー投稿カード
    │   │       └── ComposePostView            # 投稿作成シート
    │   │
    │   └── Analysis/
    │       └── AnalysisView.swift     # 分析・予測画面
    │           ├── ForecastSection            # 将来予測
    │           ├── OCRSection                 # 書類読み取り
    │           └── MonthlyReportSection       # 月次レポート
    │
    └── Utils/
        └── DesignSystem.swift         # デザイントークン（単一ソース）
            ├── Color extensions       # カラーパレット
            ├── GMGradient             # グラデーション定義
            ├── GMFont                 # タイポグラフィ
            ├── GMSpacing / GMRadius   # スペーシング・角丸
            ├── GMCardStyle            # カードスタイル ViewModifier
            ├── GMGoldGlow             # ゴールドグロー ViewModifier
            └── Double extensions      # 金額フォーマット
```

---

## カラーシステム

| Token | Hex | 用途 |
|-------|-----|------|
| `gmBackground` | `#0A0A0A` | 全画面背景 |
| `gmSurface` | `#141414` | カード背景 |
| `gmSurfaceElevated` | `#1E1E1E` | 浮き上がったカード |
| `gmGold` | `#D4AF37` | メインアクセント |
| `gmGoldLight` | `#F0D060` | ハイライト |
| `gmGoldDim` | `#8B7320` | ボーダー・暗めのゴールド |
| `gmTextPrimary` | `#FFFFFF` | 見出し・数値 |
| `gmTextSecondary` | `#A8A8A8` | サブテキスト |
| `gmTextTertiary` | `#5A5A5A` | プレースホルダー・ラベル |
| `gmPositive` | `#4CAF50` | 利益・プラス |
| `gmNegative` | `#EF5350` | 損失・マイナス |

---

## セットアップ手順

### 前提条件
- Xcode 15.0+
- iOS 17.0+
- (オプション) XcodeGen: `brew install xcodegen`

### XcodeGen を使う場合
```bash
cd GoldMirror
xcodegen generate
open GoldMirror.xcodeproj
```

### 手動でXcodeプロジェクトを作る場合
1. Xcode で **File > New > Project** → **App** テンプレートを選択
2. Product Name: `GoldMirror`、Interface: `SwiftUI`、Language: `Swift`
3. 上記ファイル構成に従い、Finder からファイルをドラッグ＆ドロップ
4. ターゲットの Deployment Target を **iOS 17.0** に設定
5. ビルド & 実行 (`⌘R`)

---

## 実装済み機能

### Dashboard（ダッシュボード）
- [x] ウェルカムヘッダー（時間帯別挨拶 + 日付）
- [x] 総資産サマリーカード（金額表示/非表示トグル）
- [x] アセット配分バー（現金 vs 証券）
- [x] 銀行口座一覧（折りたたみ可能）
- [x] 証券口座一覧（損益率表示）
- [x] クレジットカード引き落とし合計 + 一覧

### Calendar（カレンダー）
- [x] 月次カレンダーグリッド（引き落とし日マーカー付き）
- [x] 月移動ナビゲーター
- [x] 日付選択 → 詳細パネル
- [x] 引き落とし一覧（日付順ソート）

### Mirror（SNS）
- [x] 自分の資産スナップショットカード
- [x] タイムライン投稿（資産変動 + 貯蓄率バッジ）
- [x] ライク / コメントボタン
- [x] 投稿作成シート（スタブ）

### Analysis（分析）
- [x] セグメントタブ（将来予測 / OCR / 月次レポート）
- [x] 将来資産シミュレーション（バーチャート + 表）
- [x] OCRアップロードUI（カメラ / ライブラリ）
- [x] KPIカード（月次レポート）

---

## 次フェーズの実装候補

- [ ] SwiftData / CoreData による永続化
- [ ] Vision フレームワークによる実OCR実装
- [ ] WidgetKit による資産サマリーウィジェット
- [ ] Charts フレームワークによるインタラクティブグラフ
- [ ] CloudKit によるiCloud同期
- [ ] FaceID / TouchID によるロック機能
- [ ] Push通知（引き落とし日リマインダー）
- [ ] SNS Mirror のバックエンドAPI連携
