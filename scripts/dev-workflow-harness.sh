#!/usr/bin/env bash
set -euo pipefail

harness_version="0.23.0"
cmd="${1:-run}"
shift || true

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_skill_root="$(cd "$script_dir/.." && pwd)"
if [ -f "$script_skill_root/VERSION" ]; then
  default_skill_root="$script_skill_root"
else
  default_skill_root="${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow"
fi
skill_root="${DEV_WORKFLOW_SKILL_ROOT:-$default_skill_root}"
version_file="$skill_root/VERSION"

installed_skill_version() {
  if [ -f "$version_file" ]; then
    cat "$version_file"
  else
    echo "unknown"
  fi
}

version() {
  echo "$harness_version"
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

flow_reason() {
  text="$(printf '%s ' "$@" | tr '[:upper:]' '[:lower:]')"
  reason=""

  append_reason() {
    if [ -z "$reason" ]; then
      reason="$1"
    else
      reason="$reason,$1"
    fi
  }

  if printf '%s\n' "$text" | grep -Eq 'prd|需求|产品文档'; then
    append_reason "strict:prd_or_requirements"
  fi
  if printf '%s\n' "$text" | grep -Eq '改版|重构架构|多模块|高风险|strict'; then
    append_reason "strict:scope_or_risk"
  fi
  if printf '%s\n' "$text" | grep -Eq '接口|api|数据|权限|支付|订单|登录|部署|回滚'; then
    append_reason "strict:critical_surface"
  fi

  if [ -n "$reason" ]; then
    echo "$reason"
    return
  fi

  if printf '%s\n' "$text" | grep -Eq 'bug|修复|根因|追溯'; then
    append_reason "standard:bug_or_trace"
  fi
  if printf '%s\n' "$text" | grep -Eq '功能|用户行为|standard'; then
    append_reason "standard:feature_or_behavior"
  fi

  if [ -n "$reason" ]; then
    echo "$reason"
  else
    echo "quick:default_no_risk_terms"
  fi
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

pre_code_gate_for() {
  case "$1" in
    quick)
      echo "not_required"
      ;;
    standard)
      echo "confirm_TASK_or_BUG_and_test_cases_before_code"
      ;;
    strict)
      echo "confirm_REQ_and_test_cases_before_code"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

pre_code_doc_for() {
  case "$1" in
    quick)
      echo "none"
      ;;
    standard)
      echo "TASK_or_BUG"
      ;;
    strict)
      echo "REQ"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

code_allowed_for() {
  case "$1" in
    quick)
      echo "true"
      ;;
    standard|strict)
      echo "false"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

max_iterations_for() {
  case "$1" in
    quick)
      echo "1"
      ;;
    standard)
      echo "3"
      ;;
    strict)
      echo "5"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

initial_loop_phase_for() {
  case "$1" in
    quick)
      echo "implement"
      ;;
    standard)
      echo "pre_code_doc"
      ;;
    strict)
      echo "slice"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

slice_strategy_for() {
  case "$1" in
    quick)
      echo "none"
      ;;
    standard)
      echo "adaptive_if_scope_expands"
      ;;
    strict)
      echo "adaptive_required"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

stop_condition_for() {
  case "$1" in
    quick)
      echo "targeted_verification_complete_or_blocked"
      ;;
    standard)
      echo "confirmed_doc_then_targeted_verification_complete_or_blocked"
      ;;
    strict)
      echo "confirmed_slices_and_REQ_then_each_slice_verified_or_blocked"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

initial_loop_decision_for() {
  case "$1" in
    quick)
      echo "continue"
      ;;
    standard|strict)
      echo "wait_human"
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

script_version_from_file() {
  file="$1"
  if [ ! -f "$file" ]; then
    echo "missing"
    return
  fi

  found="$(sed -n 's/^harness_version="\([^"]*\)".*/\1/p' "$file" | head -n 1)"
  if [ -n "$found" ]; then
    echo "$found"
  else
    echo "legacy"
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

confirmed_pre_code_count() {
  flow="$1"
  regex='编码前确认[^：:]{0,12}[：:][[:space:]]*已确认|pre_code_confirmed[：:][[:space:]]*true'

  case "$flow" in
    quick)
      echo "0"
      ;;
    standard)
      {
        count_matching_files docs/tasks 'TASK-*.md' "$regex";
        count_matching_files docs/bugs 'BUG-*.md' "$regex";
      } | awk '{sum += $1} END {print sum + 0}'
      ;;
    strict)
      count_matching_files docs/requirements 'REQ-*.md' "$regex"
      ;;
    *)
      echo "0"
      ;;
  esac
}

test_case_confirmed_count() {
  flow="$1"
  regex='测试用例确认[^：:]{0,12}[：:][[:space:]]*已确认|test_cases_confirmed[：:][[:space:]]*true'

  case "$flow" in
    quick)
      echo "0"
      ;;
    standard)
      {
        count_matching_files docs/tasks 'TASK-*.md' "$regex";
        count_matching_files docs/bugs 'BUG-*.md' "$regex";
      } | awk '{sum += $1} END {print sum + 0}'
      ;;
    strict)
      count_matching_files docs/requirements 'REQ-*.md' "$regex"
      ;;
    *)
      echo "0"
      ;;
  esac
}

count_test_case_quality_files() {
  dir="$1"
  pattern="$2"
  marker='测试用例确认[^：:]{0,12}[：:][[:space:]]*已确认|test_cases_confirmed[：:][[:space:]]*true'

  if [ ! -d "$dir" ]; then
    echo "0"
    return
  fi

  {
    while IFS= read -r file; do
      if grep -Eq "$marker" "$file" \
        && grep -Eq '关联[[:space:]]*(REQ|BUG|需求)|REQ[[:space:]]*/[[:space:]]*BUG' "$file" \
        && grep -Eq '前置状态' "$file" \
        && grep -Eq '用户操作|操作|触发' "$file" \
        && grep -Eq '期望结果' "$file" \
        && grep -Eq '真实验证路径|真实验证计划|最终验收来源|真实接口|真实后端|真实环境|本地联调|人工实测' "$file" \
        && grep -Eq 'RED[[:space:]]*失败|先失败记录|预期先失败' "$file"; then
        printf '%s\n' "$file"
      fi
    done < <(find "$dir" -type f -name "$pattern" 2>/dev/null)
  } | wc -l | tr -d ' '
}

test_case_quality_count() {
  flow="$1"

  case "$flow" in
    quick)
      echo "0"
      ;;
    standard)
      {
        count_test_case_quality_files docs/tasks 'TASK-*.md';
        count_test_case_quality_files docs/bugs 'BUG-*.md';
      } | awk '{sum += $1} END {print sum + 0}'
      ;;
    strict)
      count_test_case_quality_files docs/requirements 'REQ-*.md'
      ;;
    *)
      echo "0"
      ;;
  esac
}

count_matching_records() {
  regex="$1"
  {
    count_matching_files docs/requirements 'REQ-*.md' "$regex"
    count_matching_files docs/tasks 'TASK-*.md' "$regex"
    count_matching_files docs/bugs 'BUG-*.md' "$regex"
    count_matching_files docs/acceptance 'ACC-*.md' "$regex"
  } | awk '{sum += $1} END {print sum + 0}'
}

real_final_evidence_count() {
  regex='(最终验收来源|验证方式|验证方法|验证结果|最终验收证据|证据|验收结论)[[:space:]]*[：:].*(真实接口|真实后端|真实环境|测试环境|本地联调|联调通过|人工实测|手工实测|真实数据|非 mock|non-mock|staging|dev api|real API|real backend)'
  count_matching_records "$regex"
}

mock_final_evidence_count() {
  regex='(最终验收来源|验证方式|验证方法|验证结果|最终验收证据|证据|验收结论|辅助模拟记录)[[:space:]]*[：:].*(mock|Playwright[[:space:]-]*route|route[[:space:]-]*mock|mock 数据|mock数据|MSW|fixture|stub|fake data|接口拦截|拦截接口|模拟接口|模拟数据)'
  count_matching_records "$regex"
}

