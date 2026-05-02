# AI编程智驾 - 完整使用手册

> **版本**：v1.3
>
> 本手册供用户阅读，了解 AI编程智驾 的完整功能和使用方法。
> 如需让 AI 自动安装，请阅读 [INSTALL.md](INSTALL.md)

---

## 一、框架特性

### 一句话定位

**AI编程智驾** — 让 AI 自动驾驶编程全流程，从环境搭建到代码交付，零手动干预。

### 核心特性

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

### 详细说明

#### 1. Claude 自动驾驶

```
传统模式：用户 → 确认 → 执行 → 确认 → ...
自动驾驶：用户 → AI 自主完成 → 汇报结果
```

Claude Code 开启 Yolo 模式后，AI 可以：
- 自动执行文件操作、终端命令
- 自动处理弹窗、异常、中断
- 遇到问题自行解决，不中断等待

#### 2. gspowers SOP 导航

gspowers 是行业共识的技能规则框架，提供标准化开发流程：

```
/gspowers → /office-hours → /plan-eng-review → /brainstorm → /subagent-dev → /review → /ship
```

每个步骤都有明确的产出物和验收标准。

#### 3. ruflo 多 Agent 并行

ruflo 打通会话记忆，支持多个 Agent 并行/接力：

- **并行**：同一任务，多 Agent 从不同角度同时执行
- **接力**：上一 Agent 输出作为下一 Agent 输入
- **记忆**：跨会话记忆，知识不丢失
// ... 382 more lines (total: 441)
### 快速触发词

| 触发词 | 功能 |
|--------|------|
| `/gspowers` | 启动 SOP 流程导航 |
| `/pipeline-dev` | 多模块流水线开发 |
| `安全审计` | 多 Agent 安全扫描 |
| `triple [任务]` | 通用三方协作 |
| `TDD` | 启用测试先行模式 |
| `允许 AI 自动扩充技能` | 授权 AI 扩展功能 |

---

## 二、核心原则：自愈式控制（Self-Healing）

AI 执行任务时，遇到缺工具、页面变化、异常情况，**不要中断**，而是：

```
1. 缺工具 → AI 直接编写/编辑工具脚本继续运行
2. 页面变 → AI 重新 snapshot -i 识别新元素
3. 弹窗/异常 → AI 自动 dialog-accept/handle
4. 失败不中断 → 分析原因，修复后继续执行
```

**传统自动化** vs **自愈式控制**：

| 传统自动化   | 自愈式控制            |
| ------------ | --------------------- |
| 页面一变就崩 | AI 动态适配，继续运行 |
| 维护成本高   | AI 自主修复，无需人工 |
| 人工干预多   | Agent 自主决策        |

**关键转变**：从「命令驱动」到「目标驱动」。AI 记住目标，遇到障碍自行解决，不等待人工。

---

## 三、新项目使用流程

> 每个新项目只需执行一次初始化

### 方式一：单文件入口（最简单）

下载仓库中的 `AICoding.md`，放入 AI IDE，对 AI 说"执行安装"即可。
详见仓库根目录 [AICoding.md](AICoding.md)。

### 方式二：在新项目目录执行

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

## 四、功能触发速查

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
| `/review-graph`           | 🆕 代码审查依赖图谱               | kf-code-review-graph |
| `/web-search [问题]`      | 🆕 多引擎智能搜索                 | kf-web-search        |
| `/browser-ops`            | 🆕 浏览器自动化操作               | kf-browser-ops       |
| `/夯 [任务]`              | 🆕 多团队竞争评审                 | kf-multi-team-compete |
| `/对齐` / `说下你的理解`  | 🆕 对齐工作流                     | kf-alignment         |
| `模型路由` / `省模式`     | 🆕 模型智能路由                   | kf-model-router      |
| `spec coding`             | 🆕 Spec 驱动开发                   | kf-spec-coding       |

---

## 五、记忆共享说明

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

---

## 六、目录结构

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

