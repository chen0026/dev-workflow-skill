#!/usr/bin/env bash
set -euo pipefail

mode="${1:-pre-commit}"
tracking_id_regex='(PRD|REQ|TASK|BUG|ACTIVE|CHG|ADR|ACC|OPS|LEGACY)-(([0-9]{8}-[0-9]{6}-[a-z0-9]{4})|([0-9]{4}))'
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$mode" = "pre-commit" ]; then
  if [ -f ".dev-workflow/commit-manifest.txt" ]; then
    [ -x "$script_dir/commit-scope.sh" ] || {
      echo "dev-workflow: 找不到 commit-scope.sh。"
      exit 1
    }
    "$script_dir/commit-scope.sh" check

    changed="$(git diff --cached --name-only --diff-filter=ACMR)"
    code_changed="$(printf '%s\n' "$changed" | grep -Ev '^(docs/|AGENTS\.md$|README\.md$|\.gitignore$|\.dev-workflow/|\.githooks/|scripts/)' || true)"
    if [ -n "$code_changed" ] && [ "${DEV_WORKFLOW_SKIP_CHG:-0}" != "1" ]; then
      change_records="$(git diff --cached --name-only --diff-filter=A | grep -E '^docs/changes/[0-9]{4}/[0-9]{2}/CHG-[0-9]{8}-[0-9]{6}-[a-z0-9]{4}-.+\.md$' || true)"
      change_record_count="$(printf '%s\n' "$change_records" | awk 'NF {count++} END {print count+0}')"
      [ "$change_record_count" -eq 1 ] || {
        echo "dev-workflow: 正式代码提交必须恰好新增 1 个 docs/changes/YYYY/MM/CHG-*.md 记录。"
        exit 1
      }
    fi
  fi

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
      echo "dev-workflow: 本次提交包含代码变更，但没有同步 docs/ 或 AGENTS.md。"
      echo "请补充 CHG 或其他正式文档，或取消 DEV_WORKFLOW_REQUIRE_DOCS=1。"
      exit 1
    fi
  fi

  exit 0
fi

if [ "$mode" = "commit-msg" ]; then
  msg_file="${2:?commit message file is required}"

  if [ -f ".dev-workflow/commit-manifest.txt" ]; then
    if ! grep -Eq '^(fix|feat|refactor|chore|docs|test)(\([^)]+\))?:[[:space:]]+.+$' "$msg_file"; then
      echo "dev-workflow: 精确提交的摘要必须使用 fix/feat(scope): 描述。"
      exit 1
    fi
    for field in '原因:' '变更:' '验证:' '影响:'; do
      if ! grep -q "^${field}[[:space:]]*[^[:space:]]" "$msg_file"; then
        echo "dev-workflow: 精确提交记录缺少 ${field}"
        exit 1
      fi
    done
  elif ! grep -Eq "$tracking_id_regex|\\[quick\\]|^(fix|feat|refactor|chore|docs|test)(\([^)]+\))?:" "$msg_file"; then
    echo "dev-workflow: commit message 建议使用 fix/feat(scope): 摘要，并记录原因、变更、验证和影响。"
  fi

  exit 0
fi

if [ "$mode" = "post-commit" ]; then
  [ -f ".dev-workflow/commit-manifest.txt" ] || exit 0
  [ -x "$script_dir/commit-scope.sh" ] || {
    echo "dev-workflow: 找不到 commit-scope.sh。"
    exit 1
  }
  "$script_dir/commit-scope.sh" verify-head
  exit 0
fi

echo "dev-workflow: unknown mode: $mode"
exit 1
