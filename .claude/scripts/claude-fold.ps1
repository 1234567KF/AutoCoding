# =============================================================================
# claude-fold.ps1 — Claude Code 输出折叠格式化工具 (Windows PowerShell)
# 绿队安全版 v2.0：输入限制 / 管道支持 / ANSI降级 / 敏感信息过滤 / 错误处理
# =============================================================================
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs,

    # === 安全参数 ===
    [ValidateRange(1, 104857600)]
    [int]$MaxInputBytes = 10485760,       # 输入限制，默认 10MB

    [ValidateRange(10, 10000)]
    [int]$FoldLength = 80,               # 折叠行宽，默认 80 字符

    [ValidateRange(1, 1000)]
    [int]$MaxLines = 500,                # 最大输出行数

    [string]$OutputFile = "",            # 输出到文件

    [switch]$PlainText = $false,         # 强制纯文本（不用 ANSI）
    [switch]$NoFiltering = $false,       # 跳过敏感信息过滤（不推荐）
    [switch]$DetectAnsi = $true          # 自动检测终端 ANSI 支持
)

# =============================================================================
# 0. 初始化 & 帮助
# =============================================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($RemainingArgs -contains '--help' -or $RemainingArgs -contains '-h') {
    Write-Host @'
claude-fold.ps1 — Claude Code 输出折叠格式化工具

用法:
  claude output.txt | claude-fold.ps1          # 管道输入
  claude-fold.ps1 -InputFile output.txt         # 文件输入
  claude-fold.ps1 -PlainText                    # 强制纯文本模式

选项:
  --help, -h          显示此帮助
  -MaxInputBytes N    输入大小限制 bytes (默认 10MB)
  -FoldLength N       折叠行宽字符数 (默认 80)
  -MaxLines N         最大输出行数 (默认 500)
  -OutputFile PATH    输出到文件
  -PlainText          强制纯文本输出（无 ANSI 颜色）
  -NoFiltering        跳过敏感信息过滤（不推荐）

安全特性: 输入大小限制 | 敏感信息过滤 | ANSI降级 | 内存保护
'@
    exit 0
}

# =============================================================================
# 1. 终端能力检测（ANSI 支持）
# =============================================================================
function Test-AnsiSupport {
    if ($PlainText) { return $false }

    # 检查是否是重定向输出
    if ([Console]::IsOutputRedirected) {
        if ($env:CLAUDE_FOLD_FORCE_ANSI -eq '1') { return $true }
        return $false
    }

    # Windows Terminal / ConEmu / Cmder
    if ($env:WT_SESSION -or $env:ConEmuANSI -or $env:CMDER_ROOT) {
        return $true
    }

    # PowerShell 5.1+
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        return $true
    }

    # Windows 10 1511+
    try {
        $OsVersion = [Environment]::OSVersion.Version
        if ($OsVersion.Major -ge 10 -and $OsVersion.Build -ge 10586) {
            return $true
        }
    } catch { }

    return $false
}

$AnsiSupported = Test-AnsiSupport
if (-not $AnsiSupported -and -not $PlainText) {
    Write-Warning "[claude-fold] 终端不支持 ANSI，自动降级为纯文本模式"
}

# =============================================================================
# 2. 读取输入（管道 or 文件）
# =============================================================================
$InputContent = ""

function Read-FileSafe {
    param([string]$Path, [int]$MaxSize = 10485760)

    if (-not (Test-Path $Path)) {
        Write-Warning "[claude-fold] 文件不存在: $Path"
        return ""
    }

    try {
        $FileSize = (Get-Item $Path).Length
        if ($FileSize -gt $MaxSize) {
            Write-Warning "[claude-fold] 文件过大 (${FileSize} bytes)，超过限制 (${MaxSize} bytes)，仅读取前 ${MaxSize} bytes"
            $Stream = [System.IO.File]::OpenRead($Path)
            $Reader = New-Object System.IO.StreamReader($Stream)
            $Content = $Reader.ReadToEndExact($MaxSize)
            $Reader.Close()
            $Stream.Close()
            return $Content
        }
        return Get-Content -Path $Path -Raw -Encoding UTF8
    } catch {
        Write-Warning "[claude-fold] 读取文件失败: $_"
        return ""
    }
}

if (-not [Console]::IsInputRedirected) {
    # 无管道：检查文件参数
    $FirstArg = $RemainingArgs | Select-Object -First 1
    if ($FirstArg -and (Test-Path $FirstArg)) {
        $InputContent = Read-FileSafe -Path $FirstArg -MaxSize $MaxInputBytes
    }
} else {
    try {
        # 管道模式：逐行读取直到达到限制
        $Sb = [System.Text.StringBuilder]::new()
        $ByteCount = 0
        while (($Line = [Console]::In.ReadLine()) -ne $null) {
            $LineBytes = [System.Text.Encoding]::UTF8.GetByteCount($Line)
            if (($ByteCount + $LineBytes) -gt $MaxInputBytes) {
                Write-Warning "[claude-fold] 输入超出限制 (${MaxInputBytes} bytes)，已截断"
                break
            }
            [void]$Sb.AppendLine($Line)
            $ByteCount += $LineBytes
        }
        $InputContent = $Sb.ToString()
    } catch {
        Write-Warning "[claude-fold] 读取管道输入失败: $_"
        $InputContent = ""
    }
}

