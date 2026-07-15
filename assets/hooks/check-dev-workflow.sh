#!/usr/bin/env bash
set -euo pipefail

mode="${1:-pre-commit}"
tracking_id_regex='(DEV|PRD|REQ|TASK|BUG|ACTIVE|CHG|ADR|ACC|OPS|LEGACY)-(([0-9]{8}-[0-9]{6}-[a-z0-9]{4})|([0-9]{4}))'
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

resolve_manifest() {
  if [ -n "${DEV_WORKFLOW_MANIFEST:-}" ]; then
    [ -f "$DEV_WORKFLOW_MANIFEST" ] || return 1
    printf '%s\n' "$DEV_WORKFLOW_MANIFEST"
    return 0
  fi

  candidates="$(mktemp)"
  if [ -f ".dev-workflow/commit-manifest.txt" ]; then
    printf '%s\n' ".dev-workflow/commit-manifest.txt" >> "$candidates"
  fi
  if [ -d ".dev-workflow/commits" ]; then
    find ".dev-workflow/commits" -maxdepth 1 -type f -name '*.txt' -print | LC_ALL=C sort >> "$candidates"
  fi
  count="$(awk 'NF {count++} END {print count+0}' "$candidates")"
  if [ "$count" -gt 1 ]; then
    rm -f "$candidates"
    echo "dev-workflow: 存在多个任务提交清单；请使用 commit-scope.sh commit TASK_KEY 精确提交。" >&2
    return 2
  fi
  if [ "$count" -eq 1 ]; then
    sed -n '1p' "$candidates"
    rm -f "$candidates"
    return 0
  fi
  rm -f "$candidates"
  return 1
}

if [ "$mode" = "pre-commit" ]; then
  manifest_status="0"
  active_manifest="$(resolve_manifest)" || manifest_status="$?"
  [ "$manifest_status" != "2" ] || exit 1
  if [ -n "$active_manifest" ]; then
    [ -x "$script_dir/commit-scope.sh" ] || {
      echo "dev-workflow: 找不到 commit-scope.sh。"
      exit 1
    }
    DEV_WORKFLOW_MANIFEST="$active_manifest" "$script_dir/commit-scope.sh" check

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
      echo "请补充 DEV 或其他长期文档，或取消 DEV_WORKFLOW_REQUIRE_DOCS=1。"
      exit 1
    fi
  fi

  exit 0
fi

if [ "$mode" = "commit-msg" ]; then
  msg_file="${2:?commit message file is required}"

  manifest_status="0"
  active_manifest="$(resolve_manifest)" || manifest_status="$?"
  [ "$manifest_status" != "2" ] || exit 1
  if [ -n "$active_manifest" ]; then
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
  manifest_status="0"
  active_manifest="$(resolve_manifest)" || manifest_status="$?"
  [ "$manifest_status" != "2" ] || exit 1
  [ -n "$active_manifest" ] || exit 0
  [ -x "$script_dir/commit-scope.sh" ] || {
    echo "dev-workflow: 找不到 commit-scope.sh。"
    exit 1
  }
  DEV_WORKFLOW_MANIFEST="$active_manifest" "$script_dir/commit-scope.sh" verify-head
  exit 0
fi

echo "dev-workflow: unknown mode: $mode"
exit 1
