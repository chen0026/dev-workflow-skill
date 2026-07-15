#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-help}"
shift || true

usage() {
  cat <<'EOF'
usage:
  commit-scope.sh prepare TASK_KEY --all
  commit-scope.sh prepare TASK_KEY -- FILE [FILE...] [--other FILE...]
  commit-scope.sh show
  commit-scope.sh stage
  commit-scope.sh check
  commit-scope.sh verify-head
  commit-scope.sh clear

独立 worktree 可用 --all；共享工作区必须把每个变更文件归类为本任务或 --other。
prepare 在人工审核前记录分类结果，不执行暂存。
人工明确批准提交后才运行 stage；提交后立即运行 verify-head。
EOF
}

fail() {
  echo "dev-workflow: $1" >&2
  exit 1
}

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || fail "当前目录不是 Git 仓库"
cd "$repo_root"

manifest=".dev-workflow/commit-manifest.txt"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

require_manifest() {
  [ -f "$manifest" ] || fail "缺少提交清单；先运行 commit-scope.sh prepare"
}

require_local_state_ignored() {
  git check-ignore -q --no-index "$manifest" \
    || fail ".dev-workflow/ 未被忽略；请先运行 /dev-workflow init"
}

manifest_task() {
  sed -n 's/^# task=//p' "$manifest" | head -n 1
}

manifest_base_head() {
  sed -n 's/^# base_head=//p' "$manifest" | head -n 1
}

current_head() {
  git rev-parse --verify HEAD 2>/dev/null || echo "NONE"
}

write_manifest_paths() {
  awk '
    substr($0, 1, 2) == "S\t" { print substr($0, 3); next }
    substr($0, 1, 2) == "O\t" { next }
    $0 !~ /^#/ && $0 !~ /^[[:space:]]*$/ { print }
  ' "$manifest" | LC_ALL=C sort -u
}

write_manifest_other_paths() {
  awk '
    substr($0, 1, 2) == "O\t" { print substr($0, 3); next }
    /^# other=/ { sub(/^# other=/, ""); print }
  ' "$manifest" | LC_ALL=C sort -u
}

