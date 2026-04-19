#!/bin/bash

read -p "GitHubのリポジトリ名を入力してください: " INPUT_NAME
PROJECT_NAME="${INPUT_NAME:-qiita-content}" # 好きなディレクトリ名・リポジトリ名に変えてください

mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

# GitHubリポジトリ作成 (Public)
echo "GitHubリポジトリを作成しています..."
git init -q
gh repo create "$PROJECT_NAME" --public --source=. --remote=origin

# インストール
echo "qiita-cliをインストールしています..."
npm init -y > /dev/null
npm install --save-dev @qiita/qiita-cli > /dev/null

# 初期化
echo "qiita initを実行しています..."
npx qiita init

# Qiitaログイン (qiitaのアクセストークンでログイン)
npx qiita login

# 既存記事を全部持ってくる
echo "既存の記事を取得しています..."
npx qiita pull

# GitHub Secrets 登録
echo "GitHub Secretsを設定しています..."
read -p "Qiitaのアクセストークンを入力してください: " QIITA_TOKEN

if [ -n "$QIITA_TOKEN" ]; then
  gh secret set QIITA_TOKEN --body "$QIITA_TOKEN" --repo "https://github.com/$(gh api user --jq .login)/$PROJECT_NAME"
else
  echo "シークレットの設定をスキップしました。"
fi

# テスト記事作成
echo "テスト記事を作成しています..."
npx qiita new "test"

# プレビュー実行
echo "プレビューサーバーを起動しています..."
npx qiita preview

echo "新しく作成した差分をpushするとGitHub Actionsで自動デプロイされて記事が更新されます。"

