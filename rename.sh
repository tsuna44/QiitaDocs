#!/bin/bash

echo "リネーム処理を開始します..."

for file in public/*.md; do
  # titleを抽出
  title=$(grep -m 1 "^title:" "$file" | sed -E 's/^title:[[:space:]]*//;s/^["\x27]//;s/["\x27]$//;s/\r//g')

  if [ -n "$title" ]; then
    # ファイル名として安全な文字列に変換
    safe_title=$(echo "$title" | sed 's/\//／/g')
    new_filename="public/${safe_title}.md"
    # リネーム実行
    if [ "$file" != "$new_filename" ]; then
      if [ ! -f "$new_filename" ]; then
        mv "$file" "$new_filename"
        echo "✓ [OK] $file -> $new_filename"
      else
        echo "[SKIP] 移動先が存在するためスキップ: $new_filename"
      fi
    fi
  else
    echo "[ERROR] $file : titleが見つかりません"
  fi
done

echo "完了"

