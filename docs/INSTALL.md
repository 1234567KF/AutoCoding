# AI编程智驾 - AI 执行安装指南

> **版本**：v1.3（完整版）
>
> 本文档供 AI 阅读并完整执行。目标：在全新环境（可能只有任一 AI 编程工具）上，从零搭建完整的 AI 编程工作台。
> 支持 Windows 和 Linux，自动检测平台并使用对应命令。
> AI 按顺序执行每个步骤即可，无需用户手动操作（除 Token 配置需要用户介入）。

---

## 一、环境检测与安装策略

> **跨平台兼容性**：如果你不是 Claude Code，请使用当前环境支持的 Terminal/Bash 权限执行后续脚本。Cursor、Cline 等工具均可通用。

### 1.1 执行原则

```
1. 先检测环境中已有什么（自动检测 Windows/Linux/macOS）
2. 缺少什么就安装什么（使用平台对应的命令）
3. Token 配置需要用户确认，其他全部自动执行
4. 根据平台选择正确的命令（PowerShell/bash）
5. 遇到缺工具/异常 → 自愈式控制，AI 自己修复继续运行
6. 优先使用本地 Ollama 模型进行环境检测、文件读写等低逻辑任务，只有在复杂架构设计或审计时才调用 Claude Code
7. 如果网络请求失败，自动切换至中国区镜像源（npmmirror/阿里云）
```

### 1.2 平台检测

```powershell
# 检测操作系统
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $PLATFORM = "windows"
    $SHELL = "powershell"
} elseif ($IsLinux -or (Test-Path "/proc/version")) {
    $PLATFORM = "linux"
    $SHELL = "bash"
} elseif ($IsMacOS) {
    $PLATFORM = "macos"
    $SHELL = "bash"
    $PACKAGE_MANAGER = "brew"
} else {
    $PLATFORM = "unknown"
}

# 检测 macOS
if ($IsMacOS) { $PLATFORM = "macos"; $SHELL = "bash"; $PACKAGE_MANAGER = "brew" }

Write-Host "检测到平台: $PLATFORM ($SHELL)"
```

### 1.3 熔断机制

```powershell
# 熔断机制：当操作失败 MAX_RETRY 次时自动切换策略
$MAX_RETRY = 3
$retryCount = 0
$currentSource = "primary"

function Invoke-WithCircuitBreaker {
    param(
        [string]$operation,
        [scriptblock]$primaryAction,
        [scriptblock]$fallbackAction
    )

    $retryCount = 0
    $currentSource = "primary"

    while ($retryCount -lt $MAX_RETRY) {
        try {
            return & $primaryAction
        } catch {
            $retryCount++
            if ($retryCount -ge $MAX_RETRY) {
                Write-Host "[熔断] 主源失败，切换至镜像源..."
                $currentSource = "mirror"
                return & $fallbackAction
            }
        }
    }
}

# 使用示例：网络请求失败自动切换镜像源
$npmSource = Invoke-WithCircuitBreaker -operation "npm install" `
    -primaryAction { npm install $package } `
    -fallbackAction { npm install $package --registry=https://registry.npmmirror.com }
```

### 1.4 检测清单

| 工具        | Windows 检测                       | Linux 检测                         | 用途             |
| ----------- | ---------------------------------- | ---------------------------------- | ---------------- |
| Claude Code | `claude --version`               | `claude --version`               | 主要 AI 编程界面 |
| Git         | `git --version`                  | `git --version`                  | 克隆仓库         |
| Node.js     | `node --version`                 | `node --version`                 | 运行 ruflo       |
| npm         | `npm --version`                  | `npm --version`                  | 安装全局包       |
| ruflo       | `claude-flow --version`          | `claude-flow --version`          | 多 Agent + 记忆  |
| gspowers    | 检查 `~/.claude/skills/gspowers` | 检查 `~/.claude/skills/gspowers` | SOP 流程         |

---

## 二、平台适配命令参考

### 2.1 Windows (PowerShell)

```powershell
# 安装工具
npm install -g ruflo

# 中国区网络自适应：检测 npm 是否慢，自动切换镜像
npm config get registry  # 检查当前源
# 如果检测到网络慢，执行：
# npm config set registry https://registry.npmmirror.com

winget install -e --id Git.Git

# 路径格式
$home = $env:USERPROFILE
$projectDir = "D:\projects\my-app"

# 环境变量
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
```

### 2.2 Linux (bash)

```bash
# 安装工具
npm install -g ruflo
sudo apt-get install git   # 或 yum/dnf

# 路径格式
home=~
project_dir="~/projects/my-app"

# 环境变量
export PATH="$PATH:/usr/local/bin"
```

---

## 三、自动安装流程

### 网络自适应检测

> 在中国区网络环境下，npm 和 git 可能访问缓慢，自动检测并切换镜像源

```powershell
# ═══════════════════════════════════════════════════════════
# 网络自适应检测脚本
# ═══════════════════════════════════════════════════════════

# npm 镜像检测与切换
function Test-NpmMirror {
    $currentRegistry = npm config get registry
    Write-Host "当前 npm 源: $currentRegistry"

    # 测试 npm 官方源速度
    $testResult = Measure-Command {
        try {
            npm view npm version --registry=https://registry.npmjs.org 2>$null
        } catch { }
    }

    if ($testResult.TotalMilliseconds -gt 3000) {
        Write-Host "[警告] npm 官方源响应缓慢（$($testResult.TotalMilliseconds)ms），建议切换镜像"
        Write-Host "执行切换: npm config set registry https://registry.npmmirror.com"
        npm config set registry https://registry.npmmirror.com
        Write-Host "[已切换] npm 镜像源: $(npm config get registry)"
    } else {
        Write-Host "[正常] npm 官方源响应良好（$($testResult.TotalMilliseconds)ms）"
    }
}

# git 镜像检测与切换（适用于中国区）
function Test-GitMirror {
    # 测试 GitHub 连接速度
    $testUrl = "https://github.com"
    $testResult = Measure-Command {
        try {
            Invoke-WebRequest -Uri $testUrl -TimeoutSec 5 -UseBasicParsing 2>$null
        } catch { }
    }

    if ($testResult.TotalMilliseconds -gt 5000 -or $null -eq $testResult) {
        Write-Host "[警告] GitHub 访问缓慢，建议配置镜像"
        # 配置 GitHub 镜像（gitee 同步）
        git config --global url."https://gitee.com/".insteadOf "https://github.com/"
        Write-Host "[已配置] GitHub 镜像: gitee.com"
    } else {
        Write-Host "[正常] GitHub 连接良好（$($testResult.TotalMilliseconds)ms）"
    }
}

# 执行检测
Write-Host "═" * 60
Write-Host "网络自适应检测"
Write-Host "═" * 60
Test-NpmMirror
Test-GitMirror
Write-Host "═" * 60
```

**镜像源参考：**

| 服务    | 官方源                     | 中国区镜像                          |
| ------- | -------------------------- | ----------------------------------- |
| npm     | https://registry.npmjs.org | https://registry.npmmirror.com      |
| GitHub  | https://github.com         | https://gitee.com (镜像同步)        |
| Node.js | https://nodejs.org         | https://npm.taobao.org/mirrors/node |

### 步骤 0：环境检测

执行以下检测，记录缺少什么：

```powershell
# ═══════════════════════════════════════════════════════════
# 环境检测脚本（Windows PowerShell / Linux bash 通用）
# ═══════════════════════════════════════════════════════════

$results = @{}

# 检测 Claude Code
if (Get-Command claude -ErrorAction SilentlyContinue) {
    $results["Claude Code"] = "found"
} else {
    $results["Claude Code"] = "missing"
}

# 检测 Git
if (Get-Command git -ErrorAction SilentlyContinue) {
    $results["Git"] = "found"
} else {
    $results["Git"] = "missing"
}

# 检测 Node.js
if (Get-Command node -ErrorAction SilentlyContinue) {
    $results["Node.js"] = "found"
} else {
    $results["Node.js"] = "missing"
}

# 检测 npm
if (Get-Command npm -ErrorAction SilentlyContinue) {
    $results["npm"] = "found"
} else {
    $results["npm"] = "missing"
}

# 检测 ruflo
if (Get-Command claude-flow -ErrorAction SilentlyContinue) {
    $results["ruflo"] = "found"
} else {
    $results["ruflo"] = "missing"
}

# 输出检测结果
    // ... 2013 lines omitted
}
    // ... 2012 lines omitted
}
    // ... 2011 lines omitted
}
    // ... 2010 lines omitted
}
    // ... 2009 lines omitted
}
    // ... 2008 lines omitted
    }
}
    // ... 2006 lines omitted
}
    // ... 2005 lines omitted
{
    // ... 2004 lines omitted
}
    // ... 2003 lines omitted
    }
    // ... 2002 lines omitted
}
    // ... 2001 lines omitted
    }
}
    // ... 1999 lines omitted
}
    // ... 1998 lines omitted
        }
    // ... 1997 lines omitted
        }
    }
}
    // ... 1994 lines omitted
    }
    // ... 1993 lines omitted
}
    // ... 1992 lines omitted
function Invoke-TDD-Cycle {
    // ... 1991 lines omitted
}
    // ... 1990 lines omitted
}
    // ... 1989 lines omitted
function New-ProjectWiki {
    // ... 1988 lines omitted
    }
    // ... 1987 lines omitted
}
    // ... 1986 lines omitted
}
    // ... 1985 lines omitted
  }
    // ... 1984 lines omitted
{
    // ... 1983 lines omitted
      }
    // ... 1982 lines omitted
  }
}
// ... 1980 more lines (total: 2271)### 步骤 3.6：安装 RTK（Token 节省工具）

> RTK（Rust Token Killer）是一个高性能 CLI 代理，通过过滤和压缩命令输出，可节省 60-90% 的 token 消耗

#### 安装方式（Windows）

```powershell
# 下载最新版本
curl -sL "https://github.com/rtk-ai/rtk/releases/download/v0.37.2/rtk-x86_64-pc-windows-msvc.zip" -o $env:TEMP\rtk.zip
Expand-Archive -Path $env:TEMP\rtk.zip -DestinationPath $env:TEMP\rtk -Force
# 安装到用户目录
$binDir = "$env:USERPROFILE\.local\bin"
if (!(Test-Path $binDir)) { New-Item -ItemType Directory -Force -Path $binDir }
Move-Item "$env:TEMP\rtk\rtk.exe" "$binDir\rtk.exe"
# 验证
& "$binDir\rtk.exe" --version
```

#### 初始化（全局 Hook）

```powershell
# 初始化并自动修补 settings.json
& "$env:USERPROFILE\.local\bin\rtk.exe" init -g --auto-patch

# 验证安装
& "$env:USERPROFILE\.local\bin\rtk.exe" gain
```

#### Token 节省效果

| 操作                          | 频率 | 普通消耗           | RTK 消耗          | 节省           |
| ----------------------------- | ---- | ------------------ | ----------------- | -------------- |
| `ls` / `tree`             | 10x  | 2,000              | 400               | -80%           |
| `git status`                | 10x  | 3,000              | 600               | -80%           |
| `git diff`                  | 5x   | 10,000             | 2,500             | -75%           |
| `cargo test` / `npm test` | 5x   | 25,000             | 2,500             | -90%           |
| `grep` / `rg`             | 8x   | 16,000             | 3,200             | -80%           |
| **总计**                |      | **~118,000** | **~23,900** | **-80%** |

#### 工作原理

```
Claude Code          settings.json        rtk-rewrite.sh        RTK binary
     │                    │                     │                    │
     │  "git status"      │                     │                    │
     │ ──────────────────►│                     │                    │
     │                    │  PreToolUse trigger  │                    │
     │                    │ ───────────────────►│                    │
     │                    │                     │  rewrite command   │
     │                    │                     │  → rtk git status  │
     │                    │◄────────────────────│                    │
     │                    │  updated command     │                    │
     │  execute: rtk git status                                      │
     │ ─────────────────────────────────────────────────────────────►│
     │                                                               │  filter
     │  "3 modified, 1 untracked ✓"                                  │
     │◄──────────────────────────────────────────────────────────────│
```

#### 命令速查

| 命令                   | 说明                                |
| ---------------------- | ----------------------------------- |
| `rtk gain`           | 显示 token 节省统计                 |
| `rtk gain --history` | 显示命令使用历史                    |
| `rtk discover`       | 分析 Claude Code 历史，发现节省机会 |
| `rtk proxy <cmd>`    | 直接执行命令（不过滤，用于调试）    |

#### ⚠️ AI 必读：npm 上的 rtk-cli 是同名错误包

```
AI 执行此处时必须严格遵循以下安装方式，禁止使用 npm install -g rtk
```

**npm 上有一个叫 `rtk-cli` 的包，它是 Static Site Generator (ssg)，跟 token 节省毫无关系！**

**正确的 RTK (Rust Token Killer) 必须从 GitHub 下载二进制：**

- GitHub: https://github.com/rtk-ai/rtk
- 下载地址: https://github.com/rtk-ai/rtk/releases/latest
- 包名格式: `rtk-x86_64-pc-windows-msvc.zip` (Windows)

**禁止**：

```powershell
npm install -g rtk        # 错误！这是 ssg，不是 token 节省工具
npm install -g rtk-cli     # 同样是错误的 ssg 工具
```

**正确安装方式**：

```powershell
# 从 GitHub 下载（见上方安装方式）
```

**验证方法**：

```powershell
rtk gain        # 显示 "RTK Token Savings" 即为正确
rtk --version   # 显示 rtk 0.37.2 即为正确（不是 rtk-cli/0.0.1）
```

#### 注意事项

- **名称冲突**：npm 上的 `rtk-cli` (ssg) 与 `rtk-ai/rtk` 重名但功能完全不同
- **Windows**：使用 Windows Terminal 或 PowerShell 运行，不要直接双击 .exe
- **重启 Claude Code**：初始化后需要重启才能加载 hook

---

### 步骤 3.6：配置 Claude Code 权限模式（Yolo 模式）

> 开启后，AI 执行命令不再逐个询问权限，全部自动同意

```powershell
# 方法 1：通过 Claude Code 命令配置
claude config set allowPermissions true

# 方法 2：直接编辑配置文件
# Windows
$settingsPath = "$env:APPDATA\Claude\settings.json"
# Linux
# settingsPath="$HOME/.config/Claude/settings.json"

# 添加或修改
@{
    "allowPermissions": true
} | ConvertTo-Json -Depth 10

# 方法 3：PowerShell 一键配置（推荐）
claude config set allowPermissions true
```

**效果**：AI 执行任务时，所有 Bash/MCP 操作默认同意，不再弹出权限询问。

**安全分级**：

| 等级                   | 适用场景             | 风险等级 | 说明                                  |
| ---------------------- | -------------------- | -------- | ------------------------------------- |
| **L1 观察模式**  | 新项目/陌生代码      | 低       | allowPermissions=false，逐项确认      |
| **L2 开发模式**  | 日常开发/调试        | 中       | allowPermissions=true，敏感操作需确认 |
| **L3 Yolo 模式** | 快速原型/实验性项目  | 高       | allowPermissions=true，全部自动同意   |
| **L4 受控 Yolo** | 信任的代码库 + CI/CD | 中       | allowPermissions=true + 审计日志      |

---

### 步骤 4：安装 ruflo（多 Agent + 记忆管理）

```powershell
# 安装 ruflo 全局
npm install -g ruflo

# 验证
claude-flow --version

# 添加 ruflo MCP 到 Claude Code（全局生效，所有项目共享）
claude mcp add ruflo -- npx -y ruflo@latest mcp start

# 验证 MCP
claude mcp list
```

---

### 步骤 5：创建全局 ruflo 配置

```powershell
# 创建全局配置目录（Windows）
$globalDir = "$env:USERPROFILE\.claude-flow"
if (!(Test-Path $globalDir)) { New-Item -ItemType Directory -Force -Path $globalDir }

# Linux 版本
# globalDir="$HOME/.claude-flow"
# mkdir -p "$globalDir"

# 创建全局配置
# 说明：全局配置让 ruflo 命令从任意目录都可执行
# 记忆按项目隔离（defaultScope: project），避免全局记忆过于庞大
$configContent = @"
version: "3.0.0"

memory:
  backend: hybrid
  enableHNSW: true
  persistPath: `~/.claude-flow/data
  cacheSize: 500
  learningBridge:
    enabled: true
    sonaMode: balanced
  memoryGraph:
    enabled: true
    similarityThreshold: 0.75

swarm:
  topology: hierarchical-mesh
  maxAgents: 5
  autoScale: true
  coordinationStrategy: consensus

hooks:
  enabled: true
  autoExecute: true

mcp:
  autoStart: true
  port: 3000

agentScopes:
  enabled: true
  defaultScope: project   # 记忆按项目隔离（推荐）

EOF
"@

# Windows 写入
$configContent | Out-File -FilePath "$globalDir\config.yaml" -Encoding UTF8

# Linux 写入
# cat > "$globalDir/config.yaml" << 'EOF'
# ... 内容同上 ...
# EOF

# 创建记忆存储目录
if (!(Test-Path "$globalDir\data")) { New-Item -ItemType Directory -Force -Path "$globalDir\data" }

Write-Host "全局 ruflo 配置完成"
Write-Host "  配置目录: $globalDir"
Write-Host "  记忆目录: $globalDir\data"
Write-Host ""
Write-Host "注意：ruflo 命令从任意目录都可执行（全局安装）"
Write-Host "      每个新项目需要运行: ruflo init --minimal --skip-claude"
Write-Host "      （创建项目级 .claude-flow/ 目录，记忆隔离）"
```

### 步骤 5b：Linux 版本的全局配置

```bash
# Linux/macOS 全局配置
globalDir="$HOME/.claude-flow"
mkdir -p "$globalDir/data"

cat > "$globalDir/config.yaml" << 'EOF'
version: "3.0.0"

memory:
  backend: hybrid
  enableHNSW: true
  persistPath: ~/.claude-flow/data
  cacheSize: 500
  learningBridge:
    enabled: true
    sonaMode: balanced

swarm:
  topology: hierarchical-mesh
  maxAgents: 5
  autoScale: true

hooks:
  enabled: true
  autoExecute: true

mcp:
  autoStart: true
  port: 3000

agentScopes:
  enabled: true
  defaultScope: project   # 记忆按项目隔离
EOF

echo "全局 ruflo 配置完成: $globalDir"
```

---

### 步骤 7：安装 gspowers（依赖 gstack + superpowers）

#### 6.1 安装 gstack

```powershell
# 创建 skills 目录
$skillsDir = "$env:USERPROFILE\.claude\skills"
if (!(Test-Path $skillsDir)) { New-Item -ItemType Directory -Force -Path $skillsDir }

# 克隆 gstack（如果不存在）
$gstackDir = "$skillsDir\gstack"
if (!(Test-Path $gstackDir)) {
    # 中国区镜像: git clone https://ghproxy.com/https://github.com/garrytan/gstack.git $gstackDir
    git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git $gstackDir
    # 执行 gstack setup
    if (Test-Path "$gstackDir\setup") {
        & "$gstackDir\setup"
    }
}

Write-Host "gstack 安装完成"
```

#### 6.2 安装 superpowers

