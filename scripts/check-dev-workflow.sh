#!/usr/bin/env bash
set -euo pipefail

mode="${1:-pre-commit}"
tracking_id_regex='(PRD|REQ|TASK|BUG|ACTIVE|ADR|ACC|OPS|LEGACY)-(([0-9]{8}-[0-9]{6}-[a-z0-9]{4})|([0-9]{4}))'
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$mode" = "pre-commit" ]; then
  if [ -x "$script_dir/check-dev-docs.sh" ]; then
    "$script_dir/check-dev-docs.sh" --staged
  elif [ -x "scripts/check-dev-docs.sh" ]; then
    scripts/check-dev-docs.sh --staged
  fi

  if [ "${DEV_WORKFLOW_REQUIRE_DOCS:-0}" = "1" ]; then
    changed="$(git diff --cached --name-only --diff-filter=ACMR)"

    code_changed="$(printf '%s\n' "$changed" | grep -Ev '^(docs/|AGENTS\.md$|README\.md$|\.gitignore$|\.dev-workflow/|\.githooks/|scripts/)' || true)"
    docs_changed="$(printf '%s\n' "$changed" | grep -E '^(docs/|AGENTS\.md$)' || true)"

    if [ -n "$code_changed" ] && [ -z "$docs_changed" ]; then
      echo "dev-workflow: 本次提交包含代码变更，但没有同步 docs/ 或 AGENTS.md。"
      echo "请补充 ACTIVE 或正式文档，或取消 DEV_WORKFLOW_REQUIRE_DOCS=1。"
      exit 1
    fi
  fi

  exit 0
fi

if [ "$mode" = "commit-msg" ]; then
  msg_file="${2:?commit message file is required}"

  if ! grep -Eq "$tracking_id_regex|\\[quick\\]" "$msg_file"; then
    echo "dev-workflow: commit message 建议包含追踪编号；quick 可使用 [quick]。"
    exit 1
  fi

  exit 0
fi

echo "dev-workflow: unknown mode: $mode"
exit 1
