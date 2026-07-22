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
skill_root="${DEV_WORKFLOW_SKILL_ROOT:-$script_parent}"

[ -f "$skill_root/assets/agents-rule.md" ] || {
  echo "dev-workflow: 找不到 assets/agents-rule.md：$skill_root"
  exit 1
}

mkdir -p "$target_dir"
cd "$target_dir"

remove_old_agent_rules() {
  source_file="$1"
  output_file="$2"

  awk '
    BEGIN {
      marker = 0
      old_h2 = 0
      old_h3 = 0
    }
    $0 == "<!-- dev-workflow:start -->" {
      marker = 1
      next
    }
    marker {
      if ($0 == "<!-- dev-workflow:end -->") marker = 0
      next
    }
    $0 == "## Dev Workflow" ||
    $0 == "## Dev Workflow Lite" ||
    $0 == "## Dev Workflow Native" ||
    $0 == "## Dev Workflow Active Isolation" ||
    $0 == "## Dev Workflow Comment Guard" ||
    $0 == "## Dev Workflow Loop Guard" ||
    $0 == "## Harness-first" {
      old_h2 = 1
      next
    }
    old_h2 {
      if ($0 ~ /^## /) old_h2 = 0
      else next
    }
    $0 ~ /^### Dev Workflow (Git Record|Isolated Commit|One Approval|Thread Files)$/ {
      old_h3 = 1
      next
    }
    old_h3 {
      if ($0 ~ /^#{1,3} /) old_h3 = 0
      else next
    }
    { print }
  ' "$source_file" > "$output_file"
}

if [ ! -f "AGENTS.md" ]; then
  cp "$skill_root/assets/agents-template.md" "AGENTS.md"
  echo "dev-workflow: 已创建精简 AGENTS.md"
else
  tmp_agents="$(mktemp)"
  remove_old_agent_rules "AGENTS.md" "$tmp_agents"
  {
    printf '\n'
    cat "$skill_root/assets/agents-rule.md"
    printf '\n'
  } >> "$tmp_agents"
  mv "$tmp_agents" "AGENTS.md"
  echo "dev-workflow: 已迁移 AGENTS.md 到 Native 规则"
fi

touch .gitignore
if ! grep -qxF ".dev-workflow/" .gitignore; then
  printf '\n.dev-workflow/\n' >> .gitignore
  echo "dev-workflow: 已把 .dev-workflow/ 加入 .gitignore"
fi

if [ "$with_templates" = "1" ]; then
  mkdir -p docs/work docs/design/decisions docs/ops
  rsync -a --ignore-existing "$skill_root/assets/docs-template/work/" docs/work/
  rsync -a --ignore-existing "$skill_root/assets/docs-template/design/decisions/" docs/design/decisions/
  rsync -a --ignore-existing "$skill_root/assets/docs-template/ops/" docs/ops/
  echo "dev-workflow: 已按需复制 DEV、ADR 和 OPS 模板"
fi

if [ "$with_scripts" = "1" ]; then
  mkdir -p scripts
  rsync -a "$skill_root/scripts/" scripts/
  chmod +x scripts/*.sh 2>/dev/null || true
  echo "dev-workflow: 已复制可选脚本到项目 scripts/"
fi

current_hooks_path=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  current_hooks_path="$(git config --get core.hooksPath || true)"
fi

if [ "$enable_hooks" = "1" ] || [ "$current_hooks_path" = ".githooks" ]; then
  mkdir -p .githooks
  cp "$skill_root/assets/hooks/pre-commit" .githooks/pre-commit
  cp "$skill_root/assets/hooks/commit-msg" .githooks/commit-msg
  cp "$skill_root/assets/hooks/post-commit" .githooks/post-commit
  chmod +x .githooks/pre-commit .githooks/commit-msg .githooks/post-commit

  if [ "$enable_hooks" = "1" ]; then
    if git rev-parse --git-dir >/dev/null 2>&1; then
      git config core.hooksPath .githooks
      echo "dev-workflow: 已启用轻量 Git hooks"
    else
      echo "dev-workflow: 当前目录不是 Git 仓库，未启用 Git hooks"
    fi
  else
    echo "dev-workflow: 已更新现有轻量 Git hooks"
  fi
else
  echo "dev-workflow: 未启用 Git hooks；需要时运行 /dev-workflow init --hooks"
fi

if [ -f "scripts/dev-workflow-harness.sh" ] ||
   [ -f "scripts/loop-work.sh" ] ||
   [ -f "scripts/active-work.sh" ] ||
   [ -f "scripts/session-state.sh" ]; then
  echo "dev-workflow: 检测到旧版项目脚本副本，未自动删除。"
  echo "dev-workflow: 审核后可运行：$skill_root/scripts/clean-project-scripts.sh --apply"
fi

echo "dev-workflow: Native 初始化完成"
