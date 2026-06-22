#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-help}"
shift || true

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
usage:
  active-work.sh start short-title
  active-work.sh list
  active-work.sh template
  active-work.sh finish ACTIVE_FILE module-name [--keep-active] < summary.md

finish summary 最多 8 个非空行。完成折叠前必须已通过人工审核。
EOF
}

fail() {
  echo "dev-workflow: $1"
  exit 1
}

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//'
}

extract_field() {
  file="$1"
  label="$2"
  grep -m 1 -E "^- ${label}：|^${label}：" "$file" 2>/dev/null \
    | sed -E "s/^- ${label}： *//; s/^${label}： *//" || true
}

start_active() {
  title="${*:-}"
  [ -n "$title" ] || fail "start 需要 short-title"

  if [ -x "$script_dir/new-doc.sh" ]; then
    "$script_dir/new-doc.sh" ACTIVE "$title"
  elif [ -x "scripts/new-doc.sh" ]; then
    scripts/new-doc.sh ACTIVE "$title"
  else
    fail "找不到 new-doc.sh"
  fi
}

list_active() {
  if [ ! -d "docs/active" ]; then
    echo "dev-workflow: 缺少 docs/active"
    exit 0
  fi

  found="0"
  while IFS= read -r file; do
    found="1"
    title="$(sed -nE 's/^# +//p' "$file" | head -n 1)"
    status="$(extract_field "$file" "状态")"
    module="$(extract_field "$file" "模块")"
    case "$title" in
      ACTIVE-YYYYMMDD-HHMMSS-XXXX-short-title)
        title="$(basename "$file" .md)"
        ;;
    esac
    [ -n "$title" ] || title="$(basename "$file" .md)"
    [ -n "$status" ] || status="unknown"
    [ -n "$module" ] || module="unknown"
    printf '%s\t%s\t%s\t%s\n' "$status" "$module" "$title" "$file"
  done < <(find docs/active -type f -name 'ACTIVE-*.md' 2>/dev/null | sort)

  if [ "$found" = "0" ]; then
    echo "dev-workflow: 没有进行中的 ACTIVE"
  fi
}

summary_template() {
  cat <<'EOF'
- 类型：
- 原因：
- 改动：
- 验证：
- 审查：
- 提交：
- 关联：
EOF
}

finish_active() {
  active_file="${1:-}"
  module="${2:-}"
  keep_active="0"

  [ -n "$active_file" ] || fail "finish 需要 ACTIVE_FILE"
  [ -n "$module" ] || fail "finish 需要 module-name"
  [ -f "$active_file" ] || fail "找不到 ACTIVE 文件：$active_file"

  shift 2 || true
  for arg in "$@"; do
    case "$arg" in
      --keep-active)
        keep_active="1"
        ;;
      *)
        fail "未知参数：$arg"
        ;;
    esac
  done

  summary="$(cat)"
  non_empty_count="$(printf '%s\n' "$summary" | awk 'NF {count++} END {print count + 0}')"
  [ "$non_empty_count" -gt 0 ] || fail "finish 需要从 stdin 传入 history 摘要"
  [ "$non_empty_count" -le 8 ] || fail "history 摘要最多 8 个非空行，当前 $non_empty_count 行"

  module_slug="$(slugify "$module")"
  [ -n "$module_slug" ] || fail "module-name 无法生成文件名"
  history_file="docs/history/${module_slug}.md"
  mkdir -p docs/history

  if [ ! -f "$history_file" ]; then
    {
      printf '# History: %s\n\n' "$module"
      printf '> 模块级完成摘要。每条最多 8 行，只写结论；细节通过提交号、PR、REQ/TASK/BUG/ACTIVE 或 archive 追溯。\n'
    } > "$history_file"
  fi

  active_title="$(sed -nE 's/^# +//p' "$active_file" | head -n 1)"
  [ -n "$active_title" ] || active_title="$(basename "$active_file" .md)"

  {
    printf '\n## %s %s\n\n' "$(date +%F)" "$active_title"
    printf '%s\n' "$summary"
  } >> "$history_file"

  if [ "$keep_active" = "1" ]; then
    echo "dev-workflow: 已写入 ${history_file}，保留 ${active_file}"
  else
    rm -f "$active_file"
    echo "dev-workflow: 已写入 ${history_file}，并清理 ${active_file}"
  fi
}

case "$cmd" in
  start)
    start_active "$@"
    ;;
  list)
    list_active
    ;;
  template)
    summary_template
    ;;
  finish)
    finish_active "$@"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac
