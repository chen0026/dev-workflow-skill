#!/usr/bin/env bash
set -euo pipefail

mode="${1:-working}"

fail() {
  echo "dev-workflow: $1"
  exit 1
}

[ -f "AGENTS.md" ] || fail "缺少 AGENTS.md"
[ -d "docs" ] || fail "缺少 docs/ 目录"
[ -f "docs/workflow.md" ] || fail "缺少 docs/workflow.md"
[ -f "docs/index.md" ] || fail "缺少 docs/index.md"

for dir in docs/prd docs/tasks docs/bugs docs/design/decisions docs/acceptance docs/ops docs/legacy docs/archive; do
  [ -d "$dir" ] || fail "缺少目录：$dir"
done

if ! grep -Eq '(PRD|TASK|BUG|ADR|ACC|OPS|LEGACY)-[0-9]{4}' "docs/index.md"; then
  fail "docs/index.md 缺少追踪编号"
fi

if git rev-parse --git-dir >/dev/null 2>&1; then
  if [ "$mode" = "--staged" ] || [ "$mode" = "staged" ]; then
    changed="$(git diff --cached --name-only --diff-filter=ACMR)"
  else
    changed="$(git status --porcelain | sed 's/^...//')"
  fi

  code_changed="$(printf '%s\n' "$changed" | grep -Ev '^(docs/|AGENTS\.md$|README\.md$|\.githooks/|scripts/)' || true)"
  docs_changed="$(printf '%s\n' "$changed" | grep -E '^(docs/|AGENTS\.md$)' || true)"

  if [ -n "$code_changed" ] && [ -z "$docs_changed" ]; then
    fail "检测到代码变更，但没有同步 docs/ 或 AGENTS.md"
  fi
fi

for task in docs/tasks/TASK-*.md; do
  [ -e "$task" ] || continue
  grep -q "关联验收" "$task" || fail "$task 缺少关联验收"
  grep -q "验证" "$task" || fail "$task 缺少验证记录"
  grep -q "代码审查" "$task" || fail "$task 缺少代码审查记录"
done

for acc in docs/acceptance/ACC-*.md; do
  [ -e "$acc" ] || continue
  grep -q "结论" "$acc" || fail "$acc 缺少验收结论"
done

echo "dev-workflow: 文档检查通过"