```powershell
# superpowers 是 Claude Code 的 plugin，通过命令安装
# 需要用户在 Claude Code 中执行：
Write-Host "[需要用户介入] 请在 Claude Code 中执行以下命令安装 superpowers:"
Write-Host "  /plugin install superpowers@claude-plugins-official"
Write-Host ""
Write-Host "如果 AI 正在 Claude Code 环境中，可以直接调用该命令"
```

#### 6.3 安装 gspowers

```powershell
# 克隆 gspowers
$gspowersDir = "$env:USERPROFILE\.claude\skills\gspowers"
if (!(Test-Path $gspowersDir)) {
    # 中国区镜像: git clone https://ghproxy.com/https://github.com/fshaan/gspowers.git $gspowersDir
    git clone https://github.com/fshaan/gspowers.git $gspowersDir
}

Write-Host "gspowers 安装完成"
Write-Host "  安装目录: $gspowersDir"
```

---

### 步骤 8：安装验证

```powershell
# 验证所有组件
Write-Host ""
Write-Host "═" * 60
Write-Host "安装验证"
Write-Host "═" * 60

$components = @(
    @{Name="Git"; Cmd="git --version"},
    @{Name="Node.js"; Cmd="node --version"},
    @{Name="ruflo"; Cmd="claude-flow --version"},
    @{Name="gstack"; Path="$env:USERPROFILE\.claude\skills\gstack"},
    @{Name="gspowers"; Path="$env:USERPROFILE\.claude\skills\gspowers"}
)

foreach ($comp in $components) {
    if ($comp.Cmd) {
        try {
            $result = Invoke-Expression $comp.Cmd 2>$null
            Write-Host "  ✓ $($comp.Name): $result"
        } catch {
            Write-Host "  ✗ $($comp.Name): 未找到"
        }
    } elseif ($comp.Path) {
        if (Test-Path $comp.Path) {
            Write-Host "  ✓ $($comp.Name): 已安装"
        } else {
            Write-Host "  ✗ $($comp.Name): 未找到"
        }
    }
}

# 检查 MCP
try {
    $mcpList = claude mcp list 2>$null
    if ($mcpList -match "ruflo") {
        Write-Host "  ✓ ruflo MCP: 已注册"
    } else {
        Write-Host "  ✗ ruflo MCP: 未注册"
    }
} catch {
    Write-Host "  ✗ ruflo MCP: 检查失败"
}

Write-Host ""
Write-Host "═" * 60
Write-Host "✅ 安装完成！"
Write-Host "═" * 60
Write-Host ""
Write-Host "下一步："
Write-Host "  1. 在项目目录运行: ruflo init --minimal --skip-claude"
Write-Host "  2. 打开 Claude Code 开始编程"
Write-Host "  3. 说 '安全审计' 或 '/gspowers' 启动工作流"
```

---

## 四、新项目使用流程

> 每个新项目只需执行一次初始化

### 在新项目目录执行

```powershell
cd D:\your-new-project

# 初始化 ruflo（每个新项目做一次）
ruflo init --minimal --skip-claude

# 打开 Claude Code
claude
```

### 验证记忆共享

在 Claude Code 中测试：

```
> 安全审计
> 架构评审
> /gspowers
> triple [任意任务]
```

---

## 四b、新电脑完整安装流程

> **目标**：在新电脑从零安装，只需一次全局安装，之后每个新项目只复制 `.claude` 即可

### 安装流程总览

```
┌─────────────────────────────────────────────────────────────┐
│  第一步：全局安装（每台电脑只需一次）                        │
│    - Claude Code、Node.js、Git                             │
│    - ruflo (npm install -g)                               │
│    - RTK (Token 节省工具)                                   │
│    - gspowers、gstack (复制到 ~/.claude/skills/)           │
├─────────────────────────────────────────────────────────────┤
│  第二步：项目安装（每个新项目只需一次）                      │
│    - 复制 .claude 目录到项目                               │
│    - 运行 install-local.sh/ps1                             │
│    - ruflo init --minimal --skip-claude                   │
├─────────────────────────────────────────────────────────────┤
│  第三步：正常使用                                           │
│    - 复制 .claude 到任何新项目                             │
│    - 无需重新安装全局工具                                   │
└─────────────────────────────────────────────────────────────┘
```

### 第一步：全局安装（每台电脑只需一次）

#### 1.1 安装基础工具

```powershell
# Windows - 使用管理员权限的 PowerShell
winget install Git.Git
winget install OpenJS.NodeJS.LTS

# 安装 Claude Code
irm https://claude.ai/install.ps1 | iex
```

#### 1.2 安装 ruflo（多 Agent + 记忆）

```powershell
# 全局安装 ruflo
npm install -g ruflo

# 添加 ruflo MCP 到 Claude Code
claude mcp add ruflo -- npx -y ruflo@latest mcp start

# 验证安装
claude-flow --version
```

#### 1.3 安装 RTK（Token 节省）

```powershell
# 下载 RTK
curl -sL "https://github.com/rtk-ai/rtk/releases/download/v0.37.2/rtk-x86_64-pc-windows-msvc.zip" -o $env:TEMP\rtk.zip
Expand-Archive -Path $env:TEMP\rtk.zip -DestinationPath $env:TEMP\rtk -Force

# 安装到用户目录
$binDir = "$env:USERPROFILE\.local\bin"
New-Item -ItemType Directory -Force -Path $binDir
Move-Item "$env:TEMP\rtk\rtk.exe" "$binDir\rtk.exe"

# 初始化（会自动修补 settings.json）
& "$binDir\rtk.exe" init -g --auto-patch

# 验证
& "$binDir\rtk.exe" gain
```

#### 1.4 安装全局技能（gspowers、gstack）

```powershell
# 创建全局技能目录
$skillsDir = "$env:USERPROFILE\.claude\skills"
if (!(Test-Path $skillsDir)) { New-Item -ItemType Directory -Force -Path $skillsDir }

# 克隆 gspowers
if (!(Test-Path "$skillsDir\gspowers")) {
    git clone https://github.com/fshaan/gspowers.git "$skillsDir\gspowers"
}

# 克隆 gstack
if (!(Test-Path "$skillsDir\gstack")) {
    git clone https://github.com/garrytan/gstack.git "$skillsDir\gstack"
}

# 复制 Pipeline 扩展
$patchDir = "D:\path\to\AutoCoding\gspowers-pipeline-patch"
if (Test-Path $patchDir) {
    Copy-Item "$patchDir\pipeline.md" "$skillsDir\gspowers\references\" -Force
    Copy-Item "$patchDir\execute-patch.md" "$skillsDir\gspowers\references\" -Force
}
```

#### 1.5 创建全局 ruflo 配置

```powershell
# 创建全局配置目录
$globalDir = "$env:USERPROFILE\.claude-flow"
if (!(Test-Path $globalDir)) { New-Item -ItemType Directory -Force -Path $globalDir }
if (!(Test-Path "$globalDir\data")) { New-Item -ItemType Directory -Force -Path "$globalDir\data" }

# 创建配置
@"
version: "3.0.0"

memory:
  backend: hybrid
  enableHNSW: true
  persistPath: ~/.claude-flow/data
  cacheSize: 500
  learningBridge:
    enabled: true
    sonaMode: balanced
  memoryGraph:
    enabled: true
    similarityThreshold: 0.75

swarm:
  topology: hierarchical-mesh
  maxAgents: 5
  autoScale: true
  coordinationStrategy: consensus

hooks:
  enabled: true
  autoExecute: true

mcp:
  autoStart: true
  port: 3000

agentScopes:
  enabled: true
  defaultScope: project
"@ | Out-File -FilePath "$globalDir\config.yaml" -Encoding UTF8
```

#### 1.6 配置 Claude Code 全局设置

```powershell
# 全局 settings.json（Token 配置）
notepad "$env:USERPROFILE\.claude\settings.json"
```

添加内容：
```json
{
  "model": "MiniMax-M2.7",
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.minimaxi.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "YOUR_TOKEN_HERE"
  },
  "permissions": {
    "defaultMode": "bypassPermissions",
    "allowPermissions": true
  }
}
```

### 第二步：项目安装（每个新项目只需一次）

#### 2.1 复制 .claude 到项目目录

```powershell
# 复制整个 .claude 目录
cp -Recurse "D:\path\to\AutoCoding\.claude" "D:\your-new-project\"

# 或在项目目录内直接复制
cd D:\your-new-project
cp -Recurse "D:\path\to\AutoCoding\.claude" .\
```

#### 2.2 运行项目本地安装

```powershell
# Windows
.\.claude\install-local.ps1

# Linux/macOS
chmod +x ./.claude/install-local.sh
./.claude/install-local.sh
```

#### 2.3 项目级 ruflo 初始化

```powershell
cd D:\your-new-project

# 项目级初始化（创建 .claude-flow/，记忆隔离）
ruflo init --minimal --skip-claude

# 验证
dir ".\.claude-flow"
```

#### 2.4 重启 Claude Code

```powershell
# 在项目目录启动 Claude Code
cd D:\your-new-project
claude
```

### 第三步：正常使用（只复制 .claude）

以后任何新项目：

```powershell
# 1. 复制 .claude
cp -Recurse "D:\existing-project\.claude" "D:\new-project\"

# 2. 初始化 ruflo（如需要）
cd D:\new-project
ruflo init --minimal --skip-claude

# 3. 启动 Claude Code
claude
```

### AgentDB Vectors 触发生效

AgentDB vectors 为 0 是正常的，需要通过以下方式触发生成：

#### 方式一：Hooks 自动学习（推荐）

Hooks 是 Claude Code 的自动学习机制，配置文件已更新支持自动触发：

```json
// settings.json.template 中已配置
{
  "hooks": {
    "pre-task": { "enabled": true, "trigger": "auto" },
    "post-task": { "enabled": true, "trigger": "auto" },
    "post-edit": { "enabled": true, "trigger": "auto" },
    "session-end": { "enabled": true, "trigger": "auto" }
  }
}
```

