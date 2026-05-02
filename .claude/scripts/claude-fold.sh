#!/usr/bin/env bash
# =============================================================================
# claude-fold.sh — Claude Code 输出折叠格式化工具 (Linux/macOS)
# 绿队安全版 v2.0：输入限制 / 管道支持 / ANSI降级 / 敏感信息过滤 / 错误处理
# =============================================================================
set -euo pipefail

# =============================================================================
# 0. 默认值
# =============================================================================
MAX_INPUT_BYTES=10485760        # 默认 10MB
FOLD_WIDTH=80                   # 默认折叠行宽 80 字符
MAX_LINES=500                   # 默认最大输出行数
PLAIN_TEXT=false                # 是否强制纯文本
NO_FILTERING=false              # 是否跳过敏感信息过滤
OUTPUT_FILE=""                  # 输出文件路径
FORCE_ANSI="${CLAUDE_FOLD_FORCE_ANSI:-0}"

# =============================================================================
# 1. 使用说明
# =============================================================================
usage() {
    cat <<'EOF'
claude-fold.sh -- Claude Code 输出折叠格式化工具

用法:
  claude output.txt | claude-fold.sh           # 管道输入
  claude-fold.sh output.txt                    # 文件输入
  claude-fold.sh --plain-text < input.txt      # 强制纯文本模式

选项:
  --help, -h          显示此帮助
  --max-input N       输入大小限制 bytes (默认 10MB)
  --width N           折叠行宽字符数 (默认 80)
  --max-lines N       最大输出行数 (默认 500)
  --output FILE       输出到文件
  --plain-text        强制纯文本输出（无 ANSI 颜色）
  --no-filter         跳过敏感信息过滤（不推荐）
  --version           显示版本

环境变量:
  CLAUDE_FOLD_FORCE_ANSI=1    强制 ANSI 输出（即使输出被重定向）

安全特性: 输入大小限制 | 敏感信息过滤 | ANSI降级 | 内存保护
EOF
}

# 参数解析
INPUT_FILE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --version) echo "claude-fold.sh v2.0.0 (绿队安全版)"; exit 0 ;;
        --max-input) MAX_INPUT_BYTES="$2"; shift 2 ;;
        --width) FOLD_WIDTH="$2"; shift 2 ;;
        --max-lines) MAX_LINES="$2"; shift 2 ;;
        --output) OUTPUT_FILE="$2"; shift 2 ;;
        --plain-text) PLAIN_TEXT=true; shift ;;
        --no-filter) NO_FILTERING=true; shift ;;
        -*) echo "[claude-fold] 未知选项: $1" >&2; usage >&2; exit 1 ;;
        *) INPUT_FILE="$1"; shift ;;
    esac
done

# 参数合法性校验
if ! [[ "$MAX_INPUT_BYTES" =~ ^[0-9]+$ ]] || [[ "$MAX_INPUT_BYTES" -gt 104857600 ]]; then
    echo "[claude-fold] 错误: --max-input 必须是 1-104857600 之间的整数" >&2
    exit 1
fi
if ! [[ "$FOLD_WIDTH" =~ ^[0-9]+$ ]] || [[ "$FOLD_WIDTH" -lt 10 ]] || [[ "$FOLD_WIDTH" -gt 10000 ]]; then
    echo "[claude-fold] 错误: --width 必须是 10-10000 之间的整数" >&2
    exit 1
fi
if ! [[ "$MAX_LINES" =~ ^[0-9]+$ ]] || [[ "$MAX_LINES" -lt 1 ]] || [[ "$MAX_LINES" -gt 100000 ]]; then
    echo "[claude-fold] 错误: --max-lines 必须是 1-100000 之间的整数" >&2
    exit 1
fi

# =============================================================================
# 2. 终端能力检测（ANSI 支持）
# =============================================================================
detect_ansi_support() {
    if [[ "$PLAIN_TEXT" == true ]]; then return 1; fi
    if [[ "$FORCE_ANSI" == "1" ]]; then return 0; fi
    if [[ ! -t 1 ]]; then return 1; fi
    case "${TERM:-dumb}" in
        dumb|""|*mono*) return 1 ;;
        *) return 0 ;;
    esac
}

