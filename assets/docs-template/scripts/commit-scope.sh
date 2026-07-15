#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-help}"
shift || true

usage() {
  cat <<'EOF'
usage:
  commit-scope.sh track TASK_KEY -- FILE [FILE...]
  commit-scope.sh prepare TASK_KEY --all
  commit-scope.sh prepare TASK_KEY -- FILE [FILE...]
  commit-scope.sh show [TASK_KEY]
  commit-scope.sh list
  commit-scope.sh stage [TASK_KEY]
  commit-scope.sh check [TASK_KEY]
  commit-scope.sh commit TASK_KEY GIT_COMMIT_ARGS...
  commit-scope.sh verify-head [TASK_KEY]
  commit-scope.sh clear [TASK_KEY]

每个任务使用 .dev-workflow/commits/TASK_KEY.txt 独立清单。
Agent 在修改文件前用 track 增量记录本线程文件；用户无须管理清单。
commit 使用 git commit --only 精确提交，保留其他线程状态。
只有不同任务清单包含同一文件时才阻断。TASK_KEY 仅允许字母、数字、点、下划线和短横线。
EOF
}

fail() {
  echo "dev-workflow: $1" >&2
  exit 1
}

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || fail "当前目录不是 Git 仓库"
cd "$repo_root"

manifest_dir=".dev-workflow/commits"
legacy_manifest=".dev-workflow/commit-manifest.txt"
manifest=""
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

validate_task_key() {
  task_key="$1"
  case "$task_key" in
    ""|*[!A-Za-z0-9._-]*) fail "TASK_KEY 仅允许字母、数字、点、下划线和短横线：$task_key" ;;
  esac
}

manifest_path_for_task() {
  validate_task_key "$1"
  printf '%s/%s.txt\n' "$manifest_dir" "$1"
}

manifest_task_from_file() {
  sed -n 's/^# task=//p' "$1" | head -n 1
}

list_manifest_files() {
  if [ -f "$legacy_manifest" ]; then
    printf '%s\n' "$legacy_manifest"
  fi
  if [ -d "$manifest_dir" ]; then
    find "$manifest_dir" -maxdepth 1 -type f -name '*.txt' -print | LC_ALL=C sort
  fi
}

select_manifest() {
  requested_task="${1:-}"
  if [ -n "${DEV_WORKFLOW_MANIFEST:-}" ]; then
    manifest="$DEV_WORKFLOW_MANIFEST"
  elif [ -n "$requested_task" ]; then
    manifest="$(manifest_path_for_task "$requested_task")"
    if [ ! -f "$manifest" ] && [ -f "$legacy_manifest" ] \
      && [ "$(manifest_task_from_file "$legacy_manifest")" = "$requested_task" ]; then
      manifest="$legacy_manifest"
    fi
  else
    manifests="$tmp_dir/manifests"
    list_manifest_files > "$manifests"
    count="$(awk 'NF {count++} END {print count+0}' "$manifests")"
    [ "$count" -gt 0 ] || fail "缺少提交清单；先运行 commit-scope.sh prepare"
    [ "$count" -eq 1 ] || fail "存在多个任务提交清单；请指定 TASK_KEY"
    manifest="$(sed -n '1p' "$manifests")"
  fi
  [ -f "$manifest" ] || fail "找不到提交清单：$manifest"
}

require_local_state_ignored() {
  candidate="${manifest:-$manifest_dir/probe.txt}"
  git check-ignore -q --no-index "$candidate" \
    || fail ".dev-workflow/ 未被忽略；请先运行 /dev-workflow init"
}

manifest_task() {
  manifest_task_from_file "$manifest"
}

manifest_base_head() {
  sed -n 's/^# base_head=//p' "$manifest" | head -n 1
}

refresh_manifest_base_head() {
  refreshed="$tmp_dir/refreshed-manifest"
  awk -v head="$(current_head)" '
    /^# base_head=/ { print "# base_head=" head; next }
    { print }
  ' "$manifest" > "$refreshed"
  mv "$refreshed" "$manifest"
}

current_head() {
  git rev-parse --verify HEAD 2>/dev/null || echo "NONE"
}

