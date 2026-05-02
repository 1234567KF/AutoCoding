#!/bin/bash
# ============================================================
# claude-stream.sh — Claude Code 流式输出 Wrapper (Linux/Mac)
# ============================================================
# 功能：以 stream-json 模式运行 claude，实现 <1s 首字反馈
#       解决默认模式 5~30s 黑盒等待问题
#
# 用法：
#   ./claude-stream.sh "重构支付模块"
#   ./claude-stream.sh -p "你的问题"
#   ./claude-stream.sh --post-process             # 管道到 claude-fold
#   claude-stream "问题" | ./claude-fold.sh       # 流式 + 折叠
#
# 安装 alias（可选）:
#   alias claude-stream='D:/AutoCoding/.claude/scripts/claude-stream.sh'
#
# 等价原生命令：
#   claude --output-format stream-json --include-partial-messages [参数...]
#
# 依赖：仅需 claude CLI（零额外依赖）
# 兼容：bash 3.2+ / zsh 5+ / Git Bash / WSL
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 管道后处理模式：将 stdin 传给 claude-fold
if [[ "${1:-}" == "-p" || "${1:-}" == "--post-process" ]]; then
    shift
    if [[ -x "$SCRIPT_DIR/claude-fold.sh" ]]; then
        exec "$SCRIPT_DIR/claude-fold.sh" "$@"
    else
        echo "警告: claude-fold.sh 未找到或不可执行，原样输出" >&2
        cat
    fi
    exit $?
fi

# 检查 claude 是否可执行
if ! command -v claude &> /dev/null; then
    echo "错误: claude 命令未找到，请确认已安装 Claude Code CLI" >&2
    echo "安装: npm install -g @anthropic-ai/claude-code" >&2
    exit 1
fi

# 使用 exec 透传所有参数到 claude（含流式标志）
exec claude --output-format stream-json --include-partial-messages "$@"
