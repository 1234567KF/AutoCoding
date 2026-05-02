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

---

## 模型智能路由

### 什么时候用什么模型？

| 场景 | 推荐模型 | 原因 |
|------|---------|------|
| 架构设计 / 需求澄清 | **deepseek-v4-pro**（Opus 级） | 需要深度推理、权衡取舍 |
| 复杂 Bug 排查 | **deepseek-v4-pro**（Opus 级） | 需要完整上下文理解和推理链 |
| 日常编码 / 执行 | **deepseek-v4-flash**（Sonnet 级） | 效率优先，常规任务性价比高 |
| 代码审查 | **deepseek-v4-flash**（Sonnet 级） | 模式匹配为主 |
| 文档生成 | **deepseek-v4-flash**（Sonnet 级） | 结构化输出，低成本 |
| 简单问答 / 格式转换 | 轻量模型（Haiku 级） | 极低成本，快速响应 |

### 切换是自动的吗？

**不是自动的。** kf-model-router 是一个建议/推荐系统，不会自动切换模型。原理：

- 当前环境模型由 Claude Code 启动时指定（如 deepseek-v4-pro）
- kf-model-router 只是**分析任务类型并推荐**应该用哪个模型
- 用户需要**手动执行** `/set-model opus|sonnet|haiku` 来切换
- **用户有感知**：每次切换都需要手动操作，AI 不会静默切换

### kf-model-router 会被其他技能自动调用吗？

**不会。** 没有任何技能会自动调用 kf-model-router。各技能是**独立运行**的，kf-model-router 的"集成"描述（配合 kf-spec、kf-code-review-graph 等）指的是**用户手动配合使用**，而非程序自动触发。

---

## 全局技能调用链

> 以下表格展示所有技能的**调用关系**和**模型需求**。调用关系分三种：
> - **独立**：不依赖也不调用其他技能，完全自包含
> - **内部 spawn**：技能执行时会 spawn 子 Agent 并行工作
> - **手动配合**：建议与其他技能搭配使用，但需用户手动触发

### kf- 系列（团队自建）

| 技能 | 原则 | 调用类型 | 调用/依赖的技能 | 推荐模型 | 说明 |
|------|------|---------|----------------|---------|------|
| `kf-go` | 快 | 独立 | 无 | flash | 工作流导航，纯展示不执行 |
| `kf-spec` | 快 | 独立 | 无（Step 0 建议配合 kf-model-router） | pro→flash | Spec 驱动：需求→分步实施 |
| `kf-code-review-graph` | 省 | 独立 | 无（建议配合 kf-model-router） | flash | 代码审查依赖图谱 |
| `kf-web-search` | 准 | 独立 | 无 | flash | 多引擎智能搜索 |
| `kf-browser-ops` | 测的准 | 独立 | 无 | flash | Playwright 浏览器自动化 |
| `kf-multi-team-compete` | 夯 | **内部 spawn** | 内部 spawn 3 个 Agent（红蓝绿队） | pro（裁判）+ flash（各队） | 多 Agent 并发竞争评审 |
| `kf-alignment` | 懂 | 独立 | 无 | pro | 对齐工作流：动前谈理解，动后谈 diff |
| `kf-model-router` | 省 | 独立 | 无（**不被任何技能自动调用**） | flash | 模型路由建议，需用户手动 /set-model |
| `kf-prd-generator` | 快 | 独立 | 无 | flash | SDD Excel → PRD |
| `kf-triple-collaboration` | 夯 | **内部 spawn** | 内部 spawn Agent（三方协作） | pro（协调）+ flash（各方） | 三方协作评审 |
| `kf-ui-prototype-generator` | 快 | 独立 | 无 | flash | UI 原型 HTML 生成 |
| `kf-skill-design-expert` | 稳 | 独立 | 无 | pro | Skill 设计专家 |
| `kf-markdown-to-docx-skill` | — | 独立 | 无 | flash | Markdown → DOCX 转换 |

### 上游技能（gstack / gspowers）

| 技能 | 来源 | 调用类型 | 调用/依赖的技能 | 推荐模型 | 说明 |
|------|------|---------|----------------|---------|------|
| `gspowers` | fshaan | 独立 | 无 | flash | SOP 流程导航，不调用 kf- 系列 |
| `gstack` / `/office-hours` | garrytan | 独立 | 无（内部有自身技能链） | pro | YC 风格产品诊断 |
| `gstack` / `/plan-ceo-review` | garrytan | 独立 | 无 | pro | CEO 视角产品评审 |
| `gstack` / `/plan-eng-review` | garrytan | 独立 | 无 | pro | 工程架构评审 |
| `gstack` / `/review` | garrytan | 独立 | 无 | flash | 代码审查 |
| `gstack` / `/ship` | garrytan | 独立 | 内部调用 /review | flash | 发布：同步→测试→PR |
| `gstack` / `/qa` | garrytan | 独立 | 内部使用 browse daemon | flash | QA 测试 |
| `gstack` / `/autoplan` | garrytan | 独立 | 内部串联 CEO→Design→Eng | pro | 全自动评审管线 |

### 关键结论

| 问题 | 答案 |
|------|------|
| kf-model-router 是否自动切换模型？ | **否。** 仅提供建议，需用户手动 /set-model |
| kf-model-router 是否被其他技能自动调用？ | **否。** 所有技能独立运行，不自动触发路由 |
| gstack/gspowers 是否调用 kf- 系列？ | **否。** 上游技能与 kf- 系列完全隔离 |
| 哪些技能会内部 spawn Agent？ | kf-multi-team-compete、kf-triple-collaboration |
| 模型切换用户有感知吗？ | **有。** 每次切换都需手动操作，用户完全可控 |

> **建议配比**：pro 20% + flash 70% + 轻量 10%，综合成本约 50%