write_paths_from_manifest() {
  source_manifest="$1"
  awk '
    substr($0, 1, 2) == "S\t" { print substr($0, 3); next }
    $0 !~ /^#/ && $0 !~ /^[[:space:]]*$/ && substr($0, 1, 2) != "O\t" { print }
  ' "$source_manifest" | LC_ALL=C sort -u
}

write_manifest_paths() {
  write_paths_from_manifest "$manifest"
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

write_head_paths() {
  git rev-parse --verify HEAD >/dev/null 2>&1 || fail "仓库还没有可核验的 HEAD 提交"
  while IFS= read -r -d '' path; do
    printf '%s\n' "$path"
  done < <(git diff-tree --root --no-commit-id --name-only --no-renames -r -z HEAD)
}

check_manifest_overlap() {
  current="$tmp_dir/current-paths"
  write_manifest_paths > "$current"
  failed="0"
  while IFS= read -r other_manifest; do
    [ "$other_manifest" != "$manifest" ] || continue
    other="$tmp_dir/other-paths"
    overlap="$tmp_dir/overlap"
    write_paths_from_manifest "$other_manifest" > "$other"
    comm -12 "$current" "$other" > "$overlap"
    if [ -s "$overlap" ]; then
      echo "dev-workflow: task_file_overlap（与任务 $(manifest_task_from_file "$other_manifest") 修改同一文件）：" >&2
      sed 's/^/  /' "$overlap" >&2
      failed="1"
    fi
  done < <(list_manifest_files)
  [ "$failed" = "0" ]
}

check_manifest_paths_exist_in_workspace() {
  expected="$tmp_dir/expected"
  workspace="$tmp_dir/workspace"
  stale="$tmp_dir/stale"
  write_manifest_paths > "$expected"
  write_workspace_paths | LC_ALL=C sort -u > "$workspace"
  comm -23 "$expected" "$workspace" > "$stale"
  if [ -s "$stale" ]; then
    echo "dev-workflow: stale_scope（清单文件当前没有变更）：" >&2
    sed 's/^/  /' "$stale" >&2
    return 1
  fi
}

check_expected_staged() {
  expected="$tmp_dir/expected"
  staged="$tmp_dir/staged"
  missing="$tmp_dir/missing-staged"
  unstaged="$tmp_dir/unstaged"
  changed_after_stage="$tmp_dir/changed-after-stage"
  write_manifest_paths > "$expected"
  write_staged_paths | LC_ALL=C sort -u > "$staged"
  comm -23 "$expected" "$staged" > "$missing"
  if [ -s "$missing" ]; then
    echo "dev-workflow: current_task_unstaged（本任务文件尚未精确暂存）：" >&2
    sed 's/^/  /' "$missing" >&2
    return 1
  fi
  write_unstaged_paths | LC_ALL=C sort -u > "$unstaged"
  comm -12 "$expected" "$unstaged" > "$changed_after_stage"
  if [ -s "$changed_after_stage" ]; then
    echo "dev-workflow: current_task_changed_after_stage（暂存后又发生变更）：" >&2
    sed 's/^/  /' "$changed_after_stage" >&2
    return 1
  fi
}

check_exact_staged_when_not_isolated() {
  [ "${DEV_WORKFLOW_COMMIT_ONLY:-0}" = "1" ] && return 0
  expected="$tmp_dir/expected"
  staged="$tmp_dir/staged"
  extra="$tmp_dir/extra-staged"
  write_manifest_paths > "$expected"
  write_staged_paths | LC_ALL=C sort -u > "$staged"
  comm -13 "$expected" "$staged" > "$extra"
  if [ -s "$extra" ]; then
    echo "dev-workflow: other_task_staged（请使用 commit-scope.sh commit TASK_KEY 精确提交，不要直接 git commit）：" >&2
    sed 's/^/  /' "$extra" >&2
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

compare_head_scope() {
  expected="$tmp_dir/expected"
  actual="$tmp_dir/actual"
  missing="$tmp_dir/missing"
  extra="$tmp_dir/extra"
  write_manifest_paths > "$expected"
  write_head_paths | LC_ALL=C sort -u > "$actual"
  comm -23 "$expected" "$actual" > "$missing"
  comm -13 "$expected" "$actual" > "$extra"
  failed="0"
  if [ -s "$missing" ]; then
    echo "dev-workflow: current_task_missed（提交缺少清单文件）：" >&2
    sed 's/^/  /' "$missing" >&2
    failed="1"
  fi
  if [ -s "$extra" ]; then
    echo "dev-workflow: out_of_scope_HEAD（提交混入清单外文件）：" >&2
    sed 's/^/  /' "$extra" >&2
    failed="1"
  fi
  [ "$failed" = "0" ]
}

check_expected_clean_after_commit() {
  expected="$tmp_dir/expected"
  workspace="$tmp_dir/workspace"
  changed="$tmp_dir/post-commit-expected"
  write_manifest_paths > "$expected"
  write_workspace_paths | LC_ALL=C sort -u > "$workspace"
  comm -12 "$expected" "$workspace" > "$changed"
  if [ -s "$changed" ]; then
    echo "dev-workflow: current_task_post_commit_changes（提交后本任务文件仍有变更）：" >&2
    sed 's/^/  /' "$changed" >&2
    return 1
  fi
}

prepare_scope() {
  require_local_state_ignored
  task_key="${1:-}"
  validate_task_key "$task_key"
  shift
  manifest="$(manifest_path_for_task "$task_key")"
  if [ -f "$legacy_manifest" ] && [ "$(manifest_task_from_file "$legacy_manifest")" = "$task_key" ]; then
    rm -f "$legacy_manifest"
  fi
  paths="$tmp_dir/prepare-scope"
  : > "$paths"

  if [ "${1:-}" = "--all" ]; then
    shift
    [ "$#" -eq 0 ] || fail "--all 后不能再指定文件"
    write_workspace_paths | LC_ALL=C sort -u > "$paths"
  else
    [ "${1:-}" = "--" ] || fail "TASK_KEY 后必须使用 --all，或使用 -- 分隔文件"
    shift
    [ "$#" -gt 0 ] || fail "prepare 至少需要一个本任务文件"
    mode="scope"
    ignored_other="0"
    for input_path in "$@"; do
      if [ "$input_path" = "--other" ]; then
        mode="other"
        continue
      fi
      if [ "$mode" = "scope" ]; then
        normalize_path "$input_path" >> "$paths"
      else
        ignored_other="1"
      fi
    done
    LC_ALL=C sort -u "$paths" -o "$paths"
    if [ "$ignored_other" = "1" ]; then
      echo "dev-workflow: --other 已兼容忽略；新版本只需列出本任务文件"
    fi
  fi

  if [ -f "$manifest" ]; then
    write_paths_from_manifest "$manifest" >> "$paths"
    LC_ALL=C sort -u "$paths" -o "$paths"
  fi
  [ -s "$paths" ] || fail "提交清单至少需要一个本任务文件"
  mkdir -p "$manifest_dir"
  draft="$tmp_dir/manifest"
  {
    printf '# task=%s\n' "$task_key"
    printf '# created_at=%s\n' "$(date +%Y-%m-%dT%H:%M:%S%z)"
    printf '# base_head=%s\n' "$(current_head)"
    while IFS= read -r path; do
      printf 'S\t%s\n' "$path"
    done < "$paths"
  } > "$draft"
  mv "$draft" "$manifest"

  check_manifest_paths_exist_in_workspace
  check_manifest_overlap
  echo "dev-workflow: 已准备任务独立提交清单（尚未暂存）：$task_key"
  sed 's/^/  /' "$paths"
}

track_scope() {
  require_local_state_ignored
  task_key="${1:-}"
  validate_task_key "$task_key"
  shift
  [ "${1:-}" = "--" ] || fail "track 需要使用 -- 分隔文件"
  shift
  [ "$#" -gt 0 ] || fail "track 至少需要一个文件"
  manifest="$(manifest_path_for_task "$task_key")"
  mkdir -p "$manifest_dir"
  paths="$tmp_dir/track-paths"
  : > "$paths"
  if [ -f "$manifest" ]; then
    write_paths_from_manifest "$manifest" > "$paths"
  fi
  for input_path in "$@"; do
    normalize_path "$input_path" >> "$paths"
  done
  LC_ALL=C sort -u "$paths" -o "$paths"

  backup="$tmp_dir/track-backup"
  had_manifest="0"
  if [ -f "$manifest" ]; then
    cp "$manifest" "$backup"
    had_manifest="1"
  fi
  created_at="$(date +%Y-%m-%dT%H:%M:%S%z)"
  if [ "$had_manifest" = "1" ]; then
    existing_created_at="$(sed -n 's/^# created_at=//p' "$backup" | head -n 1)"
    [ -z "$existing_created_at" ] || created_at="$existing_created_at"
  fi
  {
    printf '# task=%s\n' "$task_key"
    printf '# created_at=%s\n' "$created_at"
    printf '# base_head=%s\n' "$(current_head)"
    while IFS= read -r path; do
      printf 'S\t%s\n' "$path"
    done < "$paths"
  } > "$manifest"

  if ! check_manifest_overlap; then
    if [ "$had_manifest" = "1" ]; then
      mv "$backup" "$manifest"
    else
      rm -f "$manifest"
    fi
    return 1
  fi
  echo "dev-workflow: 已更新本线程文件记录：$task_key"
  sed 's/^/  /' "$paths"
}

show_scope() {
  select_manifest "${1:-}"
  printf 'task: %s\n' "$(manifest_task)"
  printf 'manifest: %s\n' "$manifest"
  echo "files:"
  write_manifest_paths | sed 's/^/  /'
}

list_scopes() {
  found="0"
  while IFS= read -r scope_manifest; do
    found="1"
    printf '%s\t%s\n' "$(manifest_task_from_file "$scope_manifest")" "$scope_manifest"
  done < <(list_manifest_files)
  [ "$found" = "1" ] || echo "dev-workflow: 当前没有任务提交清单"
}

check_scope() {
  select_manifest "${1:-}"
  check_manifest_overlap
  check_expected_staged
  check_exact_staged_when_not_isolated
  echo "dev-workflow: 当前任务文件已精确暂存：$(manifest_task)"
}

stage_scope() {
  select_manifest "${1:-}"
  check_manifest_overlap
  while IFS= read -r path; do
    if [ -e "$path" ] || [ -L "$path" ] || git ls-files --error-unmatch -- "$path" >/dev/null 2>&1; then
      git add -A -- "$path"
    elif write_staged_paths | grep -Fxq -- "$path"; then
      :
    else
      fail "无法暂存清单路径：$path"
    fi
  done < <(write_manifest_paths)
  DEV_WORKFLOW_COMMIT_ONLY=1 check_expected_staged
  echo "dev-workflow: 已暂存本任务文件，其他任务暂存状态保持不变"
}

commit_scope() {
  task_key="${1:-}"
  validate_task_key "$task_key"
  shift
  [ "$#" -gt 0 ] || fail "commit 需要 Git commit 参数，例如 -m 提交信息"
  select_manifest "$task_key"
  stage_scope "$task_key"
  refresh_manifest_base_head
  paths=()
  while IFS= read -r path; do
    paths+=("$path")
  done < <(write_manifest_paths)
  DEV_WORKFLOW_MANIFEST="$manifest" DEV_WORKFLOW_COMMIT_ONLY=1 \
    git commit --only "$@" -- "${paths[@]}"
  if [ -f "$manifest" ]; then
    verify_head_scope "$task_key"
  fi
}

verify_head_scope() {
  select_manifest "${1:-}"
  verify_head_transition
  compare_head_scope
  check_expected_clean_after_commit
  echo "dev-workflow: HEAD 提交范围与任务清单一致：$(manifest_task)"
  rm -f "$manifest"
  echo "dev-workflow: 已清理当前任务提交清单，其他任务不受影响"
  echo "dev-workflow: commit_created=true current_task_clean=true"
}

clear_scope() {
  select_manifest "${1:-}"
  task="$(manifest_task)"
  rm -f "$manifest"
  echo "dev-workflow: 已清理任务提交清单：$task"
}

case "$cmd" in
  track) track_scope "$@" ;;
  prepare) prepare_scope "$@" ;;
  show) show_scope "$@" ;;
  list) list_scopes ;;
  stage) stage_scope "$@" ;;
  check) check_scope "$@" ;;
  commit) commit_scope "$@" ;;
  verify-head) verify_head_scope "$@" ;;
  clear) clear_scope "$@" ;;
  help|-h|--help) usage ;;
  *) usage; exit 1 ;;
esac
