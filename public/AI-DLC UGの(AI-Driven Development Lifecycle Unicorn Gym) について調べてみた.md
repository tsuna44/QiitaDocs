---
title: AI-DLC UGの(AI-Driven Development Lifecycle Unicorn Gym) について調べてみた
tags:
  - 開発環境
  - 生成AI
  - AI-DCL
private: false
updated_at: '2026-03-11T20:53:29+09:00'
id: ffaddc79229b24d645d0
organization_url_name: null
slide: false
ignorePublish: false
---
AWC様が提供されている、AI DLC UG(AI-Driven Development Lifecycle Unicorn Gym) について調べてみたので、忘備録として、記述します。

# AI-DLC UG 体験談まとめ — 利用環境・プロダクト・ソースコード・AWSの要否

## はじめに

AWS が提唱する **AI-DLC（AI-Driven Development Lifecycle）** のユーザーグループ **Unicorn Gym** に参加した各社の公開体験談をもとに、以下の4点を整理しました。

- 利用する環境（エディタ・LLM）
- 作成したプロダクト（制御システム・組込み系を含む）
- ソースコードの扱い
- AWS上で稼働するプロダクトである必要があるか

---

## AI-DLC / Unicorn Gym とは

| 項目 | 概要 |
|---|---|
| **AI-DLC** | AWSが提唱するAI駆動開発ライフサイクル。「AIが実行し人間が監視する」モデル。Inception → Construction → Operation の3フェーズで構成 |
| **Unicorn Gym** | AI-DLCを2〜3日間で体験するワークショップ。架空テーマではなく、実際の業務課題・プロダクトを持ち込んで開発 |
| **参加企業（主な例）** | LIFULL、タイミー、東京海上日動システムズ、三菱電機、弥生、DMM、食べログ、日立産業制御ソリューションズ、パナソニックエレクトリックワークス 他多数 |

---

## ① 利用する環境（エディタ・LLM）

> **特定ツールへの縛りなし — 各社が自社環境を持ち込む形が基本**

### エディタ / Coding Agent

| ツール | 採用企業・特徴 |
|---|---|
| **Cursor** | 最多採用。複数社で活用 |
| **Claude Code** | タイミー・LIFULL 他 |
| **Amazon Q Developer** | LIFULL 全社活用。AWS との親和性◎。`.amazonq/rules` でAI-DLCワークフローを設定 |
| **Kiro** | 三菱電機・弥生が活用。`.kiro/steering` でステアリングファイルを設定 |
| **GitHub Copilot** | タイミー他（個人単位での活用実績あり） |

### LLM・モデル