normalize_path() {
  path="$1"
  while [[ "$path" == ./* ]]; do
    path="${path#./}"
  done

  case "$path" in
    ""|/*|..|../*|*/..|*/../*) fail "文件路径必须是仓库根目录下的普通相对路径：$1" ;;
  esac
  case "$path" in
    *$'\n'*) fail "文件路径不能包含换行：$1" ;;
  esac
  [ ! -d "$path" ] || fail "提交清单必须列出文件，不能列目录：$path"
  printf '%s\n' "$path"
}

write_staged_paths() {
  while IFS= read -r -d '' path; do
    printf '%s\n' "$path"
  done < <(git diff --cached --name-only --no-renames --diff-filter=ACMRTD -z)
}

write_head_paths() {
  git rev-parse --verify HEAD >/dev/null 2>&1 || fail "仓库还没有可核验的 HEAD 提交"
  while IFS= read -r -d '' path; do
    printf '%s\n' "$path"
  done < <(git diff-tree --root --no-commit-id --name-only --no-renames -r -z HEAD)
}

write_unstaged_paths() {
  while IFS= read -r -d '' path; do
    printf '%s\n' "$path"
  done < <(git diff --name-only --no-renames --diff-filter=ACMRTD -z)
}

write_workspace_paths() {
  write_staged_paths
  write_unstaged_paths
  while IFS= read -r -d '' path; do
    printf '%s\n' "$path"
  done < <(git ls-files --others --exclude-standard -z)
}

report_other_workspace_changes() {
  other="$tmp_dir/reported-other"
  write_manifest_other_paths > "$other"
  if [ -s "$other" ]; then
    echo "dev-workflow: other_workspace_changes（已明确归为其他任务，保持未暂存）："
    sed 's/^/  /' "$other"
  else
    echo "dev-workflow: other_workspace_changes: none"
  fi
}

validate_classification_files() {
  scope_file="$1"
  other_file="$2"
  workspace="$tmp_dir/classification-workspace"
  classified="$tmp_dir/classification-all"
  overlap="$tmp_dir/classification-overlap"
  unclassified="$tmp_dir/classification-unclassified"
  stale="$tmp_dir/classification-stale"
  staged="$tmp_dir/classification-staged"
  other_staged="$tmp_dir/classification-other-staged"

  write_workspace_paths | LC_ALL=C sort -u > "$workspace"
  {
    cat "$scope_file"
    cat "$other_file"
  } | LC_ALL=C sort -u > "$classified"
  comm -12 "$scope_file" "$other_file" > "$overlap"
  comm -23 "$workspace" "$classified" > "$unclassified"
  comm -13 "$workspace" "$classified" > "$stale"
  write_staged_paths | LC_ALL=C sort -u > "$staged"
  comm -12 "$other_file" "$staged" > "$other_staged"

  failed="0"
  if [ -s "$overlap" ]; then
    echo "dev-workflow: classification_overlap（文件不能同时属于本任务和其他任务）：" >&2
    sed 's/^/  /' "$overlap" >&2
    failed="1"
  fi
  if [ -s "$unclassified" ]; then
    echo "dev-workflow: unclassified_workspace_changes（以下文件尚未归类，禁止提交）：" >&2
    sed 's/^/  /' "$unclassified" >&2
    failed="1"
  fi
  if [ -s "$stale" ]; then
    echo "dev-workflow: stale_classification（已归类但当前没有变更）：" >&2
    sed 's/^/  /' "$stale" >&2
    failed="1"
  fi
  if [ -s "$other_staged" ]; then
    echo "dev-workflow: other_task_staged（其他任务文件必须先取消暂存）：" >&2
    sed 's/^/  /' "$other_staged" >&2
    failed="1"
  fi
  [ "$failed" = "0" ]
}

check_workspace_classification() {
  scope_file="$tmp_dir/manifest-scope"
  other_file="$tmp_dir/manifest-other"
  write_manifest_paths > "$scope_file"
  write_manifest_other_paths > "$other_file"
  validate_classification_files "$scope_file" "$other_file"
}

check_remaining_other_classification() {
  other="$tmp_dir/remaining-other"
  workspace="$tmp_dir/remaining-workspace"
  unclassified="$tmp_dir/remaining-unclassified"
  stale="$tmp_dir/remaining-stale"
  staged="$tmp_dir/remaining-staged"
  other_staged="$tmp_dir/remaining-other-staged"
  write_manifest_other_paths > "$other"
  write_workspace_paths | LC_ALL=C sort -u > "$workspace"
  comm -23 "$workspace" "$other" > "$unclassified"
  comm -13 "$workspace" "$other" > "$stale"
  write_staged_paths | LC_ALL=C sort -u > "$staged"
  comm -12 "$other" "$staged" > "$other_staged"

  failed="0"
  if [ -s "$unclassified" ]; then
    echo "dev-workflow: post_commit_unclassified_changes（提交后出现未归类文件）：" >&2
    sed 's/^/  /' "$unclassified" >&2
    failed="1"
  fi
  if [ -s "$stale" ]; then
    echo "dev-workflow: post_commit_other_changed（其他任务文件状态已变化）：" >&2
    sed 's/^/  /' "$stale" >&2
    failed="1"
  fi
  if [ -s "$other_staged" ]; then
    echo "dev-workflow: post_commit_other_staged（其他任务文件仍在暂存区）：" >&2
    sed 's/^/  /' "$other_staged" >&2
    failed="1"
  fi
  [ "$failed" = "0" ]
}

check_expected_fully_staged() {
  expected="$tmp_dir/expected"
  unstaged="$tmp_dir/unstaged"
  missed="$tmp_dir/unstaged-expected"
  write_manifest_paths > "$expected"
  write_unstaged_paths | LC_ALL=C sort -u > "$unstaged"
  comm -12 "$expected" "$unstaged" > "$missed"

  if [ -s "$missed" ]; then
    echo "dev-workflow: current_task_unstaged（暂存后又发生变更）：" >&2
    sed 's/^/  /' "$missed" >&2
    return 1
  fi
}

check_expected_clean_after_commit() {
  expected="$tmp_dir/expected"
  workspace="$tmp_dir/workspace"
  changed="$tmp_dir/post-commit-expected"
  write_manifest_paths > "$expected"
  write_workspace_paths | LC_ALL=C sort -u > "$workspace"
  comm -12 "$expected" "$workspace" > "$changed"

  if [ -s "$changed" ]; then
    echo "dev-workflow: current_task_post_commit_changes（提交后仍有清单文件变更）：" >&2
    sed 's/^/  /' "$changed" >&2
    return 1
  fi
}

verify_head_transition() {
  base_head="$(manifest_base_head)"
  [ -n "$base_head" ] || fail "提交清单缺少 base_head；请重新 prepare"
  head="$(current_head)"
  [ "$head" != "NONE" ] || fail "尚未产生可核验的提交"
  [ "$head" != "$base_head" ] || fail "HEAD 没有变化；请先完成当前任务提交"

  parent_line="$(git rev-list --parents -n 1 "$head")"
  set -- $parent_line
  if [ "$base_head" = "NONE" ]; then
    [ "$#" -eq 1 ] || fail "当前 HEAD 不是清单之后的首个提交"
  else
    [ "$#" -eq 2 ] && [ "$2" = "$base_head" ] \
      || fail "当前 HEAD 不是基于清单 base_head 的单一新提交"
  fi
}

compare_scope() {
  actual_writer="$1"
  actual_label="$2"
  expected="$tmp_dir/expected"
  actual="$tmp_dir/actual"
  missing="$tmp_dir/missing"
  extra="$tmp_dir/extra"

  write_manifest_paths > "$expected"
  "$actual_writer" | LC_ALL=C sort -u > "$actual"
  comm -23 "$expected" "$actual" > "$missing"
  comm -13 "$expected" "$actual" > "$extra"

  failed="0"
  if [ -s "$missing" ]; then
    echo "dev-workflow: current_task_missed（清单中存在但${actual_label}缺少）：" >&2
    sed 's/^/  /' "$missing" >&2
    failed="1"
  fi
  if [ -s "$extra" ]; then
    echo "dev-workflow: out_of_scope_${actual_label}（不在当前任务清单）：" >&2
    sed 's/^/  /' "$extra" >&2
    failed="1"
  fi
  [ "$failed" = "0" ]
}

prepare_scope() {
  require_local_state_ignored
  task_key="${1:-}"
  [ -n "$task_key" ] || fail "prepare 需要 TASK_KEY"
  case "$task_key" in
    *$'\n'*) fail "TASK_KEY 不能包含换行" ;;
  esac
  shift

  if [ -f "$manifest" ]; then
    existing_task="$(manifest_task)"
    [ "$existing_task" = "$task_key" ] || fail "已有其他任务提交清单：$existing_task；先完成或 clear"
  fi

  paths="$tmp_dir/prepare-scope"
  other_paths="$tmp_dir/prepare-other"
  : > "$paths"
  : > "$other_paths"

  if [ "${1:-}" = "--all" ]; then
    shift
    [ "$#" -eq 0 ] || fail "--all 后不能再指定文件"
    write_workspace_paths | LC_ALL=C sort -u > "$paths"
  else
    [ "${1:-}" = "--" ] || fail "TASK_KEY 后必须使用 --all，或使用 -- 分隔文件"
    shift
    [ "$#" -gt 0 ] || fail "prepare 至少需要一个本任务文件"
    mode="scope"
    for input_path in "$@"; do
      if [ "$input_path" = "--other" ]; then
        mode="other"
        continue
      fi
      path="$(normalize_path "$input_path")"
      if [ "$mode" = "scope" ]; then
        printf '%s\n' "$path" >> "$paths"
      else
        printf '%s\n' "$path" >> "$other_paths"
      fi
    done
    LC_ALL=C sort -u "$paths" -o "$paths"
    LC_ALL=C sort -u "$other_paths" -o "$other_paths"
  fi

  [ -s "$paths" ] || fail "提交清单至少需要一个本任务文件"
  validate_classification_files "$paths" "$other_paths"

  mkdir -p "$(dirname "$manifest")"
  draft="$tmp_dir/manifest"
  {
    printf '# task=%s\n' "$task_key"
    printf '# created_at=%s\n' "$(date +%Y-%m-%dT%H:%M:%S%z)"
    printf '# base_head=%s\n' "$(current_head)"
    while IFS= read -r path; do
      printf 'O\t%s\n' "$path"
    done < "$other_paths"
    while IFS= read -r path; do
      printf 'S\t%s\n' "$path"
    done < "$paths"
  } > "$draft"
  mv "$draft" "$manifest"

  echo "dev-workflow: 已准备提交清单（尚未暂存）：$task_key"
  sed 's/^/  /' "$paths"
  report_other_workspace_changes
}

show_scope() {
  require_manifest
  printf 'task: %s\n' "$(manifest_task)"
  echo "files:"
  write_manifest_paths | sed 's/^/  /'
  echo "other_files:"
  if [ -n "$(write_manifest_other_paths)" ]; then
    write_manifest_other_paths | sed 's/^/  /'
  else
    echo "  none"
  fi
}

check_scope() {
  require_manifest
  check_workspace_classification
  compare_scope write_staged_paths "staged"
  check_expected_fully_staged
  echo "dev-workflow: 当前任务暂存范围与提交清单一致"
  report_other_workspace_changes
}

stage_scope() {
  require_manifest
  check_workspace_classification
  while IFS= read -r path; do
    if [ -e "$path" ] || [ -L "$path" ] || git ls-files --error-unmatch -- "$path" >/dev/null 2>&1; then
      git add -A -- "$path"
    elif write_staged_paths | grep -Fxq -- "$path"; then
      :
    else
      fail "无法暂存清单路径：$path"
    fi
  done < <(write_manifest_paths)
  check_scope
}

verify_head_scope() {
  require_manifest
  verify_head_transition
  compare_scope write_head_paths "HEAD"
  check_expected_clean_after_commit
  check_remaining_other_classification
  echo "dev-workflow: HEAD 提交范围与当前任务清单一致"
  report_other_workspace_changes
  rm -f "$manifest"
  echo "dev-workflow: 已清理提交清单"
}

clear_scope() {
  rm -f "$manifest"
  echo "dev-workflow: 已清理提交清单"
}

case "$cmd" in
  prepare)
    prepare_scope "$@"
    ;;
  show)
    show_scope
    ;;
  stage)
    stage_scope
    ;;
  check)
    check_scope
    ;;
  verify-head)
    verify_head_scope
    ;;
  clear)
    clear_scope
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac
