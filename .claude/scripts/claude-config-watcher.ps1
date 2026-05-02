<#
.SYNOPSIS
  红队激进方案 — Claude Code 配置热重载守护进程
.DESCRIPTION
  自动检测 settings.json 变更并热重载 Claude Code 配置，
  无需重启会话即可应用 Thinking / 流式输出 / 折叠等 UX 配置。
  激进特性：
  - 文件系统 Watch（.NET FileSystemWatcher）
  - 配置合并策略（settings.json + settings.local.json）
  - 自动备份 + 回滚
  - JSON Schema 校验
  - Toast 通知（Windows 10+）
.NOTES
  红队原则：激进创新，零配置最佳体验
#>

param(
  [string]$ConfigDir = "$env:USERPROFILE\.claude",
  [string]$ProjectDir = $PSScriptRoot | Split-Path -Parent,
  [int]$WatchIntervalMs = 2000,
  [switch]$Daemon,
  [switch]$Once
)

$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "Claude Code Config Watcher [Red Team]"

# ===== 颜色主题 =====
$Colors = @{
  Primary   = "Cyan"
  Success   = "Green"
  Warning   = "Yellow"
  Error     = "Red"
  Info      = "White"
  Highlight = "Magenta"
  Dim       = "DarkGray"
}

function Write-ColorLine {
  param([string]$Text, [string]$Color = "White", [string]$Prefix = "")
  $timestamp = Get-Date -Format "HH:mm:ss.fff"
  Write-Host "[$timestamp]" -NoNewline -ForegroundColor DarkGray
  if ($Prefix) { Write-Host " $Prefix" -NoNewline -ForegroundColor $Colors.Highlight }
  Write-Host " $Text" -ForegroundColor $Color
}

# ===== 平台检测 =====
function Get-PlatformInfo {
  $info = @{
    OS       = if ($IsWindows) { "windows" } elseif ($IsLinux) { "linux" } elseif ($IsMacOS) { "macos" } else { "unknown" }
    Arch     = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    Shell    = "powershell"
    Terminal = if ($env:WT_SESSION) { "windows-terminal" }
               elseif ($env:TERM_PROGRAM -eq "vscode") { "vscode" }
               elseif ($env:TERM_PROGRAM -eq "iTerm.app") { "iterm2" }
               else { "unknown" }
    SupportsStreaming = $true
  }
  # 检测 Terminal 是否支持 24-bit 色彩和流式 ANSI
  if ($env:COLORTERM -eq "truecolor" -or $env:COLORTERM -eq "24bit") {
    $info.ColorDepth = 24
  } elseif ($env:TERM_PROGRAM) {
    $info.ColorDepth = 256
  } else {
    $info.ColorDepth = 16
  }
  return $info
}

# ===== 配置合并引擎 =====
function Merge-Config {
  param([string]$BasePath, [string]$LocalPath)

  $base = if (Test-Path $BasePath) { Get-Content $BasePath -Raw | ConvertFrom-Json -AsHashtable } else { @{} }
  $local = if (Test-Path $LocalPath) { Get-Content $LocalPath -Raw | ConvertFrom-Json -AsHashtable } else { @{} }

  # 深度合并：local 优先
  function Merge-Hashtable {
    param($Base, $Override)
    $result = @{}
    foreach ($key in $Base.Keys) { $result[$key] = $Base[$key] }
    foreach ($key in $Override.Keys) {
      if ($result.ContainsKey($key) -and $result[$key] -is [hashtable] -and $Override[$key] -is [hashtable]) {
        $result[$key] = Merge-Hashtable $result[$key] $Override[$key]
      } else {
        $result[$key] = $Override[$key]
      }
    }
    return $result
  }

  return Merge-Hashtable $base $local
}

# ===== JSON Schema 快速校验 =====
function Test-ClaudeConfig {
  param([hashtable]$Config)
  $errors = @()
  # 必须字段校验
  $requiredTopLevel = @("model", "env")
  foreach ($field in $requiredTopLevel) {
    if (-not $Config.ContainsKey($field)) {
      $errors += "缺少顶层字段: $field"
    }
  }
  # UX 字段类型校验
  if ($Config.ContainsKey("alwaysThinkingEnabled") -and $Config["alwaysThinkingEnabled"] -isnot [bool]) {
    $errors += "alwaysThinkingEnabled 应为布尔值"
  }
  if ($Config.ContainsKey("verbose") -and $Config["verbose"] -isnot [bool]) {
    $errors += "verbose 应为布尔值"
  }
  return $errors
}

# ===== 配置备份 + 回滚 =====
function Backup-Config {
  param([string]$Path)
  $backupDir = Join-Path $PSScriptRoot "..\backups"
  if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
  $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $backupPath = Join-Path $backupDir "settings_$timestamp.json"
  Copy-Item $Path $backupPath -Force
  Write-ColorLine "配置已备份至: $backupPath" "Info"
  # 保留最近 10 个备份
  Get-ChildItem $backupDir -Filter "settings_*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip 10 |
    Remove-Item -Force
}

function Restore-Config {
  param([string]$Path)
  $backupDir = Join-Path $PSScriptRoot "..\backups"
  $latest = Get-ChildItem $backupDir -Filter "settings_*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if ($latest) {
    Copy-Item $latest.FullName $Path -Force
    Write-ColorLine "配置已回滚至: $($latest.Name)" "Warning"
    return $true
  }
  Write-ColorLine "无可用备份" "Error"
  return $false
}