**触发流程：**
```
完成任务 → post-task hook 触发 → 自动存储 pattern → 向量化

编辑代码 → post-edit hook 触发 → 记录代码模式 → 向量化

结束会话 → session-end hook 触发 → 汇总学习 → 向量化
```

**开启方法：**
- 新项目：使用 `settings.json.template`（已包含 hooks 配置）
- 已有项目：确保 `settings.json` 中有 `"hooks": { "post-task": { "enabled": true } }`

#### 方式二：手动触发

```powershell
# 存储一个记忆
claude-flow mcp exec --tool memory_store --args '{"key":"test-pattern","value":"这是一个测试pattern","tags":["test"]}'

# 搜索记忆
claude-flow mcp exec --tool memory_search --args '{"query":"测试","limit":5}'
```

#### 方式三：对话中自然触发

当你在项目中说：
- "记住这个设计决策"
- "下次遇到这个问题用这个方案"
- 完成某个任务后

ruflo 的 hooks 会自动捕获并存储。

### ruflo AgentDB 说明

| 状态 | 含义 |
|------|------|
| vectors: 0 | 还没有存储任何记忆 |
| vectors: 100 | 已存储 100 个向量化的记忆 |
| 查询返回空 | 记忆没有被正确触发或写入 |

**Vectors 增长方式：**
- 每完成一个任务（post-task）：+1~5 个向量
- 每编辑一个文件（post-edit）：+1 个向量
- 每次会话结束（session-end）：+1 个向量
- 手动 memory_store：+1 个向量

---

## 四c、项目本地安装流程（推荐）

> **适用场景**：多项目隔离、避免全局污染、便于项目打包分享
>
> **原理**：将 gspowers 技能安装到项目自身的 `.claude/skills/` 目录，而非全局 `~/.claude/skills/`

### 两种安装模式对比

| 模式 | gspowers 位置 | settings.json | 适用场景 |
|------|---------------|---------------|----------|
| **全局安装** | `~/.claude/skills/gspowers/` | `~/.claude/settings.json` | 所有项目共享一套技能 |
| **项目本地安装** | `./.claude/skills/gspowers/` | `./.claude/settings.json` | 多项目隔离、便于打包分享 |

### 项目本地安装步骤

#### 1. 复制 AutoCoding 到目标项目

```powershell
# 复制整个 .claude 目录到你的项目
cp -Recurse "D:\path\to\AutoCoding\.claude" "D:\your-project\"
```

#### 2. 运行项目本地安装脚本

**Windows (PowerShell):**
```powershell
cd D:\your-project

# 完整安装（包括 gspowers、gstack、Pipeline 扩展）
.\.claude\install-local.ps1

# 或预览模式（不实际执行）
.\.claude\install-local.ps1 -DryRun
```

**Linux / macOS (Bash):**
```bash
cd /path/to/your-project

# 添加执行权限
chmod +x ./.claude/install-local.sh

# 完整安装
./.claude/install-local.sh

# 预览模式
./.claude/install-local.sh --dry-run
```

**Git Bash (Windows):**
```bash
cd /d/your-project
./.claude/install-local.sh
```

脚本会自动：
- 从全局 `~/.claude/skills/` 复制 gspowers 和 gstack
- 安装 Pipeline 扩展到 `.claude/skills/gspowers/references/`
- 创建 `settings.json`（从模板）
- 创建 `.claude-flow/config.yaml`（项目级记忆配置）

#### 3. 手动安装 superpowers（需要网络）

```powershell
# 在 Claude Code 中执行
/plugin install superpowers@claude-plugins-official
```

#### 4. 项目内初始化 ruflo（如需要）

```powershell
cd D:\your-project

# 项目级初始化（记忆隔离）
ruflo init --minimal --skip-claude
```

#### 5. 在项目目录启动 Claude Code

```powershell
cd D:\your-project

# Claude Code 会自动读取 .claude/settings.json
claude
```

### 项目本地安装后的目录结构

```
D:\your-project\
├── .claude/                      # 项目本地 Claude 配置（复制这个）
│   ├── skills/                   # 技能（gspowers、gstack）
│   │   ├── gspowers/           #   SOP 导航
│   │   │   ├── references/      #   SOP 定义文件
│   │   │   │   ├── execute.md
│   │   │   │   └── pipeline.md  #   Pipeline 扩展
│   │   │   └── ...
│   │   └── gstack/              #   产品流程框架
│   ├── settings.json            # 项目级配置
│   ├── install-local.ps1        # Windows 安装脚本
│   ├── install-local.sh         # Linux/macOS 安装脚本
│   └── CLAUDE.md               # 本说明文件
│
├── .claude-flow/                # 项目级 ruflo 记忆（自动创建，不复制）
│   ├── config.yaml
│   └── data/
│
└── ...其他项目文件...
```

### 记忆隔离说明

**重要**：复制 `.claude` 到新项目时，**不会**带记忆文件。每个项目的记忆存储在各自的 `.claude-flow/` 目录中，实现完全隔离。

| 目录 | 复制时 | 记忆 |
|------|--------|------|
| `.claude/` | ✅ 复制 | 不含记忆 |
| `.claude-flow/` | ❌ 不复制 | 每个项目独立 |

### 验证项目本地安装

在 Claude Code 中执行：

```
> /gspowers                          # 应该能启动 SOP 导航
> /pipeline-dev                       # 应该能启动多模块流水线
> triple [任意任务]                   # 应该能启动三方协作
```

### 已知限制

| 组件 | 全局必须 | 说明 |
|------|---------|------|
| **npm 全局包** | 是 | `npm install -g ruflo` 仍需全局安装 |
| **RTK** | 是 | `~/.local/bin/rtk.exe` 仍需全局安装 |
| **Claude Code** | 是 | 仍需全局安装 |
| **Git/Node.js** | 是 | 仍需全局安装 |
| **superpowers** | 是 | 需在 Claude Code 中手动安装 plugin |

### 何时使用项目本地 vs 全局

| 场景 | 推荐模式 |
|------|---------|
| 单个项目，长期使用 | 全局安装 |
| 多项目并行，不同配置 | 项目本地 |
| 项目要打包分享给其他人 | 项目本地 |
| 临时测试/演示 | 项目本地 |
| 所有项目用同一套技能 | 全局安装 |

---

## 五、功能触发速查

| 你说的话                    | 触发的工作                       | 来源     |
| --------------------------- | -------------------------------- | -------- |
| `安全审计`                | 多 Agent 安全漏洞扫描 + 三方对抗 | ruflo    |
| `架构评审`                | 多 Agent 系统架构评估 + 三方对抗 | ruflo    |
| `QA团队` / `测试评审`   | 多 Agent 测试质量评审 + 三方对抗 | ruflo    |
| `三方调研` / `research` | 多 Agent 通用研究任务            | ruflo    |
| `triple [任务]`           | 通用三方协作（任意任务）         | ruflo    |
| `/gspowers`               | 启动 SOP 流程导航                | gspowers |
| `/office-hours`           | YC 式产品拷问                    | gspowers |
| `/brainstorm`             | 苏格拉底式设计细化               | gspowers |
| `/subagent-dev`           | 子代理 TDD 开发                  | gspowers |
| `/review`                 | 代码审查                         | gspowers |
| `/qa`                     | 浏览器 QA                        | gspowers |
| `/ship`                   | 发布 PR                          | gspowers |

---

## 六、记忆共享说明

### 5.1 记忆层级

```
全局记忆 (~/.claude-flow/data/)
    ↓
项目级记忆 (.claude-flow/data/)
    ↓
Agent 共享（在同一个项目内的 agents 共享记忆）
```

### 5.2 同项目内 Agent 共享记忆

当 `agentScopes.defaultScope: project` 时，同一项目启动的所有 Agent 共享该项目内的记忆上下文。不同项目间记忆隔离，避免全局记忆过于庞大。

```yaml
# ~/.claude-flow/config.yaml
agentScopes:
  enabled: true
  defaultScope: project  # 记忆按项目隔离（推荐）
```

### 5.3 手动记忆操作

```bash
# 存储记忆
claude-flow mcp exec --tool memory_store --args '{"key":"key-name","value":"内容","tags":["标签"]}'

# 搜索记忆
claude-flow mcp exec --tool memory_search --args '{"query":"关键词","limit":3}'

# 列出所有记忆
claude-flow mcp exec --tool memory_list
```

---

## 七、故障排除

### 问题：某个工具检测不到

```powershell
# 刷新环境变量
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 手动刷新
refreshenv 2>$null || Write-Host "请重新打开终端"
```

### 问题：ruflo MCP 不工作

```powershell
# 重启 MCP
claude mcp remove ruflo
claude mcp add ruflo -- npx -y ruflo@latest mcp start

# 检查状态
claude mcp list
```

### 问题：gspowers 找不到

```powershell
# 检查目录
Get-ChildItem "$env:USERPROFILE\.claude\skills" -Directory
```

---

## 八、AI 执行清单

> 以下是 AI 完整执行顺序，确保每步成功后再执行下一步
>
> **版本**：v1.3（完整版，包含 RTK、TDD、Pipeline 扩展）

