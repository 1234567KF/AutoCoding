# AI编程智驾 — 单文件入口

> **AI 必读并完整执行**。你只需要这一个文件，放入任意 AI IDE（Claude Code / Trae / Cursor），即可自动完成全部安装配置。

---

## 你需要做什么

```
用户: 把这个文件放到任意目录，用 AI IDE 打开，说"执行安装" 或 "执行更新"
  ↓
你(AI): 按下面阶段依次执行，遇到错误自动修复，不要中断
  ↓
结果: 完整的 AI 编程工作台就绪（安装）/ 已更新到最新版（更新）
```

| 操作 | 触发词 | 适用场景 |
|------|--------|---------|
| 安装 | "执行安装" | 从零开始，全新安装 |
| 更新 | "执行更新" | 已有安装，升级到最新版 |

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
git clone https://github.com/1234567KF/AutoCoding.git $env:TEMP\AICoding

# 备选（中国区镜像，自动切换）
# git clone https://ghproxy.com/https://github.com/1234567KF/AutoCoding.git $env:TEMP\AICoding
```

**下载后，你(AI)必须**：
1. 进入项目目录：`cd $env:TEMP\AICoding` (Windows) / `cd /tmp/AICoding` (Linux/macOS)
2. 读取 `docs/INSTALL.md` 文件
3. **严格按照 docs/INSTALL.md 的指令完成所有安装步骤**

---

## 阶段3：按 docs/INSTALL.md 完成安装

docs/INSTALL.md 包含以下步骤（你逐项执行）：

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

**执行原则（来自 docs/INSTALL.md）**：
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

## 阶段5：更新已有安装

> 用户说"执行更新"时，跳过阶段0-3，直接执行本阶段。

**步骤1 — 定位已有项目**

检查以下路径，找到已克隆的项目目录：

| 平台 | 常见路径 |
|------|---------|
| Windows | `$env:TEMP\AICoding`、`$env:USERPROFILE\AICoding`、`$env:USERPROFILE\AutoCoding` |
| Linux/macOS | `/tmp/AICoding`、`~/AICoding`、`~/AutoCoding` |

如果一个都没找到 → 回退到阶段2（重新克隆）。

**步骤2 — 拉取最新代码**

```powershell
cd <项目目录>
git pull origin main
```

如果 git pull 失败（网络问题），自动切换镜像后重试：
```powershell
git -c url."https://ghproxy.com/https://github.com/".insteadOf "https://github.com/" pull origin main
```

**步骤3 — 重新运行本地安装脚本**

```powershell
# Windows
.\.claude\install-local.ps1

# Linux/macOS
bash .claude/install-local.sh
```

这会更新所有技能文件到最新版本，已存在的配置文件不会被覆盖。

**步骤4 — 更新全局组件（可选，按需提示）**

检测全局工具版本，如果版本过旧则提示用户升级：

| 组件 | 检查命令 | 升级命令 |
|------|---------|---------|
| ruflo | `npm ls -g ruflo` | `npm update -g ruflo` |
| RTK | `rtk --version` | 重新下载最新 RTK 二进制 |
| Claude Code | `claude --version` | `npm update -g @anthropic-ai/claude-code` |

**注意**：全局组件升级是可选操作，不强制。仅当现有版本无法正常工作时才需要升级。

**步骤5 — 验证更新**

```powershell
# 检查 git log 确认已更新到最新
git log --oneline -3
```

---

## 完成提示

**安装完成后**，提示用户：

```
✅ AI编程智驾 安装完成！

快速开始：
  1. 输入 /go 查看完整开发工作流，AI 会引导你一步步走
  2. 或者直接开始：整理需求 → /prd-generator → /kf-spec → 出代码
  3. 常用触发词: /go | /gspowers | /夯 | /对齐
```

**更新完成后**，提示用户：

```
✅ AI编程智驾 已更新到最新版！

最近更新：
  （从 git log --oneline -5 提取）

确认：
  1. 技能已刷新：.claude/skills/
  2. 配置文件未被覆盖：.claude/settings.json、.claude-flow/config.yaml
  3. 如需更新全局组件（ruflo/RTK/Claude Code），请手动执行
```

---

## 注意事项

1. **Token 配置**是唯一必须用户介入的步骤，其他全部自动
2. **跨平台**：脚本自动适配 Windows/Linux/macOS
3. **中国区**：自动检测网络并切换 npm/GitHub 镜像
4. **Trae/Cursor 用户**：跳过 Claude Code 安装，使用当前 AI IDE 即可
5. **幂等性**：本流程可以安全地重复运行，已安装的组件会跳过
