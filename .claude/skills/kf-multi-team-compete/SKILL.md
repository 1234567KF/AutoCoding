---
name: kf-multi-team-compete
description: |
  多团队竞争评审（中文别称：夯）。swarm 启动真实多 Agent 并发，红蓝绿队各含开发者 agent 按 Pipeline 流水线协作，
  裁判+汇总师评分融合。Pipeline 引擎来自 gspowers，融入本技能作为团队内部流水线编排。
  触发词："夯"、"多团队竞争"、"竞争评审"、"裁判对比"。
triggers:
  - 夯
  - 多团队竞争
  - 竞争评审
  - 裁判对比
  - 多方案对比
  - /夯
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
  - Agent
  - TaskCreate
  - TaskUpdate
  - SendMessage
  - WebSearch
  - WebFetch
metadata:
  pattern: pipeline + inversion + reviewer
  steps: "4"
  interaction: multi-turn
  recommended_model: pro
  pipeline_engine: gspowers
  integrated-skills:
    - kf-alignment
    - kf-code-review-graph
    - kf-spec
    - kf-ui-prototype-generator
    - kf-browser-ops
    - kf-web-search
    - kf-prd-generator
    - kf-model-router
---

# 夯 — 多团队竞争评审系统

你是「夯」模式的协调者。**夯 = 力大 + 万法 = 碾压**。

核心理念：swarm 多 Agent 并发，红蓝绿三队各按 **Pipeline 流水线** 推进，
不同视角方案碰撞，裁判择优，汇总博采众长，输出碾压级方案。

---

## 架构总览

```
                         Swarm Init
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        红队 Pipeline    蓝队 Pipeline    绿队 Pipeline
        (激进创新)       (稳健工程)       (安全保守)
              │              │              │
              └──────────────┼──────────────┘
                             ▼
                        裁判评分
                             │
                             ▼
                        汇总融合 → 最终方案
```

每队内部不是散兵游勇，而是 **6 阶段流水线**，阶段间有明确门控和产物交接。

---

## 团队内部流水线（Team Internal Pipeline）

每个团队（红/蓝/绿）的开发者 agent 自动执行以下流水线。
**上游阶段输出自动成为下游阶段输入。禁止跳过。**

```
Pre-Stage     Stage 0        Stage 1        Stage 2        Stage 3        Stage 4        Stage 5
 物料准备  →   需求对齐  →    架构设计   →    编码实现   →    集成测试   →    代码审查   →    方案汇总
 (协调者)      (全栈开发)     (全栈开发)     (全栈开发)     (集成测试)     (集成测试)     (前端设计师)
    │              │              │              │              │              │              │
    ▼              ▼              ▼              ▼              ▼              ▼              ▼
 PRD文档       对齐记录      架构方案       代码产物       测试报告       审查报告       团队方案
```

### Pre-Stage — 需求物料准备（条件触发）

> **触发条件**：用户输入包含 SDD Excel 文件（`.xlsx`）时自动执行；否则跳过。

- **执行者**：协调者（本 Skill 自身，不 spawn agent）
- **动作**：调用 `kf-prd-generator` 读取 SDD Excel，生成 PRD.md
- **产出**：`PRD.md` — 结构化需求文档（背景、业务流、规则、页面）
- **门控**：PRD.md 生成完成 → 三队 Stage 0 均以该 PRD 为输入

正确的链路：`SDD Excel → kf-prd-generator → PRD.md → kf-spec → Spec → 夯 并发执行`

### Stage 0 — 需求对齐

- **执行者**：全栈开发 agent
- **动作**：读取 Spec/PRD，调用 `kf-alignment` 做动前对齐
- **产出**：`{team}-00-alignment.md` — 需求理解、边界确认、技术约束
- **门控**：全栈开发确认理解无误后进入 Stage 1

### Stage 1 — 架构设计

- **执行者**：全栈开发 agent
- **输入**：Stage 0 对齐记录
- **动作**：设计数据模型、API 契约、组件树、路由方案；**可调用 `kf-web-search` 搜索技术方案和最佳实践**
- **产出**：`{team}-01-architecture.md` — 架构图、模块划分、技术选型理由
- **门控**：架构方案无歧义，关键决策点已标注

### Stage 2 — 编码实现

- **执行者**：全栈开发 agent
- **输入**：Stage 1 架构方案
- **动作**：按架构方案编码，前端设计师 agent 并行启动处理 UI 部分
- **产出**：代码文件 + `{team}-02-implementation.md`
- **门控**：代码可编译/运行，无语法错误

### Stage 3 — 集成测试

- **执行者**：集成测试 agent
- **输入**：Stage 2 代码产物
- **动作**：编写并运行测试用例，调用 `kf-browser-ops` 做 UI 自动化测试
- **产出**：`{team}-03-test-report.md` — 测试覆盖、通过/失败、边界验证
- **门控**：核心 Happy Path 测试通过方可进入 Stage 4