ANSI_SUPPORTED=false
if detect_ansi_support; then
    ANSI_SUPPORTED=true
else
    if [[ "$PLAIN_TEXT" == false ]]; then
        echo "[claude-fold] 终端不支持 ANSI，自动降级为纯文本模式" >&2
    fi
fi

# =============================================================================
# 3. 读取输入
# =============================================================================
INPUT_CONTENT=""

if [[ -n "$INPUT_FILE" ]]; then
    if [[ ! -f "$INPUT_FILE" ]]; then
        echo "[claude-fold] 错误: 文件不存在: $INPUT_FILE" >&2
        exit 1
    fi
    if [[ ! -r "$INPUT_FILE" ]]; then
        echo "[claude-fold] 错误: 文件不可读: $INPUT_FILE" >&2
        exit 1
    fi
    # 获取文件大小（兼容 macOS/Linux）
    FILE_SIZE=$(stat -f%z "$INPUT_FILE" 2>/dev/null || stat -c%s "$INPUT_FILE" 2>/dev/null || echo 0)
    if [[ "$FILE_SIZE" -gt "$MAX_INPUT_BYTES" ]]; then
        echo "[claude-fold] 文件过大 (${FILE_SIZE} bytes)，超过限制 (${MAX_INPUT_BYTES} bytes)，仅读取前 ${MAX_INPUT_BYTES} bytes" >&2
        INPUT_CONTENT="$(head -c "$MAX_INPUT_BYTES" "$INPUT_FILE" 2>/dev/null || dd bs=1 count="$MAX_INPUT_BYTES" 2>/dev/null < "$INPUT_FILE")"
    else
        INPUT_CONTENT="$(cat "$INPUT_FILE")"
    fi
elif [[ ! -t 0 ]]; then
    INPUT_CONTENT="$(head -c "$MAX_INPUT_BYTES" 2>/dev/null || dd bs=1 count="$MAX_INPUT_BYTES" 2>/dev/null)"
    ACTUAL_SIZE=$(echo -n "$INPUT_CONTENT" | wc -c)
    if [[ "$ACTUAL_SIZE" -ge "$MAX_INPUT_BYTES" ]]; then
        echo "[claude-fold] 输入超出限制 (${MAX_INPUT_BYTES} bytes)，已截断" >&2
    fi
else
    exit 0
fi

if [[ -z "$INPUT_CONTENT" ]]; then
    exit 0
fi

# =============================================================================
# 4. 敏感信息过滤
# =============================================================================
filter_sensitive_data() {
    local content="$1"

    if [[ "$NO_FILTERING" == true ]]; then
        echo "$content"
        return
    fi

    # API Key 环境变量赋值
    content="$(echo "$content" | sed -E 's/(api[_-]?key|apikey|secret[_-]?key)[=:][[:space:]]*["'"'"']?[^[:space:]"'"'"']+["'"'"']?/\1=<REDACTED>/gi')"

    # 各种 Token 格式
    content="$(echo "$content" | sed -E 's/sk-[a-zA-Z0-9_-]{20,}/sk-<REDACTED>/g')"
    content="$(echo "$content" | sed -E 's/sk-ant-[a-zA-Z0-9_-]{20,}/sk-ant-<REDACTED>/g')"
    content="$(echo "$content" | sed -E 's/ghp_[a-zA-Z0-9]{20,}/ghp_<REDACTED>/g')"
    content="$(echo "$content" | sed -E 's/github_pat_[a-zA-Z0-9_]{20,}/github_pat_<REDACTED>/g')"
    content="$(echo "$content" | sed -E 's/AKIA[0-9A-Z]{16}/AKIA<REDACTED>/g')"
    content="$(echo "$content" | sed -E 's/Bearer[[:space:]]+[a-zA-Z0-9._\-+=]{20,}/Bearer <REDACTED>/g')"
    content="$(echo "$content" | sed -E 's/(token|access[_-]?token|auth[_-]?token)[=:][[:space:]]*["'"'"']?[^[:space:]"'"'"']+["'"'"']?/\1=<REDACTED>/gi')"

    # JWT Token
    content="$(echo "$content" | sed -E 's/eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+/<JWT_REDACTED>/g')"

    # 私钥块（跨行）
    content="$(echo "$content" | sed -E '/-----BEGIN (RSA |EC |OPENSSH |)PRIVATE KEY-----/,/-----END (RSA |EC |OPENSSH |)PRIVATE KEY-----/c\<PRIVATE_KEY_REDACTED>')"

    echo "$content"
}

