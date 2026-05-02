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
    - kf-scrapling
    - kf-prd-generator
    - kf-model-router
    - kf-image-editor
    - skill-creator
---

# 夯 — 多团队竞争评审系统

你是「夯」模式的协调者。**夯 = 力大 + 万法 = 碾压**。

核心理念：swarm 多 Agent 并发，红蓝绿三队各按 **Pipeline 流水线** 推进，
不同视角方案碰撞，裁判择优，汇总博采众长，输出碾压级方案。

---

## 架构总览

```
                    用户输入（任务描述 / SDD Excel / PRD）
                             │
                    检测到 .xlsx？─── 是 ──→ Pre-Stage: kf-prd-generator → PRD.md
                             │                        │
                            否                        ▼
                             │              三队均以 PRD.md 为输入
                             └────────┬───────────────┘
                                      ▼
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

> **触发条件**：用户输入包含 SDD Excel 文件（`.xlsx`）或用户说"写PRD"/"生成PRD"时自动执行；否则跳过。

- **执行者**：协调者（本 Skill 自身，不 spawn agent）
- **动作**：
  1. 检测用户输入中是否包含 `.xlsx` 文件路径，或用户显式要求"写PRD"
  2. 若触发：`Skill({skill: "kf-prd-generator", args: "<文件路径或需求描述>"})`
  3. kf-prd-generator 完成 Phase 1 需求问询 → Phase 1.5 技术栈检测 → Phase 2 生成 PRD.md
  4. PRD.md 生成后，kf-prd-generator 自动调用 kf-alignment 做动后对齐
- **产出**：`PRD.md` — 结构化需求文档（背景、业务流、规则、页面、验收标准）
- **门控**：PRD.md 生成完成且通过 kf-prd-generator 的 Gate 1.5 机械化验证后 → 三队 Stage 0 均以该 PRD 为输入
- **跳过条件**：用户未提供 .xlsx 且未要求写 PRD，且任务描述已足够清晰 → 直接进入 Phase 1

**正确的链路**：`SDD Excel → kf-prd-generator → PRD.md → kf-spec → Spec → 夯 并发执行`

**注意**：即使无 SDD Excel，只要任务描述模糊（如一句话需求），协调者也应主动建议用户先走 kf-prd-generator 做需求结构化，或走 kf-spec 做 Spec 驱动开发，再进入 `/夯` 并发竞争。

### Stage 0 — 需求对齐（recording 模式）

- **执行者**：全栈开发 agent
- **模式**：`kf-alignment` recording 模式（不阻塞，不提问用户）
- **输入**：
  1. PRD.md / Spec（如果有）
  2. 协调者锁定的**假设基线**（Phase 1.3，由 swarm 广播注入 prompt）
  3. 本团队角色定位（红/蓝/绿）
- **动作**：
  1. 读取输入源，对齐需求理解
  2. 检查假设基线是否足够支撑 Stage 1 架构设计
  3. 若发现关键歧义（影响架构选型），记录为 `[ASSUMPTION:CRITICAL]`，不影响继续推进
  4. MUST NOT 向用户提问或阻塞流水线
- **产出**：`{team}-00-alignment.md` — 需求理解、边界确认、技术约束、补充假设清单（如有）
- **门控**：对齐记录产出后自动进入 Stage 1（不等待用户确认）
- **三队约束**：三队共享同一份假设基线，确保方案可比；各自只能补充假设，不能推翻基线

### Stage 1 — 架构设计

- **执行者**：全栈开发 agent
- **输入**：Stage 0 对齐记录
- **动作**：设计数据模型、API 契约、组件树、路由方案；**可调用 `kf-web-search` 搜索技术方案和最佳实践，或 `kf-scrapling` 深度抓取参考实现**
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

| Agent | 流水线阶段 | 联动 | 模型 |
|-------|-----------|------|------|
| **全栈开发** | Stage 0-2（对齐→架构→编码） | `kf-spec`、`kf-alignment`、`kf-web-search`（按需搜索技术方案）、`kf-scrapling`（按需深度数据采集） | `sonnet`（flash） |
| **集成测试** | Stage 3-4（测试→审查） | `kf-browser-ops`、`kf-code-review-graph`、`kf-web-search`（按需搜索测试方案） | `sonnet`（flash） |
| **前端设计师** | Stage 2 UI 并行 + Stage 5 方案汇总 | `kf-ui-prototype-generator`、`kf-web-search`（按需搜索 UI 参考）、`kf-scrapling`（按需抓取设计参考） | `sonnet`（flash） |
| **协调者（本 Skill）** | Pre-Stage + Phase 1-4（任务拆解→裁判评分→汇总融合） | 全部 integrated-skills | `opus`（pro） |

---

## 执行流程

### Step 0 — 环境准备

确认 claude-flow MCP 可用，不可用时自动修复：

```
1. 执行 `claude mcp list` 检查 ruflo 是否在线
2. 若未注册（回退模式：swarm 面板 0/15），自动执行：
   claude mcp add ruflo -- npx -y ruflo@latest mcp start
