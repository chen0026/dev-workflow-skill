#!/usr/bin/env bash
set -euo pipefail

query="${*:-}"
index=".dev-workflow/index/docs.jsonl"

if [ ! -f "$index" ]; then
  if [ -x "scripts/reindex-dev-docs.sh" ]; then
    scripts/reindex-dev-docs.sh >/dev/null
  else
    echo "dev-workflow: 缺少 $index，且没有 scripts/reindex-dev-docs.sh"
    exit 1
  fi
fi

if [ -z "$query" ]; then
  sed -n '1,20p' "$index"
  exit 0
fi

printf '%s\n' "$query" | tr '[:upper:]' '[:lower:]' | {
  IFS= read -r needle
  awk -v needle="$needle" '
    BEGIN { count = 0 }
    {
      line = tolower($0)
      if (index(line, needle) > 0) {
        print
        count++
      }
      if (count >= 20) {
        exit
      }
    }
  ' "$index"
}
