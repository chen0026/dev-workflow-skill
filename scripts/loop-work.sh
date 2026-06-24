#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-help}"
shift || true

usage() {
  cat <<'EOF'
usage:
  loop-work.sh start ACTIVE_FILE [max-iterations]
  loop-work.sh step ACTIVE_FILE "本轮目标" "关联验收项"
  loop-work.sh verify ACTIVE_FILE "真实验证证据"
  loop-work.sh decide ACTIVE_FILE continue|retry|rescope|wait_human|stop ["原因"]
  loop-work.sh status ACTIVE_FILE

规则：
  - step 必须关联验收项。
  - continue / retry / rescope 前必须已有本轮 verify。
  - wait_human / stop 可直接决策。
  - 达到最大轮次后禁止继续开新 step。
EOF
}

fail() {
  echo "dev-workflow: $1"
  exit 1
}

need_file() {
  file="${1:-}"
  [ -n "$file" ] || fail "缺少 ACTIVE_FILE"
  [ -f "$file" ] || fail "找不到 ACTIVE 文件：$file"
}

stamp_now() {
  date +%Y-%m-%dT%H:%M:%S%z
}

ensure_loop_section() {
  file="$1"
  max="${2:-3}"

  if ! grep -q '^## Loop 记录' "$file"; then
    {
      printf '\n## Loop 记录\n\n'
      printf '- 最大轮次：%s\n' "$max"
      printf '- 规则：每轮必须 step -> verify -> decide；wait_human / stop 可以直接决策。\n'
    } >> "$file"
  elif ! grep -q '^- 最大轮次：' "$file"; then
    {
      printf '\n- 最大轮次：%s\n' "$max"
    } >> "$file"
  fi
}

set_loop_max() {
  file="$1"
  max="$2"
  tmp="${file}.tmp.$$"
  awk -v max="$max" '
    BEGIN { done = 0 }
    /^- 最大轮次：/ && done == 0 {
      print "- 最大轮次：" max
      done = 1
      next
    }
    { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

max_iterations() {
  file="$1"
  found="$(grep -m 1 '^- 最大轮次：' "$file" | sed -E 's/^- 最大轮次： *//' || true)"
  case "$found" in
    ''|*[!0-9]*)
      echo "3"
      ;;
    *)
      echo "$found"
      ;;
  esac
}

round_pad() {
  printf '%03d' "$1"
}

current_round() {
  file="$1"
  found="$(grep -E '^### LOOP-[0-9]+ step ' "$file" 2>/dev/null | sed -E 's/^### LOOP-0*([0-9]+) step .*/\1/' | sort -n | tail -n 1 || true)"
  [ -n "$found" ] || found="0"
  echo "$found"
}

has_step() {
  file="$1"
  round="$2"
  grep -q "^### LOOP-$(round_pad "$round") step " "$file"
}

has_verify() {
  file="$1"
  round="$2"
  grep -q "^### LOOP-$(round_pad "$round") verify " "$file"
}

has_decide() {
  file="$1"
  round="$2"
  grep -q "^### LOOP-$(round_pad "$round") decide " "$file"
}

decision_for_round() {
  file="$1"
  round="$2"
  awk -v header="^### LOOP-$(round_pad "$round") decide " '
    $0 ~ header { in_block = 1; decision = "" }
    in_block && /^- 决策：/ { decision = $0 }
    in_block && /^### LOOP-/ && $0 !~ header { in_block = 0 }
    END {
      sub(/^- 决策： */, "", decision)
      print decision
    }
  ' "$file"
}

start_loop() {
  file="${1:-}"
  max="${2:-3}"
  need_file "$file"
  case "$max" in
    ''|*[!0-9]*)
      fail "max-iterations 必须是数字"
      ;;
  esac
  ensure_loop_section "$file" "$max"
  set_loop_max "$file" "$max"
  echo "dev-workflow: loop 已准备：$file"
}