3. 验证 ruflo MCP 在线后，swarm_init → 创建 hierarchical-mesh 拓扑
4. 为每队创建 Pipeline 任务 DAG（task_orchestrate）
5. 确认 swarm 面板计数 > 0 再进入 Phase 1
```

**回退模式**（MCP 修复失败时）：单会话顺序模拟三团队视角。

### Step 0.1 — 根据任务类型调整规模

| 任务类型 | Agent 配置 | 流水线策略 |
|----------|-----------|-----------|
| **编码开发** | 3 agent/队 × 3 队 + 裁判 + 汇总 = 11 | 完整 6 阶段流水线 |
| **文档生成** | 2 agent/队 × 3 队 + 裁判 + 汇总 = 8 | 精简 3 阶段（对齐→撰写→审查） |
| **方案评审** | 2 agent/队 × 3 队 + 裁判 + 汇总 = 8 | 快速 2 阶段（分析→论证） |

---

### Phase 1 — 任务理解与拆解

#### Phase 1.1 — 上下文收集

检查是否存在 PRD.md（来自 Pre-Stage）或 Spec 文档，若存在则作为任务理解的输入。

#### Phase 1.2 — 歧义检测与协调者反转门控（Coordinator Inversion Gate）

在输出任务规格前，协调者 MUST 检测任务描述的歧义程度。

**自动判定规则**：

| 输入条件 | 歧义等级 | 动作 |
|---------|---------|------|
| SDD Excel → PRD.md 完整链路 | 低（GREEN） | 跳过反转，直接输出任务规格 |
| Spec 文档已存在 | 低（GREEN） | 跳过反转，直接输出任务规格 |
| 用户口述 ≥3 句，含具体技术栈和范围 | 低（GREEN） | 跳过反转 |
| 用户口述 1-2 句，关键维度缺失 | 中（YELLOW） | 仅对缺失维度做选择题 |
| 一句话需求 / 模糊描述 | 高（RED） | 对 4 个关键维度逐一给选项 |

**GREEN 级也必须输出锁定版任务规格**：
- 即使报告/Spec 已足够详尽，Phase 1.3 的任务规格输出不可跳过
- 原因：任务规格是三队 agent 共享的「假设基线」载体，缺少它则三队方案不可比
- 实践：GREEN 级可简化（直接引用 Spec/报告中的关键约束），但必须显式输出 7 项结构

**YELLOW/RED 级别的反转规则**（遵循 kf-alignment interactive 模式）：

对每个有歧义的维度，给出 2-4 个具体选项，附带后果说明，禁止开放提问：

```
## 任务歧义澄清

以下维度需要你选择确认（选 A/B/C，不开放回答）：

### 1. [维度名，如：目标平台]
A. [方案名] — [一行说明]，后果：[选 A 的后果]
B. [方案名] — [一行说明]，后果：[选 B 的后果]
C. [方案名] — [一行说明]，后果：[选 C 的后果]

### 2. [下一维度]
...

