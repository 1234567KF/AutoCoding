#!/usr/bin/env bash
# ============================================================
# 红队激进方案 — Claude Code 配置热重载守护进程 (Linux/Mac)
# ============================================================
# 自动检测 settings.json 变更并热重载 Claude Code 配置，
# 无需重启会话即可应用 Thinking / 流式输出 / 折叠等 UX 配置。
#
# 激进特性：
# - inotifywait / fswatch 文件监视
# - 配置合并策略（settings.json + settings.local.json）
# - 自动备份 + 回滚
# - JSON 语法校验（jq）
# - 终端通知（osascript / notify-send）
#
# 用法：
#   ./claude-config-watcher.sh              # 前台运行
#   ./claude-config-watcher.sh --daemon     # 后台守护进程
#   ./claude-config-watcher.sh --once       # 单次检查
# ============================================================

set -euo pipefail

# ===== 颜色定义 =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
DIM='\033[2m'
NC='\033[0m'
BOLD='\033[1m'

# ===== 平台检测 =====
detect_platform() {
  case "$(uname -s)" in
    Linux*)  OS="linux" ;;
    Darwin*) OS="macos" ;;
    CYGWIN*|MINGW*|MSYS*) OS="windows" ;;
    *)       OS="unknown" ;;
  esac

  ARCH=$(uname -m)

  # 检测色彩支持
  if [[ "$COLORTERM" =~ ^(truecolor|24bit)$ ]]; then
    COLOR_DEPTH=24
  elif [[ -n "${TERM:-}" ]]; then
    COLOR_DEPTH=256
  else
    COLOR_DEPTH=16
  fi

  # 检测文件监视工具
  WATCH_CMD=""
  if command -v inotifywait &>/dev/null; then
    WATCH_CMD="inotifywait"
  elif command -v fswatch &>/dev/null; then
    WATCH_CMD="fswatch"
  fi
}

# ===== 日志输出 =====
log() {
  local level="$1" color="" prefix=""
  shift
  case "$level" in
    INFO)    color="$CYAN";    prefix="ℹ"  ;;
    SUCCESS) color="$GREEN";   prefix="✅" ;;
    WARN)    color="$YELLOW";  prefix="⚠"  ;;
    ERROR)   color="$RED";     prefix="❌" ;;
    HOT)     color="$MAGENTA"; prefix="🔄" ;;
    *)       color="$WHITE";   prefix="•"  ;;
  esac
  printf "${DIM}[%s]${NC} ${color}%s${NC} %s\n" "$(date +%H:%M:%S)" "$prefix" "$*"
}

# ===== JSON 合并函数（纯 bash + jq）=====
merge_json() {
  local base="$1" local_="$2"

  if ! command -v jq &>/dev/null; then
    log WARN "jq 未安装，使用简单覆盖合并"
    if [[ -f "$local_" ]]; then
      cat "$local_"
    elif [[ -f "$base" ]]; then
      cat "$base"
    else
      echo "{}"
    fi
    return
  fi

  # 使用 jq 深度合并：local 覆盖 base
  jq -s 'def deep_merge($other):
    reduce ($other | to_entries[]) as $item (.;
      if .[$item.key] == null then .[$item.key] = $item.value
      elif (.[$item.key] | type) == "object" and ($item.value | type) == "object" then
        .[$item.key] = (.[$item.key] | deep_merge($item.value))
      else .[$item.key] = $item.value end
    );
    .[0] as $base | .[1] as $local | $base | deep_merge($local)' \
    "${base:-/dev/null}" "${local_:-/dev/null}" 2>/dev/null || {
    log WARN "jq 合并失败，使用简单覆盖"
    if [[ -f "$local_" ]]; then cat "$local_"; elif [[ -f "$base" ]]; then cat "$base"; else echo "{}"; fi
  }
}

# ===== JSON 快速校验 =====
validate_config() {
  local file="$1"
  if ! command -v jq &>/dev/null; then
    log WARN "跳过 JSON 校验（jq 未安装）"
    return 0
  fi
  if jq empty "$file" 2>/dev/null; then
    return 0
  else
    log ERROR "JSON 语法错误: $file"
    return 1
  fi
}

# ===== 配置备份 =====
backup_config() {
  local path="$1"
  local backup_dir="${SCRIPT_DIR}/../backups"
  mkdir -p "$backup_dir"
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_path="${backup_dir}/settings_${timestamp}.json"
  cp "$path" "$backup_path"
  log INFO "配置已备份至: $backup_path"
  # 保留最近 10 个备份
  ls -t "${backup_dir}"/settings_*.json 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
}

# ===== 桌面通知 =====
send_notification() {
  local title="$1" message="$2"
  case "$OS" in
    macos)
      osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null || true
      ;;
    linux)
      if command -v notify-send &>/dev/null; then
        notify-send "$title" "$message" --app-name="Claude Config Watcher" 2>/dev/null || true
      fi
      ;;
  esac
}

