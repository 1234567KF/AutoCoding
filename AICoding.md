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

| 场景 | 自动切换模型 | 原因 |
|------|------------|------|
| 架构设计 / 需求澄清 | **deepseek-v4-pro**（Opus 级） | 需要深度推理、权衡取舍 |
| 复杂 Bug 排查 | **deepseek-v4-pro**（Opus 级） | 需要完整上下文理解和推理链 |
| 日常编码 / 执行 | **deepseek-v4-flash**（Sonnet 级） | 效率优先，常规任务性价比高 |
| 代码审查 | **deepseek-v4-flash**（Sonnet 级） | 模式匹配为主 |
| 文档生成 | **deepseek-v4-flash**（Sonnet 级） | 结构化输出，低成本 |
| 简单问答 / 格式转换 | 轻量模型（Haiku 级） | 极低成本，快速响应 |

### 切换机制

**自动切换，用户无感。** kf-model-router 在以下时机会被**自动触发**：

| 触发场景 | 自动动作 | 用户感知 |
|---------|---------|---------|
| 技能启动时声明了 `recommended_model: pro` | 自动 `/set-model opus` | **无感** |
| 技能启动时声明了 `recommended_model: flash` | 自动 `/set-model sonnet` | **无感** |
| kf-multi-team-compete 启动（主入口） | 裁判用 pro，各队 agent 用 flash | **无感** |
| kf-spec 进入 Step 0 技术选型 | 自动切换到 pro | **无感** |
| kf-alignment 执行深度对齐 | 自动切换到 pro | **无感** |
| 任务完成后回到编码阶段 | 自动切回 flash | **无感** |

实现方式：kf-model-router 被各技能在 frontmatter 中声明 `integrated-skills` 后，技能启动时自动通过 Hook 检查当前模型是否匹配推荐模型，不匹配则自动执行 `/set-model`。

---

## 全局技能调用链

> 调用关系分三种：
> - **自动调用**：主技能执行时自动触发被调用技能，用户无感
> - **内部 spawn**：技能执行时 spawn 子 Agent 并行工作，子 Agent 可自动调用其他技能
> - **独立**：不依赖也不调用其他技能，完全自包含（但可能**被**其他技能调用）

### kf- 系列（团队自建）

| 技能 | 别名 | 原则 | 调用类型 | 自动调用的技能 | 被谁调用 | 推荐模型 |
|------|------|------|---------|--------------|---------|---------|
| `kf-go` | `/go` | 快 | 独立 | 无 | 用户手动 | flash |
| `kf-spec` | spec coding | 快 | **自动调用** | kf-alignment（Step 1 对齐 + 产出后复盘）、kf-model-router（Step 0 切换 pro） | 用户手动、kf-multi-team-compete Stage 0 | pro→flash |
| `kf-code-review-graph` | `/review-graph` | 省 | 独立 | 无 | kf-multi-team-compete Stage 4（自动） | flash |
| `kf-web-search` | `/web-search` | 准 | 独立（被动技能） | 无 | **kf-multi-team-compete agent 按需自动调用**、kf-spec 资料收集、用户手动 | flash |
| `kf-browser-ops` | `/browser-ops` | 测的准 | 独立（被动技能） | 无 | **kf-multi-team-compete Stage 3 自动调用**、用户手动 | flash |
| `kf-multi-team-compete` | **`/夯`** | 夯 | **内部 spawn + 自动调用** | kf-prd-generator（Pre-Stage）、kf-alignment、kf-spec、kf-browser-ops、kf-code-review-graph、**kf-web-search**、kf-ui-prototype-generator、gspowers Pipeline | **主入口**，用户手动 `/夯` | pro（裁判+汇总）+ flash（各队 agent） |
| `kf-alignment` | `/对齐` | 懂 | 独立（被动技能） | 无 | **kf-spec 自动调用**、**kf-multi-team-compete Stage 0/Phase 3 自动调用**、kf-prd-generator Hook 自动调用 | pro |
| `kf-model-router` | 模型路由 | 省 | **自动触发**（Hook） | 无 | **所有声明 recommended_model 的技能启动时自动调用** | —（路由器本身） |
| `kf-prd-generator` | `/prd-generator` | 快 | **自动调用** | kf-alignment（产出 PRD 后 Hook 触发对齐） | 用户手动、**kf-multi-team-compete Pre-Stage 自动调用** | flash |
| `kf-triple-collaboration` | triple | 夯 | 内部 spawn | 同 kf-multi-team-compete（轻量版） | 用户手动 | pro+flash |
| `kf-ui-prototype-generator` | — | 快 | 独立（被动技能） | 无 | kf-multi-team-compete Stage 2/5 自动调用 | flash |
| `kf-skill-design-expert` | — | 稳 | 独立 | 无 | 用户手动 | pro |
| `kf-markdown-to-docx-skill` | — | — | 独立 | 无 | 用户手动 | flash |

