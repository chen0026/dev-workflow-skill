#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-report}"
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
  case "$flow" in
    quick)
      docs_allowed="0"
      ;;
    standard)
      docs_allowed="1"
      ;;
    strict)
      docs_allowed="full"
      ;;
  esac

  printf 'version: %s\n' "$(version)"
  printf 'flow: %s\n' "$flow"
  printf 'docs_allowed: %s\n' "$docs_allowed"
  printf 'docs_changed: %s\n' "$(docs_changed_count)"
  printf 'docs_index_tracked: %s\n' "$(docs_index_tracked)"
  printf 'human_review_required: true\n'
  printf 'commit_allowed: false\n'
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
  *)
    echo "usage: scripts/dev-workflow-harness.sh version|classify|check|report [task text]"
    exit 1
    ;;
esac
