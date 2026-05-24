---
title: GitHub Copilot と Claude Code のプロンプト・スキル・エージェント機能の比較（2026年版）
tags:
  - AI
  - VSCode
  - GitHubCopilot
  - LLM
  - ClaudeCode
private: false
updated_at: '2026-05-24T12:07:38+09:00'
id: c320df90b4cf655ce3f6
organization_url_name: null
slide: false
ignorePublish: false
---

# GitHub Copilot と Claude Code のプロンプト・スキル・エージェント機能の比較（2026年5月版）

GitHub Copilot と Claude Code はどちらもエディタ統合型のAIコーディングアシスタントですが、カスタマイズの仕組みが異なり、いつも混乱してしまうので、Claude Sonnet 4.6さんに整理してもらいました。
備忘録として 2026.5時点での「カスタム指示・プロンプト・スキル・エージェント」の仕様を備忘録として書いておきます。

Claude Code の commandsって、いつの間にか過去になってたんだと、びっくりしちゃいました。
たまに、こういう調査して見るといいかなと思ったりして。

> **情報の鮮度について**
> 本記事は 2026年5月時点の情報に基づいています。両ツールともアップデートが頻繁なため、最新の公式ドキュメントも必ず参照してください。

---

## 全体像の比較
> 判断の基準軸：**いつ読み込むか** / **誰が実行するか** / **どこで使うか**

## 凡例

| 記号 | カテゴリ | 意味 |
|---|---|---|
| ◉ | 常時読み込み | 毎セッション自動注入 |
| ◈ | 手動 /コマンド | ユーザーが明示的に呼び出す |
| ◆ | 文脈 自動起動 | Claude が文脈を読んで自動ロード |
| ▲ | ペルソナ・エージェント | ロール定義・並列実行 |
| ■ | スコープ・補助データ | 適用範囲・参照専用データ |

---

| カテゴリ | Claude Code | GitHub Copilot Chat |
|---|---|---|
| ◉ **常時読み込み** | `CLAUDE.md`<br>毎セッション自動注入。グローバル＋PJの2層マージ | `.github/copilot-instructions.md`<br>全チャットに常時注入。プロジェクト規約 |
| ◈ **手動 /コマンド** | `.claude/skills/*/SKILL.md` **（推奨）**<br>`.claude/commands/*.md`（legacy）<br>単純〜複雑なワークフロー両対応 | `.github/prompts/*.prompt.md`<br>Claude Code の skills 相当。`/コマンド名` で呼び出し |
| ◆ **文脈 自動起動** | `.claude/skills/*/SKILL.md`（description 重要）<br>Claude が description を読んで文脈に応じて自動ロード | `.github/instructions/*.instructions.md`<br>ファイルパターン・言語に応じて自動付与されるルール |
| ▲ **ペルソナ切り替え** | ⚠ 専用機能なし<br>`CLAUDE.md` 直書き / `skills/persona.xxx` / シムリンク切り替えで代替 | `.github/agents/*.agent.md`<br>役割・ツール・モデルを定義。Planner / Reviewer など会話全体を制御（Copilot が優位） |
| ▲ **並列サブ実行** | `.claude/agents/*.md`<br>skills から呼ばれる並列ワーカー。独立コンテキスト。直接呼ぶ用途は少ない | `.github/agents/` 兼用<br>同じ `.agent.md` がサブエージェント・cloud agent としても再利用される |
| ■ **スコープ** | `~/.claude/skills/`（個人・全PJ横断）<br>`.claude/skills/`（PJ固有）<br>競合時はプロジェクト側が優先 | `{org}/.github` リポジトリ<br>agents / instructions を組織全体に共有 |
| ■ **補助データ** | `.claude/skills/xxx.templates/`（`SKILL.md` なし）<br>コマンド化しない参照専用データ置き場 | `.github/prompts/` 内 Markdown リンク参照<br>`prompt.md` から `../docs/standards.md` のようにリンク |

---

## ⚠ 非対称性ポイント

**ペルソナ切り替え（▲）** は Copilot の `.github/agents/*.agent.md` が優位。
Claude Code には会話全体のモード・ツール・モデルを一括宣言する専用 UI が現状なく、
`CLAUDE.md` + `skills` の組み合わせで代替するのが現状のベストプラクティス。


---

## GitHub Copilot のカスタマイズ機能

GitHub Copilot のカスタマイズには「カスタム指示・プロンプトファイル・エージェントスキル・AGENTS.md」の4種類があります。それぞれ役割が異なります。