### Stage 4 — 代码审查

- **执行者**：集成测试 agent
- **输入**：Stage 2 代码 + Stage 3 测试报告
- **动作**：调用 `kf-code-review-graph` 生成依赖图谱、涟漪效应分析、审查优先级
- **产出**：`{team}-04-review-report.md`
- **门控**：无 error 级别问题；warning 级别已记录并评估

### Stage 5 — 方案汇总

- **执行者**：前端设计师 agent
- **输入**：Stage 0-4 所有产物
- **动作**：汇总团队方案，从团队视角补充 UI/UX 评估
- **产出**：`{team}-05-final.md` — 团队的最终方案（含方案概述、核心思路、优势、风险）

### 流水线自动触发

当 swarm 为团队 spawn agent 时，通过 `task_orchestrate` 定义阶段依赖 DAG：

```
Stage0 → Stage1 → Stage2 → Stage3 → Stage4 → Stage5
```

每个 agent 完成当前阶段后自动触发下一阶段。阶段失败则阻塞该团队流水线，
其他团队流水线不受影响。

---

## 三团队角色定义

| 团队 | 视角 | 优先考虑 |
|------|------|---------|
| **红队** | 激进创新者 | 性能极致、新技术采用、架构突破 |
| **蓝队** | 稳健工程师 | 可维护性、工期可控、团队能力匹配 |
| **绿队** | 安全保守者 | 零漏洞、边界完备、合规/降级/回滚 |

每队 3 个 agent 分工：

| Agent | 流水线阶段 | 联动 |
|-------|-----------|------|
| **全栈开发** | Stage 0-2（对齐→架构→编码） | `kf-spec`、`kf-alignment`、`kf-web-search`（按需搜索技术方案） |
| **集成测试** | Stage 3-4（测试→审查） | `kf-browser-ops`、`kf-code-review-graph`、`kf-web-search`（按需搜索测试方案） |
| **前端设计师** | Stage 2 UI 并行 + Stage 5 方案汇总 | `kf-ui-prototype-generator`、`kf-web-search`（按需搜索 UI 参考） |

---

## 执行流程

### Step 0 — 环境准备

确认 claude-flow MCP 可用后启动 swarm：

```
1. 检查 claude-flow MCP 在线状态
2. swarm_init → 创建 hierarchical-mesh 拓扑
3. 为每队创建 Pipeline 任务 DAG（task_orchestrate）
```

**回退模式**（MCP 不可用时）：单会话顺序模拟三团队视角。

### Step 0.1 — 根据任务类型调整规模

| 任务类型 | Agent 配置 | 流水线策略 |
|----------|-----------|-----------|
| **编码开发** | 3 agent/队 × 3 队 + 裁判 + 汇总 = 11 | 完整 6 阶段流水线 |
| **文档生成** | 2 agent/队 × 3 队 + 裁判 + 汇总 = 8 | 精简 3 阶段（对齐→撰写→审查） |
| **方案评审** | 2 agent/队 × 3 队 + 裁判 + 汇总 = 8 | 快速 2 阶段（分析→论证） |

---

### Phase 1 — 任务理解与拆解

输出统一任务规格：

```
1. 任务目标（一句话）
2. 硬约束（不可违反）
3. 软约束（尽量满足）
4. 评判维度及权重（默认见下方）
5. 任务类型判定：编码开发 / 文档生成 / 方案评审
```

默认评判维度：

| 维度 | 权重 | 说明 |
|------|------|------|
| 正确性 | 30% | 方案是否解决核心问题 |
| 性能/效率 | 20% | 时间/空间/资源开销 |
| 可维护性 | 20% | 代码清晰度、模块化 |
| 安全性 | 20% | 边界处理、权限控制 |
| 创新性 | 10% | 独到见解或更优思路 |

用户可自定义权重。

### Gate 1 — 任务规格确认后方可进入 Phase 2。

---

### Phase 2 — Swarm + Pipeline 并发执行

**三队流水线并行启动**：

```
1. swarm_init → hierarchical-mesh
2. 为每队创建 Pipeline DAG: Stage0→Stage1→Stage2→Stage3→Stage4→Stage5
3. 并行 spawn 三队的 Stage 0 agent（run_in_background: true）
4. Pipeline 自动推进：每阶段完成后自动触发下一阶段
5. 等待三队全部流水线完成
6. 收集各队 Stage 5 最终方案
```

**每个团队的最终方案必须包含**：
1. 方案概述（200 字内）
2. 核心实现思路
3. 关键代码/架构片段
4. 方案优势（3-5 点）
5. 方案风险（3-5 点）

---

### Phase 3 — 裁判评分

裁判以客观中立视角，调用 `kf-alignment` 对齐评分标准后逐一评分：

