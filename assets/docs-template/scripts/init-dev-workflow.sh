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

## Dev Workflow

所有新功能、Bug 修复、重构、维护、PRD、改版和需求类任务必须遵守 `docs/workflow.md`。

## Harness-first

开发任务不要求用户记命令。收到自然语言任务后，先运行：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" run "用户任务描述"
```

按输出的 `flow / docs_allowed / pre_code_gate / code_allowed / next_action` 执行。`code_allowed: false` 时，只能准备门禁文档，等待人工确认。

完成前运行：

```bash
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" verify "用户任务描述"
"${DEV_WORKFLOW_SKILL_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills/dev-workflow}/scripts/dev-workflow-harness.sh" check
```

`standard` 编码前必须先确认一个 TASK 或 BUG；`strict` 编码前必须先确认 REQ。确认标记统一为 `编码前确认：已确认`。

`verify` 只检查完整性；需求是否一致必须等待人工审核确认。未经用户批准，不得提交代码。
EOF
  fi
  echo "dev-workflow: 已创建 AGENTS.md"
elif ! grep -Eq "Dev Workflow|Harness-first|开发工作流强约束" "AGENTS.md"; then
  if [ -f "$skill_root/assets/agents-rule.md" ]; then
    {
      printf '\n\n'
      cat "$skill_root/assets/agents-rule.md"
    } >> "AGENTS.md"
  else
    cat >> "AGENTS.md" <<'EOF'


## Dev Workflow

所有新功能、Bug 修复、重构、维护、PRD、改版和需求类任务必须遵守 `docs/workflow.md`。

收到自然语言开发任务后，先运行已安装 skill 的 `dev-workflow-harness.sh run "用户任务描述"`；如果输出 `code_allowed: false`，先准备并确认门禁文档，标记 `编码前确认：已确认` 后再编码。完成前运行 `dev-workflow-harness.sh verify "用户任务描述"` 和 `dev-workflow-harness.sh check`。未经用户批准，不得提交代码。
EOF
  fi
  echo "dev-workflow: 已追加 AGENTS.md 规则"
else
  echo "dev-workflow: AGENTS.md 已包含工作流规则"
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
  docs/design/decisions \
  docs/acceptance \
  docs/ops \
  docs/legacy \
  docs/archive \
  .dev-workflow/index \
  .dev-workflow/session \
  .githooks

if [ "$with_templates" = "1" ]; then
  rsync -a --ignore-existing \
    "$template_dir/prd" \
    "$template_dir/requirements" \
    "$template_dir/tasks" \
    "$template_dir/bugs" \
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

if [ "$with_scripts" = "1" ]; then
  mkdir -p scripts
  rsync -a "$template_dir/scripts/" scripts/
  echo "dev-workflow: 已复制脚本到项目 scripts/"
fi

chmod +x .githooks/pre-commit .githooks/commit-msg 2>/dev/null || true
if [ "$with_scripts" = "1" ]; then
  chmod +x scripts/*.sh 2>/dev/null || true
fi

touch .gitignore
if ! grep -qxF ".dev-workflow/index/" .gitignore; then
  printf '\n.dev-workflow/index/\n' >> .gitignore
  echo "dev-workflow: 已把 .dev-workflow/index/ 加入 .gitignore"
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