项目本地（AutoCoding/）：
├── .claude/
│   ├── CLAUDE.md              # 项目指令
│   ├── settings.json          # 项目配置
│   └── skills/                # 项目本地技能
│       ├── kf-spec-coding/    # Spec 驱动开发
│       ├── kf-code-review-graph/ # 代码审查图谱
│       ├── kf-web-search/     # 多引擎搜索
│       ├── kf-browser-ops/    # 浏览器自动化
│       ├── kf-multi-team-compete/ # 多团队竞争
│       ├── kf-alignment/      # 对齐工作流
│       ├── kf-model-router/   # 模型路由
│       ├── kf-prd-generator/  # PRD 生成
│       ├── kf-triple-collaboration/ # 三方协作
│       ├── kf-ui-prototype-generator/ # UI 原型
│       ├── kf-qoder/          # Qoder 集成
│       ├── kf-skill-design-expert/ # Skill 设计
│       ├── gspowers/          # SOP 导航（上游）
│       └── gstack/            # 产品流程（上游）
```

---

## 七、快速参考

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

## 八、版本兼容性说明

| 工具        | 推荐版本 | 兼容性说明      |
| ----------- | -------- | --------------- |
| Claude Code | 最新版   | 主要界面        |
| ruflo       | v3.x     | 多 Agent + 记忆 |
| gstack      | 最新版   | 产品流程        |
| gspowers    | 最新版   | SOP 导航        |
| superpowers | 最新版   | 开发执行        |

> 本手册设计为长期可用。核心机制是 Claude Code + ruflo 的协作，无论工具版本如何更新，协作逻辑保持不变。

---

## 九、故障排除

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

## 十、TDD 测试先行模式

### 10.1 什么是 TDD

TDD（Test-Driven Development）测试先行开发：

```
RED → GREEN → REFACTOR

1. 先写测试（RED）- 测试会失败，因为代码还没写
2. 写实现让测试通过（GREEN）- 写最简单代码让测试通过
3. 重构优化（REFACTOR）- 优化代码，同时确保测试仍然通过
```

### 10.2 TDD 触发词

| 你说的话     | AI 行为                             |
| ------------ | ----------------------------------- |
| `TDD`      | 启用 TDD 模式，所有开发遵循测试先行 |
| `遵循 TDD` | 同上                                |
| `测试先行` | 同上                                |
| `关闭 TDD` | 恢复普通开发模式                    |

### 10.3 TDD 效果

```
你: "实现用户注册功能，遵循 TDD"
    ↓
AI:
  1. 先写测试: UserRegister.test.ts
  2. 运行测试 → 失败（RED）
  3. 写实现: UserRegister.ts
  4. 运行测试 → 通过（GREEN）
  5. 重构优化
  6. 提示你: "✅ TDD 完成，覆盖率 95%，是否提交？"
```

---

## 十一、Pipeline 多模块流水线

### 11.1 什么是 Pipeline 模式

当项目包含**多个有依赖关系的模块**时，Pipeline 模式自动处理：

1. 分析模块依赖拓扑
2. 按批次顺序执行（依赖模块先完成，才能执行依赖它的模块）
3. 批次间门控验证（通过才允许下一批次）
4. 状态追踪和断点恢复

### 11.2 典型场景

```
场景：电商系统
├── 用户服务（无依赖）
├── 商品服务（依赖用户服务）
├── 订单服务（依赖用户服务 + 商品服务）
└── 支付服务（依赖订单服务）

Pipeline 自动：
批次1: 用户服务 → 门控验证通过
批次2: 商品服务 → 门控验证通过
批次3: 订单服务 → 门控验证通过
批次4: 支付服务 → 完成
```

### 11.3 触发方式

```
/pipeline-dev
多模块开发
流水线开发
```

---

## 十二、AI 自动化技能扩充

### 12.1 什么是技能扩充

当用户授权"允许 AI 自动扩充技能"后，AI 可以自动扩展功能。

### 12.2 触发条件

```
用户说 "允许 AI 自动扩充技能" 或类似表述
```

### 12.3 扩充后的功能

| 用户授权后说          | AI 自动执行                   |
| --------------------- | ----------------------------- |
| `TDD`               | 启用 TDD 开发模式（测试先行） |
| `生成 Wiki`         | 压缩上下文，生成项目 Wiki     |
| `遵循 TDD + 功能名` | TDD 模式实现功能              |
| `关闭 TDD`          | 恢复普通开发模式              |

---

## 十三、安全分级说明

| 等级                   | 适用场景             | 风险等级 | 说明                                  |
| ---------------------- | -------------------- | -------- | ------------------------------------- |
| **L1 观察模式**  | 新项目/陌生代码      | 低       | allowPermissions=false，逐项确认      |
| **L2 开发模式**  | 日常开发/调试        | 中       | allowPermissions=true，敏感操作需确认 |
| **L3 Yolo 模式** | 快速原型/实验性项目  | 高       | allowPermissions=true，全部自动同意   |
| **L4 受控 Yolo** | 信任的代码库 + CI/CD | 中       | allowPermissions=true + 审计日志      |

---

## 十四、文档索引

| 文档 | 说明 |
|------|------|
| [README.md](README.md) | 项目介绍（GitHub 首页） |
| [MANUAL.md](MANUAL.md) | 完整使用手册（你在这里） |
| [INSTALL.md](INSTALL.md) | AI 执行安装指南 |
| [CHANGELOG.md](CHANGELOG.md) | 版本变更记录 |
| [AI编程智驾框架特性.md](AI编程智驾框架特性.md) | 框架特性介绍 |
