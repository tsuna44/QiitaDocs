---
title: GitHub Copilot の「AIへの指示書」まとめ：copilot-instructions.md / Skills / AGENTS.md / カスタムエージェント（VS Code / Copilot CLI）
tags:
  - VSCode
  - GitHubCopilot
  - GitHub
  - AI
  - LLM
private: false
updated_at: ''
id: null
organization_url_name: null
slide: false
ignorePublish: false
posting_campaign_uuid: null
agreed_posting_campaign_term: false
---

# GitHub Copilot の「AIへの指示書」まとめ（2026年11月版）

GitHub Copilot に読ませる Markdown ファイル（`copilot-instructions.md`、`*.instructions.md`、`SKILL.md`、`AGENTS.md`、`*.agent.md`）は種類が増え、置ける場所も増えてきました。
どれに何を書けばよいのか、長い手順書はどこに置けば守ってもらえるのか、VS Code と Copilot CLI で扱いが違うのか。毎回調べ直しているので、公式ドキュメントをもとに整理しました。

この記事で扱うツールは次の 3 つです。

- **VS Code の GitHub Copilot Chat**
- **GitHub Copilot CLI**（`copilot` コマンド）
- **GitHub CLI の `gh skill`**（スキルの検索・インストール用コマンド）

> **情報の鮮度について**
> 本記事は 2026年11月時点の公式ドキュメント（VS Code ドキュメントは 2026/11/18 更新版）に基づいています。どちらのツールも更新が頻繁なので、最新の公式ドキュメントもあわせて確認してください。

---

## 要点

- **リポジトリ共通のルール**は `.github/copilot-instructions.md`。ファイル種別ごとのルールは `.github/instructions/**/*.instructions.md`（`applyTo` で対象を指定）。
- **特定の作業の手順**はスキル（`.github/skills/<name>/SKILL.md`）。必要なときだけ読み込まれます。
- **`AGENTS.md`** は複数の AI エージェントで共通の形式です。ただし、読むかどうか・どう探すかはハーネス（ツール）ごとに違います。
- **役割ごとの設定**（使うツール、モデル、指示）はカスタムエージェント（`.github/agents/*.agent.md`）。
- **長い手順書**は、常に読まれる指示書に貼るより、スキルに分けて参照ファイルやスクリプトにするほうが守られやすい、というのが公式ドキュメントの方向性です。
- どのファイルを読むかを決めるのは**モデルではなくハーネス**です。VS Code の **Local ハーネスは非推奨**で、2027年2月に削除予定です。

---

## 読む前に：「ハーネス」を確認してください

VS Code の Copilot Chat には、モデル（GPT、Claude など）とは別に、**ハーネス**という選択肢があります。ハーネスは、モデルを動かす側の仕組みです。どの指示書を読むか、どのツールを使えるかは、モデルではなくハーネスで決まります。