### 1. カスタム指示（Custom Instructions）

Copilot への常時適用ルールを記述するファイルです。優先度は次の順で高い方が勝ちます（競合時のみ上書き、通常は全レイヤーがマージされます）。

```
個人設定（GitHub.com）
  ↓
.github/instructions/*.instructions.md（パス指定）
  ↓
.github/copilot-instructions.md（リポジトリ全体）
  ↓
AGENTS.md
  ↓
組織レベルの設定
```

#### `.github/copilot-instructions.md`（リポジトリ全体・常時ON）

リポジトリルートの `.github/` に置くだけで、そのリポジトリ上のすべてのリクエストに適用されます。

```markdown
# Copilot Instructions

- TypeScript を使用する。any 型は禁止
- テストは Vitest で記述する
- コメントは日本語で書く
```

#### `.github/instructions/*.instructions.md`（パス指定・条件適用）

`applyTo` frontmatter でファイルパターンを指定すると、対象ファイルに対してのみ適用されます。

```markdown
---
applyTo: "**/*.test.ts"
---

# テストファイルのルール

- AAA パターン（Arrange / Act / Assert）で記述
- モックは vi.mock() を使用する
```

```markdown
---
applyTo: "src/api/**"
---

# API層のルール

- 戻り値は必ず Result 型でラップする
- エラーは never throw、戻り値で表現
```

#### 個人設定

GitHub.com のアカウント設定から、すべてのリポジトリに横断適用できる個人ルールを定義できます。

---

### 2. プロンプトファイル（Prompt Files）

**ファイル形式：** `.github/prompts/*.prompt.md`

カスタム指示が「常時ON」なのに対し、プロンプトファイルは **手動で呼び出す使い捨てプロンプト** です。チャット欄で `/` を入力すると一覧が表示されます。

**対応環境：** VS Code / Visual Studio / JetBrains のみ（GitHub.com の Copilot は非対応）

```markdown
# コードレビューチェックリスト

以下の観点でコードをレビューしてください。

- [ ] セキュリティ（インジェクション・認証漏れ）
- [ ] N+1問題
- [ ] テストカバレッジ
- [ ] 命名規則の一貫性

対象ファイル: {{selection}}
```

`{{selection}}` のようにテンプレート変数も利用できます。

---

### 3. AGENTS.md

**ファイル形式：** リポジトリルートまたは任意のサブディレクトリに `AGENTS.md`

**AGENTS.md** は GitHub Copilot 専用ではなく、Claude Code・Gemini CLI など複数の AI エージェントが共通で読むことを想定した汎用フォーマットです。GitHub は 2025年8月に Copilot coding agent での AGENTS.md 対応を正式発表しました。

```markdown
# Project Agent Instructions

## セットアップ
npm install && npm run build

## テスト
npm test

## 注意事項
- 本番 DB に直接書き込まない
- .env ファイルは絶対にコミットしない
```

`.github/copilot-instructions.md` と `AGENTS.md` が共存する場合、Copilot は**両方を読みマージ**します。複数エージェントで同じリポジトリを扱うなら AGENTS.md に共通ルールを書き、Copilot 固有の追加設定を `.github/copilot-instructions.md` に書く、という使い分けが推奨されています。

---

### 4. エージェントスキル（Agent Skills）

**ファイル形式：** `<任意のディレクトリ>/SKILL.md`

Copilot coding agent・Copilot CLI・agent mode（VS Code）で使える、タスク特化型の能力定義です。**Agent Skills Open Standard** に準拠しており、Claude Code など他のエージェントとスキルを共有できます。

```markdown
---
name: generate-tests
description: 指定されたソースファイルのユニットテストを生成する
---

# テスト生成スキル

対象ファイルを読み込み、以下の手順でテストを生成してください。

1. public メソッドをすべて列挙
2. 各メソッドの正常系・異常系・境界値テストを作成
3. Vitest 形式で出力
```

Copilot のツールモデルは**宣言型**です。ファイルの読み書き・ターミナル実行・Web検索などの組み込みツールをスキルの指示文の中で参照するだけで、JSON スキーマの定義は不要です。

---

## Claude Code のカスタマイズ機能

Claude Code のカスタマイズは「CLAUDE.md・スキル・コマンド・組み込みスラッシュコマンド」で構成されます。

### 1. CLAUDE.md

**ファイル形式：** `CLAUDE.md`（プロジェクトルート / `~/.claude/CLAUDE.md`）