### 上游技能（gstack / gspowers）

| 技能 | 来源 | 调用类型 | 调用/依赖 | 说明 |
|------|------|---------|---------|------|
| `gspowers` | fshaan | 独立 | 无（但其 Pipeline 扩展被 kf-multi-team-compete 集成） | SOP 流程导航 |
| `gspowers` Pipeline 扩展 | fshaan | **被集成** | **被 kf-multi-team-compete 融入**作为团队内部流水线引擎 | 阶段编排 + 产物交接 |
| `gstack` 系列 | garrytan | 独立（内部有自身技能链） | 与 kf- 系列隔离 | 产品流程框架（office-hours/plan/review/ship/qa） |

### 主入口 `/夯` 的完整调用链

```
用户: /夯 [任务]
  │
  ├─ kf-model-router 自动切换 → 裁判用 pro
  │
  ├─ Pre-Stage（条件触发：输入含 SDD Excel .xlsx 时）
  │     └─ kf-prd-generator 读取 SDD Excel → 生成 PRD.md
  │
  ├─ Phase 1: 任务拆解
  │     └─ kf-alignment（对齐任务理解）
  │
  ├─ Phase 2: 三队 Pipeline 并发
  │   ├─ 红队 Pipeline（gspowers Pipeline 引擎）
  │   │   ├─ Stage 0: kf-alignment + kf-spec（需求对齐）
  │   │   ├─ Stage 1: 架构设计
  │   │   ├─ Stage 2: kf-ui-prototype-generator（UI）+ kf-web-search（查资料）
  │   │   ├─ Stage 3: kf-browser-ops（自动化测试）
  │   │   ├─ Stage 4: kf-code-review-graph（代码审查）
  │   │   └─ Stage 5: 方案汇总
  │   ├─ 蓝队 Pipeline（同上，稳健工程视角）
  │   └─ 绿队 Pipeline（同上，安全保守视角）
  │
  ├─ Phase 3: 裁判评分
  │     └─ kf-alignment（统一评分标准）
  │
  └─ Phase 4: 汇总融合 → 最终方案
```

### 关键结论

| 问题 | 答案 |
|------|------|
| kf-model-router 是否自动切换模型？ | **是。** 技能启动时自动检查并切换，用户无感 |
| kf-model-router 是否被其他技能自动调用？ | **是。** 所有声明 `recommended_model` 的技能启动时自动调用 |
| kf-web-search 是否可被自动调用？ | **是。** kf-multi-team-compete agent 按需自动调用搜索资料 |
| kf-browser-ops 是否可被自动调用？ | **是。** kf-multi-team-compete Stage 3 自动调用做 UI 测试 |
| kf-alignment 是否可被自动调用？ | **是。** kf-spec、kf-multi-team-compete、kf-prd-generator 均自动调用 |
| gspowers Pipeline 与 `/夯` 的关系？ | Pipeline 引擎被融入 `/夯` 作为团队内部流水线编排引擎 |
| kf-prd-generator 是否可被自动调用？ | **是。** `/夯` 输入 SDD Excel 时 Pre-Stage 自动调用生成 PRD.md |
| `/夯` 是谁的别名？ | `kf-multi-team-compete` 的中文别称，主入口技能 |
| gstack/gspowers 是否调用 kf- 系列？ | **否。** 上游技能与 kf- 系列隔离，但 Pipeline 引擎被 `/夯` 集成 |

> **建议配比**：pro 20% + flash 70% + 轻量 10%，综合成本约 50%。自动切换由 kf-model-router Hook 实现，默认开启。