check() {
  if [ -x "$skill_root/scripts/check-dev-docs.sh" ]; then
    "$skill_root/scripts/check-dev-docs.sh" >/dev/null
  elif [ -x "$script_dir/check-dev-docs.sh" ]; then
    "$script_dir/check-dev-docs.sh" >/dev/null
  elif [ -x "scripts/check-dev-docs.sh" ]; then
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
  pre_code_gate="$(pre_code_gate_for "$flow")"

  printf 'version: %s\n' "$(version)"
  printf 'installed_skill_version: %s\n' "$(installed_skill_version)"
  printf 'flow: %s\n' "$flow"
  printf 'flow_reason: %s\n' "$(flow_reason "$@")"
  printf 'docs_allowed: %s\n' "$docs_allowed"
  printf 'pre_code_gate: %s\n' "$pre_code_gate"
  printf 'pre_code_doc: %s\n' "$(pre_code_doc_for "$flow")"
  printf 'pre_code_confirmation_marker: %s\n' '编码前确认：已确认'
  printf 'test_case_confirmation_marker: %s\n' '测试用例确认：已确认'
  printf 'code_allowed: %s\n' "$(code_allowed_for "$flow")"
  printf 'loop_phase: %s\n' "$(initial_loop_phase_for "$flow")"
  printf 'loop_next_decision: %s\n' "$(initial_loop_decision_for "$flow")"
  printf 'max_iterations: %s\n' "$(max_iterations_for "$flow")"
  printf 'stop_condition: %s\n' "$(stop_condition_for "$flow")"
  printf 'slice_strategy: %s\n' "$(slice_strategy_for "$flow")"
  printf 'slice_inputs: %s\n' 'requirement_structure,code_boundaries,risk_points,testability'
  printf 'test_case_policy: %s\n' 'requirement_behavior_first_confirm_before_code'
  printf 'test_case_required_fields: %s\n' 'REQ_or_BUG,scenario,precondition,action,expected_result,test_type,real_verification_path,mock_policy,red_failure'
  printf 'verification_policy: %s\n' 'real_final_evidence_required'
  printf 'mock_policy: %s\n' 'development_or_supplement_only_never_final'
  printf 'final_evidence_required: %s\n' 'real_backend_or_real_api_or_real_runtime_or_human_manual_verification'
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
      printf 'next_action: draft_TASK_or_BUG_with_test_cases_then_wait_for_human_confirmation\n'
      ;;
    strict)
      printf 'next_action: draft_REQ_with_test_matrix_then_wait_for_human_confirmation\n'
      ;;
  esac
  printf 'verify_command: %s/scripts/dev-workflow-harness.sh verify "%s"\n' "$skill_root" "$*"
  printf 'check_command: %s/scripts/dev-workflow-harness.sh check\n' "$skill_root"
}

doctor() {
  project_harness_file="scripts/dev-workflow-harness.sh"
  project_harness_version="$(script_version_from_file "$project_harness_file")"
  installed_version="$(installed_skill_version)"
  upgrade_needed="false"
  missing_required=""
  project_scripts_present="false"

  add_missing() {
    if [ -z "$missing_required" ]; then
      missing_required="$1"
    else
      missing_required="$missing_required,$1"
    fi
  }

  [ -f "AGENTS.md" ] || add_missing "AGENTS.md"
  [ -d "docs" ] || add_missing "docs/"
  [ -f "docs/workflow.md" ] || add_missing "docs/workflow.md"

  project_script_probe="$(find scripts -maxdepth 1 -type f \( -name 'dev-workflow-harness.sh' -o -name 'search-dev-docs.sh' -o -name 'reindex-dev-docs.sh' -o -name 'new-doc.sh' -o -name 'new-doc-id.sh' -o -name 'check-dev-docs.sh' -o -name 'check-dev-workflow.sh' -o -name 'clean-templates.sh' -o -name 'clean-project-scripts.sh' -o -name 'session-state.sh' -o -name 'init-dev-workflow.sh' \) -print -quit 2>/dev/null || true)"
  if [ -n "$project_script_probe" ]; then
    project_scripts_present="true"
  fi

  if [ "$project_harness_version" != "missing" ] && [ "$project_harness_version" != "$installed_version" ]; then
    upgrade_needed="true"
  fi

  hooks_path="none"
  hooks_enabled="false"
  if git rev-parse --git-dir >/dev/null 2>&1; then
    hooks_path="$(git config --get core.hooksPath || true)"
    [ -n "$hooks_path" ] || hooks_path="none"
    if [ "$hooks_path" = ".githooks" ]; then
      hooks_enabled="true"
    fi
  fi

  if [ -f ".dev-workflow/index/docs.jsonl" ]; then
    local_index="present"
  else
    local_index="missing"
  fi

  doctor_status="ok"
  next_action="none"
  if [ -n "$missing_required" ]; then
    doctor_status="needs_init"
    next_action="/dev-workflow init"
  elif [ "$upgrade_needed" = "true" ]; then
    doctor_status="project_scripts_legacy"
    next_action="/dev-workflow clean-scripts 或 /dev-workflow init --with-scripts"
  elif [ "$(docs_index_tracked)" = "true" ]; then
    doctor_status="blocked"
    next_action="git rm --cached docs/index.md"
  elif [ "$local_index" = "missing" ]; then
    doctor_status="review"
    next_action="/dev-workflow check"
  fi

  [ -n "$missing_required" ] || missing_required="none"

  printf 'version: %s\n' "$(version)"
  printf 'installed_skill_version: %s\n' "$installed_version"
  printf 'project_harness_version: %s\n' "$project_harness_version"
  printf 'project_harness_file: %s\n' "$project_harness_file"
  printf 'project_scripts_present: %s\n' "$project_scripts_present"
  printf 'using_skill_scripts: true\n'
  printf 'upgrade_needed: %s\n' "$upgrade_needed"
  printf 'missing_required: %s\n' "$missing_required"
  printf 'docs_index_tracked: %s\n' "$(docs_index_tracked)"
  printf 'local_index: %s\n' "$local_index"
  printf 'hooks_path: %s\n' "$hooks_path"
  printf 'hooks_enabled: %s\n' "$hooks_enabled"
  printf 'doctor_status: %s\n' "$doctor_status"
  printf 'next_action: %s\n' "$next_action"
}

