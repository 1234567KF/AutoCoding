# AI编程智驾 — 项目配置

> 总纲：[AICoding原则.docx](AICoding原则.docx) — AI编程修炼手册2026

本项目是 AI 编程工作台的完整技能集合，遵循**稳、省、准、测的准、夯、快、懂**六大原则。

## 技能一览

### kf- 系列（团队自建）

| 技能 | 原则 | 说明 |
|------|------|------|
| `kf-spec-coding` | 快 | Spec 驱动开发：需求 → Spec → 分步实施 |
| `kf-code-review-graph` | 省 | 代码审查依赖图谱，轻装上阵快速提取 |
| `kf-web-search` | 准 | 多引擎智能搜索，避免通用大模型哄骗 |
| `kf-browser-ops` | 测的准 | 浏览器自动化测试，Playwright 复现 bug |
| `kf-multi-team-compete` | 夯 | 红蓝绿队多 Agent 并发竞争评审 |
| `kf-alignment` | 懂 | 对齐工作流：动前谈理解，动后谈 diff |
| `kf-model-router` | 省 | 模型智能路由：计划 Opus，执行 Sonnet |
| `kf-prd-generator` | 快 | SDD Excel → PRD 生成器 |
| `kf-triple-collaboration` | 夯 | 三方协作评审 |
| `kf-ui-prototype-generator` | 快 | UI 原型生成器 |
| `kf-qoder` | 稳 | Qoder 专家团集成 |
| `kf-skill-design-expert` | 稳 | Skill 设计专家 |
| `kf-markdown-to-docx-skill` | — | Markdown → DOCX 转换 |

### 上游技能（非自建，不加 kf- 前缀）

| 技能 | 来源 | 说明 |
|------|------|------|
| `gspowers` | fshaan | SOP 流程导航 |
| `gstack` | garrytan | 产品流程框架 |

## 目录结构

```
.claude/
├── CLAUDE.md                  # 本文件
├── settings.json              # Claude Code 配置
├── settings.local.json        # 本地覆盖配置
├── install-local.ps1          # Windows 安装脚本
├── install-local.sh           # Linux/macOS 安装脚本
├── helpers/                   # Hook 处理器
├── agents/                   # Agent 定义
├── commands/                 # 自定义命令
└── skills/                   # 技能
    ├── kf-spec-coding/        # Spec 驱动开发
    ├── kf-code-review-graph/  # 代码审查图谱
    ├── kf-web-search/         # 多引擎搜索
    ├── kf-browser-ops/        # 浏览器自动化
    ├── kf-multi-team-compete/ # 多团队竞争
    ├── kf-alignment/          # 对齐工作流
    ├── kf-model-router/       # 模型路由
    ├── kf-prd-generator/      # PRD 生成器
    ├── kf-triple-collaboration/ # 三方协作
    ├── kf-ui-prototype-generator/ # UI 原型
    ├── kf-qoder/              # Qoder 集成
    ├── kf-skill-design-expert/ # Skill 设计
    ├── kf-markdown-to-docx-skill/ # MD→DOCX
    ├── gspowers/              # SOP 导航（上游）
    └── gstack/               # 产品流程（上游）
```

## 快速开始

```powershell
# 1. 运行本地安装脚本（首次或技能更新时）
.\.claude\install-local.ps1

# 2. 在项目目录启动 Claude Code
claude
```

## 常用触发词

| 触发词 | 技能 | 原则 |
|--------|------|------|
| `spec coding` / `写spec文档` | kf-spec-coding | 快 |
| `/对齐` / `说下你的理解` | kf-alignment | 懂 |
| `/review-graph` | kf-code-review-graph | 省 |
| `/web-search [问题]` | kf-web-search | 准 |
| `/browser-ops` | kf-browser-ops | 测的准 |
| `/夯 [任务]` | kf-multi-team-compete | 夯 |
| `triple [任务]` | kf-triple-collaboration | 夯 |
| `/gspowers` | gspowers | 稳 |
| `/prd-generator` | kf-prd-generator | 快 |
| `模型路由` / `省模式` | kf-model-router | 省 |

## 全局依赖

| 工具 | 安装命令 | 说明 |
|------|---------|------|
| Claude Code | `irm https://claude.ai/install.ps1 \| iex` | 主界面 |
| Node.js | `winget install OpenJS.NodeJS.LTS` | 运行环境 |
| ruflo | `npm install -g ruflo` | 多 Agent + 记忆 |
| RTK | 见 INSTALL.md | Token 节省 |

## 项目隔离

- **记忆隔离**：每个项目的 ruflo 记忆存储在 `.claude-flow/`
- **配置隔离**：`settings.json` 只影响本项目
- **技能隔离**：kf- 系列技能为项目本地安装

## 更多信息

- [AICoding原则.docx](AICoding原则.docx) — 修炼总纲
- [AICoding.md](AICoding.md) — 单文件入口（给 AI 看）
- [INSTALL.md](INSTALL.md) — AI 安装指南
- [MANUAL.md](MANUAL.md) — 用户使用手册