```
## 裁判评分卡

### {队名}方案
| 维度 | 得分(1-10) | 加权分 | 评语 |
|------|-----------|--------|------|
| 正确性 | x | x*0.3 | ... |
| 性能/效率 | x | x*0.2 | ... |
| 可维护性 | x | x*0.2 | ... |
| 安全性 | x | x*0.2 | ... |
| 创新性 | x | x*0.1 | ... |
| **总分** | | **X.X** | |

### 排名
1. {队名} — X.X 分 — {一词汇总}
2. {队名} — Y.Y 分 — {一词汇总}
3. {队名} — Z.Z 分 — {一词汇总}
```

---

### Phase 4 — 汇总融合

根据分差选择融合策略：

| 分差 | 策略 | 做法 |
|------|------|------|
| 冠军领先 >15% | **择优采纳** | 直接用第一名，吸收第二名亮点 |
| 冠亚接近 <15% | **博采众长** | 取各方案最强维度杂交融合 |
| 三方都很接近 | **按需融合** | 根据场景偏好选择侧重 |

融合输出：

```
## 最终方案 — {融合策略}

### 方案来源
- 核心架构：来自{某队}
- 安全加固：来自{某队}
- 性能优化：来自{某队}
- 工程落地：来自{某队}

### 实现步骤
1. ...
2. ...

### 优势汇总
- {各队优势}

### 风险管控
- {各队风险提示 + 缓解措施}

### 碾压指标
| 维度 | 单方案最高分 | 融合方案分 | 提升 |
|------|------------|-----------|------|
| ... | ... | ... | ... |
```

---

## 快速模式（轻量任务）

跳过完整 swarm 和流水线，双视角对比：

```
快速夯 — 双视角对比（顺序模拟）：
  视角A: "最优雅的做法是？"
  视角B: "最快的做法是？"
  → 二选一或融合 → 直接输出最终方案
```

---

## 输出规范

每次执行完成后输出摘要：

```markdown
## 夯 执行摘要

### 任务
{一句话}

### 三团队方案对比
| 团队 | 方案要点 | 评分 | 流水线阶段 |
|------|---------|------|-----------|
| 红队 激进 | {要点} | X.X | 6/6 完成 |
| 蓝队 稳健 | {要点} | X.X | 6/6 完成 |
| 绿队 安全 | {要点} | X.X | 6/6 完成 |

### 代码审查图谱
{集成测试 agent 调用 kf-code-review-graph 生成}

### 最终决策
- 策略：{择优/博采众长/按需融合}
- 方案保存至：`.gspowers/artifacts/hammer-{date}-{topic}.md`

### 碾压指标
- 参与 Agent 数：{N}
- 比单方案提升：{X}%
- 覆盖的风险维度：{列表}
```

---

## Gotchas

- 输入为 SDD Excel（`.xlsx`）时，**必须先执行 Pre-Stage** 调用 `kf-prd-generator` 生成 PRD.md，链路：`SDD Excel → PRD.md → kf-spec → Spec → 夯并发`
- 流水线阶段失败只阻塞该团队，不影响其他团队并行推进
- Stage 2 编码阶段前端设计师可与全栈开发并行（UI 实现 + 后端实现独立）
- 裁判评分前必须调用 `kf-alignment` 统一评分尺度，避免三队方案评分标准不一致
- 回退模式（无 MCP）下流水线改为单会话顺序模拟，每阶段输出后等待确认
- 快速模式跳过流水线和 swarm，仅做双视角文本对比，不生成中间产物

---

## 联动关系

| 技能 | 调用时机 | 用途 |
|------|---------|------|
| `kf-model-router` | 启动时 | 自动切换模型：裁判/汇总用 pro，各队 agent 用 flash |
| `kf-prd-generator` | Pre-Stage（条件触发） | 输入为 SDD Excel 时自动调用，生成 PRD.md 作为需求基线 |
| `kf-alignment` | Stage 0 + Phase 3 | 动前对齐 + 裁判评分标准对齐 |
| `kf-spec` | Stage 0 | 读取 Spec/PRD 作为需求基线 |
| `kf-web-search` | Stage 1/2/3（按需） | agent 搜索技术方案、最佳实践、测试方案、UI 参考 |
| `kf-ui-prototype-generator` | Stage 2 + Stage 5 | 前端设计师 UI 原型生成 |
| `kf-browser-ops` | Stage 3 | 集成测试 agent 自动化测试 |
| `kf-code-review-graph` | Stage 4 | 代码审查依赖图谱 |
| `gspowers` Pipeline 引擎 | Step 0 + Phase 2 | 团队内部流水线阶段编排 + 产物交接（融入夯） |
| `claude-flow` (swarm_init, agent_spawn, task_orchestrate) | Step 0 + Phase 2 | 多 Agent 并发 + Pipeline DAG 编排 |
