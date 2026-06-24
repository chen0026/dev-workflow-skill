#!/usr/bin/env bash
set -euo pipefail

query="${*:-}"
index=".dev-workflow/index/docs.jsonl"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
reindex_script="$script_dir/reindex-dev-docs.sh"
if [ ! -x "$reindex_script" ] && [ -x "scripts/reindex-dev-docs.sh" ]; then
  reindex_script="scripts/reindex-dev-docs.sh"
fi

index_needs_rebuild() {
  if [ ! -f "$index" ]; then
    return 0
  fi

  if [ ! -d "docs" ]; then
    return 1
  fi

  changed="$(
    find docs \
      -type f \
      -name "*.md" \
      ! -path "docs/archive/*" \
      ! -path "docs/index.md" \
      ! -name "TEMPLATE.md" \
      -newer "$index" \
      -print \
      -quit
  )"

  [ -n "$changed" ]
}

if index_needs_rebuild; then
  if [ -x "$reindex_script" ]; then
    "$reindex_script" >/dev/null
  else
    echo "dev-workflow: 缺少 ${index}，且没有 ${reindex_script}"
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