verify() {
  flow="$(classify "$@")"
  docs_allowed="$(docs_allowed_for "$flow")"
  docs_changed="$(docs_changed_count)"
  code_changed="$(changed_code_count)"
  requirements_files="$(count_files docs/requirements 'REQ-*.md')"
  task_files="$(count_files docs/tasks 'TASK-*.md')"
  bug_files="$(count_files docs/bugs 'BUG-*.md')"
  task_or_bug_files="$((task_files + bug_files))"
  acceptance_files="$(count_files docs/acceptance 'ACC-*.md')"
  pre_code_confirmed="$(confirmed_pre_code_count "$flow")"
  test_case_confirmed="$(test_case_confirmed_count "$flow")"
  test_case_quality_records="$(test_case_quality_count "$flow")"
  requirements_with_acceptance="$(count_matching_files docs/requirements 'REQ-*.md' '验收方式|手工验收|可自动化测试|测试状态')"
  records_with_evidence="$(
    {
      count_matching_files docs/tasks 'TASK-*.md' '验证方式|验证结果|验收结论|测试';
      count_matching_files docs/bugs 'BUG-*.md' '验证结果|验证|复现步骤|根因';
      count_matching_files docs/acceptance 'ACC-*.md' '验收标准|验证记录|结论';
    } | awk '{sum += $1} END {print sum + 0}'
  )"
  real_final_evidence="$(real_final_evidence_count)"
  mock_final_evidence="$(mock_final_evidence_count)"
  docs_budget_status="ok"
  pre_code_status="ok"
  requirement_status="ok"
  evidence_status="ok"
  verification_source_status="ok"
  test_case_status="ok"
  machine_gate="pass"

  if [ "$flow" = "quick" ] && [ "$code_changed" -gt 0 ] && [ "$docs_changed" -gt 0 ]; then
    docs_budget_status="over_budget"
    machine_gate="review"
  fi

  if [ "$flow" = "standard" ] && [ "$code_changed" -gt 0 ] && [ "$docs_changed" -gt 1 ]; then
    docs_budget_status="over_budget"
    machine_gate="review"
  fi

  if [ "$flow" = "standard" ] && [ "$code_changed" -gt 0 ] && [ "$task_or_bug_files" -eq 0 ]; then
    pre_code_status="missing_TASK_or_BUG"
    machine_gate="blocked"
  fi

  if [ "$flow" = "standard" ] && [ "$code_changed" -gt 0 ] && [ "$task_or_bug_files" -gt 0 ] && [ "$pre_code_confirmed" -eq 0 ]; then
    pre_code_status="missing_pre_code_confirmation"
    machine_gate="blocked"
  fi

  if [ "$flow" = "standard" ] && [ "$code_changed" -gt 0 ] && [ "$task_or_bug_files" -gt 0 ] && [ "$test_case_confirmed" -eq 0 ]; then
    test_case_status="missing_test_case_confirmation"
    machine_gate="blocked"
  fi

  if [ "$flow" = "standard" ] && [ "$code_changed" -gt 0 ] && [ "$test_case_confirmed" -gt 0 ] && [ "$test_case_quality_records" -eq 0 ]; then
    test_case_status="missing_test_case_quality_fields"
    machine_gate="blocked"
  fi

  if [ "$flow" = "strict" ] && [ "$requirements_files" -eq 0 ]; then
    requirement_status="missing_REQ"
    pre_code_status="missing_REQ"
    machine_gate="blocked"
  fi

  if [ "$flow" = "strict" ] && [ "$requirements_files" -gt 0 ] && [ "$requirements_with_acceptance" -lt "$requirements_files" ]; then
    requirement_status="missing_acceptance"
    machine_gate="blocked"
  fi

  if [ "$flow" = "strict" ] && [ "$code_changed" -gt 0 ] && [ "$requirements_files" -gt 0 ] && [ "$pre_code_confirmed" -eq 0 ]; then
    pre_code_status="missing_pre_code_confirmation"
    machine_gate="blocked"
  fi

  if [ "$flow" = "strict" ] && [ "$code_changed" -gt 0 ] && [ "$requirements_files" -gt 0 ] && [ "$test_case_confirmed" -eq 0 ]; then
    test_case_status="missing_test_case_confirmation"
    machine_gate="blocked"
  fi

  if [ "$flow" = "strict" ] && [ "$code_changed" -gt 0 ] && [ "$test_case_confirmed" -gt 0 ] && [ "$test_case_quality_records" -eq 0 ]; then
    test_case_status="missing_test_case_quality_fields"
    machine_gate="blocked"
  fi

  if [ "$flow" != "quick" ] && [ "$code_changed" -gt 0 ] && [ "$records_with_evidence" -eq 0 ]; then
    evidence_status="missing_evidence"
    if [ "$machine_gate" = "pass" ]; then
      machine_gate="review"
    fi
  fi

  if [ "$code_changed" -gt 0 ] && [ "$mock_final_evidence" -gt 0 ] && [ "$real_final_evidence" -eq 0 ]; then
    verification_source_status="mock_only_final_evidence"
    evidence_status="mock_only_final_evidence"
    machine_gate="blocked"
  fi

  if [ "$(docs_index_tracked)" = "true" ]; then
    machine_gate="blocked"
  fi

  loop_phase="$(initial_loop_phase_for "$flow")"
  loop_next_decision="$(initial_loop_decision_for "$flow")"
  if [ "$machine_gate" = "blocked" ]; then
    loop_next_decision="stop"
    if [ "$pre_code_status" != "ok" ] || [ "$requirement_status" != "ok" ] || [ "$test_case_status" != "ok" ]; then
      loop_phase="pre_code_doc"
    else
      loop_phase="verify"
    fi
  elif [ "$machine_gate" = "review" ]; then
    loop_next_decision="wait_human"
    if [ "$evidence_status" != "ok" ]; then
      loop_phase="verify"
    else
      loop_phase="human_gate"
    fi
  else
    loop_phase="human_gate"
    loop_next_decision="wait_human"
  fi

  printf 'version: %s\n' "$(version)"
  printf 'installed_skill_version: %s\n' "$(installed_skill_version)"
  printf 'flow: %s\n' "$flow"
  printf 'flow_reason: %s\n' "$(flow_reason "$@")"
  printf 'docs_allowed: %s\n' "$docs_allowed"
  printf 'pre_code_gate: %s\n' "$(pre_code_gate_for "$flow")"
  printf 'pre_code_doc: %s\n' "$(pre_code_doc_for "$flow")"
  printf 'pre_code_confirmation_marker: %s\n' '编码前确认：已确认'
  printf 'pre_code_confirmed_records: %s\n' "$pre_code_confirmed"
  printf 'pre_code_status: %s\n' "$pre_code_status"
  printf 'test_case_confirmation_marker: %s\n' '测试用例确认：已确认'
  printf 'test_case_confirmed_records: %s\n' "$test_case_confirmed"
  printf 'test_case_quality_records: %s\n' "$test_case_quality_records"
  printf 'test_case_status: %s\n' "$test_case_status"
  printf 'loop_phase: %s\n' "$loop_phase"
  printf 'loop_next_decision: %s\n' "$loop_next_decision"
  printf 'max_iterations: %s\n' "$(max_iterations_for "$flow")"
  printf 'stop_condition: %s\n' "$(stop_condition_for "$flow")"
  printf 'slice_strategy: %s\n' "$(slice_strategy_for "$flow")"
  printf 'test_case_policy: %s\n' 'requirement_behavior_first_confirm_before_code'
  printf 'test_case_required_fields: %s\n' 'REQ_or_BUG,scenario,precondition,action,expected_result,test_type,real_verification_path,mock_policy,red_failure'
  printf 'verification_policy: %s\n' 'real_final_evidence_required'
  printf 'mock_policy: %s\n' 'development_or_supplement_only_never_final'
  printf 'final_evidence_required: %s\n' 'real_backend_or_real_api_or_real_runtime_or_human_manual_verification'
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
  printf 'real_final_evidence_records: %s\n' "$real_final_evidence"
  printf 'mock_final_evidence_records: %s\n' "$mock_final_evidence"
  printf 'verification_source_status: %s\n' "$verification_source_status"
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
  doctor)
    doctor
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
    echo "usage: scripts/dev-workflow-harness.sh version|classify|doctor|run|report|verify|check [task text]"
    exit 1
    ;;
esac