GitHub Copilot の `copilot-instructions.md` に相当する、**Claude に対する常時読み込み指示**です。ユーザーレベル（`~/.claude/`）とプロジェクトレベルの両方が自動マージされます。

```markdown
# プロジェクト指示

## 技術スタック
- TypeScript 5.x / Node.js 22
- テスト: Vitest

## ルール
- コメントは日本語で書く
- any 型は禁止
- エラーは Result 型で表現、throw しない
```

Claude Code は `AGENTS.md` も認識します。AGENTS.md が存在する場合は CLAUDE.md と合わせて参照します。

---

### 2. スキル（Skills）

**ファイル形式：** `.claude/skills/<スキル名>/SKILL.md`

Claude Code のスキルは **Agent Skills Open Standard** 準拠でありながら、**独自の拡張フィールド**を持ちます。

#### 基本形式

```markdown
---
name: generate-tests
description: 指定されたソースファイルのユニットテストを生成する
---

# テスト生成スキル

対象ファイルを受け取り Vitest 形式のテストを生成します。
...
```

#### 独自拡張フィールド

Claude Code 固有の重要なフィールドが2つあります。

| フィールド | 値 | 説明 |
|------------|----|------|
| `context`  | `fork` | メイン会話と**切り離された独立コンテキスト**でスキルを実行 |
| `agent`    | `Explore` / `Plan` / `general-purpose` | `context: fork` 時に使用するサブエージェントの種類 |

```markdown
---
name: security-audit
description: コードベースのセキュリティ監査を実行する
context: fork
agent: Explore
---

# セキュリティ監査スキル

以下の観点でコードを静的解析してください。
- 入力バリデーション漏れ
- SQLインジェクション / XSS
- 認証・認可の抜け
- 秘密情報のハードコーディング

調査結果をレポート形式でまとめてください。
```

`context: fork` を使うと、スキルはメイン会話の履歴を持たない**独立したサブエージェント**として実行されます。大規模なコードベース調査など、メイン会話のコンテキストを汚染したくないタスクに向いています。

#### スキルの起動方法

スキルには**2つの起動経路**があります。

1. **自動トリガー**：ユーザーのメッセージを読んで Claude が description に基づき判断して自動起動
2. **手動起動**：`/スキル名` で明示的に呼び出し

スキルを作成すると自動的にスラッシュコマンドとしても登録されます。

---

### 3. コマンド（Commands）

**ファイル形式：** `.claude/commands/<コマンド名>.md`

**コマンドとスキルは統合されています。** `.claude/commands/deploy.md` と `.claude/skills/deploy/SKILL.md` はどちらも `/deploy` として機能し、動作は同じです。既存の `.claude/commands/` ファイルはそのまま動作します。新規作成するなら `.claude/skills/` 配下の SKILL.md 形式を推奨します（`context: fork` などの高度な機能が使えるため）。

---

### 4. 組み込みスラッシュコマンド

Claude Code には最初から使えるスラッシュコマンドが 60+ あります。代表的なものを示します。

| コマンド | 説明 |
|----------|------|
| `/help` | ヘルプを表示 |
| `/clear` | 会話をクリア |
| `/review` | プルリクエストをレビュー |
| `/simplify` | 変更済みコードを品質・効率・再利用性の観点でリファクタ |
| `/loop` | プロンプトや他のスラッシュコマンドを定期実行 |
| `/schedule` | 定期実行エージェントをスケジュール設定 |
| `/security-review` | 現在のブランチのセキュリティレビュー |
| `/init` | CLAUDE.md を新規作成 |
| `/fast` | 高速モードへ切り替え（Claude Opus 使用） |

---

## 機能対応表（詳細）

### カスタム指示系

| ファイル | Copilot | Claude Code | 適用タイミング |
|----------|:-------:|:-----------:|----------------|
| `.github/copilot-instructions.md` | ✅ | ❌ | 常時（Copilot専用） |
| `.github/instructions/*.instructions.md` | ✅ | ❌ | applyTo条件一致時 |
| `AGENTS.md` | ✅ | ✅ | 常時（マルチエージェント共通） |
| `CLAUDE.md` | ❌ | ✅ | 常時（Claude Code専用） |

### スキル・プロンプト系

| 機能 | Copilot | Claude Code | 備考 |
|------|:-------:|:-----------:|------|
| `SKILL.md`（Agent Skills Open Standard） | ✅ | ✅ | スキルの共通形式 |
| `.prompt.md`（手動起動プロンプト） | ✅ | ❌ | Copilot専用（スキルで代替可） |
| スキル自動トリガー | ✅ | ✅ | description-based |
| スキル手動起動（スラッシュコマンド） | ✅ | ✅ | `/スキル名` |
| `context: fork`（サブエージェント分離） | ❌ | ✅ | Claude Code独自拡張 |
| `agent:` フィールド | ❌ | ✅ | Claude Code独自拡張 |

