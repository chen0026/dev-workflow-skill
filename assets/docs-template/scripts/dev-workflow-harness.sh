#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-run}"
shift || true

skill_root="${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}"
version_file="$skill_root/VERSION"

version() {
  if [ -f "$version_file" ]; then
    cat "$version_file"
  else
    echo "unknown"
  fi
}

classify() {
  text="$(printf '%s ' "$@" | tr '[:upper:]' '[:lower:]')"

  if printf '%s\n' "$text" | grep -Eq 'prd|需求|产品文档|改版|重构架构|多模块|接口|api|数据|权限|支付|订单|登录|部署|回滚|高风险|strict'; then
    echo "strict"
    return
  fi

  if printf '%s\n' "$text" | grep -Eq 'bug|修复|功能|用户行为|根因|追溯|standard'; then
    echo "standard"
    return
  fi

  echo "quick"
}

docs_allowed_for() {
  case "$1" in
    quick)
      echo "0"
      ;;
    standard)
      echo "1"
      ;;
    strict)
      echo "full"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

docs_index_tracked() {
  if git rev-parse --git-dir >/dev/null 2>&1 && git ls-files --error-unmatch docs/index.md >/dev/null 2>&1; then
    echo "true"
  else
    echo "false"
  fi
}

docs_changed_count() {
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git status --porcelain -- docs AGENTS.md 2>/dev/null | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

changed_code_count() {
  if git rev-parse --git-dir >/dev/null 2>&1; then
    {
      git status --porcelain 2>/dev/null \
        | sed 's/^...//' \
        | grep -Ev '^(docs/|AGENTS\.md$|README\.md$|\.gitignore$|\.dev-workflow/|\.githooks/|scripts/)' || true
    } | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

count_files() {
  dir="$1"
  pattern="$2"
  if [ -d "$dir" ]; then
    find "$dir" -type f -name "$pattern" | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

count_matching_files() {
  dir="$1"
  pattern="$2"
  regex="$3"
  if [ -d "$dir" ]; then
    {
      find "$dir" -type f -name "$pattern" -exec grep -El "$regex" {} + 2>/dev/null || true
    } | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

check() {
  if [ -x "scripts/check-dev-docs.sh" ]; then
    scripts/check-dev-docs.sh >/dev/null
  fi

  if [ "$(docs_index_tracked)" = "true" ]; then
    echo "dev-workflow: docs/index.md 仍被 Git 跟踪，请执行：git rm --cached docs/index.md"
    exit 1
  fi

  echo "dev-workflow: harness check passed"
}

report() {
  flow="$(classify "$@")"
  docs_allowed="$(docs_allowed_for "$flow")"

  printf 'version: %s\n' "$(version)"
  printf 'flow: %s\n' "$flow"
  printf 'docs_allowed: %s\n' "$docs_allowed"
  printf 'docs_changed: %s\n' "$(docs_changed_count)"
  printf 'docs_index_tracked: %s\n' "$(docs_index_tracked)"
  printf 'human_review_required: true\n'
  printf 'commit_allowed: false\n'
}

run() {
  flow="$(classify "$@")"
  report "$@"
  printf 'entry: natural-language\n'
  case "$flow" in
    quick)
      printf 'next_action: implement_minimal_change_then_verify\n'
      ;;
    standard)
      printf 'next_action: keep_one_task_or_bug_record_if_trace_needed_then_verify\n'
      ;;
    strict)
      printf 'next_action: create_and_confirm_REQ_before_coding\n'
      ;;
  esac
  printf 'verify_command: scripts/dev-workflow-harness.sh verify "%s"\n' "$*"
  printf 'check_command: scripts/dev-workflow-harness.sh check\n'
}

verify() {
  flow="$(classify "$@")"
  docs_allowed="$(docs_allowed_for "$flow")"
  docs_changed="$(docs_changed_count)"
  code_changed="$(changed_code_count)"
  requirements_files="$(count_files docs/requirements 'REQ-*.md')"
  task_files="$(count_files docs/tasks 'TASK-*.md')"
  bug_files="$(count_files docs/bugs 'BUG-*.md')"
  acceptance_files="$(count_files docs/acceptance 'ACC-*.md')"
  requirements_with_acceptance="$(count_matching_files docs/requirements 'REQ-*.md' '验收方式|手工验收|可自动化测试|测试状态')"
  records_with_evidence="$(
    {
      count_matching_files docs/tasks 'TASK-*.md' '验证方式|验证结果|验收结论|测试';
      count_matching_files docs/bugs 'BUG-*.md' '验证结果|验证|复现步骤|根因';
      count_matching_files docs/acceptance 'ACC-*.md' '验收标准|验证记录|结论';
    } | awk '{sum += $1} END {print sum + 0}'
  )"
  docs_budget_status="ok"
  requirement_status="ok"
  evidence_status="ok"
  machine_gate="pass"

  if [ "$flow" = "quick" ] && [ "$code_changed" -gt 0 ] && [ "$docs_changed" -gt 0 ]; then
    docs_budget_status="over_budget"
    machine_gate="review"
  fi

  if [ "$flow" = "standard" ] && [ "$code_changed" -gt 0 ] && [ "$docs_changed" -gt 1 ]; then
    docs_budget_status="over_budget"
    machine_gate="review"
  fi

  if [ "$flow" = "strict" ] && [ "$requirements_files" -eq 0 ]; then
    requirement_status="missing_REQ"
    machine_gate="blocked"
  fi

  if [ "$flow" = "strict" ] && [ "$requirements_files" -gt 0 ] && [ "$requirements_with_acceptance" -lt "$requirements_files" ]; then
    requirement_status="missing_acceptance"
    machine_gate="blocked"
  fi

  if [ "$flow" != "quick" ] && [ "$code_changed" -gt 0 ] && [ "$records_with_evidence" -eq 0 ]; then
    evidence_status="missing_evidence"
    if [ "$machine_gate" = "pass" ]; then
      machine_gate="review"
    fi
  fi

  if [ "$(docs_index_tracked)" = "true" ]; then
    machine_gate="blocked"
  fi

  printf 'version: %s\n' "$(version)"
  printf 'flow: %s\n' "$flow"
  printf 'docs_allowed: %s\n' "$docs_allowed"
  printf 'docs_changed: %s\n' "$docs_changed"
  printf 'code_changed: %s\n' "$code_changed"
  printf 'docs_budget_status: %s\n' "$docs_budget_status"
  printf 'requirements_files: %s\n' "$requirements_files"
  printf 'requirements_with_acceptance: %s\n' "$requirements_with_acceptance"
  printf 'requirement_status: %s\n' "$requirement_status"
  printf 'task_files: %s\n' "$task_files"
  printf 'bug_files: %s\n' "$bug_files"
  printf 'acceptance_files: %s\n' "$acceptance_files"
  printf 'records_with_evidence: %s\n' "$records_with_evidence"
  printf 'evidence_status: %s\n' "$evidence_status"
  printf 'docs_index_tracked: %s\n' "$(docs_index_tracked)"
  printf 'machine_gate: %s\n' "$machine_gate"
  printf 'requirement_match: pending-human-review\n'
  printf 'human_review_required: true\n'
  printf 'commit_allowed: false\n'

  [ "$machine_gate" != "blocked" ]
}

case "$cmd" in
  version)
    version
    ;;
  classify)
    classify "$@"
    ;;
  check)
    check
    ;;
  report)
    report "$@"
    ;;
  run)
    run "$@"
    ;;
  verify)
    verify "$@"
    ;;
  *)
    echo "usage: scripts/dev-workflow-harness.sh version|classify|run|report|verify|check [task text]"
    exit 1
    ;;
esac
