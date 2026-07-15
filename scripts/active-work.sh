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
  active-work.sh current
  active-work.sh bind ACTIVE_FILE
  active-work.sh unbind
  active-work.sh resolve keyword [keyword...]
  active-work.sh match keyword [keyword...]
  active-work.sh template
  active-work.sh finish ACTIVE_FILE module-name [--keep-active] < summary.md

start 会自动绑定当前对话；resolve 优先返回绑定，只在无绑定时执行 match 并保存唯一结果。
多个 ACTIVE 命中时，match/resolve 会返回 ambiguous_active 并退出 2，禁止自动猜。
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

current_branch() {
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown"
  else
    echo "no-git"
  fi
}

stamp_now() {
  date +%Y-%m-%dT%H:%M:%S%z
}

context_key() {
  context_id="${DEV_WORKFLOW_CONTEXT_ID:-${CODEX_THREAD_ID:-}}"
  [ -n "$context_id" ] || fail "缺少对话标识；请设置 DEV_WORKFLOW_CONTEXT_ID"
  key="$(printf '%s' "$context_id" | git hash-object --stdin)" \
    || fail "对话标识无法生成绑定键"
  printf '%s\n' "$key"
}

binding_file() {
  printf '.dev-workflow/bindings/%s.active\n' "$(context_key)"
}

bind_active() {
  active_file="${1:-}"
  [ -n "$active_file" ] || fail "bind 需要 ACTIVE_FILE"
  case "$active_file" in
    docs/active/ACTIVE-*.md) ;;
    *) fail "只能绑定 docs/active/ACTIVE-*.md" ;;
  esac
  [ -f "$active_file" ] || fail "找不到 ACTIVE 文件：$active_file"

  file="$(binding_file)"
  mkdir -p "$(dirname "$file")"
  printf '%s\n' "$active_file" > "$file"
  echo "$active_file"
}

current_active() {
  file="$(binding_file)"
  if [ ! -f "$file" ]; then
    echo "dev-workflow: no_active_binding" >&2
    return 1
  fi

  active_file="$(sed -n '1p' "$file")"
  if [ ! -f "$active_file" ]; then
    rm -f "$file"
    echo "dev-workflow: stale_active_binding" >&2
    return 1
  fi

  printf '%s\n' "$active_file"
}

unbind_active() {
  file="$(binding_file)"
  rm -f "$file"
  echo "dev-workflow: 已解除当前对话 ACTIVE 绑定"
}

remove_bindings_for_active() {
  active_file="$1"
  [ -d ".dev-workflow/bindings" ] || return 0

  while IFS= read -r file; do
    if [ "$(sed -n '1p' "$file")" = "$active_file" ]; then
      rm -f "$file"
    fi
  done < <(find .dev-workflow/bindings -type f -name '*.active' 2>/dev/null)
}

hydrate_active() {
  file="$1"
  title="$(basename "$file" .md)"
  branch="$(current_branch)"
  stamp="$(stamp_now)"
  tmp="${file}.tmp.$$"

  awk -v title="$title" -v file="$file" -v branch="$branch" -v stamp="$stamp" '
    NR == 1 && $0 ~ /^# ACTIVE-YYYYMMDD-HHMMSS-XXXX-short-title/ {
      print "# " title
      next
    }
    /^- ACTIVE 文件：/ {
      print "- ACTIVE 文件：" file
      next
    }
    /^- 任务指纹：/ {
      print "- 任务指纹：" title
      next
    }
    /^- 分支：/ {
      print "- 分支：" branch
      next
    }
    /^- 创建时间：/ {
      print "- 创建时间：" stamp
      next
    }
    /^- 最后更新：/ {
      print "- 最后更新：" stamp
      next
    }
    { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

start_active() {
  title="${*:-}"
  [ -n "$title" ] || fail "start 需要 short-title"

  if [ -x "$script_dir/new-doc.sh" ]; then
    active_file="$("$script_dir/new-doc.sh" ACTIVE "$title")"
  elif [ -x "scripts/new-doc.sh" ]; then
    active_file="$(scripts/new-doc.sh ACTIVE "$title")"
  else
    fail "找不到 new-doc.sh"
  fi
  hydrate_active "$active_file"
  bind_active "$active_file" >/dev/null
  echo "$active_file"
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

match_active() {
  [ "$#" -gt 0 ] || fail "match 需要 keyword"
  [ -d "docs/active" ] || fail "缺少 docs/active"

  matches=""
  count="0"
  query="$(printf '%s ' "$@" | tr '[:upper:]' '[:lower:]')"

  while IFS= read -r file; do
    title="$(sed -nE 's/^# +//p' "$file" | head -n 1)"
    status="$(extract_field "$file" "状态")"
    module="$(extract_field "$file" "模块")"
    source="$(extract_field "$file" "来源")"
    branch="$(extract_field "$file" "分支")"
    fingerprint="$(extract_field "$file" "任务指纹")"
    haystack="$(printf '%s %s %s %s %s %s' "$(basename "$file")" "$title" "$module" "$source" "$branch" "$fingerprint" | tr '[:upper:]' '[:lower:]')"

    matched="1"
    for token in $query; do
      case "$haystack" in
        *"$token"*) ;;
        *)
          matched="0"
          ;;
      esac
    done

    if [ "$matched" = "1" ]; then
      count="$((count + 1))"
      matches="${matches}${status:-unknown}\t${module:-unknown}\t${title:-$(basename "$file" .md)}\t${file}
"
    fi
  done < <(find docs/active -type f -name 'ACTIVE-*.md' 2>/dev/null | sort)

  if [ "$count" -eq 0 ]; then
    echo "dev-workflow: no_active_match"
    exit 1
  fi

  if [ "$count" -gt 1 ]; then
    echo "dev-workflow: ambiguous_active"
    printf '%b' "$matches"
    exit 2
  fi

  printf '%b' "$matches" | awk -F '\t' '{print $4}'
}

resolve_active() {
  [ "$#" -gt 0 ] || fail "resolve 需要 keyword"

  if active_file="$(current_active 2>/dev/null)"; then
    printf '%s\n' "$active_file"
    return 0
  fi

  if active_file="$(match_active "$@")"; then
    bind_active "$active_file" >/dev/null
    printf '%s\n' "$active_file"
    return 0
  else
    status="$?"
    printf '%s\n' "$active_file"
    return "$status"
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
      printf '> 模块级完成摘要。每条最多 8 行，只写结论；细节通过提交号、PR、DEV/ACTIVE 或 archive 追溯。\n'
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
    remove_bindings_for_active "$active_file"
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
  current)
    current_active
    ;;
  bind)
    bind_active "$@"
    ;;
  unbind)
    unbind_active
    ;;
  resolve)
    resolve_active "$@"
    ;;
  match)
    match_active "$@"
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
