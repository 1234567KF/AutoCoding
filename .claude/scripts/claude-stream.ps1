# =============================================================================
# claude-stream.ps1 — Claude Code 流式输出包装器 (Windows PowerShell)
# 绿队安全版 v2.0：参数校验 / 超时保护 / 降级回滚 / 日志记录 / 注入检测
# =============================================================================
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs,

    # === 安全参数 ===
    [ValidateRange(1, 3600)]
    [int]$TimeoutSeconds = 600,          # 超时保护，默认 10 分钟

    [ValidateRange(1, 1048576)]
    [int]$MaxInputBytes = 1048576,       # 输入大小限制，默认 1MB

    [string]$LogFile = "",               # 自定义日志路径，默认自动生成

    [switch]$NoStream = $false,          # 强制禁用流式输出（降级模式）
    [switch]$VerboseLog = $false         # 详细日志
)

# =============================================================================
# 0. 初始化：路径 & 日志
# =============================================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptDir "..\..")
$LogDir = Join-Path $ProjectRoot ".claude\logs"

# 确保日志目录存在
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

if ([string]::IsNullOrEmpty($LogFile)) {
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $LogFile = Join-Path $LogDir "claude-stream_${Timestamp}.log"
}

function Write-Log {
    param([string]$Level, [string]$Message)
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $LogLine = "[$TimeStamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogLine -Encoding UTF8
    if ($VerboseLog) {
        Write-Host $LogLine
    }
}

Write-Log "INFO" "===== claude-stream 启动 (绿队安全版) ====="
Write-Log "INFO" "项目路径: $ProjectRoot"
Write-Log "INFO" "超时设置: ${TimeoutSeconds}s"
Write-Log "INFO" "输入限制: ${MaxInputBytes} bytes"

# =============================================================================
# 1. 参数校验（防止注入）
# =============================================================================
function Test-SafeArgument {
    param([string]$Arg)
    $DangerousPatterns = @(
        '`',                           # PowerShell 转义
        '\$\(',                        # 子表达式
        ';&',                          # 命令链
        '\|',                          # 管道注入
        '>',                           # 重定向
        '<',                           # 输入重定向
        '&&'                           # cmd 链
    )
    foreach ($Pattern in $DangerousPatterns) {
        if ($Arg -match $Pattern) {
            Write-Log "WARN" "疑似注入参数被清理: '$Arg' (匹配: '$Pattern')"
            $Global:InjectionWarning = $true
            return $Arg -replace [regex]::Escape($Pattern), ''
        }
    }
    return $Arg
}

$SafeArgs = @()
$Global:InjectionWarning = $false
foreach ($Arg in $RemainingArgs) {
    $SafeArgs += Test-SafeArgument -Arg $Arg
}

$TotalArgLength = ($SafeArgs -join ' ').Length
if ($TotalArgLength -gt 10000) {
    Write-Log "ERROR" "参数总长度超出限制: ${TotalArgLength} > 10000，疑似注入攻击，已拒绝"
    Write-Host "[claude-stream] 错误: 参数过长（>10000字符），已拒绝执行" -ForegroundColor Red
    exit 1
}

# 明文凭据检测（记录警告但不中断）
$ArgString = $SafeArgs -join ' '
if ($ArgString -match '(?i)(api[_-]?key|apikey|secret|token|password|passwd)\s*[=:]\s*\S+') {
    Write-Log "WARN" "命令行参数中检测到凭据模式。请使用环境变量传递凭据。"
    Write-Host "[claude-stream] 警告: 命令行参数中检测到可能的凭据。请通过环境变量或 stdin 传递。" -ForegroundColor Yellow
}
if ($ArgString -match '(?i)(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16})') {
    Write-Log "WARN" "检测到已知 API Key/Token 格式"
    Write-Host "[claude-stream] 警告: 检测到 API Key/Token 模式" -ForegroundColor Yellow
}

# =============================================================================
# 2. 输入大小校验（stdin）
# =============================================================================
$StdinContent = ""
if ([Console]::IsInputRedirected) {
    try {
        $StdinContent = [Console]::In.ReadToEnd()
    } catch {
        Write-Log "ERROR" "读取 stdin 失败: $_"
    }
}
if ($StdinContent.Length -gt $MaxInputBytes) {
    Write-Log "ERROR" "stdin 输入超出限制: $($StdinContent.Length) > $MaxInputBytes"
    Write-Host "[claude-stream] 错误: 输入过大（>$MaxInputBytes bytes），已拒绝处理" -ForegroundColor Red
    exit 2
}

