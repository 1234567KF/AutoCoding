# AI编程智驾 (AI Programming Autopilot)

> 让 AI 自动驾驶编程全流程，从环境搭建到代码交付，零手动干预。
> 总纲：[AICoding原则.docx](AICoding原则.docx) — **稳、省、准、测的准、夯、快、懂**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**AI编程智驾** 是一套完整的 AI 编程工作台，遵循六大原则，集成 Claude Code、gspowers SOP 导航、ruflo 多 Agent 并行执行等工具。

---

## 六大原则

| 原则 | 含义 | 对应技能 |
|------|------|---------|
| **稳** | 好用不贵，长期维护 | gspowers、gstack |
| **省** | 模型搭配，稳固 ROI | kf-model-router、kf-code-review-graph、RTK |
| **准** | 避免通用大模型哄骗 | kf-web-search |
| **测的准** | 浏览器自动化测试 | kf-browser-ops |
| **夯** | 多 Agent 并发竞争碾压 | kf-multi-team-compete、kf-triple-collaboration |
| **快** | MVP 快速验证，能 Mock 就 Mock | kf-spec、kf-prd-generator |
| **懂** | 动前对齐，动后 diff | kf-alignment |

---

## 第三方开源集成

本项目集成了以下优秀的开源项目：

| 集成项目 | 来源 | 许可证 | 用途 |
|----------|------|--------|------|
| [gspowers](https://github.com/fshaan/gspowers) | fshaan | MIT | SOP 流程导航 |
| [frontend-slides](https://github.com/zarazhangrui/frontend-slides) | zarazhangrui | MIT | 演示文稿生成 |
| [ruflo](https://github.com/ruvnet/ruflo) | ruvnet | MIT | 多 Agent 编排 |
| [RTK](https://github.com/rafaelkallis/rtk) | rafaelkallis | MIT | Token 优化 |

详见 [CREDITS.md](CREDITS.md) 完整致谢。

---

## 快速开始

### 前置要求

- Claude Code 已安装
- Node.js >= 18
- Git

### 方式零：单文件入口（最简单）

**只需下载一个文件**，放入 AI IDE，AI 自动完成全部安装：

```
1. 下载 AICoding.md（本仓库根目录）
2. 放入任意目录，用 AI IDE（Claude Code / Trae / Cursor）打开
3. 对 AI 说"执行安装"
4. AI 自动完成：环境检测 → 下载项目 → 安装配置 → 完成
```

> `AICoding.md` 只有 ~100 行，内容永远不需要更新——它从 GitHub 实时拉取最新仓库。

### 方式一：AI 自动安装

将整个项目给 AI 阅读，AI 自动完成所有配置：

```
1. 将项目文件夹复制到新环境
2. 在项目目录打开 Claude Code
3. 让 AI 阅读 INSTALL.md
4. AI 自动完成所有安装（仅需用户配置 Token）
```

### 方式二：手动安装

```powershell
# 安装 Claude Code
irm https://claude.ai/install.ps1 | iex

# 安装 ruflo
npm install -g ruflo

# 安装 gspowers
git clone https://github.com/fshaan/gspowers.git ~/.claude/skills/gspowers
```

详见 [INSTALL.md](INSTALL.md)

---

## 功能触发词

| 触发词 | 功能 | 来源 |
|--------|------|------|
| `/gspowers` | 启动 SOP 流程导航 | gspowers |
| `/pipeline-dev` | 多模块流水线开发 | gspowers |
| `安全审计` | 多 Agent 安全扫描 | ruflo |
| `triple [任务]` | 通用三方协作 | kf-triple-collaboration |
| `TDD` | 启用测试先行模式 | 扩展 |
| `spec coding` / `写spec文档` | Spec 驱动开发 | kf-spec |
| `/review-graph` | 代码审查依赖图谱 | kf-code-review-graph |
| `/web-search [问题]` | 多引擎智能搜索 | kf-web-search |
| `/browser-ops` | 浏览器自动化操作 | kf-browser-ops |
| `/夯 [任务]` | 多团队竞争评审 | kf-multi-team-compete |
| `/对齐` / `说下你的理解` | 对齐工作流 | kf-alignment |
| `模型路由` / `省模式` | 模型智能路由 | kf-model-router |
| `/prd-generator` | PRD 文档生成 | kf-prd-generator |

---

## 文档结构

| 文档 | 说明 |
|------|------|
| [README.md](README.md) | 项目介绍（你在这里） |
| [MANUAL.md](MANUAL.md) | 完整使用手册（给人看） |
| [INSTALL.md](INSTALL.md) | AI 执行安装指南（给 AI 看） |
| [CHANGELOG.md](CHANGELOG.md) | 版本变更记录 |
| [CREDITS.md](CREDITS.md) | 第三方开源项目致谢 |

---

## 目录结构

```
AI编程智驾/
├── README.md              # 项目入口
├── MANUAL.md              # 完整手册
├── INSTALL.md             # AI 安装指南
├── AICoding.md            # 单文件入口（给 AI 看）
├── CHANGELOG.md           # 版本记录
├── CREDITS.md             # 第三方致谢
├── LICENSE                # MIT 许可证
├── mvp技术栈.md            # MVP 技术栈定义
│
├── .claude/               # Claude Code 项目配置
│   ├── CLAUDE.md          # 项目指令
│   ├── settings.json      # 项目配置
│   ├── agents/            # Agent 定义
│   ├── commands/          # 自定义命令
│   └── skills/            # 技能（kf- 系列 + 上游）
│       ├── kf-spec/         # Spec 驱动开发
│       ├── kf-code-review-graph/   # 代码审查图谱
│       ├── kf-web-search/          # 多引擎搜索
│       ├── kf-browser-ops/         # 浏览器自动化
│       ├── kf-multi-team-compete/  # 多团队竞争评审
│       ├── kf-alignment/           # 对齐工作流
│       ├── kf-model-router/        # 模型路由
│       ├── kf-prd-generator/       # PRD 生成器
│       ├── kf-triple-collaboration/# 三方协作
│       ├── kf-ui-prototype-generator/ # UI 原型
│       ├── kf-skill-design-expert/ # Skill 设计
│       ├── kf-markdown-to-docx-skill/ # MD→DOCX
│       ├── gspowers/               # SOP 导航（上游）
│       └── gstack/                 # 产品流程（上游）
│
├── templates/             # 配置模板
│   ├── settings.json.template
│   ├── config.yaml.template
│   ├── tdd-config.yaml.template
│   ├── pre-commit.template
│   ├── pipeline-example.md
│   └── wiki-template.md
│
└── gspowers-pipeline-patch/  # Pipeline 扩展
    ├── pipeline.md
    ├── execute-patch.md
    └── install-pipeline.ps1
```

---

## 贡献

欢迎提交 Issue 和 Pull Request！

见 [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 许可

MIT License - 详见 [LICENSE](LICENSE)