```powershell
# ═══════════════════════════════════════════════════════════════
# Claude × gspowers × ruflo 金手指 - 完整安装流程
# AI 按顺序执行，无需用户介入（除 Token 配置和 superpowers 安装）
# ═══════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════
# 阶段一：环境准备
# ═══════════════════════════════════════════════════════════════

# [步骤 0] 检测环境
# 执行第一章的检测脚本，检测：
# - Claude Code、Git、Node.js、npm、ruflo 是否存在
# - 网络速度，自动切换镜像源（npm/GitHub）

# [步骤 1] 安装缺失工具
if (Git 不存在):
    winget install Git.Git
if (Node.js 不存在):
    winget install OpenJS.NodeJS.LTS
# 可选：Bun（推荐）
if (Bun 不存在):
    irm bun.sh/install.ps1 | iex

# ═══════════════════════════════════════════════════════════════
# 阶段二：核心安装
# ═══════════════════════════════════════════════════════════════

# [步骤 2] 安装 Claude Code（如缺失）
if (claude 命令不存在):
    irm https://claude.ai/install.ps1 | iex

# [步骤 3] 配置 API Token
# [需要用户介入] 提示用户在 Claude Code 中配置 Token
# 或使用模板创建 settings.json：
# 模板文件: templates/settings.json.template
# 目标位置: $env:USERPROFILE\.claude\settings.json
# 注意: 将 YOUR_TOKEN_HERE 替换为你的实际 Token

# [步骤 3.1] 安装 markitdown（MCP 文档转换工具）
npm install -g @digipair/skill-markitdown
claude mcp add markitdown -- npx -y @digipair/skill-markitdown

# [步骤 3.2] 安装 RTK（Token 节省工具，节省 60-90% token）
# 下载 RTK
curl -sL "https://github.com/rtk-ai/rtk/releases/download/v0.37.2/rtk-x86_64-pc-windows-msvc.zip" -o $env:TEMP\rtk.zip
Expand-Archive -Path $env:TEMP\rtk.zip -DestinationPath $env:TEMP\rtk -Force
# 安装到用户目录
$binDir = "$env:USERPROFILE\.local\bin"
New-Item -ItemType Directory -Force -Path $binDir
Move-Item "$env:TEMP\rtk\rtk.exe" "$binDir\rtk.exe"
# 初始化并自动修补 settings.json
& "$binDir\rtk.exe" init -g --auto-patch
# 验证
& "$binDir\rtk.exe" gain

# [步骤 3.3] 配置 Claude Code 权限模式（Yolo 模式）
# 在 settings.json 中添加：
# "permissions": { "defaultMode": "bypassPermissions" }
# "skipDangerousModePermissionPrompt": true

# ═══════════════════════════════════════════════════════════════
# 阶段三：ruflo 安装
# ═══════════════════════════════════════════════════════════════

# [步骤 4] 安装 ruflo（多 Agent + 记忆管理）
npm install -g ruflo
claude mcp add ruflo -- npx -y ruflo@latest mcp start

# [步骤 5] 创建全局配置
# 模板文件: templates/config.yaml.template
# 目标位置: $env:USERPROFILE\.claude-flow\config.yaml
# 配置：
# - memory.path: 全局记忆存储路径
# - agents: Agent 配置
# - defaults: 默认行为

# ═══════════════════════════════════════════════════════════════
# 阶段四：gspowers 生态安装
# ═══════════════════════════════════════════════════════════════

# [步骤 6] 安装 gstack（产品流程框架）
$skillsDir = "$env:USERPROFILE\.claude\skills"
if (!(Test-Path "$skillsDir\gstack")):
    git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git "$skillsDir\gstack"
    if (Test-Path "$skillsDir\gstack\setup"):
        & "$skillsDir\gstack\setup"

# [步骤 6.1] 安装 superpowers
# [需要用户介入] 在 Claude Code 中执行：
# /plugin install superpowers@claude-plugins-official

# [步骤 6.2] 安装 gspowers（SOP 导航）
if (!(Test-Path "$skillsDir\gspowers")):
    git clone https://github.com/fshaan/gspowers.git "$skillsDir\gspowers"

# ═══════════════════════════════════════════════════════════════
# 阶段五：gspowers 功能扩展（可选，需用户授权）
# ═══════════════════════════════════════════════════════════════

# [步骤 7] 技能扩充（用户说"允许 AI 自动扩充技能"后执行）

# 7.1 扩展 gspowers TDD 功能
# 模板文件: templates/tdd-config.yaml.template
# 目标位置: $env:USERPROFILE\.claude-flow\tdd-config.yaml
# 功能：强制测试先行模式（RED → GREEN → REFACTOR）

# 7.2 扩展 gspowers Wiki 生成功能
# 创建 $skillsDir\gspowers\wiki-helper.ps1
# 功能：上下文压缩，生成项目 Wiki

# 7.3 扩展 gspowers Pipeline 功能（多模块流水线）
# [重要] 复制 pipeline.md 到 $skillsDir\gspowers\references\pipeline.md
# 修改 $skillsDir\gspowers\references\execute.md
# 添加 pipeline-dev 流程（依赖解析、批次编排、门控验证）
# 详见第二十一章

# 7.4 创建全局 Git hooks
# 模板文件: templates/pre-commit.template
# 目标位置: $env:USERPROFILE\.claude-flow\hooks\pre-commit
# 功能：自动格式化、lint、测试

# ═══════════════════════════════════════════════════════════════
# 阶段六：验证
# ═══════════════════════════════════════════════════════════════

# [步骤 8] 验证安装
# 检查所有组件版本：
claude-flow --version      # ruflo
claude --version           # Claude Code
git --version              # Git
node --version             # Node.js
& "$env:USERPROFILE\.local\bin\rtk.exe" --version  # RTK
# 检查 MCP
claude mcp list            # 应包含 ruflo, markitdown
# 检查 skills
Get-ChildItem "$env:USERPROFILE\.claude\skills" -Directory

# ═══════════════════════════════════════════════════════════════
# 完成！
# ═══════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "✅ 安装完成！" -ForegroundColor Green
Write-Host ""
Write-Host "下一步："
Write-Host "  1. 进入项目: cd D:\project"
Write-Host "  2. 初始化: ruflo init --minimal --skip-claude"
Write-Host "  3. 打开 Claude Code: claude"
Write-Host ""
Write-Host "可选功能（用户授权后可用）："
Write-Host "  - 说 'TDD' 启用测试先行模式"
Write-Host "  - 说 '生成 Wiki' 压缩上下文"
Write-Host "  - 说 '/pipeline-dev' 启动多模块流水线开发"
Write-Host "  - 说 '安全审计' 启动三方协作评审"
```

### 步骤速查表

| 步骤 | 操作 | 必需 | 用户介入 |
|------|------|------|----------|
| 0 | 环境检测 | ✓ | |
| 1 | 安装 Git/Node.js | ✓ | |
| 2 | 安装 Claude Code | ✓ | |
| 3 | 配置 API Token | ✓ | **是** |
| 3.1 | 安装 markitdown | | |
| 3.2 | 安装 RTK | | |
| 3.3 | 配置权限模式 | | |
| 4 | 安装 ruflo | ✓ | |
| 5 | 创建全局配置 | ✓ | |
| 6 | 安装 gspowers 生态 | ✓ | |
| 6.1 | 安装 superpowers | | **是** |
| 7 | 技能扩充（TDD/Wiki/Pipeline） | | **是** |
| 8 | 验证安装 | ✓ | |

### 扩展功能清单

| 扩展名称 | 位置 | 功能说明 |
|----------|------|----------|
| TDD 流程 | gspowers/tdd-helper.ps1 | 强制测试先行模式 |
| Wiki 生成 | gspowers/wiki-helper.ps1 | 上下文压缩 |
| Pipeline 开发 | gspowers/references/pipeline.md | 多模块流水线 |
| RTK Token 节省 | .local/bin/rtk.exe | 节省 60-90% token |
| markitdown | MCP | Markdown 转换 |

---

## 九、目录结构

```
~$USERPROFILE/
├── .claude/
│   ├── skills/
│   │   ├── gstack/              # GStack（产品流程框架）
│   │   └── gspowers/           # gspowers（SOP 导航）
│   └── settings.json
├── .claude-flow/                 # ruflo 全局配置
│   ├── config.yaml             # 全局配置（记忆路径、agent 配置）
│   └── data/                    # 全局记忆存储（跨项目共享）
└── .claude/
    └── skills/                  # Claude Code skills（superpowers 等）
```

---

## 十、快速参考

```powershell
# 安装后验证
claude-flow --version          # ruflo 版本
claude mcp list                  # MCP 工具列表（应包含 ruflo）
git --version                   # Git 版本
node --version                  # Node.js 版本

# 新项目初始化
cd D:\project
ruflo init --minimal --skip-claude

# 启动 Claude Code
claude

# 常用触发词
安全审计                          # ruflo 三方协作
架构评审                          # ruflo 三方协作
/gspowers                        # gspowers SOP
/triple [任务]                   # 通用三方协作
```

---

## 十一、版本兼容性说明

| 工具        | 推荐版本 | 兼容性说明      |
| ----------- | -------- | --------------- |
| Claude Code | 最新版   | 主要界面        |
| ruflo       | v3.x     | 多 Agent + 记忆 |
| gstack      | 最新版   | 产品流程        |
| gspowers    | 最新版   | SOP 导航        |
| superpowers | 最新版   | 开发执行        |

> 本文档设计为长期可用。核心机制是 Claude Code + ruflo 的协作，无论工具版本如何更新，协作逻辑保持不变。

---

## 十二、上下文压缩与项目 Wiki 生成

### 12.1 功能说明

当对话上下文过长时，AI 应主动触发**上下文压缩**，生成项目 Wiki 文档，实现长期记忆和知识沉淀。

### 12.2 触发条件

```
触发条件（满足任一）：
- 对话轮次超过 10 轮
- 上下文 token 超过 80% 限制
- 用户说 "生成 Wiki" 或 "压缩上下文"
- 完成重要里程碑（功能开发、bug修复、设计决策）
```

### 12.3 压缩流程