请逐项回复 A/B/C。
```

**关键维度清单**（仅对缺失/模糊的维度提问）：
1. **技术栈**：已明确则跳过，否则给 MVP/标准/现有技术栈三选一
2. **目标平台**：已明确则跳过，否则给 Web/iOS+Android/跨平台三选一
3. **范围边界**：已明确则跳过，否则给 2-3 种范围裁剪方案
4. **性能/安全档位**：已明确则跳过，否则给原型级/生产级/极致优化三选一

**禁止行为**：
- 禁止对已明确的信息重复提问
- 禁止开放问题（如"你觉得哪个更好？"）
- 禁止对同一维度问两次

#### Phase 1.3 — 任务规格输出与锁定

用户确认所有歧义澄清后（或 GREEN 级直接输出），输出锁定版任务规格：

```
1. 任务目标（一句话）
2. 输入来源：[SDD Excel → PRD.md / 用户口述 / Spec 文档 / 其他]
3. 硬约束（不可违反）
4. 软约束（尽量满足）
5. 假设基线（协调者锁定的默认假设 → 注入三队 Stage 0）
6. 评判维度及权重（默认见下方）
7. 任务类型判定：编码开发 / 文档生成 / 方案评审
```

**假设基线机制**：协调者在 Phase 1.3 锁定的假设，在 Phase 2 spawn 三队时，MUST 注入到每个 agent 的 Stage 0 prompt 中。三队 agent 在 recording 模式下基于同一份假设基线工作，确保方案可比。

默认评判维度：

| 维度 | 权重 | 说明 |
|------|------|------|
| 正确性 | 30% | 方案是否解决核心问题 |
| 性能/效率 | 20% | 时间/空间/资源开销 |
| 可维护性 | 20% | 代码清晰度、模块化 |
| 安全性 | 20% | 边界处理、权限控制 |
| 创新性 | 10% | 独到见解或更优思路 |

用户可自定义权重。

### Gate 1 — 任务规格锁定 + 假设基线确认后方可进入 Phase 2。

---

### Phase 2 — Swarm + Pipeline 并发执行

**桥接层**：本 Skill 使用 Claude Code 内置 Agent 工具执行（非 ruflo swarm MCP）。通过 `hammer-bridge.cjs` 追踪 Agent 状态，弥补 ruflo 面板始终显示 0/15 的体验缺口。

**三队流水线并行启动，每个 agent 按需自动分配模型**：

```
0. 若 Pre-Stage 已产出 PRD.md，将 PRD.md 路径注入三队的 Stage 0 prompt 中作为输入
0.5. node .claude/helpers/hammer-bridge.cjs init --task "<任务名>" --total-agents <N>
1. swarm_init → hierarchical-mesh
2. 为每队创建 Pipeline DAG: Stage0→Stage1→Stage2→Stage3→Stage4→Stage5
3. 并行 spawn 三队的 Stage 0 agent（run_in_background: true, model: "sonnet"）
   每个 agent spawn 后 MUST 调用:
     node .claude/helpers/hammer-bridge.cjs agent-spawn --team <红/蓝/绿> --agent <agent名> --task-id <阶段>
   每个 agent 的 prompt 中 MUST 包含：
     - 若 PRD.md 存在：@PRD.md 文件引用
     - 若 Spec 存在：@spec.md 文件引用
     - 任务规格（Phase 1.3 锁定版输出）
     - 协调者假设基线（Phase 1.3 锁定，三队共享）
     - 本团队的角色定位（红/蓝/绿）
     - kf-alignment recording 模式指令（不提问、不阻塞、记录假设）
   模型路由：
     - 全栈开发 agent → model: "sonnet"（flash, 执行层面）
     - 集成测试 agent → model: "sonnet"（flash, 执行层面）
     - 前端设计师 agent → model: "sonnet"（flash, 执行层面）
     - 协调者（本 Skill 自身）→ model: "opus"（pro, 规划+评判层面）
4. Pipeline 自动推进：每阶段完成后自动触发下一阶段
   每阶段完成时调用:
     node .claude/helpers/hammer-bridge.cjs agent-done --team <队名> --agent <agent名> --output <产物文件>
5. 等待三队全部流水线完成
   执行中可随时查看状态:
     node .claude/helpers/hammer-bridge.cjs status