- Amazon Q / Claude / Codex を**組み合わせて利用**するアプローチが報告されている（タイミー）
- 「大枠を Claude Code で作り、細かい詰めを Codex で」という使い分けも
- AI-DLCのワークフロー定義は **[AWS Labs の GitHub](https://github.com/awslabs)** で公式公開済み

### 💡 GitHub Copilot + VS Code でも問題なし！

GitHub Copilot + VS Code 環境でも**完全に参加・実践可能**です。

`.github/copilot-instructions.md` に AI-DLC のワークフロー（Inception → Construction）を記述するだけで設定完了。タイミーでも Copilot の活用実績があります。

```
.github/
  copilot-instructions.md   # プロジェクト全体のAI-DLCルールを記述
  instructions/
    general.instructions.md # 言語・ファイルパス別の細かい指示（VS Code v1.100+）
  prompts/
    inception.prompt.md     # よく使うプロンプトの再利用
```

---

## ② 作成したプロダクト

> **実際の業務課題を持ち込んで開発 — 架空テーマは使わない**

| 企業 | 開発対象・内容 | 達成レベル |
|---|---|---|
| **LIFULL** | 本番搭載予定の機能（6チーム30名） | 3チームMVP完了・1チームはProduction可能レベル |
| **タイミー** | プロダクション搭載予定の機能（11チーム69名） | 全チームMVP実装・一部はStaging/Prodデプロイ |
| **東京海上日動システムズ** | 金融系業務システム（4チーム） | 4チームが動作版完成・1チームはテスト環境デプロイ |
| **三菱電機 電力ICTセンター** | 電力の制御・監視システム向けソフトウェア（制御システム周辺のWebアプリ等） | 5チームが3日でMVP達成 |
| **弥生** | 会計・給与パッケージソフトへの機能追加（AIチーム/サブスクチームの2チーム） | 既存パッケージへの機能追加を検証 |
| **DMM** | プラットフォーム系機能（2日間） | 全チームがコード生成〜動作確認まで完了。最大80%の工数削減 |

### 制御システム・組込み系の事例

#### 三菱電機 電力ICTセンター

- 電力の安定供給を支える**制御・監視システムの開発部門**
- 33名のエンジニアが参加（CI/CD・インフラ・アジャイル推進担当など）
- 開発対象：制御システム周辺のWebアプリ・次世代電力プラットフォーム
- ツール：**Kiro**（公開直後から活用）+ GitLab Duo
- UG後すぐに実プロダクトの検討フェーズにAI-DLCを適用開始
- 従来はプログラム製作未経験のメンバーもUIイメージを作成できるように

#### 2026年1月 合同UG（11社）に参加した組込み系企業

| 企業 | 領域 |
|---|---|
| **アルプスアルパイン** | 電子部品・車載モジュールメーカー |
| **日立産業制御ソリューションズ** | FA・制御システム系 |
| **三菱電機ビルソリューションズ** | ビル設備制御システム |
| **パナソニックエレクトリックワークス** | 電気設備・制御機器 |

:::note warn
組込みソフト固有の事例の詳細な公開は現時点では限定的ですが、制御システムに近い領域での適用実績は存在します。
:::

---

## ③ 作成したプロダクトのソースコードの扱い

> **外部公開義務なし — 各社の社内リポジトリで管理**

- GitHub のプライベートリポジトリ等で各社が管理。**外部への公開を求められることはない**
- LIFULL では、企画書・仕様書などのドキュメントを Markdown で作成し、GitHub でのレビュー・管理に移行。コードも含め社内管理
- 参加企業のコードが外部に公開されている事例は確認されていない

:::note info
AI-DLC 自体のワークフロー定義は AWS Labs GitHub で公式公開されており、各社はこれを参照し社内設定として利用します。プロダクトのソースコードとは別物です。
:::

---

## ④ AWS上で稼働するプロダクトである必要があるか

> **結論：必須ではない**

### 必須ではない理由

- AI-DLC は**特定ツール・クラウドに依存しない方法論**
- 「各組織の特徴やニーズに合わせてカスタマイズして実施するプログラム」と位置づけられている
- Kiro・Cursor・GitHub Copilot など**非AWS系ツールでの実施事例**あり
- 弥生・食べログ等、AWS以外の環境でも実施

### AWSとの親和性は高い

- AWSのSAがサポートに入ることが多い
- Amazon Q Developer 向けのステアリングファイルが公式提供済み
- LIFULL は Amazon Q Developer 全社活用でAWS環境と高い親和性
- ただし、**AWS上へのデプロイが前提条件**という記述は各社体験談に見当たらない

---

## まとめ

| 項目 | 概要 |
|---|---|
| **利用環境** | ツール自由。Cursor・Claude Code・Amazon Q・Kiro・GitHub Copilot 等。GitHub Copilot + VS Code 環境でも完全に参加・実践可能 |
| **作成プロダクト** | 各社の実業務課題を持ち込む。MVP〜Production投入レベルまで実績あり。パッケージソフト（弥生）、制御システム周辺（三菱電機）の事例も存在 |
| **ソースコード** | 外部公開義務なし。各社の社内リポジトリ（GitHub プライベート等）で管理 |
| **AWS必須か** | 必須ではない。ただし AWS の SA サポートや Amazon Q との親和性は高い |

---

## 参考記事

### AWS Blog（各社事例レポート）

| 企業 | 記事 |
|---|---|
| LIFULL | [LIFULL 様の AI-DLC Unicorn Gym 実践レポート](https://aws.amazon.com/jp/blogs/news/lifull-ai-dlc/) |
| タイミー | [タイミー様の AI-DLC Unicorn Gym 開催レポート: 全社横断で挑む開発生産性の変革](https://aws.amazon.com/jp/blogs/news/timee-ai-dlc/) |
| 東京海上日動システムズ | [金融業界初 AI-DLC Unicorn Gym による開発変革への挑戦](https://aws.amazon.com/jp/blogs/news/tokio-marine-ai-dlc/) |
| 三菱電機 電力ICTセンター | [三菱電機のエンジニア 33 名が 3 日間で体感した AI 駆動開発の可能性](https://aws.amazon.com/jp/blogs/news/mitsubishi-electric-power-ict-ai-dlc-unicorn-gym/) |
| 弥生 | [弥生株式会社様の AI-DLC Unicorn Gym 開催レポート](https://aws.amazon.com/jp/blogs/news/yayoi-ai-dlc/) |
| 11社合同（日立産業制御・アルプスアルパイン・パナソニックEW 他） | [11 社合同 AI-DLC Unicorn Gym で体験した開発のパラダイムシフト](https://aws.amazon.com/jp/blogs/news/joint-ai-dlc-unicorn-gym-202601/) |

### 各社 Tech Blog

| 企業 | 記事 |
|---|---|
| LIFULL Creators Blog | [AI-DLCで挑むOSマイグレーション：研修で学んだ新しい開発スタイル](https://www.lifull.blog/entry/2026/01/06/120000) |
| Timee Product Team Blog | [3日間のUnicorn Gymが1ヶ月で組織を変えた —— データで見るAI-DLC導入の波及効果](https://tech.timee.co.jp/entry/2026/03/06/141357) |
| CyberAgent AIオペレーション室（note） | [AWS発「AI-DLC」ワークショップレポート！現場に適用するには？](https://note.com/ca_ai_ope/n/n14ba20754a53) |

### その他

- [AWS Labs GitHub（AI-DLCワークフロー定義）](https://github.com/awslabs)
- 本記事は上記公開体験談をもとに作成（2026年3月）
