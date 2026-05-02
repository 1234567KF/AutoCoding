# ============================================================
# claude-stream.ps1 — Claude Code 流式输出 Wrapper (Windows)
# ============================================================
# 功能：以 stream-json 模式运行 claude，实现 <1s 首字反馈
#       解决默认模式 5~30s 黑盒等待问题
#
# 用法：
#   .\claude-stream.ps1 "重构支付模块"
#   .\claude-stream.ps1 -p "你的问题"        # -p: 普通 prompt 模式
#   .\claude-stream.ps1 -PostProcess          # 管道到 claude-fold 折叠
#   claude-stream "问题" | .\claude-fold.ps1  # 流式 + 折叠
#
# 等价原生命令：
#   claude --output-format stream-json --include-partial-messages [参数...]
#
# 依赖：仅需 claude CLI（零额外依赖）
# 兼容：Windows PowerShell 5.1+ / PowerShell Core 6+
# ============================================================

param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs,
    [switch]$PostProcess
)

# 管道后处理模式：将 stdin 传给 claude-fold
if ($PostProcess) {
    if (Test-Path "$PSScriptRoot\claude-fold.ps1") {
        $input | & "$PSScriptRoot\claude-fold.ps1"
    } else {
        Write-Warning "claude-fold.ps1 未找到，原样输出"
        $input | Write-Output
    }
    exit 0
}

# 检查 claude 是否可执行
$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claudeCmd) {
    Write-Error "错误: claude 命令未找到，请确认已安装 Claude Code CLI"
    Write-Error "安装: npm install -g @anthropic-ai/claude-code"
    exit 1
}

# 构建流式参数（始终追加，不与已有参数冲突）
$streamArgs = @(
    '--output-format', 'stream-json',
    '--include-partial-messages'
)

# 合并用户传入的参数
$allArgs = $streamArgs + $RemainingArgs

# 执行 claude，透传退出码
$proc = Start-Process -FilePath "claude" -ArgumentList $allArgs -NoNewWindow -PassThru -Wait
exit $proc.ExitCode
