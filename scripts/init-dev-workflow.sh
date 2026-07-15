#!/usr/bin/env bash
set -euo pipefail

target_dir="$(pwd)"
enable_hooks="0"
with_templates="0"
with_scripts="0"

for arg in "$@"; do
  case "$arg" in
    --enable-hooks|--hooks)
      enable_hooks="1"
      ;;
    --with-templates)
      with_templates="1"
      ;;
    --with-scripts)
      with_scripts="1"
      ;;
    *)
      target_dir="$arg"
      ;;
  esac
done

script_parent="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -d "$script_parent/assets/docs-template" ]; then
  skill_root="$script_parent"
  template_dir="$skill_root/assets/docs-template"
else
  skill_root="${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}"
  template_dir="$script_parent"
fi

if [ ! -f "$template_dir/workflow.md" ]; then
  echo "dev-workflow: 找不到模板目录或 workflow.md：$template_dir"
  exit 1
fi

mkdir -p "$target_dir"
cd "$target_dir"

if [ ! -f "AGENTS.md" ]; then
  if [ -f "$skill_root/assets/agents-template.md" ]; then
    cp "$skill_root/assets/agents-template.md" "AGENTS.md"
  else
    cat > "AGENTS.md" <<'EOF'
# AGENTS.md

## Dev Workflow Lite

普通开发任务默认直接调查、实现、测试和审查，不强制写过程文档。普通修改只使用结构化 Git commit；复杂任务只维护一个 DEV。共享工作区使用任务独立 manifest 和 `git commit --only`。未经用户明确批准不得 commit。
EOF
  fi
  echo "dev-workflow: 已创建 AGENTS.md"
fi

if ! grep -q "Dev Workflow Lite" "AGENTS.md"; then
  {
    printf '\n\n'
    cat "$skill_root/assets/agents-rule.md"
  } >> "AGENTS.md"
  echo "dev-workflow: 已追加 Lite 覆盖规则到 AGENTS.md"
fi

if ! grep -q "Dev Workflow Git Record" "AGENTS.md"; then
  cat >> "AGENTS.md" <<'EOF'


### Dev Workflow Git Record

本节覆盖旧的 Dev Workflow CHG Record。普通修改不再创建 CHG、REQ、TASK、BUG 或 ACC，结构化 Git commit 是修改历史的唯一事实记录。复杂任务只维护一个 `docs/work/YYYY/MM/DEV-*.md`，贯穿需求、计划、问题、进度、验收和关联 commits。历史先用 Git 追查真实 diff。
EOF
  echo "dev-workflow: 已追加 Git/DEV 修改记录规则到 AGENTS.md"
fi

if ! grep -q "Dev Workflow Isolated Commit" "AGENTS.md"; then
  cat >> "AGENTS.md" <<'EOF'


### Dev Workflow Isolated Commit

共享工作区为每个任务使用独立 `.dev-workflow/commits/TASK_KEY.txt`。提交时只在清单中列本任务文件，并使用 `commit-scope.sh commit TASK_KEY ...`通过 `git commit --only`精确提交；不得为了当前任务取消其他任务的暂存状态。只有不同任务清单包含同一文件时才停止并人工确认。
EOF
  echo "dev-workflow: 已追加共享工作区精确提交规则到 AGENTS.md"
fi

if ! grep -q "Dev Workflow One Approval" "AGENTS.md"; then
  cat >> "AGENTS.md" <<'EOF'


### Dev Workflow One Approval

提交前必须一次性展示文件范围、完整 commit message 和验证结果；使用 DEV 时再展示 DEV 变化，只询问一次。用户确认后立即提交，不得重复确认。
EOF
  echo "dev-workflow: 已追加单次提交授权规则到 AGENTS.md"
fi

if ! grep -q "Dev Workflow Thread Files" "AGENTS.md"; then
  cat >> "AGENTS.md" <<'EOF'


### Dev Workflow Thread Files

每个线程使用稳定 TASK_KEY；首次修改文件前由 Agent 后台执行 `commit-scope.sh track TASK_KEY -- FILE...`，后续发现文件时增量记录，用户无须操作。文件已被其他线程记录时在编码前停止，正常情况仍由本线程直接提交。只有 commit 成功、HEAD 变化、提交文件与本线程记录一致且这些文件无残留时，才能报告提交成功。
EOF
  echo "dev-workflow: 已追加本线程文件记录与提交成功校验规则到 AGENTS.md"
fi

if [ -d "docs" ] && [ ! -f "docs/workflow.md" ]; then
  archive_dir="docs/archive/legacy-docs-$(date +%Y%m%d-%H%M%S)"
  movable="$(find docs -mindepth 1 -maxdepth 1 ! -name archive -print)"

  if [ -n "$movable" ]; then
    mkdir -p "$archive_dir"
    while IFS= read -r item; do
      mv "$item" "$archive_dir/"
    done <<EOF
$movable
EOF
    echo "dev-workflow: 已归档旧 docs 到 $archive_dir"
  fi
fi

mkdir -p docs
rsync -a --ignore-existing \
  "$template_dir/README.md" \
  "$template_dir/workflow.md" \
  docs/

mkdir -p \
  docs/prd \
  docs/work \
  docs/active \
  docs/history \
  docs/design/decisions \
  docs/ops \
  docs/legacy \
  docs/archive \
  .dev-workflow/index \
  .dev-workflow/session \
  .dev-workflow/bindings \
  .dev-workflow/commits \
  .githooks

if [ "$with_templates" = "1" ]; then
  rsync -a --ignore-existing \
    "$template_dir/prd" \
    "$template_dir/work" \
    "$template_dir/active" \
    "$template_dir/history" \
    "$template_dir/design" \
    "$template_dir/ops" \
    "$template_dir/legacy" \
    docs/
  echo "dev-workflow: 已复制模板到项目 docs/"
fi

rsync -a --ignore-existing "$template_dir/.githooks/" .githooks/
rsync -a "$template_dir/.githooks/pre-commit" .githooks/pre-commit
rsync -a "$template_dir/.githooks/commit-msg" .githooks/commit-msg
rsync -a "$template_dir/.githooks/post-commit" .githooks/post-commit

if [ "$with_scripts" = "1" ]; then
  mkdir -p scripts
  rsync -a "$template_dir/scripts/" scripts/
  echo "dev-workflow: 已复制脚本到项目 scripts/"
fi

chmod +x .githooks/pre-commit .githooks/commit-msg .githooks/post-commit 2>/dev/null || true
if [ "$with_scripts" = "1" ]; then
  chmod +x scripts/*.sh 2>/dev/null || true
fi

touch .gitignore
if ! grep -qxF ".dev-workflow/" .gitignore; then
  printf '\n.dev-workflow/\n' >> .gitignore
  echo "dev-workflow: 已把 .dev-workflow/ 加入 .gitignore"
fi
if ! grep -qxF "docs/index.md" .gitignore; then
  printf 'docs/index.md\n' >> .gitignore
  echo "dev-workflow: 已把 docs/index.md 加入 .gitignore"
fi

if [ "$enable_hooks" = "1" ]; then
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git config core.hooksPath .githooks
    echo "dev-workflow: 已启用 Git hooks"
  else
    echo "dev-workflow: 当前目录不是 Git 仓库，未启用 Git hooks"
  fi
else
  echo "dev-workflow: Git hooks 未自动启用。需要时执行：git config core.hooksPath .githooks"
fi

echo "dev-workflow: 初始化完成"