> The selected agent harness, not the language model, determines instruction support.
> （[Custom instructions reference](https://code.visualstudio.com/docs/agents/reference/custom-instructions-reference)）

| ハーネス | ひとことで言うと |
|---|---|
| **Copilot**（標準） | Copilot CLI と同じルールで `.github/`、`~/.copilot/` を読む。**本記事は基本的にこれを前提にしています** |
| Local（**非推奨**、2027年2月に削除予定） | 従来の VS Code 独自の動作。`chat.*` 設定で読み込みを変えられる |
| Anthropic Claude / OpenAI Codex | それぞれ Claude Code / Codex と同じルールで読む |

### ハーネスの選び方と確認方法

ハーネスは、**新しいセッションを始めるときに**選びます（[Choose an agent harness](https://code.visualstudio.com/docs/agents/run/agent-harnesses)）。

1. Chat ビューで **New Chat**（`+`）を押す（Agents ウィンドウでは **New** を押して、フォルダかリポジトリを選ぶ）
2. チャット入力欄の **Session Target** のドロップダウンで、ハーネスを選ぶ
3. 最初のプロンプトを送る

- **最初のプロンプトを送る前に選びます。** 途中で変えられるのは Local ハーネスから別のハーネスに引き継ぐときだけなので、それ以外は新しいセッションを作ります。
- **モデルやエージェントを変えても、ハーネスは変わりません。**（"Changing the model or agent role does not change the harness."）
- 今のハーネスは、エディタのチャットでは**チャットのタイトルの先頭**に、Agents ウィンドウでは入力欄に薄い文字で表示されます。
- Session Target には、使える条件を満たしたハーネスだけが表示されます。Local ハーネスはエディタの Chat ビューでだけ選べます（Agents ウィンドウでは選べません）。
- **デフォルトのハーネスを名前で指定する設定はありません。** ドキュメントでは「Start with **Copilot** for day-to-day coding and agent tasks」と、Copilot ハーネスが勧められています。

「ネットの記事のとおりに設定したのに効かない」「`~/.copilot/` に置いたのに読まれない」ときは、まずどのハーネスを使っているかを確認してください。以前の記事や解説で紹介されている `chat.*` 設定の多くは、Local ハーネスにしか効きません。

詳しくは [7章](#7-ハーネスについて) で説明します。

---

## 1. AIへの指示書

### AIへの指示書とは

この記事では、AI エージェントに「このプロジェクトではこう作業してほしい」と伝えるために置いておく Markdown ファイルを、まとめて **AIへの指示書** と呼びます。毎回プロンプトに書かなくても、ファイルに書いておけばエージェントが読み込んでくれます。

指示書には何種類かあり、**いつ読み込まれるか**が違います。常に読まれるもの、対象のファイルを扱うときだけ読まれるもの、必要と判断されたときだけ読まれるもの、ユーザーが選んだときだけ使われるものがあります。何を書くかは、この読み込まれ方に合わせて決めます。

ただし、指示書は「お願い」であって強制ではありません。

> Instructions guide the model. They don't guarantee compliance or replace tests, code review, or security controls.
> （[Use custom instructions in VS Code](https://code.visualstudio.com/docs/copilot/customization/custom-instructions)）

### 指示書の種類

| 指示書 | 書く内容 | 読み込まれるタイミング | 特徴 | 本記事の章 |
|---|---|---|---|---|
| `copilot-instructions.md` | プロジェクト全体の短いルール（使う言語、コーディング規約、ビルド方法など） | 常に（チャットのたびに送られる） | すべての作業に効く。長くするとほかの指示が埋もれる | 2 |
| `*.instructions.md` | 特定のファイル種別だけのルール（TypeScript の規約、テストの書き方など） | `applyTo` に一致するファイルを扱うとき | 全体ルールを膨らませずに、対象を絞れる | 2 |
| `SKILL.md`（スキル） | 特定の作業の手順（テストの実行、リリース作業など）と、補助ファイル・スクリプト | `description` から関連すると判断されたとき、または `/スキル名` で呼んだとき | 必要なときだけ読まれるので、詳しく書ける | 3 |
| `AGENTS.md` | プロジェクトの概要、ビルド・テストのコマンド、規約など | ハーネスによる（Copilot では常に） | Copilot 以外のエージェント（Codex など）と共通で使える形式 | 4 |
| `*.agent.md`（カスタムエージェント） | 役割（レビュー担当、計画担当など）ごとの指示、使うツール、モデル | ユーザーが選んだとき、またはサブエージェントとして呼ばれたとき | 指示だけでなく、ツールやモデルもまとめて切り替えられる | 5 |

GitHub の公式ドキュメントでは、ほぼすべての作業に関係するシンプルな指示はカスタム指示に、関連するときだけ読ませたい詳細な指示はスキルにすることが推奨されています（[Adding agent skills for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)）。
VS Code のドキュメントは、カスタムエージェントを作るのは「繰り返し出てくる役割が、専用の指示・ツール・出力形式を必要とするとき」で、プロジェクト全体の規約はカスタム指示に、その場限りの要求はプロンプトに書くよう説明しています（[Custom agents in VS Code](https://code.visualstudio.com/docs/agent-customization/custom-agents)）。

> 補足：VS Code には `*.prompt.md`（プロンプトファイル）もありますが、「Other harnesses don't load prompt files.」とあり、非推奨の Local ハーネスでしか読まれません（[Custom agents in VS Code](https://code.visualstudio.com/docs/agent-customization/custom-agents)）。本記事では扱いません。

### 例：カスタム指示とスキルの書き分け

「全部 `copilot-instructions.md` に書けばいいのでは？」と思うかもしれません。でも、`copilot-instructions.md` は**チャットのたびに毎回送られる**ファイルです。E2E テストの手順をここに書くと、README の誤字を直してもらうときにもその手順が送られます。手順が増えるほど指示書が長くなり、本当に毎回守ってほしいルールが埋もれます。

そこで、同じテストの話でも、毎回守ってほしい短いルールと、テストを実行するときにだけ必要な手順に分けます。

**`.github/copilot-instructions.md`（ほぼすべての作業に関係する、短いルール）**

```markdown
- TypeScript で書く。`any` は使わない。
- パッケージ管理は pnpm を使う（npm / yarn は使わない）。
- コードを変更したら、関係するテストも追加・更新する。
- コミットメッセージは Conventional Commits 形式で書く。
```

**`.github/skills/run-e2e-tests/SKILL.md`（関連するときだけ読ませたい、詳しい手順）**

```markdown
---
name: run-e2e-tests
description: Playwright の E2E テストを実行し、失敗したテストを調査する。E2E テストの実行・追加・失敗調査を頼まれたときに使う。
---

# E2E テストの実行と失敗調査

## 前提
- テスト用 DB を起動する：`docker compose -f docker-compose.test.yml up -d`
- 環境変数は `.env.test` を使う（`.env` は使わない）

## 手順
1. `pnpm build` でビルドする
2. `pnpm test:e2e` を実行する
3. 失敗したら `playwright-report/` のトレースを確認する
4. 不安定なテストか確かめるには、`pnpm test:e2e --repeat-each=3` で繰り返し実行する
5. 修正後は、失敗していたテストだけを `pnpm test:e2e -g "<テスト名>"` で再実行する

## 注意
- `page.waitForTimeout()` は使わず、`expect(...).toBeVisible()` などで待つ
- テストデータは `tests/fixtures/` の factory で作る
```

| | `copilot-instructions.md` | スキル（`SKILL.md`） |
|---|---|---|
| 送られるタイミング | チャットのたびに毎回 | 関連すると判断されたとき、または `/スキル名` で呼んだとき（それまでは `name` と `description` だけ） |
| 向いている内容 | どの作業でも守ってほしい、1 行で意味が通るルール | 特定の作業でだけ必要な、手順・前提・注意点 |
| 長く書くと | 毎回送られる量が増え、ほかの指示が埋もれる | 呼ばれたときだけ読まれるので、詳しく書ける |

判断の目安は「**この 1 行は、README の誤字修正を頼んだときにも必要か？**」です。必要ならカスタム指示に、そうでなければスキルに書きます。スキルの読み込みの仕組みは [3章](#3-skillsskillmd)、長い手順書の置き方は [6章](#6-長い手順がある場合の実装のしかた) で詳しく説明します。

#### 参考：Anthropic（Claude Code）も同じ考え方

Claude Code の公式ドキュメントでも、常に読まれる `CLAUDE.md` とスキルを同じように書き分けるよう説明されています。

| 観点 | Anthropic のドキュメントの記述 |
|---|---|
| `CLAUDE.md` に書くもの | 「Keep it to facts Claude should hold in every session: build commands, conventions, project layout, "always do X" rules.」（[How Claude remembers your project](https://code.claude.com/docs/en/memory)） |
| `CLAUDE.md` の長さ | 「target under 200 lines per CLAUDE.md file. Longer files consume more context and reduce adherence.」（同上） |
| スキルに移すもの | 「If an entry is a multi-step procedure or only matters for one part of the codebase, move it to a skill or a path-scoped rule instead.」（同上） |
| スキルを作るタイミング | 「when a section of CLAUDE.md has grown into a procedure rather than a fact.」（[Extend Claude with skills](https://code.claude.com/docs/en/skills)） |
| なぜ分けるのか | 「every line in it takes a little of Claude's attention on *every* task, whether it's relevant or not.」「A long release procedure sitting in a skill doesn't weigh on your unrelated bug fix the way it would in `CLAUDE.md`.」（[Best practices for Claude Code](https://code.claude.com/docs/en/best-practices)） |

**事実（毎回守るルール）は常に読まれる指示書に、手順はスキルに**、という分け方は、GitHub と Anthropic の両方のドキュメントで同じです。

---

## 2. copilot-instructions.md

リポジトリ全体のルールを書くファイルです。対象のファイルを絞りたいルールは `*.instructions.md` に分けます。

GitHub のドキュメントでは、カスタム指示は「短く、それだけで意味が通る文」にすると効果的で、チャットのたびに送られるので大半のリクエストに当てはまる内容にすべき、とされています（[About customizing GitHub Copilot responses](https://docs.github.com/en/copilot/concepts/prompting-and-context/custom-instructions)）。

### 置き場所

| 単位 | ファイル | VS Code（Copilot ハーネス） | Copilot CLI | 用途 |
|---|---|---|---|---|
| プロジェクト | `.github/copilot-instructions.md` | ✅ | ✅ | リポジトリ全体のルール |
| プロジェクト | `.github/instructions/**/*.instructions.md` | ✅ | ✅ | `applyTo` に一致するファイルの作業時だけ適用 |
| プロジェクト | `AGENTS.md`（ネストも可） | ✅ | ✅ | エージェント共通のルール（[4章](#4-agentsmd)） |
| プロジェクト | `CLAUDE.md` / `.claude/CLAUDE.md` | ―（Claude ハーネスで読まれる） | ✅ | Claude Code との互換 |
| プロジェクト | `GEMINI.md` | 記載なし | ✅ | Gemini CLI との互換 |
| 個人 | `~/.copilot/copilot-instructions.md` | ✅ | ✅ | すべてのプロジェクトに共通の個人ルール |
| 個人 | `~/.copilot/instructions/**/*.instructions.md` | ✅ | ✅ | 個人ルールのうち、`applyTo` に一致するファイルの作業時だけ適用 |

出典：[Custom instructions reference](https://code.visualstudio.com/docs/agents/reference/custom-instructions-reference)、[Adding custom instructions for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions)

**プロジェクトのファイルについて**

Copilot CLI は、次の場所からこれらのファイルを探します。

> the repository root, the current working directory, intermediate directories between them, and any directories nested in the path of a file it is working on.

ただし `.github/instructions/` については「but not intermediate directories」とあり、中間ディレクトリからは探しません。

**個人のファイルについて**

- 非推奨の Local ハーネスは `~/.copilot/` を読みません。個人の指示として、VS Code のユーザープロファイルに保存した指示（Agent Customizations エディタで作成したもの）を使います（[Custom instructions reference](https://code.visualstudio.com/docs/agents/reference/custom-instructions-reference)）。「`~/.copilot/` に置いたのに効かない」ときは、使っているハーネスを確認してください。
- VS Code の設定 `chat.instructionsFilesLocations` で、指示ファイルを探す場所を追加できます。ただし同じドキュメントには「Prefer native harness folders for portability」とあり、Copilot CLI などのほかのツールはエディタの設定を引き継がないため、ハーネス標準のフォルダに置くことが勧められています。
- Copilot CLI では、環境変数 `COPILOT_HOME` を設定すると `~/.copilot` の代わりにそのディレクトリが使われます。
- Copilot CLI では、`COPILOT_CUSTOM_INSTRUCTIONS_DIRS`（カンマ区切り）で、`AGENTS.md` と `*.instructions.md` を探すディレクトリを追加できます。
- `~/.copilot` 配下のファイルは **Settings Sync では同期されません**（[Custom instructions reference](https://code.visualstudio.com/docs/agents/reference/custom-instructions-reference)）。dotfiles などで自分で管理する必要があります。

### 優先順位はない

> Copilot CLI combines their instructions ... but does not define a general precedence order between these files. Avoid conflicting instructions.
> （[Adding custom instructions for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions)）

VS Code のドキュメントにも「Don't rely on a universal precedence order.」とあります。**「個人設定がプロジェクト設定を上書きする」といった動作はない**ので、矛盾するルールを書かないことが前提です。

### `*.instructions.md` の書き方

```markdown
---
name: TypeScript ルール
description: TypeScript のコーディング規約
applyTo: "**/*.ts,**/*.tsx"
---

- `any` は使わない
- 関数には戻り値の型を明記する
```

| フィールド | 説明 |
|---|---|
| `applyTo` | カンマ区切りの glob。**ワークスペースルートからの相対パス**です（`*.py` はルート直下だけに一致し、`**/*.py` なら全階層に一致）。デフォルト値はありません |
| `name` | UI での表示名（省略時はファイル名） |
| `description` | Local ハーネスで、必要に応じて読み込むかの判断に使われます |
| `excludeAgent` | `"code-review"` または `"cloud-agent"` を指定すると、その機能では使われなくなります（CLI のドキュメントに記載） |

補足：`.github/copilot-instructions.md`、`AGENTS.md`、`CLAUDE.md` では、`@relative/path` と書くと別ファイルを取り込めます。ただし絶対パスと `~/` で始まるパスは読み込まれません。`*.instructions.md` と `GEMINI.md` では展開されません（Copilot CLI のドキュメントに記載）。

### 読み込まれているかを確認する

- **VS Code**：コマンドパレットで **`Chat: Open Customizations`** を実行し、**Instructions** タブで検出されているファイルを確認します。ただし一覧に出るのは「検出された」ということだけです。実際に使われたかは応答の **References** セクションで確認しますが、ドキュメントにも「helps check inclusion, not compliance」とあり、従ったかどうかまではわかりません（[Use custom instructions in VS Code](https://code.visualstudio.com/docs/copilot/customization/custom-instructions)）。
- **Copilot CLI**：`/instructions` で、検出された instructions ファイルの一覧が表示され、ファイルごとに有効・無効を切り替えられます。**ファイルを編集しても、実行中のセッションには反映されません。** 一度終了して `copilot --continue` で再開するか、`/new` で新しいセッションを始めます（[Adding custom instructions for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions)）。

---

## 3. Skills（SKILL.md）

特定の作業の手順を書いておき、必要なときだけ読ませる仕組みです。1 スキル 1 ディレクトリで、中に `SKILL.md` と補助ファイルを置きます。

### スキルの読み込みは 3 段階

VS Code のドキュメントでは、スキルは次の 3 段階で読み込まれると説明されています（[Use Agent Skills in VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills)）。

1. **Discovery**：`name` と `description` だけを読む
2. **Instructions loading**：関連すると判断されたら `SKILL.md` の本文を読む（`/スキル名` で呼んだ場合は即この段階）
3. **Resource access**：本文から参照されているファイルだけを読む。**本文で参照されていないファイルは読まれません**

このため、`description` に「何をするか」と「いつ使うか」を書くことが重要です。

### 置き場所

スキルは、**チームで共有したいものはリポジトリの中**に、**自分だけで使うものはホームディレクトリ（`~`）の下**に置きます。

| 単位 | 場所 | VS Code（Copilot ハーネス） | Copilot CLI | 使い分け |
|---|---|---|---|---|
| プロジェクト | `.github/skills/<name>/SKILL.md` | ✅ | ✅ | **チームで共有するスキル**。リポジトリにコミットすると、そのリポジトリを使う全員が使える |
| プロジェクト | `.claude/skills/<name>/SKILL.md` | ―（Claude ハーネス用）※ | ✅ | 同上（Claude Code と共用したい場合） |
| プロジェクト | `.agents/skills/<name>/SKILL.md` | ―（Codex ハーネス用）※ | ✅ | 同上（Codex などと共用したい場合） |
| 個人 | `~/.copilot/skills/<name>/SKILL.md` | ✅ | ✅ | **自分だけが使うスキル**。リポジトリに入らないのでほかの人には影響せず、自分のすべてのプロジェクトで使える |
| 個人 | `~/.agents/skills/<name>/SKILL.md` | ―（Codex ハーネス用）※ | ✅ | 同上（Codex などと共用したい場合） |
| 個人 | `~/.claude/skills/<name>/SKILL.md` | ―（Claude ハーネス用）※ | 記載なし | 同上（Claude Code と共用したい場合） |

出典：[Use Agent Skills in VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills)、[Adding agent skills for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)、[About agent skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)

※ VS Code のドキュメントの表は、ハーネスごとに対応する場所を 1 つずつ示したもので、「認識するディレクトリのすべてではない」と書かれています。Local ハーネスは `.claude/skills/`、`.agents/skills/`、`~/.claude/skills/`、`~/.agents/skills/` も読みます。Copilot ハーネスがこれらを読むかどうかは明記されていないので、**確実に読ませたいなら `.github/skills/` と `~/.copilot/skills/` に置く**のが無難です。

### ディレクトリ構成の例

```
.github/
└── skills/
    └── webapp-testing/        ← ディレクトリ名と name を一致させる
        ├── SKILL.md
        ├── references/
        │   └── troubleshooting.md   ← SKILL.md の本文から参照する
        └── scripts/
            └── run-tests.sh         ← SKILL.md の本文から参照する
```

`scripts/`（実行するコード）、`references/`（ドキュメント）、`assets/`（テンプレートなど）は、Agent Skills のオープンな仕様で決められている任意のディレクトリです（[Agent Skills Specification](https://agentskills.io/specification)）。

### 有効にする方法：置くだけ

スキルは、**決められたディレクトリに `<スキル名>/SKILL.md` を置くだけで使えます。** 登録や設定の変更は要りません。

| ツール | 置いた後にすること | 確認方法 |
|---|---|---|
| VS Code | 新しいチャットを開く | チャット入力欄で `/` を入力し、一覧にスキルが出るか確認する。または `Chat: Open Customizations` の **Skills** タブを見る |
| Copilot CLI | 新しいセッションを始める（セッション中に追加したときは `/skills reload`） | `/skills info <スキル名>` または `/skills list` |

出典：[Use Agent Skills in VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills)、[Adding agent skills for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)

- Copilot CLI の `/skills add <dir>` や `copilot skill add` は、**決められた場所以外**にスキルを置きたいときに使うコマンドです。上の表の場所に置くなら使いません。
- 一覧に出てこないときは、次の 3 点を確認してください。
  - 置き場所が、使っているハーネスに合っているか（[7章](#7-ハーネスについて)）
  - `name` がディレクトリ名と一致しているか
  - `name` に使えない文字が入っていないか（エラーを出さずに読み込まれません）
- 一覧に出ても、「AI に任せる」場合は必ず使われるとは限りません（[スキルの呼び出し方](#スキルの呼び出し方)）。

### SKILL.md の書き方

```markdown
---
name: webapp-testing
description: Webアプリのテストを実行し、失敗を調査する。テスト実行やテスト失敗の調査を頼まれたときに使う。
argument-hint: "[test file] [options]"
---

# Webアプリのテスト

1. [scripts/run-tests.sh](./scripts/run-tests.sh) を実行する
2. テストが失敗したら [references/troubleshooting.md](./references/troubleshooting.md) を読む
3. ...
```

| フィールド | 必須 | 説明 |
|---|---|---|
| `name` | ✅ | **小文字英数字とハイフンのみ**で、最大 64 文字。**親ディレクトリ名と一致**させます。不正な文字が入っていると、**エラーを出さずに読み込まれません** |
| `description` | ✅ | 何をするか ＋ **いつ使うか**。最大 1024 文字 |
| `argument-hint` | | `/` コマンドで使うときの入力ヒント（VS Code） |
| `user-invocable` | | `false` にすると `/` メニューに表示されません（自動読み込みはされます）。VS Code |
| `disable-model-invocation` | | `true` にすると `/` コマンドからだけ実行されます。VS Code |
| `context` | | `fork` にするとサブエージェントで実行されます（実験的機能）。VS Code |
| `allowed-tools` | | 確認なしで使ってよいツール（例：`shell`）。Copilot CLI |
| `license` | | ライセンス。Copilot CLI |

`allowed-tools` について、GitHub のドキュメントは、`shell` や `bash` を事前許可するのは**中身を確認して信頼できるスキルだけ**にするよう警告しています。

### スキルをサブエージェントで実行する

サブエージェントは、メインのチャットとは**別のコンテキスト**で作業し、**結果だけ**をメインのエージェントに返す仕組みです。多くのファイルを読む調査などに使うと、メインのチャットのコンテキストを汚しません（[Use subagents](https://code.visualstudio.com/docs/agents/run/subagents)）。

スキルをサブエージェントで実行する方法は 2 つあります。

| 方法 | 設定のしかた | 使えるハーネス |
|---|---|---|
| `context: fork` | SKILL.md の frontmatter に `context: fork` と書く。VS Code の設定 `github.copilot.chat.skillTool.enabled` を有効にする必要がある（実験的機能） | Copilot（ドキュメントに別の記載がないため） |
| プロンプトでサブエージェントに任せる | 「サブエージェントを使って、認証まわりを調査して」のように、普通の言葉で依頼する | Copilot：`task` ツールが使われる（ツール名を書く必要はない）<br>Local（非推奨）：**Configure Tools** で **Run Subagent**（`agent/runSubagent`）を有効にしてから依頼する |

- `context: fork` は、スキルが呼ばれると**必ず**サブエージェントで実行されます。「In a forked context, the skill executes in a dedicated subagent and only its final result is returned to the parent agent.」（[Use Agent Skills in VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills)）
- プロンプトで依頼する方法は、その都度サブエージェントに任せるかを指示する方法です。
- `runSubagent` は Local ハーネスのツールです。「Copilot uses its native `task` tool rather than Local's `runSubagent`.」（[Use subagents](https://code.visualstudio.com/docs/agents/run/subagents)）。Local ハーネスは 2027年2月に削除される予定なので、これから作るなら Copilot ハーネスの方法を使います。
- サブエージェントは自分でもモデルを呼び出します。そのため、メインのコンテキストが小さくなっても、全体の利用量やコストが減るとは限りません（"a smaller main context doesn't necessarily mean lower total usage or cost."）。

### SKILL.md に書かないこと

「人向けの手順書があるので、それをそのままスキルにすればよい」と考えがちです。でも、人向けの手順書と SKILL.md は、読み手が違います。人向けの手順書は**前提知識がない人**に向けて、背景や用語の説明を丁寧に書きます。SKILL.md の読み手は、**一般的な知識をすでに持っていて、リポジトリのコードも自分で読める AI** です。

Anthropic のスキル作成ガイドは、次の前提で書くよう勧めています。

> **Default assumption:** Claude is already very smart
> Only add context Claude doesn't already have.
> （[Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)）

#### 書かないもの

| 書かないもの | 理由（出典） |
|---|---|
| 一般的な知識の説明（PDF とは何か、HTTP の仕組みなど） | 「You don't need to explain what a PDF is, how HTTP works, or what a database migration does.」（[Agent Skills best practices](https://agentskills.io/skill-creation/best-practices)） |
| コードを読めばわかること（ディレクトリ構成、使っているライブラリなど） | 「Only write down what Claude can't find by reading the repo」「The `CLAUDE.md` rule applies to skills too」（[Best practices for Claude Code](https://code.claude.com/docs/en/best-practices)） |
| 「エラーを適切に処理する」のような一般論 | 一般論ではなく、プロジェクト固有の手順やつまずきやすい点を書くべきとされています（[Agent Skills best practices](https://agentskills.io/skill-creation/best-practices)） |
| あらゆる例外ケースの網羅 | 「Overly comprehensive skills can hurt more than they help」「Concise, stepwise guidance with a working example tends to outperform exhaustive documentation.」（同上） |
| 選択肢の列挙（「A でも B でも C でもよい」） | 「Provide defaults, not menus」。基本の方法を 1 つ決めて、例外のときだけ別の方法を書きます（同上） |
| 「2025年8月より前なら〜」のような、時期で変わる情報 | 「Don't include information that will become outdated」。古い方法は「旧方式」として分けます（[Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)） |

#### 書くもの

**AI がスキルなしでは知り得ないこと**だけを書きます。

> Focus on what the agent *wouldn't* know without your skill: project-specific conventions, domain-specific procedures...
> （[Agent Skills best practices](https://agentskills.io/skill-creation/best-practices)）

たとえば、次のようなものです。

- チームで決めたこと（会議で決まった方針など）
- 特定の人の頭の中にしかない手順（デプロイの手順など）
- AI が実際に間違えたことへの具体的な注意（「ユーザー ID は DB では `user_id`、認証サービスでは `uid`」など）

#### 例：人向けの書き方と SKILL.md の書き方

両方のガイドに、PDF の文字を抜き出す手順で同じような例が載っています。

**人向け（冗長）**

```markdown
PDF（Portable Document Format）は、テキストや画像などを含む一般的なファイル形式です。
PDF からテキストを抽出するにはライブラリが必要です。いくつかのライブラリがありますが、
pdfplumber は使いやすく、多くのケースに対応できるのでおすすめです。
まず pip でインストールし、次に以下のコードを使います……
```

**SKILL.md 向け（簡潔）**

````markdown
## PDF からテキストを抽出する

pdfplumber を使う。スキャンした PDF の場合は pdf2image と pytesseract を使う。

```python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```
````

#### 1 行ずつ確認する

書いた内容は、1 行ずつ次の問いで確認します。

- 「この指示がなかったら、AI は間違えるか？」答えが「いいえ」なら削ります（"Would the agent get this wrong without this instruction?" If the answer is no, cut it.）
- 「AI はこれをコードを読んで知ることができるか？ 実際に読みに行くか？」両方「はい」なら削ります（"Could it find this by reading the code?" "Would it actually go and look?"）
- 「この説明は、トークンを使う価値があるか？」（"Does this paragraph justify its token cost?"）

#### 人向けの手順書からスキルを作るなら

1. **まずスキルなしで AI に作業させて、どこで間違えるかを見ます。** Anthropic のガイドは、長い資料を書く前に評価用のシナリオを作るよう勧めています（"Create evaluations BEFORE writing extensive documentation."）
2. 手順書のうち、**AI が間違えた部分とプロジェクト固有の部分だけ**を SKILL.md に残します。
3. コマンドの順番や引数が決まっている部分は、`scripts/` にスクリプトとして置きます（[6章](#6-長い手順がある場合の実装のしかた)）。
4. 実際の作業で使い、間違えたところを足していきます。

> 上の「人向けの手順書と SKILL.md は読み手が違う」という整理は、筆者がドキュメントの記述をまとめたものです。

### スキルの呼び出し方

人から見ると、スキルを使う方法は 2 つあります。

| 方法 | 人がすること | スキルが使われるかどうか |
|---|---|---|
| **人が名前を指定して呼ぶ** | チャットで `/スキル名` と入力する（例：`/webapp-testing`） | 必ず使われる |
| **AI に任せる** | スキル名は書かず、普通に依頼する（例：「テストを実行して、失敗したら原因を調べて」） | AI が、依頼の内容とスキルの `description` を見比べて、関係があると判断したときだけ使われる |

「AI に任せる」場合は、関係のある依頼でも**必ず選ばれるとは限りません**。確実に使わせたい作業は、`/スキル名` で呼びます。

**VS Code**

frontmatter の設定で、どちらの方法で使えるかを変えられます。

| 設定 | 人が `/スキル名` で呼ぶ | AI が判断して使う |
|---|---|---|
| デフォルト | ✅ | ✅ |
| `user-invocable: false` | ❌（`/` メニューに出ない） | ✅ |
| `disable-model-invocation: true` | ✅ | ❌（人が呼んだときだけ使われる） |
| 両方を設定 | ❌ | ❌（無効） |

```
/webapp-testing 認証まわりの変更分だけ
```

のように、`/スキル名` の後ろに追加の指示を書けます。ドキュメントには、Discovery の段階で検出されても**関連するリクエストのたびに必ず選ばれるわけではない**、とも書かれています（[Use Agent Skills in VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills)）。

作成と確認は **`Chat: Open Customizations`** の **Skills** タブで行えます。**New Skill** を使うと、選択中のハーネスに合った保存場所が提示されます。

**Copilot CLI**

- **人が名前を指定して呼ぶ**：プロンプトの中で `/スキル名` と書きます
- **AI に任せる**：スキル名は書かずに依頼すると、プロンプトとスキルの `description` から Copilot が判断します

```
Use the /frontend-design skill to create a responsive navigation bar in React.
```

| コマンド | 内容 |
|---|---|
| `/skills` | 対話形式のピッカーで有効・無効を切り替えます |
| `/skills list` | スキルの一覧を表示します |
| `/skills info <name>` | 詳細（保存場所、提供元のプラグインなど）を表示します |
| `/skills add <dir>` | スキルを探す場所を追加します |
| `/skills remove <dir>` | `add` で追加した場所を外します（プラグインのスキルはプラグイン側で管理します） |
| `/skills reload` | セッション中に追加したスキルを、再起動なしで読み込みます |

シェルからは次のように操作できます。

```bash
copilot skill list
copilot skill add <FILE | URL | DIRECTORY>
copilot skill disable <name>
copilot skill enable <name>
```

出典：[Adding agent skills for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)

### 公開されているスキルを使う：`gh skill`

`gh skill` は、GitHub 上で公開されているスキルを検索・インストール・更新するための GitHub CLI のサブコマンドです。

> `gh skill` is in public preview ... GitHub CLI to version 2.90.0 or later.
> （[Adding agent skills for Copilot cloud agent](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)）

| コマンド | 内容 |
|---|---|
| `gh skill search <query>` | 公開リポジトリからスキルを検索します |
| `gh skill preview <repo> [<skill>]` | インストールせずに、中身（ファイル構成と `SKILL.md`）を確認します |
| `gh skill install <repo> [<skill[@version]>]` | インストールします（別名 `gh skill add`） |
| `gh skill list` | インストール済みのスキルを一覧表示します |
| `gh skill update [<skill>...]` | 更新します（`--pin` で固定したスキルはスキップされます） |
| `gh skill publish [<dir>]` | 検証してから、GitHub Release として公開します |

```bash
# プロジェクトスコープに、Copilot 向けにインストール（デフォルト）
gh skill install github/awesome-copilot git-commit

# ユーザースコープに、Claude Code 向けにインストール
gh skill install github/awesome-copilot git-commit --agent claude-code --scope user

# 保存先ディレクトリを直接指定
gh skill install github/awesome-copilot git-commit --dir ./my-skills
```

- `--scope`：`project`（デフォルト）または `user`
- `--agent`：`github-copilot`（非対話で実行したときのデフォルト）、`claude-code`、`codex`、`cursor` など
- `--dir`：保存先を直接指定します（`--agent` と `--scope` より優先）
- プロジェクトスコープでは、GitHub Copilot、Cursor、Codex、Gemini CLI などの複数のエージェントが **`.agents/skills`** を共有ディレクトリとして使います（[gh skill install](https://cli.github.com/manual/gh_skill_install)）
- インストール時に、取得元を記録するメタデータが frontmatter に書き込まれます。`gh skill update` はこの情報を使って更新を確認します

他人が作ったスキルにはスクリプトが含まれていることもあるので、インストールする前に `gh skill preview` で中身を確認しておくと安心です。

---

## 4. AGENTS.md

### AGENTS.md とは

`AGENTS.md` は、コーディングエージェント向けの指示を書くための、特定の会社に依存しないオープンな形式です。

> A simple, open format for guiding coding agents
> （[AGENTS.md](https://agents.md/)）

公式サイトでは「エージェント向けの README」と説明されており、README には書かないような、エージェントが必要とするビルド手順・テスト・規約などを書く場所とされています。現在は Linux Foundation 傘下の Agentic AI Foundation が管理しています（同サイト）。

- **書く内容の例**：プロジェクトの概要、ビルド・テストのコマンド、コードスタイル、テストの手順、セキュリティ上の注意など（同サイトの「Popular choices」）
- **必須の項目はありません**。普通の Markdown で、見出しも自由です（同サイトの FAQ）
- **ネストできます**。サブディレクトリにも置けて、編集しているファイルに一番近い `AGENTS.md` が優先されます（同サイトの FAQ：「The closest AGENTS.md to the edited file wins」）

### 形式は共通でも、読み込み方はハーネスごとに違う

VS Code のドキュメントには、次のように書かれています。

> `AGENTS.md` is a cross-agent instruction format. It is not a custom agent definition, and its discovery rules differ by harness.
> （[Custom instructions reference](https://code.visualstudio.com/docs/agents/reference/custom-instructions-reference)）

| ハーネス / ツール | `AGENTS.md` の扱い | 出典 |
|---|---|---|
| VS Code：Copilot ハーネス | 読む。リポジトリのルート、作業ディレクトリ、その間のディレクトリ、作業中のファイルまでのパスにあるものを探す | [Custom instructions reference](https://code.visualstudio.com/docs/agents/reference/custom-instructions-reference) |
| VS Code：Codex ハーネス | 読む。プロジェクトのルートからセッションの作業ディレクトリまでの `AGENTS.md` をつなげて使う | 同上 |
| VS Code：Claude ハーネス | 表に `AGENTS.md` の記載はなく、Claude 側のドキュメントを参照するよう書かれている | 同上 |
| VS Code：Local ハーネス（非推奨） | `chat.useAgentsMdFile` がオンのとき、ルートの `AGENTS.md` を読む。ネストしたものは `chat.useNestedAgentsMdFiles`（実験的機能、デフォルトはオフ）も必要 | 同上 |
| Copilot CLI | 読む。リポジトリのルート、作業ディレクトリ、その間、作業中のファイルまでのパスにあるものを探す。`COPILOT_CUSTOM_INSTRUCTIONS_DIRS` で探す場所を追加できる | [Adding custom instructions for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions) |
| Claude Code（参考） | v2.1.277 以降で読む。ただしデフォルトでは、**作業ディレクトリかその上に `CLAUDE.md`（`.claude/CLAUDE.md`、`CLAUDE.local.md` も含む）がないときだけ**読む | [Manage Claude's memory](https://code.claude.com/docs/en/memory) |

Claude Code のドキュメントでは、`AGENTS.md` が直接読まれない環境でも、`CLAUDE.md` に `@AGENTS.md` と書いて取り込めば、全ツールで 1 つのファイルを共有できると説明されています（[Manage Claude's memory](https://code.claude.com/docs/en/memory)）。

### Copilot 以外のエージェントも使うなら

- Copilot と Codex など、複数のエージェントを併用するチームでは、共通のルールを `AGENTS.md` に書くと、ファイルを重複して持たずに済みます
- Copilot CLI は `.github/copilot-instructions.md` と `AGENTS.md` の**両方を読んで組み合わせます**。優先順位はないので、同じ内容を両方に書いたり、矛盾する内容を書いたりしないようにします（[Adding custom instructions for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions)）
- 名前が似ていますが、`AGENTS.md` は**カスタムエージェントの定義ファイルではありません**（上の VS Code ドキュメントの引用のとおり）。カスタムエージェントは次の章の `*.agent.md` です

---

## 5. カスタムエージェント（*.agent.md）

### カスタムエージェントとは

「レビュー担当」「計画担当」のような役割ごとに、指示・使えるツール・モデルをまとめて定義しておく仕組みです。

> Custom agents combine instructions, tools, and an optional language model into a reusable configuration for a specific role, such as planning or code review.
> （[Custom agents in VS Code](https://code.visualstudio.com/docs/agent-customization/custom-agents)）

GitHub のドキュメントでは、カスタムエージェントは「専門家の定義」で、サブエージェントは「別のコンテキストウィンドウで任された作業をしているエージェント」と区別されています（[Custom agents](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-custom-agents)）。

以前の「カスタムチャットモード」（`.chatmode.md`）は、カスタムエージェントに名前が変わりました。`.agent.md` にリネームします（[Custom agent file reference](https://code.visualstudio.com/docs/agents/reference/custom-agent-file-reference)）。

### 置き場所

| 場所 | VS Code | Copilot CLI |
|---|---|---|
| `.github/agents/*.agent.md` | ✅ | ✅ |
| `.claude/agents/*.md` | ✅（Claude 形式） | ✅ |
| `~/.copilot/agents/*.agent.md` | ✅（Copilot ハーネス） | ✅ |
| `~/.claude/agents/*.md` | ✅（Claude 形式） | 記載なし |
| Organization / Enterprise の `.github` または `.github-private` リポジトリの `agents/` | ✅（自動で検出） | ✅（優先度は最も低い） |

出典：[Custom agent file reference](https://code.visualstudio.com/docs/agents/reference/custom-agent-file-reference)、[GitHub Copilot CLI command reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference)、[Creating custom agents for Copilot cloud agent](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/create-custom-agents)

- Copilot CLI では、ファイル名（`.md` / `.agent.md` を除いた部分）がエージェントの ID になります。**同じ ID のエージェントがあると、個人（`~/.copilot/agents/`）のものが使われます**（[Creating and using custom agents for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli)）
- VS Code の Local ハーネスは、ユーザー単位のカスタムエージェントを `~/.copilot/agents` ではなく VS Code のプロファイルに保存します（[Custom agent file reference](https://code.visualstudio.com/docs/agents/reference/custom-agent-file-reference)）

### `*.agent.md` の書き方

```markdown
---
name: reviewer
description: コードレビューを行う。変更差分のレビューを頼まれたときに使う。
tools: ["read", "search"]
---

あなたはコードレビュー担当です。ファイルは編集せず、指摘だけを返してください。

- 指摘には重要度（高・中・低）を付ける
- ...
```

主なフィールド（VS Code・Copilot CLI・GitHub.com で共通のもの）：

| フィールド | 必須 | 説明 |
|---|---|---|
| `description` | ✅ | 何をするエージェントか、いつ使うか |
| `name` | | 表示名。省略時はファイル名 |
| `tools` | | 使えるツール。`read`、`edit`、`search`、`execute` などの別名や、`<MCPサーバー名>/*` で指定。省略するとすべてのツール |
| `model` | | 使うモデル。省略時は現在のモデル |
| `target` | | `vscode` または `github-copilot`。省略時は両方。**セッションのハーネスを切り替えるものではありません** |
| `user-invocable` | | `false` にすると、選択メニューに表示されなくなります（サブエージェントとしては呼べます） |
| `disable-model-invocation` | | `true` にすると、ほかのエージェントからサブエージェントとして呼ばれなくなります。`infer` の代わりに使います |

出典：[Custom agents configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration)、[Custom agent file reference](https://code.visualstudio.com/docs/agents/reference/custom-agent-file-reference)

- 本文（frontmatter より下）は**最大 30,000 文字**です（[Custom agents configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration)）
- `handoffs`（応答後に別のエージェントへ切り替える提案）は **Local ハーネスだけ**で使えます。Copilot ハーネスと GitHub.com では使えません（[Custom agent file reference](https://code.visualstudio.com/docs/agents/reference/custom-agent-file-reference)、[Custom agents configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration)）
- 使えるフィールドやツール名はハーネスによって違います（[7章](#7-ハーネスについて)）

### カスタム指示との関係

> In the Copilot harness, the agent's instructions are added to your custom instructions and take precedence if they conflict.
> （[Custom agents in VS Code](https://code.visualstudio.com/docs/agent-customization/custom-agents)）

Copilot ハーネスでは、カスタムエージェントの指示は `copilot-instructions.md` などに**追加**され、矛盾した場合はエージェント側が優先されます。

一方 Copilot CLI では、カスタムエージェントが**サブエージェントとして実行されたときは、リポジトリのカスタム指示を受け取りません**。受け取らせたい場合は `include-custom-instructions: true` を指定します。`/agent` や `--agent` でユーザーが選んだ場合は受け取ります（[Creating and using custom agents for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli)）。

### 呼び出し方

**VS Code**：**Session Target** でハーネスを選び、**Agent** のドロップダウンからカスタムエージェントを選びます。別のエージェントに切り替えるまで選ばれたままです。ほかのエージェントからサブエージェントとして呼ばれることもあります。作成は `Chat: Open Customizations` の Agents タブ、または **`Chat: New Custom Agent`** から行えます（[Custom agents in VS Code](https://code.visualstudio.com/docs/agent-customization/custom-agents)）。

**Copilot CLI**（[Creating and using custom agents for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli)）

| 方法 | 例 |
|---|---|
| スラッシュコマンド | `/agent` で一覧から選ぶ（`N` キーで新規作成） |
| プロンプトで指示 | `Use the security-auditor agent on all files in the /src/app directory` |
| 自動 | Copilot がプロンプトから判断し、サブエージェントとして実行する |
| コマンドライン | `copilot --agent security-auditor --prompt "Check /src/app/validator.go"` |

新しく作ったエージェントは、CLI を再起動すると読み込まれます。

---

## 6. 長い手順がある場合の実装のしかた

「リリース手順」「障害調査の手順」のように、Markdown の手順書や参考資料がすでにある場合、それを AI に守らせる実装方法はいくつかあります。

### 公式ドキュメントに書かれていること

- **長い指示書は見落とされやすい**：GitHub のコードレビュー向けチュートリアルには、「Very long instruction files may result in some instructions being overlooked.」とあり、1 つの指示ファイルは**約 1,000 行まで**にするよう勧められています（[Customizing Copilot code review](https://docs.github.com/en/copilot/tutorials/customize-code-review)）
- **リンクを書くだけでは届かない**：「A link doesn't guarantee that the document's contents reach the model.」（[Use custom instructions in VS Code](https://code.visualstudio.com/docs/copilot/customization/custom-instructions)）
- **手順はスキルに**：「For a reusable multi-step workflow rather than coding conventions or project context, consider an agent skill.」（同上）
- **SKILL.md は 500 行まで**：「Keep your main `SKILL.md` under 500 lines. Move detailed reference material to separate files.」（[Agent Skills Specification](https://agentskills.io/specification)）
- **参照ファイルは「いつ読むか」を書く**：「see references/ for details」ではなく、「API が 200 以外を返したら `references/api-errors.md` を読む」のように書くほうが役に立つとされています（[Agent Skills best practices](https://agentskills.io/skill-creation/best-practices)）
- **間違えやすいコマンドはスクリプトに**：「a tested script in `scripts/` is more reliable.」（[Using scripts in skills](https://agentskills.io/skill-creation/using-scripts)）
- **フックはモデルに頼らずに動く**：「Unlike custom instructions, hooks run code rather than asking the model to follow a rule.」（[About hooks](https://docs.github.com/en/copilot/concepts/agents/hooks)）

### 実装方法と遵守度

> **遵守度について**
> 下の表の「遵守度」は、公式の計測データではありません。上に挙げた公式ドキュメントに書かれている**読み込みの仕組み**（いつ・何が AI のコンテキストに入るか）から見た、筆者の評価です。どの方法でも、AI が 100% 従うことは保証されていません。

| # | 実装方法 | 手順書が読まれるタイミング | 遵守度 | 理由 | 向いている使い方 |
|---|---|---|---|---|---|
| 1 | `copilot-instructions.md` に手順を直接書く | 常に | 短ければ高／長いと低 | 必ずコンテキストに入るが、長くなるほど、ほかの指示とまとめて見落とされやすくなる（約 1,000 行が目安） | 数行で済む、全作業に共通の手順 |
| 2 | `copilot-instructions.md` から `@path` で取り込む | 常に | #1 と同じ | 中身はコンテキストに入るので #1 と同じ扱い。ファイルが分かれて管理しやすくなるだけで、長さの問題は解決しない | 手順書を別ファイルで管理したいが、常に読ませたい場合 |
| 3 | 指示書に手順書へのリンクだけを書く | AI が開くと判断したときだけ | 低 | リンクは中身が届くことを保証しない | おすすめしない |
| 4 | `*.instructions.md`（`applyTo`）に書く | 対象のファイルを扱うとき | ファイル単位のルールなら高／作業手順なら低 | 「どのファイルを触るか」で読み込まれるので、「どの作業をするか」に結びつく手順には合わない | 特定のファイル種別に関わるルール |
| 5 | スキルの `SKILL.md` 本文に手順を書く | `/スキル名` で呼んだとき／関連すると判断されたとき | `/` で呼べば高／自動だと中 | 呼ばれれば本文全体がコンテキストに入る。ただし自動では、関連する場面でも必ず選ばれるとは限らない | 500 行以内に収まる作業手順 |
| 6 | スキル＋`references/` に手順書を分ける | スキルが読まれ、さらに本文の指示で参照されたとき | 中 | 本文で「いつ読むか」を書いておけば読まれる。書いていないと読まれない | 長い手順書、場合分けの多い資料 |
| 7 | スキル＋`scripts/` に手順をスクリプト化する | スキルが読まれ、スクリプトを実行したとき | 高 | スクリプトの中の手順は、AI の解釈によらず同じように実行される。AI が判断するのは「実行するかどうか」だけになる | コマンドの順番や引数が決まっている手順 |
| 8 | カスタムエージェントの本文に書く | エージェントを選んでいる間ずっと | 選んでいれば高 | 選んでいる間は常にコンテキストに入り、Copilot ハーネスではカスタム指示より優先される。本文は 30,000 文字まで | 特定の役割で毎回守らせたい手順（レビューの観点など） |
| 9 | フックでチェックする | 決められたタイミング（ツール実行前など）で必ず | 最も高（チェックできる範囲で） | モデルにお願いするのではなく、コードとして実行される | 「このコマンドは実行させない」「編集後に必ずフォーマットする」など、機械的に判定できるもの |

### おすすめの組み合わせ

```
.github/
├── copilot-instructions.md     # 「リリース作業は /release スキルを使う」とだけ書く
└── skills/
    └── release/
        ├── SKILL.md            # 手順の骨組み（チェックリスト形式）
        ├── references/
        │   └── rollback.md     # 「失敗したら読む」と SKILL.md に書く
        └── scripts/
            └── release.sh      # 間違えると困るコマンドはここに
```

- 手順の骨組みは `SKILL.md` に、詳しい資料は `references/` に、間違えると困るコマンドは `scripts/` に分けます（#5〜#7 の組み合わせ）
- 大事な作業は `/スキル名` で明示的に呼ぶと、スキルが選ばれないことを防げます
- 「絶対にやってはいけないこと」は、指示書だけに頼らずフックや権限設定で防ぎます。VS Code のドキュメントにも「A 'do not edit' instruction alone is not a permission boundary.」とあります（[Custom agents in VS Code](https://code.visualstudio.com/docs/agent-customization/custom-agents)）

---

## 7. ハーネスについて

### ハーネスとは

ここまで「Copilot ハーネス」「Local ハーネス」という言葉を使ってきました。**ハーネス**は、モデルを動かす側の仕組みのことで、どのファイルを読み込むか、どのツールを使えるかを決めます。VS Code のドキュメントでは、次のように説明されています。

> The selected agent harness, not the language model, determines instruction support.
> （[Custom instructions reference](https://code.visualstudio.com/docs/agents/reference/custom-instructions-reference)）

カスタムエージェントについても、同じ場所に置いたファイルでも、ハーネスが違えば動作も違うと書かれています。

> A shared file location does not imply identical behavior across harnesses.
> （[Custom agent file reference](https://code.visualstudio.com/docs/agents/reference/custom-agent-file-reference)）

たとえば Copilot ハーネスで Claude モデルを選んでも、Claude ハーネスに切り替わるわけではありません（[Use custom instructions in VS Code](https://code.visualstudio.com/docs/copilot/customization/custom-instructions)）。

### VS Code のハーネス

2026年11月時点の VS Code では、Copilot Chat のセッションごとにハーネスを選びます。

| ハーネス | 概要 |
|---|---|
| **Copilot** | 標準。Copilot CLI と同じ探索ルール（`.github/`、`~/.copilot/`） |
| Anthropic Claude | Claude Code と同じ探索ルール（`CLAUDE.md`、`.claude/`） |
| OpenAI Codex | Codex と同じ探索ルール（`AGENTS.md`、`.agents/`） |
| Local（**非推奨**） | 従来の VS Code 独自の探索。`chat.*` 設定で動作を変えられる |

> The Local harness is deprecated and will be removed in February 2027. Move your workflows to the Copilot harness before then.
> （[Use Agent Skills in VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills)）

### ハーネスによって変わるもの

| 対象 | ハーネスによる違い | 本記事の章 |
|---|---|---|
| カスタム指示 | 読むファイルが違う（Copilot は `copilot-instructions.md` と `AGENTS.md`、Claude は `CLAUDE.md`、Codex は `AGENTS.md`） | 2、4 |
| スキル | 探すディレクトリが違う（`.github/skills/`、`.claude/skills/`、`.agents/skills/`） | 3 |
| `AGENTS.md` | ネストしたファイルの探し方が違う | 4 |
| カスタムエージェント | 使えるフィールドやツール名が違う（`handoffs` は Local だけ、など） | 5 |
| プロンプトファイル | Local ハーネスだけが読む | 1 |
| サブエージェント | 使うツールが違う（Copilot は `task`、Local は `runSubagent`） | 3 |
| `chat.*` 設定 | 多くは Local ハーネスだけに効く | 下記 |

### Local ハーネス用の設定に注意

| 設定 | 状態 | 内容 |
|---|---|---|
| `chat.instructionsFilesLocations` | 継続サポート | instructions を探す場所を追加します。ただし **Copilot CLI や Copilot アプリはエディターの設定を引き継がない**ため、標準のフォルダーに置くことが推奨されています |
| `chat.agentFilesLocations` | 継続サポート | カスタムエージェントを探す場所を追加します。上と同じ理由で、Copilot では標準のフォルダーが推奨されています |
| `chat.agentSkillsLocations` | **非推奨** | Local ハーネス用に、スキルを探す場所を追加します |
| `chat.includeApplyingInstructions` | Local 用 | `applyTo` に一致した `.instructions.md` を含めます |
| `chat.useAgentsMdFile` / `chat.useNestedAgentsMdFiles` | Local 用 | `AGENTS.md` を読み込みます（ネストの探索は実験的機能で、デフォルトはオフ） |
| `chat.useClaudeMdFile` | Local 用 | `CLAUDE.md` を読み込みます |
| `chat.useCustomizationsInParentRepositories` | Local 用 | モノレポのサブフォルダーを開いたとき、親リポジトリのカスタマイズを探します |

出典：[Custom instructions reference](https://code.visualstudio.com/docs/agents/reference/custom-instructions-reference)、[Use Agent Skills in VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills)、[Custom agent file reference](https://code.visualstudio.com/docs/agents/reference/custom-agent-file-reference)

**以前の記事や解説で紹介されている `chat.*` 設定の多くは、Local ハーネスにしか効きません。** Copilot ハーネスで「設定したのに反映されない」ときは、まずこの点を疑ってください。

---

## おすすめの構成

```
# リポジトリ（チームで共有）
.github/
├── copilot-instructions.md          # 全体の短いルール
├── instructions/
│   ├── typescript.instructions.md   # applyTo: "**/*.ts"
│   └── test.instructions.md         # applyTo: "tests/**"
├── skills/
│   └── <name>/SKILL.md              # 特定作業の手順（＋ references/ scripts/）
└── agents/
    └── <name>.agent.md              # 役割ごとのエージェント
AGENTS.md                            # 他のエージェントと共有するなら

# 個人（dotfiles などで管理）
~/.copilot/
├── copilot-instructions.md          # 自分の好み（言語、口調など）
├── skills/<name>/SKILL.md           # 自分だけが使うスキル
└── agents/<name>.agent.md           # 自分だけが使うエージェント
```

- VS Code の Copilot ハーネスと Copilot CLI の**両方で確実に読まれる**のは、`.github/` と `~/.copilot/` の組み合わせです
- `chat.instructionsFilesLocations` などの VS Code 設定に頼らず、**標準のフォルダーに置く**ほうが CLI と共有できます
- `copilot-instructions.md` と `AGENTS.md` を両方置く場合は、内容が重複・矛盾しないようにします
- Claude Code も併用する場合は、Copilot CLI が `CLAUDE.md`、`.claude/skills`、`.claude/agents` も読むことを踏まえて、内容の重複に注意してください

---

## ハマりどころ

| 症状 | 確認すること |
|---|---|
| スキルが一覧に出てこない | `name` が小文字英数字とハイフンだけか、ディレクトリ名と一致しているか（不正な名前は**エラーなしで無視**されます） |
| スキルが使われない | `description` に「いつ使うか」が書いてあるか。確実に使わせたいなら `/スキル名` で呼ぶ |
| スキルの補助ファイルが使われない | `SKILL.md` の本文からリンクしているか、「いつ読むか」を書いているか |
| 長い指示書の一部が守られない | 指示書が長すぎないか。手順はスキルに分ける（[6章](#6-長い手順がある場合の実装のしかた)） |
| VS Code で設定を変えても反映されない | そのセッションのハーネスが Local 以外ではないか（`chat.*` 設定の多くは Local 専用） |
| CLI でルールの変更が反映されない | 実行中のセッションには反映されません。`/new` するか、終了して `copilot --continue` で再開します |
| CLI のサブエージェントがリポジトリのルールを守らない | カスタムエージェントに `include-custom-instructions: true` を指定しているか |
| 個人ルールとリポジトリのルールが食い違う | 優先順位の決まりはありません。矛盾しないように書き直します |

---

## 参考

**カスタム指示**
- [Use custom instructions in VS Code](https://code.visualstudio.com/docs/copilot/customization/custom-instructions)
- [Custom instructions reference (VS Code)](https://code.visualstudio.com/docs/agents/reference/custom-instructions-reference)
- [Adding custom instructions for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions)
- [About customizing GitHub Copilot responses](https://docs.github.com/en/copilot/concepts/prompting-and-context/custom-instructions)
- [Customizing Copilot code review](https://docs.github.com/en/copilot/tutorials/customize-code-review)

**スキル**
- [Use Agent Skills in VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills)
- [Adding agent skills for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)
- [About agent skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [Adding agent skills for Copilot cloud agent](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)
- [gh skill (GitHub CLI manual)](https://cli.github.com/manual/gh_skill)
- [Agent Skills Specification](https://agentskills.io/specification)
- [Agent Skills best practices](https://agentskills.io/skill-creation/best-practices)
- [Using scripts in skills](https://agentskills.io/skill-creation/using-scripts)

**AGENTS.md**
- [AGENTS.md](https://agents.md/)
- [Manage Claude's memory (Claude Code)](https://code.claude.com/docs/en/memory)

**カスタムエージェント**
- [Custom agents in VS Code](https://code.visualstudio.com/docs/agent-customization/custom-agents)
- [Custom agent file reference (VS Code)](https://code.visualstudio.com/docs/agents/reference/custom-agent-file-reference)
- [Custom agents (GitHub Docs)](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-custom-agents)
- [Custom agents configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration)
- [Use subagents (VS Code)](https://code.visualstudio.com/docs/agents/run/subagents)
- [Creating and using custom agents for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli)
- [Creating custom agents for Copilot cloud agent](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/create-custom-agents)
- [GitHub Copilot CLI command reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference)

**フック**
- [About hooks (GitHub Docs)](https://docs.github.com/en/copilot/concepts/agents/hooks)
- [Agent hooks in VS Code](https://code.visualstudio.com/docs/copilot/customization/hooks)

**Claude Code（Anthropic）**
- [How Claude remembers your project](https://code.claude.com/docs/en/memory)
- [Extend Claude with skills](https://code.claude.com/docs/en/skills)
- [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices)
- [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