```
1. AI 检测到需要压缩
       ↓
2. 分析当前项目结构
       ↓
3. 提取关键信息：
   - 已完成的功能清单
   - 技术决策记录
   - 遇到的问题和解决方案
   - 项目架构说明
   - 待办事项
       ↓
4. 生成 Wiki 文档
       ↓
5. 保存到 .claude-flow/wiki/ 目录
       ↓
6. 清理上下文，保留 Wiki 引用
```

### 12.4 Wiki 文档模板

```markdown
# [项目名] Wiki

> 自动生成时间: $DATE
> 最后更新: $DATE

## 项目概述

[项目简介、一句话描述]

## 技术栈

| 类别 | 技术 |
|------|------|
| 前端 | React, Next.js |
| 后端 | Node.js, Express |
| 数据库 | PostgreSQL |
| 部署 | Docker, K8s |

## 项目结构

```

src/
├── components/    # 组件
├── pages/        # 页面
├── api/          # API
└── utils/        # 工具函数

```

## 已完成功能

| 功能 | 完成日期 | 状态 |
|------|----------|------|
| 用户登录 | 2026-01-01 | 已上线 |
| 商品列表 | 2026-01-15 | 已上线 |

## 技术决策记录

### 决策 1: 选择 PostgreSQL 作为主数据库
- 日期: 2026-01-01
- 原因: 需要事务支持、JSON 字段、成熟生态
- 备选: MongoDB, MySQL

### 决策 2: 使用 Zustand 做状态管理
- 日期: 2026-01-05
- 原因: 轻量、TypeScript 支持好、够用就好
- 备选: Redux, MobX

## 遇到的问题和解决方案

### 问题 1: 登录会话过期
- 日期: 2026-01-10
- 现象: 用户频繁掉线
- 原因: Token 过期时间太短
- 解决: 延长 Token 有效期，增加 Refresh Token

## 待办事项

- [ ] 支付功能开发
- [ ] 邮件通知系统
- [ ] 管理后台

## 重要链接

- [Figma 设计稿](链接)
- [API 文档](链接)
- [监控面板](链接)
```

### 12.5 AI 自动执行命令

```powershell
# AI 执行压缩时
mkdir -p .claude-flow/wiki

# 生成 Wiki
cat > .claude-flow/wiki/project-wiki.md << 'EOF'
# 项目 Wiki 内容
EOF

# 清理上下文，保留引用
# AI 在后续对话中引用: "根据 project-wiki.md，我们之前决定..."
```

---

## 十三、gspowers TDD 扩展方案

### 13.1 问题

gspowers 的 `/subagent-dev` 默认没有强制 TDD（测试先行）流程。如果用户要求遵循 TDD，需要扩展 gspowers 的行为。

### 13.2 解决方案

当用户说"遵循 TDD"或"测试先行"时，AI 自动在 `/subagent-dev` 流程前插入 TDD 阶段。

### 13.3 TDD 扩展命令

当用户要求 TDD 时，AI 执行以下扩展流程：

```
┌─────────────────────────────────────────────────────────────┐
│  TDD 扩展流程（插入 /subagent-dev 之前）                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Phase 1: 写失败测试                                        │
│     - 先写测试（RED）                                       │
│     - 明确功能预期                                           │
│                                                             │
│  Phase 2: 最小实现                                          │
│     - 让测试通过（GREEN）                                   │
│     - 不追求完美，只求通过                                    │
│                                                             │
│  Phase 3: 重构                                             │
│     - 优化代码（REFACTOR）                                  │
│     - 确保测试仍然通过                                       │
│                                                             │
│  Phase 4: 提交                                             │
│     - commit 时附带测试覆盖率                                │
└─────────────────────────────────────────────────────────────┘
```

### 13.4 AI 自动 TDD 触发

用户只需说一句话，AI 自动执行完整 TDD：

```
你: "实现用户注册功能，遵循 TDD"
    ↓
AI:
  1. 先写测试: UserRegister.test.ts
  2. 运行测试 → 失败（RED）
  3. 写实现: UserRegister.ts
  4. 运行测试 → 通过（GREEN）
  5. 重构优化
  6. 提示你:
     "✅ TDD 完成
      测试: UserRegister.test.ts
      实现: UserRegister.ts
      覆盖率: 95%
      是否提交？"
    ↓
你: "是"
    ↓
git commit -m "[TDD] 实现用户注册功能"
```

### 13.5 TDD 配置文件

AI 会在项目目录创建 `.claude-flow/tdd-config.yaml`：

```yaml
# TDD 配置
tdd:
  enabled: true
  testFramework: "jest"  # jest / vitest / pytest / ...
  testDir: "src/__tests__"
  coverageThreshold: 80  # 覆盖率门槛
  phases:
    - write-test       # 先写测试
    - run-test-red     # 运行测试，确认失败
    - write-code        # 写实现代码
    - run-test-green   # 运行测试，确认通过
    - refactor          # 重构
    - commit            # 提交
```

### 13.6 TDD 执行命令参考

```powershell
# TDD 模式下的测试命令
npm test -- --coverage        # 运行测试并生成覆盖率
npm test -- --watch           # 监听模式，文件变化自动测试

# 覆盖率检查
npm test -- --coverage --coverageThreshold=80

# 如果覆盖率不达标，AI 会提示你
# "覆盖率仅 65%，未达到 80% 门槛，请增加测试或优化代码"
```

### 13.7 gspowers TDD 模式触发词

| 你说的话     | AI 行为                             |
| ------------ | ----------------------------------- |
| `TDD`      | 启用 TDD 模式，所有开发遵循测试先行 |
| `遵循 TDD` | 同上                                |
| `测试先行` | 同上                                |
| `关闭 TDD` | 恢复普通开发模式                    |

---

## 十四、AI 自动化技能扩充（无需用户手动）

### 14.1 说明

当用户授权"允许 AI 自动扩充技能"后，AI 可以自动为 gspowers 和其他工具添加新功能，无需用户提供额外文件或地址。

### 14.2 触发条件

```
用户说 "允许 AI 自动扩充技能" 或类似表述
    ↓
AI 开始检测和扩充
```

### 14.3 扩充范围

AI 会自动检测并扩充以下技能（如果存在）：

| 技能目录    | 扩充内容          | 说明                      |
| ----------- | ----------------- | ------------------------- |
| gspowers    | TDD 流程          | 强制测试先行模式          |
| gspowers    | Wiki 生成         | 上下文压缩触发            |
| gspowers    | 代码审查增强      | 多 Agent 协作评审         |
| gstack      | 架构决策记录      | 自动记录设计决策          |
| superpowers | 子 Agent 记忆共享 | 同一项目 Agent 共享上下文 |
| 全局        | Git hook          | 自动格式化、lint、测试    |

### 14.4 自动扩充命令

```powershell
# ═══════════════════════════════════════════════════════════════
# AI 自动技能扩充脚本
# 当用户授权后，AI 执行此脚本
# ═══════════════════════════════════════════════════════════════

# 1. 检测现有技能
$skillsDir = "$env:USERPROFILE\.claude\skills"

# 2. 为 gspowers 添加 TDD 扩展
if (Test-Path "$skillsDir\gspowers") {
    Write-Host "扩展 gspowers TDD 功能..."

    # 创建 TDD 辅助脚本
    $tddHelper = @"
# gspowers TDD 扩展
# 自动插入测试先行流程

function Invoke-TDD-Cycle {
    param([string]`$task)

    Write-Host "[TDD] Phase 1: 写失败测试"
    # AI 先写测试

    Write-Host "[TDD] Phase 2: 运行测试 (RED)"
    # AI 运行测试，确认失败

    Write-Host "[TDD] Phase 3: 写实现 (GREEN)"
    # AI 写最小实现

    Write-Host "[TDD] Phase 4: 重构 (REFACTOR)"
    # AI 重构优化

    Write-Host "[TDD] Phase 5: 提交"
    # AI 提交代码
}
"@

    $tddHelper | Out-File -FilePath "$skillsDir\gspowers\tdd-helper.ps1" -Encoding UTF8
    Write-Host "  ✓ gspowers TDD 扩展已添加"
}

# 3. 为 gspowers 添加 Wiki 生成功能
if (Test-Path "$skillsDir\gspowers") {
    Write-Host "扩展 gspowers Wiki 生成功能..."

    $wikiHelper = @"
# gspowers Wiki 生成扩展
# 上下文压缩触发

function New-ProjectWiki {
    param([string]`$projectPath)

    `$wikiDir = Join-Path `$projectPath ".claude-flow\wiki"
    if (!(Test-Path `$wikiDir)) {
        New-Item -ItemType Directory -Force -Path `$wikiDir | Out-Null
    }

    # 生成 Wiki
    `$content = @"
# `$(Split-Path `$projectPath -Leaf) Wiki
# 生成时间: `$(Get-Date -Format 'yyyy-MM-dd HH:mm')

## 项目概述
[请 AI 补充]

## 技术栈
[请 AI 补充]

## 项目结构
[请 AI 补充]

## 已完成功能
[请 AI 补充]

## 技术决策记录
[请 AI 补充]

## 待办事项
[请 AI 补充]
"@

    `$content | Out-File -FilePath "`$wikiDir\project-wiki.md" -Encoding UTF8
    Write-Host "  ✓ Wiki 已生成: `$(`$wikiDir\project-wiki.md)"
}
"@

    $wikiHelper | Out-File -FilePath "$skillsDir\gspowers\wiki-helper.ps1" -Encoding UTF8
    Write-Host "  ✓ gspowers Wiki 扩展已添加"
}