FILTERED_CONTENT="$(filter_sensitive_data "$INPUT_CONTENT")"

# =============================================================================
# 5. 输出折叠格式化
# =============================================================================
format_folded_output() {
    local content="$1" width="$2" use_ansi="$3"
    local total_lines truncated=false line_count=0
    total_lines=$(echo "$content" | wc -l | tr -d ' ')

    local CYAN='' RESET='' GRAY='' YELLOW=''
    local FOLD_ARROW='->' CONT_ARROW='>'
    if [[ "$use_ansi" == true ]]; then
        CYAN=$'\e[36m'
        RESET=$'\e[0m'
        GRAY=$'\e[90m'
        YELLOW=$'\e[33m'
    fi

    local output=""

    while IFS= read -r line; do
        line_count=$((line_count + 1))
        if [[ "$line_count" -gt "$MAX_LINES" ]]; then
            truncated=true
            break
        fi

        local remaining="$line"
        local is_first=true

        while [[ -n "$remaining" ]]; do
            if [[ ${#remaining} -le $width ]]; then
                local part="$remaining"
                remaining=""
            else
                local chunk="${remaining:0:$width}"
                local space_pos
                space_pos=$(echo "$chunk" | grep -ob ' ' | tail -1 | cut -d: -f1 2>/dev/null || echo "")
                if [[ -n "$space_pos" ]] && [[ "$space_pos" -gt 0 ]]; then
                    part="${remaining:0:$space_pos}"
                    remaining="${remaining:$((space_pos + 1))}"
                else
                    part="$chunk"
                    remaining="${remaining:$width}"
                fi
            fi

            if [[ "$is_first" == true ]]; then
                if [[ "$use_ansi" == true ]]; then
                    output+="${CYAN}${line_count}${RESET} ${part} ${GRAY}${FOLD_ARROW}${RESET}"$'\n'
                else
                    output+="${line_count} ${part} ->"$'\n'
                fi
                is_first=false
            else
                output+="  ${CONT_ARROW} ${part}"$'\n'
            fi
        done
    done <<< "$content"

    if [[ "$truncated" == true ]]; then
        local trunc_msg="... (输出已截断，共 ${total_lines} 行，仅显示前 ${MAX_LINES} 行)"
        if [[ "$use_ansi" == true ]]; then
            output+="${YELLOW}${trunc_msg}${RESET}"$'\n'
        else
            output+="${trunc_msg}"$'\n'
        fi
    fi

    echo -n "$output"
}

FORMATTED="$(format_folded_output "$FILTERED_CONTENT" "$FOLD_WIDTH" "$ANSI_SUPPORTED")"

# =============================================================================
# 6. 输出
# =============================================================================
if [[ -n "$OUTPUT_FILE" ]]; then
    CLEAN_OUTPUT="$(echo "$FORMATTED" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')"
    echo "$CLEAN_OUTPUT" > "$OUTPUT_FILE" || {
        echo "[claude-fold] 错误: 写入文件失败: $OUTPUT_FILE" >&2
        exit 1
    }
    echo "[claude-fold] 已输出到: $OUTPUT_FILE" >&2
else
    echo "$FORMATTED"
fi

exit 0
