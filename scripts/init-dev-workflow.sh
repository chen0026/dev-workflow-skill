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

普通开发任务默认直接调查、实现、测试和审查，不强制写过程文档或运行 harness。跨会话或交接时只使用一个 ACTIVE；PRD 改版或高风险变更编码前确认 REQ 和验收项。最终验收必须有真实证据，mock 只能辅助。普通 Bug / 功能正式提交时只新增一个精简 CHG，并用 Git message 记录原因、变更、验证和影响。未经用户明确批准不得 commit。
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

if ! grep -q "Dev Workflow CHG Record" "AGENTS.md"; then
  cat >> "AGENTS.md" <<'EOF'


### Dev Workflow CHG Record

普通 Bug / 功能不新建 REQ、TASK、BUG 或 ACC 留痕。正式提交时恰好新增一个精简 `docs/changes/YYYY/MM/CHG-*.md`，并根据实际 diff 生成 `fix/feat(scope): 摘要`，正文记录原因、变更、验证和影响。用户同时确认待提交文件、CHG 和 commit message 后才 commit。历史先搜索 `docs/changes/`，再用 Git 追查真实 diff。
EOF
  echo "dev-workflow: 已追加 CHG 修改记录规则到 AGENTS.md"
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
  docs/requirements \
  docs/tasks \
  docs/bugs \
  docs/active \
  docs/changes \
  docs/history \
  docs/design/decisions \
  docs/acceptance \
  docs/ops \
  docs/legacy \
  docs/archive \
  .dev-workflow/index \
  .dev-workflow/session \
  .dev-workflow/bindings \
  .githooks

if [ "$with_templates" = "1" ]; then
  rsync -a --ignore-existing \
    "$template_dir/prd" \
    "$template_dir/requirements" \
    "$template_dir/tasks" \
    "$template_dir/bugs" \
    "$template_dir/active" \
    "$template_dir/changes" \
    "$template_dir/history" \
    "$template_dir/design" \
    "$template_dir/acceptance" \
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