# 4. 创建全局 Git hooks（自动格式化/测试）
$hooksDir = "$env:USERPROFILE\.claude-flow\hooks"
New-Item -ItemType Directory -Force -Path `$hooksDir

$preCommitHook = @"
#!/bin/bash
# 自动 pre-commit hook
# 格式化代码、运行测试

echo "Running pre-commit checks..."

# 格式化
npm run format 2>/dev/null || true

# lint
npm run lint 2>/dev/null || true

# 测试
npm test -- --coverage 2>/dev/null || true

echo "Pre-commit complete"
"@

$preCommitHook | Out-File -FilePath "$hooksDir\pre-commit" -Encoding ASCII
Write-Host "  ✓ Git hooks 已配置"

# 5. 输出扩充结果
Write-Host ""
Write-Host "═" * 60
Write-Host "✅ 技能扩充完成"
Write-Host "═" * 60
Write-Host ""
Write-Host "已扩展:"
Write-Host "  ✓ gspowers TDD 流程"
Write-Host "  ✓ gspowers Wiki 生成"
Write-Host "  ✓ Git hooks (format/lint/test)"
Write-Host ""
Write-Host "使用方式:"
Write-Host "  说 'TDD' 启用测试先行模式"
Write-Host "  说 '生成 Wiki' 压缩上下文"
```

### 14.5 扩充后的功能触发

| 用户授权后说          | AI 自动执行                   |
| --------------------- | ----------------------------- |
| `TDD`               | 启用 TDD 开发模式（测试先行） |
| `生成 Wiki`         | 压缩上下文，生成项目 Wiki     |
| `遵循 TDD + 功能名` | TDD 模式实现功能              |
| `关闭 TDD`          | 恢复普通开发模式              |

---

## 十五、一键完整安装脚本

> 以下脚本由 AI 读取后自动执行，完成所有配置
>
> **版本**：v1.3（完整版）

```powershell
# ═══════════════════════════════════════════════════════════════
# Claude × gspowers × ruflo 金手指 - 一键安装脚本
# AI 执行，无需用户介入（除 Token 配置和 superpowers 安装）
# 版本：v1.3（包含 RTK、TDD、Pipeline 扩展）
# ═══════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗"
Write-Host "║  Claude × gspowers × ruflo 金手指 - 一键安装                ║"
Write-Host "║  版本: v1.3（完整版）                                      ║"
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 阶段一：环境准备
# ═══════════════════════════════════════════════════════════════

Write-Host "[1/9] 检测环境..." -ForegroundColor Yellow
# 检测操作系统、已安装工具、网络速度
# （参见第一章）

Write-Host "[2/9] 安装缺失工具..." -ForegroundColor Yellow
# 如果 Git 缺失 → winget install Git.Git
# 如果 Node.js 缺失 → winget install OpenJS.NodeJS.LTS
# （参见第三章步骤1）

# ═══════════════════════════════════════════════════════════════
# 阶段二：核心安装
# ═══════════════════════════════════════════════════════════════

Write-Host "[3/9] 安装 Claude Code..." -ForegroundColor Yellow
# 如果 claude 命令不存在
irm https://claude.ai/install.ps1 | iex
# （参见第三章步骤2）

Write-Host "[3.1/9] 配置 API Token..." -ForegroundColor Yellow
# [需要用户介入]
# 提示用户在 Claude Code 中配置 Token
# 或创建 $env:USERPROFILE\.claude\settings.json
# （参见第三章步骤3）

Write-Host "[3.2/9] 安装 markitdown..." -ForegroundColor Yellow
npm install -g @digipair/skill-markitdown
claude mcp add markitdown -- npx -y @digipair/skill-markitdown

Write-Host "[3.3/9] 安装 RTK（Token 节省 60-90%）..." -ForegroundColor Yellow
# 下载 RTK
$rtkUrl = "https://github.com/rtk-ai/rtk/releases/download/v0.37.2/rtk-x86_64-pc-windows-msvc.zip"
curl -sL $rtkUrl -o $env:TEMP\rtk.zip
Expand-Archive -Path $env:TEMP\rtk.zip -DestinationPath $env:TEMP\rtk -Force
# 安装到用户目录
$binDir = "$env:USERPROFILE\.local\bin"
New-Item -ItemType Directory -Force -Path $binDir
Move-Item "$env:TEMP\rtk\rtk.exe" "$binDir\rtk.exe"
# 初始化并自动修补 settings.json
& "$binDir\rtk.exe" init -g --auto-patch
& "$binDir\rtk.exe" gain

Write-Host "[3.4/9] 配置权限模式（Yolo）..." -ForegroundColor Yellow
# 在 settings.json 中添加 bypassPermissions 配置
# （参见第三章步骤3.3）

# ═══════════════════════════════════════════════════════════════
# 阶段三：ruflo 安装
# ═══════════════════════════════════════════════════════════════

Write-Host "[4/9] 安装 ruflo..." -ForegroundColor Yellow
npm install -g ruflo
claude mcp add ruflo -- npx -y ruflo@latest mcp start

Write-Host "[5/9] 创建全局配置..." -ForegroundColor Yellow
# 创建 $env:USERPROFILE\.claude-flow\config.yaml
# （参见第三章步骤5）

# ═══════════════════════════════════════════════════════════════
# 阶段四：gspowers 生态安装
# ═══════════════════════════════════════════════════════════════

Write-Host "[6/9] 安装 gstack..." -ForegroundColor Yellow
$skillsDir = "$env:USERPROFILE\.claude\skills"
if (!(Test-Path "$skillsDir\gstack")):
    git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git "$skillsDir\gstack"
    if (Test-Path "$skillsDir\gstack\setup"):
        & "$skillsDir\gstack\setup"

Write-Host "[6.1/9] 安装 superpowers..." -ForegroundColor Yellow
# [需要用户介入]
Write-Host "请在 Claude Code 中执行: /plugin install superpowers@claude-plugins-official" -ForegroundColor Cyan

Write-Host "[6.2/9] 安装 gspowers..." -ForegroundColor Yellow
if (!(Test-Path "$skillsDir\gspowers")):
    git clone https://github.com/fshaan/gspowers.git "$skillsDir\gspowers"

# ═══════════════════════════════════════════════════════════════
# 阶段五：gspowers 功能扩展（可选，需用户授权）
# ═══════════════════════════════════════════════════════════════

Write-Host "[7/9] 技能扩充（等待用户授权）..." -ForegroundColor Yellow
# 等待用户说 "允许 AI 自动扩充技能"
# 如果已授权，执行以下扩展：

# 7.1 扩展 gspowers TDD 功能
Write-Host "  ✓ 扩展 gspowers TDD 功能..."
# 创建 $skillsDir\gspowers\tdd-helper.ps1

# 7.2 扩展 gspowers Wiki 生成功能
Write-Host "  ✓ 扩展 gspowers Wiki 生成功能..."
# 创建 $skillsDir\gspowers\wiki-helper.ps1

# 7.3 扩展 gspowers Pipeline 功能（多模块流水线）
Write-Host "  ✓ 扩展 gspowers Pipeline 功能..."
# 复制 pipeline.md 到 $skillsDir\gspowers\references\pipeline.md
# 修改 execute.md 添加 pipeline-dev 流程
# 参见第二十一章

# 7.4 创建全局 Git hooks
Write-Host "  ✓ 创建全局 Git hooks..."
# 创建 $env:USERPROFILE\.claude-flow\hooks\pre-commit

# ═══════════════════════════════════════════════════════════════
# 阶段六：验证
# ═══════════════════════════════════════════════════════════════

Write-Host "[8/9] 验证安装..." -ForegroundColor Yellow
claude-flow --version
claude --version
git --version
node --version
& "$binDir\rtk.exe" --version
claude mcp list

Write-Host "[9/9] 清理..." -ForegroundColor Yellow
Remove-Item $env:TEMP\rtk.zip -Force -ErrorAction SilentlyContinue

# ═══════════════════════════════════════════════════════════════
# 完成！
# ═══════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ 安装完成！版本: v1.3" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "下一步："
Write-Host "  1. 进入项目: cd D:\project" -ForegroundColor White
Write-Host "  2. 初始化: ruflo init --minimal --skip-claude" -ForegroundColor White
Write-Host "  3. 打开 Claude Code: claude" -ForegroundColor White
Write-Host ""
Write-Host "可选功能（用户授权后可用）：" -ForegroundColor Yellow
Write-Host "  - 说 'TDD' 启用测试先行模式" -ForegroundColor Gray
Write-Host "  - 说 '生成 Wiki' 压缩上下文" -ForegroundColor Gray
Write-Host "  - 说 '/pipeline-dev' 启动多模块流水线开发" -ForegroundColor Gray
Write-Host "  - 说 '安全审计' 启动三方协作评审" -ForegroundColor Gray
```

---

## 十六、用户授权声明

> 以下内容在用户说"允许 AI 自动扩充技能"时触发

```
用户授权后，AI 可以：
✓ 扩展 gspowers 功能（TDD、Wiki 生成、Pipeline 多模块流水线）
✓ 创建/修改项目配置文件
✓ 安装额外工具（如果需要）
✓ 生成项目 Wiki 和文档

用户随时可以说"停止技能扩充"取消授权
```

### 16.1 授权后可用的扩展功能

| 扩展名称 | 触发词 | 功能说明 |
|----------|--------|----------|
| TDD 流程 | `TDD` / `遵循 TDD` | 强制测试先行模式 |
| Wiki 生成 | `生成 Wiki` | 上下文压缩 |
| Pipeline 开发 | `/pipeline-dev` | 多模块依赖流水线开发 |
| Git hooks | 自动 | pre-commit 格式化/lint/测试 |

### 16.2 扩展安装位置

| 扩展 | 目标路径 |
|------|----------|
| TDD 流程 | `~/.claude/skills/gspowers/tdd-helper.ps1` |
| Wiki 生成 | `~/.claude/skills/gspowers/wiki-helper.ps1` |
| Pipeline 开发 | `~/.claude/skills/gspowers/references/pipeline.md` |
| Git hooks | `~/.claude-flow/hooks/pre-commit` |

---

## 十七、gspowers 多模块流水线扩展

