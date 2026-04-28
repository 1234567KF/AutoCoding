# AI编程智驾 (AI Programming Autopilot)

> 让 AI 自动驾驶编程全流程，从环境搭建到代码交付，零手动干预。

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**AI编程智驾** 是一套完整的 AI 编程工作台，集成 Claude Code、gspowers SOP 导航、ruflo 多 Agent 并行执行等工具，让 AI 能够自主完成从环境搭建到代码交付的全流程。

---

## 核心特性

| # | 特性 | 说明 |
|---|------|------|
| 1 | **Claude 自动驾驶** | Claude Code + Yolo 模式，AI 自主决策，无需频繁确认 |
| 2 | **gspowers SOP 导航** | 行业共识的技能规则框架，标准化开发流程 |
| 3 | **ruflo 多 Agent 并行** | 打通会话记忆，多 Agent 并行/接力执行 |
| 4 | **RTK Token 节省** | 节省 60-90% Token 消耗，成本大幅降低 |
| 5 | **markitdown 万物可读** | Markdown/HTML/文档互转，任何格式都能处理 |
| 6 | **TDD 测试先行** | 强制测试先行模式，质量有保障 |
| 7 | **通用三方协作** | 货比三家，多角度评审，决策更全面 |
| 8 | **Pipeline 流水线** | 复杂任务分模块分步骤，依赖自动编排，批量验证 |

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

### 方式一：AI 自动安装（推荐）

将本项目给 AI 阅读，AI 自动完成所有配置：

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
| `/office-hours` | YC 式产品拷问 | gspowers |
| `/subagent-dev` | 子代理 TDD 开发 | gspowers |
| `/pipeline-dev` | 多模块流水线开发 | gspowers |
| `/frontend-slides` | 创建精美 HTML 演示文稿 | frontend-slides |
| `安全审计` | 多 Agent 安全扫描 | ruflo |
| `架构评审` | 多 Agent 系统架构评估 | ruflo |
| `triple [任务]` | 通用三方协作 | ruflo |
| `TDD` | 启用测试先行模式 | 扩展 |

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
├── CHANGELOG.md           # 版本记录
├── LICENSE                # MIT 许可证
├── CONTRIBUTING.md         # 贡献指南
├── AI编程智驾框架特性.md   # 框架特性介绍
│
├── templates/             # 配置模板
│   ├── settings.json.template
│   ├── config.yaml.template
│   ├── tdd-config.yaml.template
│   ├── pre-commit.template
│   ├── pipeline-example.md
│   └── wiki-template.md
│
├── skills/                # 技能扩展
│   ├── prd-generator/     # PRD 生成器
│   └── frontend-slides/   # HTML 演示文稿生成器
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
