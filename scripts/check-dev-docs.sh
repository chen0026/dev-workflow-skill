#!/usr/bin/env bash
set -euo pipefail

mode="${1:-working}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fail() {
  echo "dev-workflow: $1"
  exit 1
}

[ -f "AGENTS.md" ] || fail "缺少 AGENTS.md"
[ -d "docs" ] || fail "缺少 docs/ 目录"
[ -f "docs/workflow.md" ] || fail "缺少 docs/workflow.md"

for dir in docs/prd docs/requirements docs/tasks docs/bugs docs/active docs/changes docs/history docs/design/decisions docs/acceptance docs/ops docs/legacy docs/archive; do
  [ -d "$dir" ] || fail "缺少目录：$dir"
done

validate_change() {
  change="$1"
  [ -f "$change" ] || fail "CHG 文件不存在：$change"
  grep -Eq '^id: CHG-[0-9]{8}-[0-9]{6}-[a-z0-9]{4}-.+' "$change" || fail "$change 缺少有效 id"
  grep -Eq '^type: (bug|feature|refactor|maintenance)$' "$change" || fail "$change 的 type 无效"
  grep -Eq '^module: [^[:space:]]+' "$change" || fail "$change 缺少 module"
  ! grep -q '^module: module-name$' "$change" || fail "$change 仍使用 module 占位符"
  grep -Eq '^created_at: [0-9]{4}-[0-9]{2}-[0-9]{2}T' "$change" || fail "$change 缺少 created_at"
  grep -Eq '^files: \[[^]]+\]$' "$change" || fail "$change 的 files 必须列出实际文件"
  grep -Eq '^related: \[.*\]$' "$change" || fail "$change 缺少 related"
  for field in '原因' '变更' '验证' '影响'; do
    grep -Eq "^- ${field}：[^[:space:]].+" "$change" || fail "$change 缺少完整${field}记录"
  done
}

if [ "$mode" = "--staged" ] || [ "$mode" = "staged" ]; then
  while IFS= read -r change; do
    [ -n "$change" ] || continue
    validate_change "$change"
  done < <(git diff --cached --name-only --diff-filter=AM | grep -E '^docs/changes/[0-9]{4}/[0-9]{2}/CHG-.*\.md$' || true)
else
  while IFS= read -r change; do
    validate_change "$change"
  done < <(find docs/changes -type f -name 'CHG-*.md' | sort)
fi

if git rev-parse --git-dir >/dev/null 2>&1; then
  if [ "$mode" = "--staged" ] || [ "$mode" = "staged" ]; then
    changed="$(git diff --cached --name-only --diff-filter=ACMR)"
  else
    changed="$(git status --porcelain | sed 's/^...//')"
  fi

  if [ "${DEV_WORKFLOW_REQUIRE_DOCS:-0}" = "1" ]; then
    code_changed="$(printf '%s\n' "$changed" | grep -Ev '^(docs/|AGENTS\.md$|README\.md$|\.gitignore$|\.dev-workflow/|\.githooks/|scripts/)' || true)"
    docs_changed="$(printf '%s\n' "$changed" | grep -E '^(docs/|AGENTS\.md$)' || true)"

    if [ -n "$code_changed" ] && [ -z "$docs_changed" ]; then
      fail "检测到代码变更，但没有同步 docs/ 或 AGENTS.md；quick 可不设置 DEV_WORKFLOW_REQUIRE_DOCS"
    fi
  fi
fi

if [ "$mode" != "--staged" ] && [ "$mode" != "staged" ]; then
  for task in docs/tasks/TASK-*.md; do
    [ -e "$task" ] || continue
    grep -q "验证" "$task" || fail "$task 缺少验证记录"
    grep -q "代码审查" "$task" || fail "$task 缺少代码审查记录"
  done

  for bug in docs/bugs/BUG-*.md; do
    [ -e "$bug" ] || continue
    grep -q "根因" "$bug" || fail "$bug 缺少根因记录"
    grep -q "验证" "$bug" || fail "$bug 缺少验证记录"
  done

  for active in docs/active/ACTIVE-*.md; do
    [ -e "$active" ] || continue
    grep -q "状态" "$active" || fail "$active 缺少状态记录"
    grep -q "下一步" "$active" || fail "$active 缺少下一步记录"
  done

  for acc in docs/acceptance/ACC-*.md; do
    [ -e "$acc" ] || continue
    grep -q "结论" "$acc" || fail "$acc 缺少验收结论"
  done
fi

echo "dev-workflow: 文档检查通过"
