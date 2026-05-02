# ============================================================
# claude-fold.ps1 — Claude Code 输出折叠格式化工具 (Windows)
# ============================================================
# 功能：对 Claude Code stream-json 输出做语义折叠后处理
#   - Read 类型工具调用折叠为 "[Read: 文件名]"
#   - Write/Edit 工具调用折叠为 "[Edit: 文件名 (+N -M)]"
#   - Bash/长输出截断为前 N 行 + 折叠提示
#   - ANSI 转义码标记折叠区域（终端友好）
#
# 用法：
#   claude-stream "问题" | .\claude-fold.ps1
#   claude --output-format stream-json "问题" | .\claude-fold.ps1
#   Get-Content transcript.json | .\claude-fold.ps1
#
# 选项：
#   -MaxBashLines N     Bash 输出截断行数（默认 20）
#   -NoColor            禁用 ANSI 色彩
#
# 依赖：纯 PowerShell，零外部依赖
# 兼容：Windows PowerShell 5.1+ / PowerShell Core 6+
# ============================================================

param(
    [Parameter(ValueFromPipeline = $true)]
    [string]$InputLine,

    [int]$MaxBashLines = 20,
    [switch]$NoColor
)

begin {
    $ESC = [char]27
    $C_RESET  = if ($NoColor) { "" } else { "$ESC[0m" }
    $C_DIM    = if ($NoColor) { "" } else { "$ESC[2m" }
    $C_BOLD   = if ($NoColor) { "" } else { "$ESC[1m" }
    $C_CYAN   = if ($NoColor) { "" } else { "$ESC[36m" }
    $C_YELLOW = if ($NoColor) { "" } else { "$ESC[33m" }
    $C_GREEN  = if ($NoColor) { "" } else { "$ESC[32m" }
    $C_BLUE   = if ($NoColor) { "" } else { "$ESC[34m" }

    # 状态：跟踪当前是否在 Bash 输出块中
    $script:BashBlock = $false
    $script:BashLines = [System.Collections.ArrayList]::new()
}

process {
    if (-not $InputLine) { return }

    try {
        $obj = $InputLine | ConvertFrom-Json -ErrorAction Stop

        # ---- 折叠 Read 工具调用 ----
        if ($obj.type -eq 'tool_use' -and $obj.name -eq 'Read') {
            # 兼容 PS5.1：不使用 ?? 运算符
            $fp = if ($obj.input.file_path) { $obj.input.file_path }
                  elseif ($obj.input.path) { $obj.input.path }
                  else { '?' }
            $fn = Split-Path $fp -Leaf
            Write-Output "${C_CYAN}[Read: $fn]${C_RESET} ${C_DIM}$fp${C_RESET}"
            return
        }

        # ---- 折叠 Write/Edit/MultiEdit 工具调用 ----
        if ($obj.type -eq 'tool_use' -and ($obj.name -eq 'Write' -or $obj.name -eq 'Edit' -or $obj.name -eq 'MultiEdit')) {
            $fp = if ($obj.input.file_path) { $obj.input.file_path }
                  elseif ($obj.input.path) { $obj.input.path }
                  else { '?' }
            $fn = Split-Path $fp -Leaf
            Write-Output "${C_GREEN}[Edit: $fn]${C_RESET} ${C_DIM}$fp${C_RESET}"
            return
        }

        # ---- 折叠 Bash 工具调用（显示命令摘要） ----
        if ($obj.type -eq 'tool_use' -and $obj.name -eq 'Bash') {
            $cmd = if ($obj.input.command) { $obj.input.command } else { '' }
            if ($cmd.Length -gt 80) { $cmd = $cmd.Substring(0, 77) + '...' }
            Write-Output "${C_YELLOW}[Bash: $cmd]${C_RESET}"
            return
        }

        # ---- 截断工具结果中的长输出 ----
        if ($obj.type -eq 'tool_result') {
            $out = if ($obj.content) { $obj.content } else { '' }
            $lines = $out -split "`n"
            if ($lines.Count -gt $MaxBashLines) {
                $preview = ($lines[0..($MaxBashLines-1)] -join "`n")
                Write-Output $preview
                $hidden = $lines.Count - $MaxBashLines
                Write-Output "${C_YELLOW}[... +${hidden} 行已折叠, ctrl+o 展开完整输出]${C_RESET}"
            } else {
                Write-Output $out
            }
            return
        }

        # ---- 高亮普通文本输出 ----
        if ($obj.type -eq 'content_block_delta' -and $obj.delta.type -eq 'text_delta') {
            Write-Host -NoNewline $obj.delta.text
            return
        }

        # ---- 其他：原样输出 ----
        Write-Output $InputLine

    } catch {
        # 非 JSON 行：原样透传
        Write-Output $InputLine
    }
}

end {
    Write-Output ""
}