if ([string]::IsNullOrEmpty($InputContent)) {
    exit 0
}

# =============================================================================
# 3. 敏感信息过滤
# =============================================================================
function Protect-SensitiveData {
    param([string]$Content)

    if ($NoFiltering) { return $Content }

    $Result = $Content

    # API Key 格式
    $Result = $Result -replace '(?i)(api[_-]?key|apikey|secret[_-]?key)\s*[=:]\s*["''`]?([^\s"'']+)["''`]?', '${1}=<REDACTED>'
    $Result = $Result -replace '(?i)sk-[a-zA-Z0-9_-]{20,}', 'sk-<REDACTED>'
    $Result = $Result -replace '(?i)sk-ant-[a-zA-Z0-9_-]{20,}', 'sk-ant-<REDACTED>'
    $Result = $Result -replace '(?i)ghp_[a-zA-Z0-9]{20,}', 'ghp_<REDACTED>'
    $Result = $Result -replace '(?i)github_pat_[a-zA-Z0-9_]{20,}', 'github_pat_<REDACTED>'
    $Result = $Result -replace '(?i)AKIA[0-9A-Z]{16}', 'AKIA<REDACTED>'
    $Result = $Result -replace '(?i)Bearer\s+[a-zA-Z0-9._\-+=]{20,}', 'Bearer <REDACTED>'
    $Result = $Result -replace '(?i)(token|access[_-]?token|auth[_-]?token)\s*[=:]\s*["''`]?([^\s"'']+)["''`]?', '${1}=<REDACTED>'
    # JWT Token
    $Result = $Result -replace 'eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+', '<JWT_REDACTED>'
    # 私钥块
    $Result = $Result -replace '-----BEGIN (RSA |EC |OPENSSH |)PRIVATE KEY-----[\s\S]*?-----END (RSA |EC |OPENSSH |)PRIVATE KEY-----', '<PRIVATE_KEY_REDACTED>'

    return $Result
}

$FilteredContent = Protect-SensitiveData -Content $InputContent

# =============================================================================
# 4. 输出折叠格式化
# =============================================================================
function Format-FoldedOutput {
    param(
        [string]$Content,
        [int]$Width = 80,
        [bool]$UseAnsiColor = $false
    )

    $Lines = $Content -split "`r?`n"
    $TotalLines = $Lines.Count
    $OutputLines = @()
    $Truncated = $false

    if ($TotalLines -gt $MaxLines) {
        $Lines = $Lines | Select-Object -First $MaxLines
        $Truncated = $true
    }

    $LineNum = 0
    foreach ($Line in $Lines) {
        $LineNum++

        if ($Line.Length -gt $Width) {
            $Remaining = $Line
            $PartNum = 0
            $IsFirstPart = $true

            while ($Remaining.Length -gt 0) {
                if ($Remaining.Length -le $Width) {
                    $Part = $Remaining
                    $Remaining = ""
                } else {
                    $Chunk = $Remaining.Substring(0, [Math]::Min($Width, $Remaining.Length))
                    $LastSpace = $Chunk.LastIndexOf(' ')
                    if ($LastSpace -gt 0) {
                        $Part = $Remaining.Substring(0, $LastSpace)
                        $Remaining = $Remaining.Substring($LastSpace + 1)
                    } else {
                        $Part = $Chunk
                        $Remaining = $Remaining.Substring($Width)
                    }
                }

                $PartNum++
                if ($IsFirstPart) {
                    if ($UseAnsiColor) {
                        $OutputLines += "$([char]0x1B)[36m${LineNum}$([char]0x1B)[0m $Part $([char]0x1B)[90m->$([char]0x1B)[0m"
                    } else {
                        $OutputLines += "$LineNum $Part ->"
                    }
                    $IsFirstPart = $false
                } else {
                    $ContPrefix = if ($UseAnsiColor) { "$([char]0x1B)[90m  >$([char]0x1B)[0m " } else { "  > " }
                    $OutputLines += "${ContPrefix}${Part}"
                }
            }
        } else {
            if ($UseAnsiColor) {
                $OutputLines += "$([char]0x1B)[36m${LineNum}$([char]0x1B)[0m $Line"
            } else {
                $OutputLines += "$LineNum $Line"
            }
        }
    }

    if ($Truncated) {
        $TruncMsg = "... (输出已截断，共 $TotalLines 行，仅显示前 $MaxLines 行)"
        if ($UseAnsiColor) {
            $OutputLines += "$([char]0x1B)[33m${TruncMsg}$([char]0x1B)[0m"
        } else {
            $OutputLines += $TruncMsg
        }
    }

    return $OutputLines -join "`n"
}

$Formatted = Format-FoldedOutput -Content $FilteredContent -Width $FoldLength -UseAnsiColor $AnsiSupported

# =============================================================================
# 5. 输出
# =============================================================================
if ($OutputFile) {
    try {
        $CleanOutput = $Formatted -replace '\x1B\[[0-9;]*[a-zA-Z]', ''
        Set-Content -Path $OutputFile -Value $CleanOutput -Encoding UTF8
        Write-Warning "[claude-fold] 已输出到: $OutputFile"
    } catch {
        Write-Warning "[claude-fold] 写入文件失败: $_"
        exit 1
    }
} else {
    Write-Output $Formatted
}

exit 0