---

## 混乱しやすいポイント

### Copilot: prompt file vs custom instructions vs agent skills

| 比較軸 | Custom Instructions | Prompt Files | Agent Skills |
|--------|--------------------|--------------|----|
| 起動 | 常時自動 | 手動（`/` で呼ぶ） | 自動 or 手動 |
| 目的 | コーディングスタイル・ルール定義 | タスクのテンプレート化 | 専門タスクの能力拡張 |
| 対象エージェント | Chat全般 | Chat（IDE内のみ） | coding agent / CLI / agent mode |
| ファイル場所 | `.github/` | `.github/prompts/` | 任意（SKILL.md） |

### Claude Code: commands vs skills の違い

以前は別概念でしたが、**現在は統合されています。**
`.claude/commands/foo.md` と `.claude/skills/foo/SKILL.md` はどちらも `/foo` として動作します。

### AGENTS.md vs CLAUDE.md

- **AGENTS.md** → マルチエージェント対応の汎用形式。Copilot・Claude Code・Gemini CLI などが共通で読む
- **CLAUDE.md** → Claude Code 専用の詳細指示。`AGENTS.md` より詳細な制御が可能

両ファイルが共存する場合、Claude Code は両方をマージして使用します。

---

## エコシステムの現状（2026年5月時点）

### Agent Skills コミュニティ

[github/awesome-copilot](https://github.com/github/awesome-copilot) と [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) がそれぞれのエコシステムの中心です。また、[VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) には 1000+ のスキルが集まっており、両エージェントで流用可能なものも多数あります。

### スキルの互換性

SKILL.md の基本形式（`name`・`description` の frontmatter + Markdown の指示本文）はどちらのエージェントでも動作します。ただし、`context: fork` や `agent:` といった**Claude Code 独自フィールドは Copilot では無視**されます（エラーにはなりません）。

---

## まとめ

GitHub Copilot と Claude Code のカスタマイズ機能を整理すると、次のような設計思想の違いが見えてきます。

- **GitHub Copilot**：IDE に深く統合されたフロー重視の設計。ファイル種別ごとの細かい指示切り替えが得意。
- **Claude Code**：ターミナルファーストの自律エージェント設計。`context: fork` によるサブエージェント分離など、大規模・複雑なタスクの委譲に強み。

どちらが優れているかではなく、**タスクの性質に応じて使い分け**、あるいは**両方を組み合わせる**のが 2026年現在のベストプラクティスです。Claude Code は Copilot Pro+ / Enterprise プランから外部エージェントとして呼び出せるようになっているため、Copilot ワークフローの中から Claude Code に委譲する構成も可能です。

---

## 参考リンク

### 公式ドキュメント

- [GitHub Copilot features（GitHub Docs）](https://docs.github.com/en/copilot/get-started/features)
- [Use prompt files in VS Code（VS Code Docs）](https://code.visualstudio.com/docs/copilot/customization/prompt-files)
- [Use Agent Skills in VS Code（VS Code Docs）](https://code.visualstudio.com/docs/copilot/customization/agent-skills)
- [Adding repository custom instructions for GitHub Copilot（GitHub Docs）](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- [About agent skills（GitHub Docs）](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [Copilot coding agent now supports AGENTS.md（GitHub Changelog）](https://github.blog/changelog/2025-08-28-copilot-coding-agent-now-supports-agents-md-custom-instructions/)
- [Extend Claude with skills（Claude Code Docs）](https://code.claude.com/docs/en/skills)

### コミュニティリソース

- [github/awesome-copilot](https://github.com/github/awesome-copilot)
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
- [VoltAgent/awesome-agent-skills（1000+ skills）](https://github.com/VoltAgent/awesome-agent-skills)

### 比較記事

- [GitHub Copilot Skills vs SKILL.md — How They Compare（2026）](https://www.agensi.io/learn/github-copilot-skills-vs-skill-md-2026)
- [What Is the Agent Skills Open Standard?（2026 Explainer）](https://www.agensi.io/learn/agent-skills-open-standard)
- [Claude Code vs GitHub Copilot（2026）: Terminal Agent vs Multi-Model Platform](https://www.morphllm.com/comparisons/claude-code-vs-copilot)