> **目标**：在 gspowers 的 `/subagent-dev` 基础上，增加多模块依赖感知流水线开发能力
>
> **改造点**：B（增强 gspowers 的 `/subagent-dev`）
>
> **补丁位置**：`gspowers-pipeline-patch/`

### 17.1 扩展背景

gspowers 原生的 `/subagent-dev` 是针对**单模块**的 TDD 开发流程。但实际项目中经常遇到**多模块有依赖**的场景：

```
典型场景：
├── 用户服务（user-service）      - 无依赖
├── 商品服务（product-service）  - 依赖用户服务
├── 订单服务（order-service）    - 依赖用户服务 + 商品服务
└── 支付服务（payment-service）  - 依赖订单服务
```

原有的单模块开发无法处理模块间的**执行顺序**和**依赖验证**。

### 17.2 扩展方案

#### 改造文件清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `references/pipeline.md` | **新增** | 多模块流水线开发完整规范 |
| `references/execute.md` | **修改** | 在 subagent-dev 步骤中添加 Pipeline 路由 |

#### 补丁文件位置

```
gspowers-pipeline-patch/
├── pipeline.md           # 新增文件内容
├── execute-patch.md       # 修改 execute.md 的详细说明
└── install-pipeline.ps1   # 自动安装脚本
```

### 17.3 安装步骤

#### 方式一：手动安装

1. 复制 `pipeline.md` 到 `~/.claude/skills/gspowers/references/pipeline.md`
2. 按照 `execute-patch.md` 的说明修改 `execute.md`

#### 方式二：自动安装

```powershell
# 运行安装脚本
./gspowers-pipeline-patch/install-pipeline.ps1

# 该脚本会：
# 1. 备份原始 execute.md
# 2. 复制 pipeline.md
# 3. 提示手动应用 execute.md 补丁
```

#### 方式三：让 AI 自动应用

```
请根据 gspowers-pipeline-patch/execute-patch.md 的说明
修改 ~/.claude/skills/gspowers/references/execute.md
```

### 17.4 核心概念

#### 17.4.1 依赖解析

自动分析模块间的依赖关系，构建 DAG（有向无环图）：

```
用户输入：
  - 模块A（无依赖）
  - 模块B（依赖A）
  - 模块C（依赖A、B）
  - 模块D（依赖B、C）

解析结果：
  graph = {
    A: [],
    B: [A],
    C: [A, B],
    D: [B, C]
  }
```

#### 17.4.2 批次划分

根据 DAG 拓扑排序，自动划分执行批次：

```
批次1: [A]           - 无依赖的模块先执行
批次2: [B]           - 依赖 A 的模块
批次3: [C]           - 依赖 A、B 的模块
批次4: [D]           - 依赖 B、C 的模块
```

#### 17.4.3 门控验证

每个批次执行完成后进行门控检查：

| 结果 | 后续动作 |
|------|----------|
| 全部 `passed` | 进入下一批次 |
| 有 `failed` | 终止流水线，提示用户修复 |

#### 17.4.4 模块状态

| 状态 | 说明 |
|------|------|
| `pending` | 等待执行 |
| `running` | 执行中 |
| `passed` | 测试全部通过 |
| `failed` | 测试未通过或执行错误 |
| `skipped` | 依赖失败，跳过 |

### 17.5 触发方式

#### 方式一：显式触发

```
/pipeline-dev
多模块开发
流水线开发
```

#### 方式二：配置触发

在 `implementation-plan.md` 中添加 `pipeline.modules` 配置：

```yaml
pipeline:
  enabled: true
  modules:
    - name: user-service
      path: services/user
      depends_on: []
    - name: product-service
      path: services/product
      depends_on: [user-service]
    - name: order-service
      path: services/order
      depends_on: [user-service, product-service]
```

#### 方式三：对话触发

用户描述模块配置，AI 自动解析：

```
你：项目有四个模块，用户、商品、订单、支付，订单依赖前两个，支付依赖订单
AI：已识别模块依赖关系，自动进入 Pipeline 模式
```

### 17.6 state.json 扩展

Pipeline 模式需要在 `state.json` 中新增 `pipeline` 节点：

```json
{
  "version": "1.2",
  "pipeline": {
    "enabled": true,
    "modules": {
      "user-service": {
        "name": "user-service",
        "display_name": "用户服务",
        "path": "services/user",
        "depends_on": [],
        "status": "pending",
        "batch": 1
      },
      "product-service": {
        "name": "product-service",
        "path": "services/product",
        "depends_on": ["user-service"],
        "status": "pending",
        "batch": 2
      }
    },
    "batches": [
      ["user-service"],
      ["product-service"]
    ],
    "current_batch": 1
  }
}
```

### 17.7 执行流程

```
用户: /gspowers
    ↓
检测到需要 Pipeline 模式
    ↓
pipeline-init（初始化）
    - 解析模块配置
    - 构建 DAG
    - 检测循环依赖
    - 划分批次
    - 显示流水线概览
    ↓
用户: /gspowers（继续）
    ↓
pipeline-execute（批次执行）
    ↓
pipeline-gate-check（门控检查）
    ↓
通过 → 进入下一批次
失败 → 终止，等待修复
    ↓
所有批次完成
    ↓
pipeline-complete（流水线完成）
    ↓
进入 finish 阶段（/review）
```

### 17.8 断点恢复

如果流水线中途失败/中断，恢复时：

```
检测到未完成的流水线

当前状态:
├─ 批次1: user-service ✓ passed
├─ 批次2: product-service ✓ passed
├─ 批次3: order-service ✗ failed (测试失败)
└─ 批次4: payment-service ○ pending

是否从批次3继续？（是 / 重新开始）
```

### 17.9 与原有 subagent-dev 的关系

| 方面 | subagent-dev（单模块） | pipeline-dev（多模块） |
|------|------------------------|------------------------|
| 适用场景 | 单个功能/模块开发 | 多模块有依赖的系统 |
| 执行方式 | 串行 | 批次并行 + 批次串行 |
| 依赖处理 | 无 | DAG 解析 + 门控验证 |
| 状态粒度 | 整体 pass/fail | 模块级状态追踪 |
| 恢复能力 | 无 | 支持断点恢复 |
| 后向兼容 | - | 单模块时自动退化为单模块模式 |

### 17.10 典型使用场景

#### 场景一：微服务开发

```
模块：api-gateway, user-service, auth-service, product-service, order-service, payment-service
依赖：
  - api-gateway: 无
  - user-service: 无
  - auth-service → user-service
  - product-service: 无
  - order-service → user-service, product-service
  - payment-service → order-service
```

#### 场景二：前后端分离

```
前端模块：shared-components, user-pages, admin-pages, dashboard
后端模块：core, api
依赖：
  - core: 无
  - api → core
  - shared-components: 无
  - user-pages → shared-components
  - admin-pages → shared-components
  - dashboard → shared-components, user-pages
```

#### 场景三：前后端分离项目（并行开发）

```
Backend: core → api
Frontend: shared → pages

可以：
  批次1: backend-core + frontend-shared（并行）
  批次2: backend-api + frontend-pages（并行）
  批次3: integration-test
```

### 17.11 已知限制

1. **循环依赖检测**：如果存在循环依赖，流水线会报错并停止
2. **跨批次接口变更**：当模块接口变更时，需要手动同步到依赖模块
3. **测试隔离**：确保模块测试是隔离的，不会相互影响

---

## 十八、完整触发词速查表

| 触发词                      | 功能                       | 来源              |
| --------------------------- | -------------------------- | ----------------- |
| `/gspowers`               | 启动 SOP 流程导航          | gspowers          |
| `/office-hours`           | YC 式产品拷问              | gspowers          |
| `/brainstorm`             | 苏格拉底式设计细化         | gspowers          |
| `/subagent-dev`           | 子代理 TDD 开发            | gspowers          |
| `/review`                 | 代码审查                   | gspowers          |
| `/qa`                     | 浏览器 QA                  | gspowers          |
| `/ship`                   | 发布 PR                    | gspowers          |
| `安全审计`                | 多 Agent 安全漏洞扫描      | ruflo             |
| `架构评审`                | 多 Agent 系统架构评估      | ruflo             |
| `QA团队`                  | 多 Agent 测试质量评审      | ruflo             |
| `三方调研`                | 多 Agent 通用研究任务      | ruflo             |
| `triple [任务]`           | 通用三方协作               | ruflo             |
| `mastergo` / `原型解析` | MasterGo 原型生成 PRD/Spec | mastergo-prd-spec |
| `全量解析原型`            | 解析整个原型生成完整文档   | mastergo-prd-spec |
| `单功能解析 [页面]`       | 解析单个页面/模块          | mastergo-prd-spec |
| `TDD`                     | 启用测试先行模式           | 扩展              |
| `关闭 TDD`                | 恢复普通开发模式           | 扩展              |
| `生成 Wiki`               | 压缩上下文，生成项目 Wiki  | 扩展              |
| `允许 AI 自动扩充技能`    | 授权 AI 扩展工具功能       | 用户              |
| `停止技能扩充`            | 取消授权                   | 用户              |
| `/pipeline-dev`          | 多模块流水线开发           | gspowers-pipeline |
| `多模块开发`              | 同上                       | gspowers-pipeline |
| `流水线开发`              | 同上                       | gspowers-pipeline |

---

## 十九、最终说明

```
本文档是 AI 可完整执行的安装和操作指南。

用户只需：
1. 把本文档给 AI 阅读
2. AI 自动完成所有安装和配置
3. 用户授权（可选）AI 自动扩充技能

之后用户可以：
- 在任意项目目录打开 Claude Code
- 说触发词执行各种功能
- 授权 AI 自动管理代码和 Git

全程无需手动安装工具、配置环境，AI 全部自动完成。
```
