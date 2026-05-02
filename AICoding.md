# AI编程智驾 — 单文件入口

> **AI 必读并完整执行**。你只需要这一个文件，放入任意 AI IDE（Claude Code / Trae / Cursor），即可自动完成全部安装配置。

---

## 你需要做什么

```
用户: 把这个文件放到任意目录，用 AI IDE 打开，说"执行安装"
  ↓
你(AI): 按下面4个阶段依次执行，遇到错误自动修复，不要中断
  ↓
结果: 完整的 AI 编程工作台就绪
```

---

## 阶段0：平台与网络检测

```powershell
# 检测操作系统
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $PLATFORM = "windows"
} elseif ($IsLinux -or (Test-Path "/proc/version")) {
    $PLATFORM = "linux"
} elseif ($IsMacOS) {
    $PLATFORM = "macos"
}

Write-Host "检测到平台: $PLATFORM"
```

**网络检测**：如果 npm/git 访问缓慢（>3秒），自动切换中国区镜像：
```powershell
# npm镜像: npm config set registry https://registry.npmmirror.com
# git镜像: git config --global url."https://ghproxy.com/https://github.com/".insteadOf "https://github.com/"
```

---

## 阶段1：安装基础工具

检测并安装缺失的工具：

| 工具 | Windows 安装 | Linux/macOS 安装 |
|------|-------------|-----------------|
| Git | `winget install Git.Git` | `sudo apt install git` / `brew install git` |
| Node.js | `winget install OpenJS.NodeJS.LTS` | `curl -fsSL https://deb.nodesource.com/setup_lts.x \| sudo bash -` |
| Claude Code | `irm https://claude.ai/install.ps1 \| iex` | `npm install -g @anthropic-ai/claude-code` |

**注意**：如果用户使用的是 Trae/Cursor 而非 Claude Code，跳过 Claude Code 安装，使用当前 AI IDE 即可。

---

## 阶段2：下载项目仓库

> **推荐方式**：从 GitHub 克隆最新版本。如果 GitHub 访问慢，自动切换到镜像。

```powershell
# 主源（GitHub）
git clone https://github.com/1234567KF/AutoCoding.git $env:TEMP\AutoCoding

# 备选（中国区镜像，自动切换）
# git clone https://ghproxy.com/https://github.com/1234567KF/AutoCoding.git $env:TEMP\AutoCoding
```

**下载后，你(AI)必须**：
1. 进入项目目录：`cd $env:TEMP\AutoCoding` (Windows) / `cd /tmp/AutoCoding` (Linux/macOS)
2. 读取 `INSTALL.md` 文件
3. **严格按照 INSTALL.md 的指令完成所有安装步骤**

---

## 阶段3：按 INSTALL.md 完成安装

INSTALL.md 包含以下步骤（你逐项执行）：

| 步骤 | 内容 | 自动 |
|------|------|------|
| 环境检测 | 检查已安装的工具版本 | ✓ |
| 安装 ruflo | `npm install -g ruflo` | ✓ |
| 配置 MCP | `claude mcp add ruflo -- npx -y ruflo@latest mcp start` | ✓ |
| 安装 markitdown | `npm install -g @digipair/skill-markitdown` | ✓ |
| 安装 RTK | 从 GitHub 下载 RTK 二进制 | ✓ |
| 安装 gspowers/gstack | 克隆到 `~/.claude/skills/` | ✓ |
| 配置 ruflo 全局配置 | 创建 `~/.claude-flow/config.yaml` | ✓ |
| 配置 API Token | 在 `~/.claude/settings.json` 中设置 | **需用户提供** |
| 安装 superpowers | `/plugin install superpowers@claude-plugins-official` | **需用户确认** |
| 配置权限模式 | 设置 bypassPermissions | ✓ |

**执行原则（来自 INSTALL.md）**：
1. 先检测，缺什么装什么
2. Token 配置需要用户介入，提示用户提供
3. 遇到错误自动修复，不中断（自愈式控制）
4. 网络问题自动切换中国区镜像

---

## 阶段4：验证安装

```powershell
# 检查所有组件
git --version
node --version
npm --version
claude-flow --version       # ruflo
claude mcp list             # 应包含 ruflo, markitdown

# 检查技能目录
Get-ChildItem "$env:USERPROFILE\.claude\skills" -Directory  # Windows
ls ~/.claude/skills/                                         # Linux/macOS
```

---

## 验证完成

安装完成后，提示用户：

```
✅ AI编程智驾 安装完成！

下一步：
  1. 在新项目目录运行: ruflo init --minimal --skip-claude
  2. 启动 AI IDE 开始编程
  3. 常用触发词: /gspowers | 安全审计 | TDD | triple [任务]
```

---

## 注意事项

1. **Token 配置**是唯一必须用户介入的步骤，其他全部自动
2. **跨平台**：脚本自动适配 Windows/Linux/macOS
3. **中国区**：自动检测网络并切换 npm/GitHub 镜像
4. **Trae/Cursor 用户**：跳过 Claude Code 安装，使用当前 AI IDE 即可
5. **幂等性**：本流程可以安全地重复运行，已安装的组件会跳过