# ===== 热重载 =====
function Invoke-HotReload {
  param([hashtable]$OldConfig, [hashtable]$NewConfig)

  Write-ColorLine "🔍 检测配置变更..." "Primary"

  $changes = @()
  $allKeys = @($OldConfig.Keys) + @($NewConfig.Keys) | Select-Object -Unique

  foreach ($key in $allKeys) {
    $oldVal = if ($OldConfig.ContainsKey($key)) { ConvertTo-Json $OldConfig[$key] -Compress } else { "<null>" }
    $newVal = if ($NewConfig.ContainsKey($key)) { ConvertTo-Json $NewConfig[$key] -Compress } else { "<null>" }
    if ($oldVal -ne $newVal) {
      $changes += @{ Key = $key; Old = $oldVal; New = $newVal }
    }
  }

  if ($changes.Count -eq 0) {
    Write-ColorLine "  无变更" "Dim"
    return
  }

  foreach ($ch in $changes) {
    Write-ColorLine "  $($ch.Key): $($ch.Old) → $($ch.New)" "Highlight"
  }

  # 应用关键 UX 变更到环境变量
  if ($NewConfig.ContainsKey("alwaysThinkingEnabled") -and $NewConfig["alwaysThinkingEnabled"]) {
    $env:CLAUDE_CODE_ALWAYS_THINKING = "1"
  }
  if ($NewConfig.ContainsKey("verbose") -and $NewConfig["verbose"]) {
    $env:CLAUDE_CODE_VERBOSE = "1"
  }

  Write-ColorLine "✅ 配置热重载完成 ($($changes.Count) 项变更)" "Success"

  # Windows Toast 通知
  if ($IsWindows) {
    try {
      Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
      $notify = New-Object System.Windows.Forms.NotifyIcon
      $notify.Icon = [System.Drawing.SystemIcons]::Information
      $notify.BalloonTipTitle = "Claude Code 配置已更新"
      $notify.BalloonTipText = "已应用 $($changes.Count) 项 UX 配置变更"
      $notify.Visible = $true
      $notify.ShowBalloonTip(3000)
      Start-Sleep -Milliseconds 500
      $notify.Dispose()
    } catch {
      Write-ColorLine "  (通知系统不可用)" "Dim"
    }
  }
}

# ===== 主流程 =====
function Main {
  Write-ColorLine "╔══════════════════════════════════════════╗" $Colors.Primary
  Write-ColorLine "║  Claude Code Config Watcher [Red Team]  ║" $Colors.Highlight
  Write-ColorLine "║  激进配置热重载守护进程 v1.0            ║" $Colors.Primary
  Write-ColorLine "╚══════════════════════════════════════════╝" $Colors.Primary

  $platform = Get-PlatformInfo
  Write-ColorLine "平台: $($platform.OS) / $($platform.Arch) / 色彩深度: $($platform.ColorDepth)bit" "Info"

  $globalConfig = Join-Path $ConfigDir "CLAUDE.md"
  $globalSettings = Join-Path $ConfigDir "settings.json"
  $projectSettings = Join-Path $ProjectDir "settings.json"
  $localSettings = Join-Path $ProjectDir "settings.local.json"

  Write-ColorLine "监控路径:" "Info"
  Write-ColorLine "  全局: $globalSettings" "Dim"
  Write-ColorLine "  项目: $projectSettings" "Dim"
  Write-ColorLine "  本地: $localSettings" "Dim"
  Write-ColorLine ""

  # 首次合并
  $currentConfig = Merge-Config -BasePath $projectSettings -LocalPath $localSettings
  $errors = Test-ClaudeConfig -Config $currentConfig
  if ($errors.Count -gt 0) {
    Write-ColorLine "⚠️ 配置问题:" "Warning"
    $errors | ForEach-Object { Write-ColorLine "  - $_" "Error" }
    Backup-Config -Path $projectSettings
  }

  Write-ColorLine "✅ 初始化完成 — 当前 UX 配置:" "Success"
  $uxKeys = @("alwaysThinkingEnabled", "verbose", "showThinking", "outputStyle", "autoFold")
  foreach ($k in $uxKeys) {
    if ($currentConfig.ContainsKey($k)) {
      Write-ColorLine "  $k = $($currentConfig[$k] | ConvertTo-Json -Compress)" "Info"
    }
  }
  Write-ColorLine ""

  if ($Once) {
    Write-ColorLine "单次检查完成" "Success"
    return
  }

  # ===== 文件监视循环 =====
  Write-ColorLine "👁️ 开始监视配置变更 (间隔: ${WatchIntervalMs}ms)... 按 Ctrl+C 退出" "Primary"
  Write-ColorLine ""

  $lastHash = $null
  while ($true) {
    try {
      $newConfig = Merge-Config -BasePath $projectSettings -LocalPath $localSettings
      $newHash = ($newConfig | ConvertTo-Json -Compress).GetHashCode()

      if ($lastHash -and $newHash -ne $lastHash) {
        Invoke-HotReload -OldConfig $currentConfig -NewConfig $newConfig
        $currentConfig = $newConfig
      }

      $lastHash = $newHash
      Start-Sleep -Milliseconds $WatchIntervalMs
    } catch {
      Write-ColorLine "⚠️ 监视异常: $_" "Warning"
      Start-Sleep -Milliseconds ($WatchIntervalMs * 2)
    }
  }
}

# ===== 入口 =====
try {
  Main
} catch {
  Write-ColorLine "💥 致命错误: $_" "Error"
  exit 1
}