6. 收集各队 Stage 5 最终方案
   生成最终摘要:
     node .claude/helpers/hammer-bridge.cjs summary --task "<任务名>"
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
- **GREEN 级别也不能跳过 Phase 1.3 任务规格输出**——即使报告/Spec 已详尽，锁定版规格（任务目标、约束、假设基线、评判维度）是三队可比的前提，缺失则三队方案不可比
- ruflo swarm 面板始终显示 0/15 是正常的——本 Skill 使用 Claude Code 内置 Agent 工具执行，通过 `hammer-bridge.cjs` 追踪状态。运行 `node .claude/helpers/hammer-bridge.cjs status` 查看实际进度
- 流水线阶段失败只阻塞该团队，不影响其他团队并行推进
- Stage 2 编码阶段前端设计师可与全栈开发并行（UI 实现 + 后端实现独立）
- 裁判评分前必须调用 `kf-alignment` 统一评分尺度，避免三队方案评分标准不一致
- 回退模式（无 MCP）下流水线改为单会话顺序模拟，每阶段输出后等待确认
- 快速模式跳过流水线和 swarm，仅做双视角文本对比，不生成中间产物

## Harness 反馈闭环（铁律 3）

每个 Phase 完成后 MUST 执行机械化验证：

| Phase | 验证动作 | 失败处理 |
|-------|---------|---------|
| Pre-Stage（条件触发） | `node .claude/helpers/harness-gate-check.cjs --skill kf-multi-team-compete --stage prestage --required-files "PRD.md" --forbidden-patterns TODO 待定` | PRD.md 缺失则阻断进入 Phase 1 |
| Phase 1 | `node .claude/helpers/harness-gate-check.cjs --skill kf-multi-team-compete --stage phase1 --required-sections "## 任务目标" "## 评判维度及权重" --forbidden-patterns TODO 待定` | 任务规格不完整则回退 |
| Phase 2（每队） | `node .claude/helpers/harness-gate-check.cjs --skill kf-multi-team-compete --stage <N> --team <红/蓝/绿> --required-files "{team}-0<N>-*.md" --forbidden-patterns TODO 待定` | 阶段产物缺失则阻断该团队流水线 |
| Phase 3 | `node .claude/helpers/harness-gate-check.cjs --skill kf-multi-team-compete --stage phase3 --required-sections "## 裁判评分卡" "## 排名" --forbidden-patterns TODO 待定` | 评分卡不完整则回退 |
| Phase 4 | `node .claude/helpers/harness-gate-check.cjs --skill kf-multi-team-compete --stage phase4 --required-sections "## 最终方案" "## 融合策略" "## 碾压指标" --forbidden-patterns TODO 待定` | 汇总不完整则回退融合 |

验证原则：**Plan → Build → Verify → Fix** 强制循环，不接受主观"我觉得好了"。

## Harness 记忆持久化（铁律 4）

Phase 4 汇总融合完成后 MUST 将最终评分卡和方案摘要写入 `memory/hammer-results.md`，下次 `/夯` 启动时自动加载历史结果作为参考基线。

---

## 联动关系

| 技能 | 调用时机 | 用途 |
|------|---------|------|
| `kf-model-router` | 启动时 | 自动切换模型：裁判/汇总用 pro，各队 agent 用 flash |
| `kf-prd-generator` | Pre-Stage（条件触发） | 输入为 SDD Excel 时自动调用，生成 PRD.md 作为需求基线 |
| `kf-alignment` | Stage 0 + Phase 3 | 动前对齐 + 裁判评分标准对齐 |
| `kf-spec` | Stage 0 | 读取 Spec/PRD 作为需求基线 |
| `kf-web-search` | Stage 1/2/3（按需） | agent 搜索技术方案、最佳实践、测试方案、UI 参考 |
| `kf-scrapling` | Stage 1/2/3（按需） | agent 深度网页抓取（反反爬），补充 web-search 无法访问的站点 |
| `kf-ui-prototype-generator` | Stage 2 + Stage 5 | 前端设计师 UI 原型生成 |
| `kf-browser-ops` | Stage 3 | 集成测试 agent 自动化测试 |
| `kf-code-review-graph` | Stage 4 | 代码审查依赖图谱 |
| `kf-image-editor` | Stage 2 + Stage 5（按需） | 前端设计师 AI 自然语言 P 图、方案配图、截图优化 |
| `skill-creator` | Stage 1 + Stage 2（按需） | agent 按需创建新 Skill 封装重复模式 |
| `gspowers` Pipeline 引擎 | Step 0 + Phase 2 | 团队内部流水线阶段编排 + 产物交接（融入夯） |
| `claude-flow` (swarm_init, agent_spawn, task_orchestrate) | Step 0 + Phase 2 | 多 Agent 并发 + Pipeline DAG 编排 |
