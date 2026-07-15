#!/usr/bin/env bash
set -euo pipefail

root="$(pwd)"
index_dir="$root/.dev-workflow/index"
jsonl="$index_dir/docs.jsonl"
include_archive="0"
write_md="0"

for arg in "$@"; do
  case "$arg" in
    --include-archive)
      include_archive="1"
      ;;
    --write-md)
      write_md="1"
      ;;
  esac
done

[ -d "docs" ] || {
  echo "dev-workflow: 缺少 docs/ 目录"
  exit 1
}

mkdir -p "$index_dir"
: > "$jsonl"

find_args=(docs -type f -name "*.md")
if [ "$include_archive" != "1" ]; then
  find_args+=( ! -path "docs/archive/*" )
fi

while IFS= read -r file; do
  base="$(basename "$file")"
  if [ "$file" = "docs/index.md" ]; then
    continue
  fi

  case "$base" in
    TEMPLATE.md)
      continue
      ;;
  esac

  id="$(printf '%s\n' "$base" | sed -nE 's/^((DEV|PRD|REQ|TASK|BUG|ACTIVE|CHG|ADR|ACC|OPS|LEGACY)-(([0-9]{8}-[0-9]{6}-[a-z0-9]{4})|([0-9]{4})).*)\.md$/\1/p')"
  type="$(printf '%s\n' "$base" | sed -nE 's/^(DEV|PRD|REQ|TASK|BUG|ACTIVE|CHG|ADR|ACC|OPS|LEGACY)-.*/\1/p')"
  title="$(sed -nE 's/^# +//p' "$file" | head -n 1)"
  status="$(grep -m 1 -E '(^状态：|^\*\*状态\*\*：|^status:)' "$file" | sed -E 's/^(\*\*)?状态(\*\*)?： *//; s/^status: *//' || true)"
  mtime="$(date -r "$file" +%Y-%m-%dT%H:%M:%S%z 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)"

  [ -n "$id" ] || id="$base"
  if [ -z "$type" ] && printf '%s\n' "$file" | grep -q '^docs/history/'; then
    type="HISTORY"
  fi
  if [ -z "$type" ] && printf '%s\n' "$file" | grep -q '^docs/active/'; then
    type="ACTIVE"
  fi
  [ -n "$type" ] || type="DOC"
  [ -n "$title" ] || title="$base"
  [ -n "$status" ] || status="unknown"

  printf '%s\t%s\t%s\t%s\t%s\n' "$file" "$id" "$type" "$title" "$status" |
    awk -F '\t' -v mtime="$mtime" '
      function esc(s) {
        gsub(/\\/,"\\\\",s)
        gsub(/"/,"\\\"",s)
        return s
      }
      {
        printf("{\"path\":\"%s\",\"id\":\"%s\",\"type\":\"%s\",\"title\":\"%s\",\"status\":\"%s\",\"mtime\":\"%s\"}\n", esc($1), esc($2), esc($3), esc($4), esc($5), esc(mtime))
      }
    ' >> "$jsonl"
done < <(find "${find_args[@]}" | sort)

if [ "$write_md" = "1" ]; then
  {
    printf '# 文档索引\n\n'
    printf '> 此文件由 `scripts/reindex-dev-docs.sh --write-md` 生成。`docs/index.md` 默认加入 `.gitignore`，不要提交它，避免多分支合并冲突。\n\n'
    printf '| 类型 | 编号 | 标题 | 状态 | 路径 |\n'
    printf '|------|------|------|------|------|\n'
    sed -E 's/^\{"path":"([^"]+)","id":"([^"]+)","type":"([^"]+)","title":"([^"]+)","status":"([^"]+)".*/| \3 | \2 | \4 | \5 | `\1` |/' "$jsonl"
  } > docs/index.md
fi

echo "dev-workflow: 已生成 $jsonl"
