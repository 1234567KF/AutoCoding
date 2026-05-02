#!/bin/bash
# ============================================================
# claude-fold.sh — Claude Code 输出折叠格式化工具 (Linux/Mac)
# ============================================================
# 功能：对 Claude Code stream-json 输出做语义折叠后处理
#   - Read 类型工具调用折叠为 "[Read: 文件名]"
#   - Write/Edit 工具调用折叠为 "[Edit: 文件名 (+N -M)]"
#   - Bash/长输出截断为前 N 行 + 折叠提示
#   - ANSI 转义码标记折叠区域（终端友好）
#
# 用法：
#   claude-stream "问题" | ./claude-fold.sh
#   claude --output-format stream-json "问题" | ./claude-fold.sh
#   cat transcript.json | ./claude-fold.sh
#
# 环境变量：
#   NO_COLOR=1          禁用 ANSI 色彩输出
#   FOLD_BASH_LINES=N   Bash 输出截断行数（默认 20）
#
# 依赖：bash 3.2+ / sed / grep / awk (POSIX，零外部依赖)
#       注意：不依赖 jq——纯 shell 文本解析
# 兼容：Linux / macOS / WSL / Git Bash
# ============================================================

set -euo pipefail

# ---- 配置 ----
NO_COLOR="${NO_COLOR:-false}"
MAX_BASH_LINES="${FOLD_BASH_LINES:-20}"

# ---- ANSI 转义码（终端友好） ----
if [[ "$NO_COLOR" == "true" || "$NO_COLOR" == "1" ]]; then
    C_RESET=''; C_DIM=''; C_BOLD=''
    C_CYAN=''; C_YELLOW=''; C_GREEN=''; C_BLUE=''
else
    C_RESET=$'\e[0m'
    C_DIM=$'\e[2m'
    C_BOLD=$'\e[1m'
    C_CYAN=$'\e[36m'
    C_YELLOW=$'\e[33m'
    C_GREEN=$'\e[32m'
    C_BLUE=$'\e[34m'
fi

# ---- 工具函数：从 JSON 行提取字符串字段值（纯 sed，无 jq 依赖） ----
extract_str() {
    # $1: 行内容, $2: 字段名
    # 输出字段值（不含外层引号），失败时返回空串
    local line="$1" field="$2" val
    val=$(printf '%s\n' "$line" | sed -n 's/.*"'"$field"'"\s*:\s*"\(\([^"\\]\|\\.\)*\)".*/\1/p' | head -1)
    if [[ -z "$val" ]]; then
        return 1
    fi
    # 解转义：\" -> " , \\ -> \ , \n -> 换行, \t -> 制表
    val="${val//\\\"/\"}"
    val="${val//\\\\/\\}"
    printf '%s' "$val"
    return 0
}

# ---- 提取 file_path（尝试多种字段名） ----
get_filepath() {
    local line="$1" fp
    fp=$(extract_str "$line" "file_path" 2>/dev/null || true)
    [[ -n "$fp" ]] && { printf '%s' "$fp"; return; }
    fp=$(extract_str "$line" "filePath" 2>/dev/null || true)
    [[ -n "$fp" ]] && { printf '%s' "$fp"; return; }
    fp=$(extract_str "$line" "path" 2>/dev/null || true)
    [[ -n "$fp" ]] && { printf '%s' "$fp"; return; }
    printf '%s' "?"
}

# ---- 主处理循环 ----
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && { printf '\n'; continue; }

    # 尝试提取 type 和 name 字段
    etype=$(extract_str "$line" "type" 2>/dev/null || true)
    ename=$(extract_str "$line" "name" 2>/dev/null || true)

    # ---- 折叠 Read 工具调用 ----
    if [[ "$etype" == "tool_use" && "$ename" == "Read" ]]; then
        fp=$(get_filepath "$line")
        fn=$(basename "$fp" 2>/dev/null || printf '%s' "$fp")
        printf '%b\n' "${C_CYAN}[Read: ${fn}]${C_RESET} ${C_DIM}${fp}${C_RESET}"
        continue
    fi

    # ---- 折叠 Write/Edit/MultiEdit 工具调用 ----
    if [[ "$etype" == "tool_use" ]]; then
        case "$ename" in
            Write|Edit|MultiEdit)
                fp=$(get_filepath "$line")
                fn=$(basename "$fp" 2>/dev/null || printf '%s' "$fp")
                printf '%b\n' "${C_GREEN}[Edit: ${fn}]${C_RESET} ${C_DIM}${fp}${C_RESET}"
                continue
                ;;
            Bash)
                cmd=$(extract_str "$line" "command" 2>/dev/null || printf '%s' "?")
                if [[ ${#cmd} -gt 80 ]]; then cmd="${cmd:0:77}..."; fi
                printf '%b\n' "${C_YELLOW}[Bash: ${cmd}]${C_RESET}"
                continue
                ;;
        esac
    fi

    # ---- 截断工具结果中的长输出（tool_result 类型） ----
    if [[ "$etype" == "tool_result" ]]; then
        content=$(extract_str "$line" "content" 2>/dev/null || true)
        if [[ -n "$content" ]]; then
            line_count=$(printf '%s\n' "$content" | wc -l | tr -d ' ')
            if [[ "$line_count" -gt "$MAX_BASH_LINES" ]]; then
                printf '%s\n' "$content" | head -n "$MAX_BASH_LINES"
                local hidden=$(( line_count - MAX_BASH_LINES ))
                printf '%b\n' "${C_YELLOW}[... +${hidden} 行已折叠, ctrl+o 展开完整输出]${C_RESET}"
            else
                printf '%s\n' "$content"
            fi
            continue
        fi
    fi

    # ---- 默认：原样输出 ----
    printf '%s\n' "$line"
done
