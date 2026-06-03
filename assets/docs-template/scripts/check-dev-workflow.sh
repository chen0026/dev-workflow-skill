#!/usr/bin/env bash
set -euo pipefail

mode="${1:-pre-commit}"
tracking_id_regex='(PRD|REQ|TASK|BUG|ADR|ACC|OPS|LEGACY)-(([0-9]{8}-[0-9]{6}-[a-z0-9]{4})|([0-9]{4}))'

if [ "$mode" = "pre-commit" ]; then
  if [ -x "scripts/check-dev-docs.sh" ]; then
    scripts/check-dev-docs.sh --staged
  fi

  changed="$(git diff --cached --name-only --diff-filter=ACMR)"

  code_changed="$(printf '%s\n' "$changed" | grep -Ev '^(docs/|AGENTS\.md$|README\.md$|\.gitignore$|\.dev-workflow/|\.githooks/|scripts/)' || true)"
  docs_changed="$(printf '%s\n' "$changed" | grep -E '^(docs/|AGENTS\.md$)' || true)"

  if [ -n "$code_changed" ] && [ -z "$docs_changed" ]; then
    echo "dev-workflow: 本次提交包含代码变更，但没有同步 docs/ 或 AGENTS.md。"
    echo "请补充 TASK / BUG / ACC 等文档后再提交。"
    exit 1
  fi

  exit 0
fi

if [ "$mode" = "commit-msg" ]; then
  msg_file="${2:?commit message file is required}"

  if ! grep -Eq "$tracking_id_regex" "$msg_file"; then
    echo "dev-workflow: commit message 必须包含追踪编号，例如 TASK-20260528-153012-a7f3 或 BUG-20260528-153012-a7f3。"
    exit 1
  fi

  exit 0
fi

echo "dev-workflow: unknown mode: $mode"
exit 1