# =============================================================================
# 3. 版本兼容性检测
# =============================================================================
function Get-ClaudeVersion {
    try {
        $v = claude --version 2>&1
        if ($LASTEXITCODE -eq 0 -and $v -match '(\d+\.\d+\.\d+)') {
            return $Matches[1]
        }
    } catch {
        Write-Log "WARN" "无法获取 Claude Code 版本: $_"
    }
    return "0.0.0"
}

$ClaudeVersion = Get-ClaudeVersion
Write-Log "INFO" "Claude Code 版本: $ClaudeVersion"

try {
    if ([version]$ClaudeVersion -lt [version]"2.0.0") {
        Write-Log "WARN" "当前版本 $ClaudeVersion 过低（需要 >= 2.0.0），自动降级为普通模式"
        $NoStream = $true
    }
} catch {
    Write-Log "WARN" "版本比较失败，保守降级为普通模式"
    $NoStream = $true
}

# =============================================================================
# 4. 环境变量设置（UX 增强）
# =============================================================================
$OriginalEnv = @{}
$UxEnvVars = @{
    'CLAUDE_CODE_ENABLE_THINKING' = '1'      # 显示 Thinking 过程
    'CLAUDE_CODE_STREAM_DELAY'    = '0'      # 无延迟流式输出
}

if (-not $NoStream) {
    foreach ($Key in $UxEnvVars.Keys) {
        $OriginalEnv[$Key] = [Environment]::GetEnvironmentVariable($Key, 'Process')
        [Environment]::SetEnvironmentVariable($Key, $UxEnvVars[$Key], 'Process')
        Write-Log "INFO" "设置环境变量: ${Key}=${UxEnvVars[$Key]}"
    }
} else {
    Write-Log "INFO" "降级模式：跳过流式输出环境变量设置"
}

# =============================================================================
# 5. 执行 Claude Code（带超时保护 + 退出码透传）
# =============================================================================
$ExitCode = 0
$StartTime = Get-Date

try {
    if ($StdinContent.Length -gt 0) {
        Write-Log "INFO" "stdin 输入长度: $($StdinContent.Length) 字符"
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "claude"
    $psi.Arguments = $SafeArgs -join ' '
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = ($StdinContent.Length -gt 0)
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = $ProjectRoot

    if (-not $NoStream) {
        foreach ($Key in $UxEnvVars.Keys) {
            $psi.EnvironmentVariables[$Key] = $UxEnvVars[$Key]
        }
    }

    $Process = [System.Diagnostics.Process]::Start($psi)

    if ($StdinContent.Length -gt 0) {
        $Process.StandardInput.Write($StdinContent)
        $Process.StandardInput.Close()
    }

    $TimeoutReached = -not $Process.WaitForExit($TimeoutSeconds * 1000)

    if ($TimeoutReached) {
        Write-Log "ERROR" "执行超时 (${TimeoutSeconds}s)，正在终止进程..."
        Write-Host "[claude-stream] 错误: 执行超时 (${TimeoutSeconds}s)，已强制终止" -ForegroundColor Red

        try {
            $Process.Kill()
            $Process.WaitForExit(5000)
        } catch {
            Write-Log "ERROR" "终止进程失败: $_"
        }

        # 输出已有的 stdout/stderr
        $RemainingOut = $Process.StandardOutput.ReadToEnd()
        $RemainingErr = $Process.StandardError.ReadToEnd()
        if ($RemainingOut) { Write-Host $RemainingOut }
        if ($RemainingErr) { Write-Host $RemainingErr -ForegroundColor Red }

        $ExitCode = 124
    } else {
        $ExitCode = $Process.ExitCode
        Write-Log "INFO" "执行完成，退出码: $ExitCode"
    }

    $Duration = (Get-Date) - $StartTime
    Write-Log "INFO" "耗时: $($Duration.TotalSeconds.ToString('F2'))s"

} catch {
    Write-Log "ERROR" "执行异常: $_"
    Write-Host "[claude-stream] 致命错误: $_" -ForegroundColor Red
    $ExitCode = 255
}

# =============================================================================
# 6. 清理：恢复原始环境变量
# =============================================================================
foreach ($Key in $UxEnvVars.Keys) {
    if ($OriginalEnv.ContainsKey($Key) -and $OriginalEnv[$Key] -ne $null) {
        [Environment]::SetEnvironmentVariable($Key, $OriginalEnv[$Key], 'Process')
    } else {
        [Environment]::SetEnvironmentVariable($Key, $null, 'Process')
    }
}
Write-Log "INFO" "环境变量已恢复"

# =============================================================================
# 7. 退出码正确传递
# =============================================================================
Write-Log "INFO" "===== claude-stream 结束 (退出码: $ExitCode) ====="
exit $ExitCode