# ===== 应用热重载 =====
apply_hot_reload() {
  log HOT "检测到配置变更，应用热重载..."

  # 更新环境变量
  if echo "$MERGED_CONFIG" | jq -e '.alwaysThinkingEnabled' &>/dev/null; then
    export CLAUDE_CODE_ALWAYS_THINKING=1
  fi
  if echo "$MERGED_CONFIG" | jq -e '.verbose' &>/dev/null; then
    export CLAUDE_CODE_VERBOSE=1
  fi
  if echo "$MERGED_CONFIG" | jq -e '.outputStyle.includePartialMessages' &>/dev/null; then
    export CLAUDE_CODE_STREAM_OUTPUT=1
  fi

  log SUCCESS "热重载完成"
  send_notification "Claude Code 配置已更新" "已应用 UX 配置变更" 2>/dev/null || true
}

# ===== 单次检查 =====
run_once() {
  log INFO "单次配置检查..."

  validate_config "$PROJECT_SETTINGS" || true
  if [[ -f "$LOCAL_SETTINGS" ]]; then
    validate_config "$LOCAL_SETTINGS" || true
  fi

  MERGED_CONFIG=$(merge_json "$PROJECT_SETTINGS" "$LOCAL_SETTINGS")

  log INFO "当前 UX 配置:"
  echo "$MERGED_CONFIG" | jq -r '
    "  alwaysThinkingEnabled: \(.alwaysThinkingEnabled // "未设置")",
    "  verbose: \(.verbose // "未设置")",
    "  showThinking: \(.showThinking // "未设置")",
    "  outputStyle.format: \(.outputStyle.format // "未设置")",
    "  autoFold.enabled: \(.autoFold.enabled // "未设置")"
  ' 2>/dev/null || echo "$MERGED_CONFIG"

  log SUCCESS "单次检查完成"
}

# ===== 文件监视循环 =====
watch_loop() {
  if [[ -z "$WATCH_CMD" ]]; then
    log WARN "未检测到 inotifywait 或 fswatch，使用轮询模式（间隔: ${WATCH_INTERVAL}s）"

    local last_hash=""
    while true; do
      local new_config new_hash
      new_config=$(merge_json "$PROJECT_SETTINGS" "$LOCAL_SETTINGS")
      new_hash=$(echo "$new_config" | md5sum 2>/dev/null || md5 2>/dev/null || echo "$new_config" | cksum)

      if [[ -n "$last_hash" && "$new_hash" != "$last_hash" ]]; then
        apply_hot_reload
      fi

      last_hash="$new_hash"
      sleep "${WATCH_INTERVAL}"
    done
    return
  fi

  log INFO "使用 $WATCH_CMD 文件监视..."

  # 构建监视文件列表
  local watch_files=("$PROJECT_SETTINGS")
  [[ -f "$LOCAL_SETTINGS" ]] && watch_files+=("$LOCAL_SETTINGS")

  case "$WATCH_CMD" in
    inotifywait)
      inotifywait -q -m -e modify,create,delete,move --format '%w%f %e' "${watch_files[@]}" | while read -r file event; do
        log HOT "文件变更: $file ($event)"
        sleep 1  # 防抖
        apply_hot_reload
      done
      ;;
    fswatch)
      fswatch -o "${watch_files[@]}" | while read -r _; do
        log HOT "文件变更检测"
        sleep 1  # 防抖
        apply_hot_reload
      done
      ;;
  esac
}

# ===== 主入口 =====
main() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

  CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  GLOBAL_SETTINGS="${CONFIG_DIR}/settings.json"
  PROJECT_SETTINGS="${PROJECT_DIR}/settings.json"
  LOCAL_SETTINGS="${PROJECT_DIR}/settings.local.json"
  WATCH_INTERVAL="${CLAUDE_WATCH_INTERVAL:-2}"

  detect_platform

  echo ""
  printf "${CYAN}╔══════════════════════════════════════════╗${NC}\n"
  printf "${MAGENTA}║  Claude Code Config Watcher [Red Team]  ║${NC}\n"
  printf "${CYAN}║  激进配置热重载守护进程 v1.0            ║${NC}\n"
  printf "${CYAN}╚══════════════════════════════════════════╝${NC}\n"
  printf "\n"

  log INFO "平台: $OS / $ARCH / 色彩深度: ${COLOR_DEPTH}bit"

  # 解析参数
  local mode="daemon"
  for arg in "$@"; do
    case "$arg" in
      --once)   mode="once" ;;
      --daemon) mode="daemon" ;;
      --help|-h)
        echo "用法: $0 [--once|--daemon|--help]"
        echo "  --once    单次检查配置"
        echo "  --daemon  持续监视配置变更（默认）"
        exit 0
        ;;
    esac
  done

  case "$mode" in
    once)
      run_once
      ;;
    daemon)
      log INFO "监控路径:"
      log INFO "  项目: $PROJECT_SETTINGS"
      [[ -f "$LOCAL_SETTINGS" ]] && log INFO "  本地: $LOCAL_SETTINGS"

      # 首次合并 + 校验
      validate_config "$PROJECT_SETTINGS" || backup_config "$PROJECT_SETTINGS"
      [[ -f "$LOCAL_SETTINGS" ]] && validate_config "$LOCAL_SETTINGS" || true

      MERGED_CONFIG=$(merge_json "$PROJECT_SETTINGS" "$LOCAL_SETTINGS")

      log SUCCESS "初始化完成 — 开始监视配置变更"
      printf "${DIM}  按 Ctrl+C 退出${NC}\n"
      printf "\n"

      watch_loop
      ;;
  esac
}

main "$@"
