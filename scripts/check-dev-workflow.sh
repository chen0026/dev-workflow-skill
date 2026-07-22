#!/usr/bin/env bash
set -euo pipefail

mode="${1:-pre-commit}"
tracking_id_regex='(DEV|PRD|REQ|TASK|BUG|ACTIVE|CHG|ADR|ACC|OPS|LEGACY)-(([0-9]{8}-[0-9]{6}-[a-z0-9]{4})|([0-9]{4}))'
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$mode" = "pre-commit" ]; then
  if git diff --cached --name-only | grep -Eq '^(docs/|AGENTS\.md$)'; then
    if [ -x "$script_dir/check-dev-docs.sh" ]; then
      "$script_dir/check-dev-docs.sh" --staged
    elif [ -x "scripts/check-dev-docs.sh" ]; then
      scripts/check-dev-docs.sh --staged
    fi
  fi

  if [ "${DEV_WORKFLOW_REQUIRE_DOCS:-0}" = "1" ]; then
    changed="$(git diff --cached --name-only --diff-filter=ACMR)"
    code_changed="$(printf '%s\n' "$changed" | grep -Ev '^(docs/|AGENTS\.md$|README\.md$|\.gitignore$|\.dev-workflow/|\.githooks/|scripts/)' || true)"
    docs_changed="$(printf '%s\n' "$changed" | grep -E '^(docs/|AGENTS\.md$)' || true)"

    if [ -n "$code_changed" ] && [ -z "$docs_changed" ]; then
      echo "dev-workflow: DEV_WORKFLOW_REQUIRE_DOCS=1，但本次代码提交没有同步长期文档。"
      exit 1
    fi
  fi

  exit 0
fi

if [ "$mode" = "commit-msg" ]; then
  msg_file="${2:?commit message file is required}"
  if ! grep -Eq "$tracking_id_regex|^(fix|feat|refactor|chore|docs|test)(\([^)]+\))?:[[:space:]]+.+$" "$msg_file"; then
    echo "dev-workflow: 建议使用 fix/feat(scope): 摘要，并在正文记录原因、变更、验证和影响。"
  fi
  exit 0
fi

if [ "$mode" = "post-commit" ]; then
  exit 0
fi

echo "dev-workflow: unknown mode: $mode"
exit 1
