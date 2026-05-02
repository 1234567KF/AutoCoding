# AI编程智驾 — 项目配置

> 总纲：[AICoding原则.docx](docs/AICoding原则.docx) — AI编程修炼手册2026

本项目是 AI 编程工作台的完整技能集合，遵循**稳、省、准、测的准、夯、快、懂**六大原则。

## 技能一览

### kf- 系列（团队自建）

| 技能 | 别名 | 原则 | 调用链 | 说明 |
|------|------|------|--------|------|
| `kf-go` | `/go` | 快 | 独立 | 工作流导航：查看全局路径和当前进度 |
| `kf-spec` | spec coding | 快 | 自动调用 kf-alignment、kf-model-router；被 `/夯` 调用 | Spec 驱动开发：需求 → Spec → 分步实施 |
| `kf-code-review-graph` | `/review-graph` | 省 | 被 `/夯` Stage 4 自动调用 | 代码审查依赖图谱，轻装上阵快速提取 |
| `kf-web-search` | `/web-search` | 准 | 被 `/夯` agent 按需自动调用 | 多引擎智能搜索，agent 自动搜索技术方案 |
| `kf-browser-ops` | `/browser-ops` | 测的准 | 被 `/夯` Stage 3 自动调用 | 浏览器自动化测试，Playwright 复现 bug |
| `kf-scrapling` | — | 准 | 被 `/夯` Stage 1/2/3 按需自动调用 | Web 爬虫+反反爬，深度数据采集，替代/补充 web-search |
| `kf-multi-team-compete` | **`/夯`** | 夯 | **主入口**，自动调用 10 个技能 + Pipeline 引擎 | 红蓝绿队多 Agent 并发竞争评审 |
| `kf-alignment` | `/对齐` | 懂 | 被 kf-spec、`/夯`、kf-prd-generator 自动调用 | 对齐工作流：动前谈理解，动后谈 diff |
| `kf-model-router` | 模型路由 | 省 | **自动触发**：所有技能启动时自动检查并切换模型 | 模型智能路由：计划 pro，执行 flash，用户无感 |
| `kf-prd-generator` | `/prd-generator` | 快 | 自动调用 kf-alignment（产出后 Hook 对齐）；被 `/夯` Pre-Stage 自动调用 | SDD Excel → PRD 生成器 |
| `kf-triple-collaboration` | triple | 夯 | 内部 spawn（轻量版 `/夯`） | 三方协作评审 |
| `kf-ui-prototype-generator` | — | 快 | 被 `/夯` Stage 2/5 自动调用 | UI 原型 HTML 生成 |
| `kf-image-editor` | — | 快 | 被 `/夯` Stage 2/5 自动调用 | AI 自然语言 P 图，Nano Banana MCP |
| `kf-skill-design-expert` | — | 稳 | 独立，包含 Harness Engineering 评审体系 | Skill 设计专家 + 五根铁律审计 |
| `kf-markdown-to-docx-skill` | — | — | 独立 | Markdown → DOCX 转换 |

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
├── helpers/                   # Hook 处理器 + 审计脚本
│   ├── harness-gate-check.cjs # 机械化门控验证
│   └── harness-audit.cjs      # 五根铁律全路径审计
├── agents/                   # Agent 定义
├── commands/                 # 自定义命令
└── skills/                   # 技能
    ├── kf-spec/        # Spec 驱动开发
    ├── kf-code-review-graph/  # 代码审查图谱
    ├── kf-web-search/         # 多引擎搜索
    ├── kf-browser-ops/        # 浏览器自动化
    ├── kf-multi-team-compete/ # 多团队竞争
    ├── kf-alignment/          # 对齐工作流
    ├── kf-model-router/       # 模型路由
    ├── kf-prd-generator/      # PRD 生成器
    ├── kf-triple-collaboration/ # 三方协作
    ├── kf-ui-prototype-generator/ # UI 原型
    ├── kf-skill-design-expert/ # Skill 设计
    ├── kf-markdown-to-docx-skill/ # MD→DOCX
    ├── kf-scrapling/          # Web 爬虫 + 反反爬
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

| 触发词 | 技能 | 原则 | 自动调用 |
|--------|------|------|---------|
| `/go` / `/导航` / `/开始` | kf-go | 快 | — |
| `/夯 [任务]` | kf-multi-team-compete | 夯 | 自动调用 10 个子技能 |
| `spec coding` / `写spec文档` | kf-spec | 快 | 自动调用 kf-alignment + kf-model-router |
| `/对齐` / `说下你的理解` | kf-alignment | 懂 | 被多个技能自动调用 |
| `/review-graph` | kf-code-review-graph | 省 | 被 `/夯` 自动调用 |
| `/web-search [问题]` | kf-web-search | 准 | 被 `/夯` agent 按需自动调用 |
| `/browser-ops` | kf-browser-ops | 测的准 | 被 `/夯` 自动调用 |
| `/gspowers` | gspowers | 稳 | Pipeline 引擎被 `/夯` 集成 |
| `/prd-generator` | kf-prd-generator | 快 | 自动调用 kf-alignment |
| `triple [任务]` | kf-triple-collaboration | 夯 | 轻量版 `/夯` |
| `模型路由` / `省模式` | kf-model-router | 省 | **全自动**，用户无感 |
| `Harness 评审` / `五根铁律审计` | kf-skill-design-expert | 稳 | 全路径扫描，评分矩阵 + 缺陷分级 |
| `P图` / `改图` / `修图` / `去水印` | kf-image-editor | 快 | AI 自然语言 P 图，被 `/夯` Stage 2/5 调用 |
| `转docx` / `markdown转word` | kf-markdown-to-docx-skill | — | Markdown → DOCX 转换 |
| `爬虫` / `抓取` / `scrape` / `反反爬` | kf-scrapling | 准 | Web 爬虫，被 `/夯` Stage 1/2/3 按需调用 |

## 自动调用链速览

```
用户触发 "/夯 [任务]"
  │
  ├─ kf-model-router 自动切换模型（pro/flash）
  │
  ├─ Pre-Stage：kf-prd-generator → PRD.md（条件触发：输入含 SDD Excel 时）
  │
  └─ 三队 Pipeline 并发（gspowers Pipeline 引擎）
       ├─ kf-alignment   ← 需求对齐（Stage 0）
       ├─ kf-spec        ← 需求基线（Stage 0）
       ├─ kf-web-search  ← 技术资料搜索（Stage 1/2/3 按需）
       ├─ kf-scrapling  ← 深度网页抓取（Stage 1/2/3 按需，反反爬）
       ├─ kf-ui-prototype-generator ← UI 原型（Stage 2/5）
       ├─ kf-image-editor ← AI P 图（Stage 2/5）
       ├─ kf-browser-ops ← 自动化测试（Stage 3）
       └─ kf-code-review-graph ← 代码审查（Stage 4）
```

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

- [AICoding原则.docx](docs/AICoding原则.docx) — 修炼总纲
- [AICoding.md](AICoding.md) — 单文件入口（给 AI 看）
- [INSTALL.md](docs/INSTALL.md) — AI 安装指南
- [MANUAL.md](docs/MANUAL.md) — 用户使用手册
- [memory/MEMORY.md](memory/MEMORY.md) — 跨会话记忆索引
- [memory/harness-audit-history.md](memory/harness-audit-history.md) — Harness 评审历史

## Harness Engineering 评审

```bash
# 全路径五根铁律审计
node .claude/helpers/harness-audit.cjs --all --verbose
```