step_loop() {
  file="${1:-}"
  target="${2:-}"
  acceptance="${3:-}"
  need_file "$file"
  [ -n "$target" ] || fail "step 需要本轮目标"
  [ -n "$acceptance" ] || fail "step 需要关联验收项"
  ensure_loop_section "$file" "3"

  current="$(current_round "$file")"
  max="$(max_iterations "$file")"

  if [ "$current" -gt 0 ] && ! has_decide "$file" "$current"; then
    fail "上一轮 LOOP-$(round_pad "$current") 尚未 decide，不能开始新 step"
  fi

  if [ "$current" -gt 0 ]; then
    last_decision="$(decision_for_round "$file" "$current")"
    case "$last_decision" in
      wait_human|stop)
        fail "上一轮决策为 ${last_decision}，不能继续编码"
        ;;
    esac
  fi

  if [ "$current" -ge "$max" ]; then
    fail "已达到最大轮次 ${max}，停止并汇报"
  fi

  next="$((current + 1))"
  {
    printf '\n### LOOP-%s step %s\n\n' "$(round_pad "$next")" "$(stamp_now)"
    printf -- '- 本轮目标：%s\n' "$target"
    printf -- '- 关联验收项：%s\n' "$acceptance"
    printf -- '- 状态：step\n'
  } >> "$file"

  echo "dev-workflow: 已记录 LOOP-$(round_pad "$next") step"
}

verify_loop() {
  file="${1:-}"
  evidence="${2:-}"
  need_file "$file"
  [ -n "$evidence" ] || fail "verify 需要真实验证证据"
  ensure_loop_section "$file" "3"

  current="$(current_round "$file")"
  [ "$current" -gt 0 ] || fail "没有当前 loop step"
  has_step "$file" "$current" || fail "没有当前 loop step"
  if has_decide "$file" "$current"; then
    fail "LOOP-$(round_pad "$current") 已 decide，不能补 verify"
  fi

  {
    printf '\n### LOOP-%s verify %s\n\n' "$(round_pad "$current")" "$(stamp_now)"
    printf -- '- 真实验证证据：%s\n' "$evidence"
    printf -- '- 状态：verified\n'
  } >> "$file"

  echo "dev-workflow: 已记录 LOOP-$(round_pad "$current") verify"
}

decide_loop() {
  file="${1:-}"
  decision="${2:-}"
  reason="${3:-}"
  need_file "$file"
  [ -n "$decision" ] || fail "decide 需要决策"
  ensure_loop_section "$file" "3"

  case "$decision" in
    continue|retry|rescope|wait_human|stop) ;;
    *)
      fail "决策必须是 continue|retry|rescope|wait_human|stop"
      ;;
  esac

  current="$(current_round "$file")"
  [ "$current" -gt 0 ] || fail "没有当前 loop step"
  if has_decide "$file" "$current"; then
    fail "LOOP-$(round_pad "$current") 已 decide"
  fi

  case "$decision" in
    continue|retry|rescope)
      has_verify "$file" "$current" || fail "$decision 前必须先记录本轮 verify"
      ;;
  esac

  [ -n "$reason" ] || reason="未填写"

  {
    printf '\n### LOOP-%s decide %s\n\n' "$(round_pad "$current")" "$(stamp_now)"
    printf -- '- 决策：%s\n' "$decision"
    printf -- '- 原因：%s\n' "$reason"
  } >> "$file"

  echo "dev-workflow: 已记录 LOOP-$(round_pad "$current") decide=$decision"
}

status_loop() {
  file="${1:-}"
  need_file "$file"
  ensure_loop_section "$file" "3"
  current="$(current_round "$file")"
  max="$(max_iterations "$file")"
  decision="none"
  verified="false"
  if [ "$current" -gt 0 ]; then
    decision="$(decision_for_round "$file" "$current")"
    [ -n "$decision" ] || decision="pending"
    if has_verify "$file" "$current"; then
      verified="true"
    fi
  fi

  printf 'active_file: %s\n' "$file"
  printf 'current_iteration: %s\n' "$current"
  printf 'max_iterations: %s\n' "$max"
  printf 'current_verified: %s\n' "$verified"
  printf 'last_decision: %s\n' "$decision"
}

case "$cmd" in
  start)
    start_loop "$@"
    ;;
  step)
    step_loop "$@"
    ;;
  verify)
    verify_loop "$@"
    ;;
  decide)
    decide_loop "$@"
    ;;
  status)
    status_loop "$@"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac
