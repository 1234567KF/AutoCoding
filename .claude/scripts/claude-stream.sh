#!/usr/bin/env bash
# =============================================================================
# claude-stream.sh — Claude Code 流式输出包装器 (Linux/macOS)
# 绿队安全版 v2.0：参数校验 / 超时保护 / 降级回滚 / 日志记录 / 注入检测
# =============================================================================
set -euo pipefail

# =============================================================================
# 0. 初始化：路径 & 日志 & 默认值
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$PROJECT_ROOT/.claude/logs"
TIMEOUT_SECONDS=600            # 默认 10 分钟超时
MAX_INPUT_BYTES=1048576        # 默认 1MB 输入限制
NO_STREAM=false                # 降级模式标志
VERBOSE_LOG=false
INJECTION_WARNING=false

# 确保日志目录存在
mkdir -p "$LOG_DIR"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${LOG_DIR}/claude-stream_${TIMESTAMP}.log"

# 日志函数
log_msg() {
    local level="$1" message="$2" ts
    ts="$(date '+%Y-%m-%d %H:%M:%S.%3N' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S')"
    echo "[$ts] [$level] $message" >> "$LOG_FILE"
    if [[ "$VERBOSE_LOG" == true ]]; then
        echo "[$ts] [$level] $message" >&2
    fi
}

# =============================================================================
# 1. 参数解析
# =============================================================================
CLAUDE_ARGS=()
PIPE_INPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --timeout)
            TIMEOUT_SECONDS="$2"
            if ! [[ "$TIMEOUT_SECONDS" =~ ^[0-9]+$ ]] || [[ "$TIMEOUT_SECONDS" -lt 1 ]] || [[ "$TIMEOUT_SECONDS" -gt 3600 ]]; then
                echo "[claude-stream] 错误: --timeout 必须是 1-3600 之间的整数" >&2
                exit 1
            fi
            shift 2 ;;
        --max-input)
            MAX_INPUT_BYTES="$2"
            if ! [[ "$MAX_INPUT_BYTES" =~ ^[0-9]+$ ]] || [[ "$MAX_INPUT_BYTES" -lt 1 ]]; then
                echo "[claude-stream] 错误: --max-input 必须是正整数" >&2
                exit 1
            fi
            shift 2 ;;
        --no-stream) NO_STREAM=true; shift ;;
        --verbose) VERBOSE_LOG=true; shift ;;
        --log-file) LOG_FILE="$2"; shift 2 ;;
        --help|-h)
            echo "用法: claude-stream.sh [选项] [-- claude参数...]"
            echo ""
            echo "选项:"
            echo "  --timeout N      超时秒数 (1-3600, 默认 600)"
            echo "  --max-input N    输入大小限制 bytes (默认 1MB)"
            echo "  --no-stream      强制禁用流式输出（降级模式）"
            echo "  --verbose        详细日志输出到 stderr"
            echo "  --log-file PATH  自定义日志路径"
            echo "  --help, -h       显示此帮助"
            echo ""
            echo "安全特性: 参数注入检测 | 超时保护 | 自动降级 | 凭据泄露检测"
            exit 0 ;;
        --) shift; CLAUDE_ARGS+=("$@"); break ;;
        *)  CLAUDE_ARGS+=("$1"); shift ;;
    esac
done

log_msg "INFO" "===== claude-stream 启动 (绿队安全版) ====="
log_msg "INFO" "项目路径: $PROJECT_ROOT"
log_msg "INFO" "超时设置: ${TIMEOUT_SECONDS}s"
log_msg "INFO" "输入限制: ${MAX_INPUT_BYTES} bytes"
log_msg "INFO" "参数: ${CLAUDE_ARGS[*]:-<无>}"

# =============================================================================
# 2. 参数校验（防止注入 & 凭据泄露）
# =============================================================================
sanitize_arg() {
    local arg="$1"
    if [[ "$arg" =~ [\;\&\|\>\<\(\)\$\{\}\#\!\~] ]] || [[ "$arg" =~ \` ]]; then
        log_msg "WARN" "疑似注入参数被清理: '$arg'"
        INJECTION_WARNING=true
        arg="${arg//[\;\&\|\>\<\(\)\$\{\}\#\!\~\`]/}"
    fi
    echo "$arg"
}

SANITIZED_ARGS=()
for arg in "${CLAUDE_ARGS[@]}"; do
    SANITIZED_ARGS+=("$(sanitize_arg "$arg")")
done
CLAUDE_ARGS=("${SANITIZED_ARGS[@]}")

if [[ "$INJECTION_WARNING" == true ]]; then
    log_msg "WARN" "部分参数包含可疑字符，已自动清理"
fi

# 参数总长度校验
TOTAL_ARG_LEN=$(printf '%s ' "${CLAUDE_ARGS[@]}" | wc -c)
if [[ "$TOTAL_ARG_LEN" -gt 10000 ]]; then
    log_msg "ERROR" "参数总长度超出限制: ${TOTAL_ARG_LEN} > 10000"
    echo "[claude-stream] 错误: 参数过长（>10000字符），疑似注入攻击，已拒绝执行" >&2
    exit 1
fi

# 凭据泄露检测
ARG_STRING="${CLAUDE_ARGS[*]}"
if echo "$ARG_STRING" | grep -qiE '(api[_-]?key|apikey|secret|token|password|passwd)[=: ][^ ]+' 2>/dev/null; then
    log_msg "WARN" "命令行参数中检测到可能的凭据信息。请使用环境变量传递凭据。"
    echo "[claude-stream] 警告: 命令行参数中检测到可能的凭据。请通过环境变量或 stdin 传递。" >&2
fi
if echo "$ARG_STRING" | grep -qE '(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16})' 2>/dev/null; then
    log_msg "WARN" "检测到已知格式的 API Key / Token 模式"
    echo "[claude-stream] 警告: 检测到 API Key / Token 模式" >&2
fi

# =============================================================================
# 3. 输入大小校验
# =============================================================================
if [[ ! -t 0 ]]; then
    PIPE_INPUT="$(cat)"
    INPUT_SIZE=$(echo -n "$PIPE_INPUT" | wc -c)
    if [[ "$INPUT_SIZE" -gt "$MAX_INPUT_BYTES" ]]; then
        log_msg "ERROR" "stdin 输入超出限制: ${INPUT_SIZE} > ${MAX_INPUT_BYTES}"
        echo "[claude-stream] 错误: 输入过大（>${MAX_INPUT_BYTES} bytes），已拒绝处理" >&2
        exit 2
    fi
    log_msg "INFO" "管道输入长度: ${INPUT_SIZE} 字符"
fi

# =============================================================================
# 4. Claude Code 版本 & 能力检测
# =============================================================================
get_claude_version() {
    local ver
    if ver="$(claude --version 2>/dev/null)"; then
        echo "$ver" | grep -oP '\d+\.\d+\.\d+' || echo "0.0.0"
    else
        echo "0.0.0"
    fi
}

CLAUDE_VERSION="$(get_claude_version)"
log_msg "INFO" "Claude Code 版本: $CLAUDE_VERSION"

version_ge() {
    printf '%s\n%s\n' "$2" "$1" | sort -V -C 2>/dev/null || return 1
}

MIN_VERSION_FOR_STREAM="2.0.0"
if ! version_ge "$CLAUDE_VERSION" "$MIN_VERSION_FOR_STREAM"; then
    log_msg "WARN" "当前 Claude Code $CLAUDE_VERSION 不支持流式输出（需要 >= $MIN_VERSION_FOR_STREAM），自动降级"
    NO_STREAM=true
fi

# =============================================================================
# 5. 环境变量设置（UX 增强）
# =============================================================================
declare -A UX_ENV_VARS=(
    ["CLAUDE_CODE_ENABLE_THINKING"]="1"
    ["CLAUDE_CODE_STREAM_DELAY"]="0"
)

declare -A ORIGINAL_ENV_VALUES=()

if [[ "$NO_STREAM" == false ]]; then
    for key in "${!UX_ENV_VARS[@]}"; do
        ORIGINAL_ENV_VALUES[$key]="${!key:-__UNSET__}"
        export "${key}=${UX_ENV_VARS[$key]}"
        log_msg "INFO" "设置环境变量: ${key}=${UX_ENV_VARS[$key]}"
    done
else
    log_msg "INFO" "降级模式：跳过流式输出环境变量设置"
fi

# =============================================================================
# 6. 执行 Claude Code（带超时保护 + 退出码透传）
# =============================================================================
cleanup_env() {
    for key in "${!UX_ENV_VARS[@]}"; do
        if [[ "${ORIGINAL_ENV_VALUES[$key]:-}" == "__UNSET__" ]]; then
            unset "$key"
        else
            export "${key}=${ORIGINAL_ENV_VALUES[$key]}"
        fi
    done
    log_msg "INFO" "环境变量已恢复"
}

trap 'log_msg "WARN" "收到中断信号，正在清理..."; cleanup_env; exit 130' INT TERM

EXIT_CODE=0
START_TIME="$(date +%s)"

STDOUT_TMP="$(mktemp)"
STDERR_TMP="$(mktemp)"
# shellcheck disable=SC2064
trap "rm -f '$STDOUT_TMP' '$STDERR_TMP'" EXIT

log_msg "INFO" "开始执行: claude ${CLAUDE_ARGS[*]:-<无参数>}"

if [[ -n "$PIPE_INPUT" ]]; then
    echo "$PIPE_INPUT" | timeout "$TIMEOUT_SECONDS" claude "${CLAUDE_ARGS[@]}" >"$STDOUT_TMP" 2>"$STDERR_TMP" || true
    EXIT_CODE=${PIPESTATUS[0]:-$?}
else
    timeout "$TIMEOUT_SECONDS" claude "${CLAUDE_ARGS[@]}" >"$STDOUT_TMP" 2>"$STDERR_TMP" || true
    EXIT_CODE=${PIPESTATUS[0]:-$?}
fi

# 超时检测
if [[ $EXIT_CODE -eq 124 ]]; then
    log_msg "ERROR" "执行超时 (${TIMEOUT_SECONDS}s)，已强制终止"
    echo "[claude-stream] 错误: 执行超时 (${TIMEOUT_SECONDS}s)，已强制终止" >&2
fi

# 输出结果
cat "$STDOUT_TMP"
if [[ -s "$STDERR_TMP" ]]; then
    cat "$STDERR_TMP" >&2
fi

# 耗时统计
END_TIME="$(date +%s)"
DURATION=$((END_TIME - START_TIME))
log_msg "INFO" "执行完成，退出码: $EXIT_CODE, 耗时: ${DURATION}s"

# 清理环境变量
cleanup_env

log_msg "INFO" "===== claude-stream 结束 (退出码: $EXIT_CODE) ====="
exit "$EXIT_CODE"
