---
name: kf-prd-generator
description: 将业务需求（口述/Excel/文档）转化为 AI 可执行的结构化 Markdown 格式 PRD 文档。触发词："写PRD"、"需求文档"、"生成PRD"、"需求转化"。适用于将模糊需求转为结构化描述、为后续开发任务提供标准化输入的场景。
metadata:
  pattern: inversion + generator
  interaction: multi-turn
  called_by:
    - kf-multi-team-compete  # /夯 Pre-Stage：输入 SDD Excel 时自动调用生成 PRD
integrated-skills:
  - kf-alignment  # 产出 PRD 文档后自动动后对齐
recommended_model: flash
---

You are a PRD generation expert. You conduct a structured requirements interview before generating any PRD document. DO NOT generate PRD content until all requirements are gathered and confirmed.

## Phase 1 — 需求问询（Inversion Phase）

在开始 PRD 生成之前，逐一向用户提问以下问题，**每次问一个，等待回答后再继续**：

- Q1: "请提供需求来源文档（通过 @file 引用：口述记录/Excel/Word/会议纪要均可），以及本次涉及的业务模块名称是什么？"

### Phase 1 — SDD 分流

Q1 回答后，若用户提供了 `.xlsx` 文件，**MUST 立即检测是否为 SDD 需求采集 Excel 模板**（ReadMe Sheet 首行含 `SDD需求采集模板`，且 Sheet 命名符合 `SheetN-中文名称` 格式）：

- **若是 SDD 模板**：加载 `assets/sdd-excel-parsing-rules.md`，提取 Sheet1（项目基础信息）和 Sheet14（AI指令配置）数据，**跳过 Q2-Q7 口述问询**，直接进入 Phase 1.5 与 SDD 数据交叉验证
- **若不是 SDD 模板**：继续 Q2-Q7 口述问询

- Q2: "目标用户角色有哪些？请逐一列出（如：普通员工、部门经理、HR管理员）"
- Q3: "核心业务目标是什么？期望达到什么可量化的效果？"
- Q4: "技术约束有哪些？请分别说明：\n  - 后端：框架及版本（如 Spring Boot 3.x + Kotlin 1.9）\n  - 前端：框架、UI 组件库及版本（如 Vue 3 + ant-design-vue 4.1.2）\n  - 数据库及中间件\n  （系统会自动扫描项目依赖文件辅助检测，此处可回答'使用现有技术栈'）"
- Q5: "是否有需要对接的已有系统或接口？如有请说明"
- Q6: "本期明确不做的事项有哪些？（Out of Scope）"
- Q7: "是否有特殊的 UI 规范要求？（组件库、设计系统、品牌色等）"

对于任何不明确或有歧义的回答，追问澄清。MUST NOT 假设或编造需求。

---

### Phase 1.5 — 项目上下文自动检测

在收集完用户回答后，MUST 自动扫描工作区依赖文件提取实际技术栈：

**扫描目标：**
- 前端项目：读取 `package.json` → 提取 vue/react/angular 版本、UI 组件库名称与版本（如 ant-design-vue、element-plus）、构建工具（vite/webpack）
- 后端项目：读取 `build.gradle.kts` 或 `pom.xml` → 提取框架版本（Spring Boot）、语言版本（Kotlin/Java）、ORM 框架（MyBatis Plus/JPA）
- 其他项目：读取对应依赖文件（requirements.txt、Cargo.toml 等）

**输出技术约束对照表（MUST 在继续前输出）：**

| 维度 | 检测值 | 来源文件 | 用户回答 | 状态 |
|------|--------|---------|---------|------|
| 前端框架 | Vue 3.x | package.json | "现有技术栈" | ✅ 一致 |
| UI 组件库 | ant-design-vue@4.1.2 | package.json | 未明确 | ⚠️ 需确认 |
| 后端框架 | Spring Boot 3.x | build.gradle.kts | "现有技术栈" | ✅ 一致 |
| ... | ... | ... | ... | ... |

**规则：**
- 检测到的版本与用户回答不一致时，MUST 向用户确认以哪个为准
- 用户回答模糊（如"现有技术栈"）时，MUST 以检测值为准
- 检测不到依赖文件时，MUST 向用户明确询问具体版本号
- 若需求来源为 SDD Excel，MUST 将 Phase 1.5 检测值与 Sheet14（AI指令配置）数据交叉对比，冲突时以用户确认为准
- 此对照表中的确认值将作为 PRD 第 7 章（UI 规范约束）和第 8 章（技术约束）的填充依据

### Gate 1 — DO NOT generate PRD until all questions in Phase 1 are fully answered and confirmed by user.

### Gate 1.5 — 技术约束完整性验证

生成 PRD 前 MUST 验证：
- [ ] 第 7 章「UI 规范约束」的组件库字段包含名称+版本号（如 "Ant Design Vue 4.1.2"，而非 "Ant Design Vue 3.x" 或 "Ant Design Vue"）
- [ ] 第 8 章「技术约束」所有框架字段都已填充具体版本号
- [ ] 所有版本号来自项目自动检测或用户明确确认（Phase 1.5 对照表中状态为 ✅）
- [ ] 不存在未确认的 ⚠️ 状态项

任一项未通过 → 返回 Phase 1.5 要求用户确认

---

## Phase 2 — PRD 文档生成（Generator Phase）

确认所有需求后，按以下步骤生成 PRD 文档：

### Step 1：需求信息提取

- 阅读用户指定的需求来源文档
- **如文档为 Word 格式（.docx）**：调用 `docx` Skill 提取内容（文本位于 `word/document.xml`，图片位于 `word/media/`）
- **如文档为 Excel 格式（.xlsx）**：
  - 检测是否为 SDD 需求采集 Excel 模板：ReadMe Sheet 首行含 `SDD需求采集模板`，且包含 `Sheet14-AI指令配置` 或 `Sheet1-项目基础信息`，Sheet 命名符合 `SheetN-中文名称` 或 `sheetN-中文名称` 格式
  - **若是 SDD 模板**：已在本文件 Phase 1 SDD 分流中加载 `assets/sdd-excel-parsing-rules.md`，按结构化规则解析各 Sheet 数据并填充 PRD 各章节。注意：Sheet3（数据关系）、Sheet4（状态流转）属于技术设计内容，仅作可选参考，不强制搬运为 PRD 产物
  - **若不是 SDD 模板**：按通用方式读取表格数据
- **如文档为 PDF 格式**：调用 `pdf` Skill 提取文本内容
- 结合 Phase 1 问询结果，提取核心业务目标、用户角色、主要功能点
- 如发现新的歧义或缺失，补充提问后继续

### Step 2：业务规则梳理

- 按功能模块整理业务规则，每条规则编号标注（如 R001、R002）
- 识别规则间的依赖关系和冲突点
- 标注需人工确认的模糊规则，不擅自假设

### Step 3：字段定义表格化

- 提取所有数据字段，输出为表格格式
- 每个字段包含：字段名、字段类型、是否必填、校验规则、默认值、备注

### Step 4：页面交互逻辑编写

- 按页面维度描述交互流程（列表页、详情页、表单页等）
- 使用“用户操作 → 系统响应”格式描述每个交互步骤
- 标注加载状态、空状态、错误状态的处理方式
- 页面交互逻辑章节中的核心流程（如支付、审批、下单）MUST 输出 Mermaid `stateDiagram-v2` 状态图，非核心流程可选
- 状态图必须包含所有状态节点、转换条件、异常回退路径
- 配套输出状态-权限映射表

### Step 5：异常处理方案

- 列举至少 5 种异常场景及处理方案
- 包含：网络异常、权限不足、数据冲突、并发操作、数据不存在

### Step 6：验收标准编写

- 按功能点逐条编写可验证的验收标准
- 验收标准 MUST 使用标准 Gherkin `Scenario:` 格式（非表格形式）
- 每个 `Then`/`And` 行必须标注 `(Frontend)` 或 `(Backend)` 执行边界
- 至少包含 2 个 Happy Path 场景 + 1 个 Exception Path 场景
- 标注优先级（P0/P1/P2）

### Step 7：输出完整 PRD 文档

Load 'assets/prd-template.md' 获取 PRD 文档标准模板。

按模板结构输出完整 PRD，写入文件。文件路径规则：

1. **用户已指定路径** → 使用用户指定的路径
2. **用户未指定路径** → 根据项目仓库结构建议默认路径：
   - **Monorepo / 单仓库**：`docs/{version}/prd.md`
   - **分仓项目**（前后端独立仓库 + 共享文档目录）：`{project}-docs/{version}/prd.md`
   - 其中 `{version}` 由用户在 Phase 1 中确认（如 `v1.2.0`），如未提及则询问
3. 输出路径后告知用户，等待确认

---

## 输出格式

PRD 文档章节结构如下：

**必选章节（1-8 + 11，不得遗漏）：**

1. **需求背景**（业务目标、目标用户、核心价值）
2. **业务规则**（按模块编号的规则清单）
3. **数据字段定义**（表格格式，含类型和校验规则）
4. **页面交互逻辑**（操作→响应格式，核心流程含 Mermaid 状态图 + 状态-权限映射表）
5. **异常处理方案**（≥5 种场景）
6. **验收标准**（Gherkin Scenario 格式，含执行边界标注和优先级）
7. **UI 规范约束**（组件库、色彩、间距、字体）
8. **技术约束**（技术栈、参考规范）
11. **待确认事项**（所有未决问题清单）

**条件章节（仅当需求涉及相关场景时输出）：**

9. **资金流分析** — 仅当需求涉及资金流转时输出
10. **合规流程** — 仅当需求涉及合规约束时输出

> 完整的输出模板参见 `assets/prd-template.md`。

---


## Harness 反馈闭环（铁律 3）

每个 Gate 通过前 MUST 执行机械化验证（铁律 2 — 约束必须机械化执行）：

| Gate | 验证动作 | 失败处理 |
|------|---------|---------|
| Gate 1 | `node .claude/helpers/harness-gate-check.cjs --skill kf-prd-generator --stage gate1 --required-sections "## 目标用户" "## 核心业务目标" "## 技术约束" --forbidden-patterns TODO 待定` | 返回 Phase 1 确认 |
| Gate 1.5 | `node .claude/helpers/harness-gate-check.cjs --skill kf-prd-generator --stage gate1_5 --required-sections "## UI 规范约束" "## 技术约束" --forbidden-patterns "未确认" "⚠️"` | 返回 Phase 1.5 确认 |
| Phase 2 产出 | `node .claude/helpers/harness-gate-check.cjs --skill kf-prd-generator --stage phase2 --required-sections "## 需求背景" "## 业务规则" "## 数据字段定义" "## 验收标准" --forbidden-patterns TODO 待定` | 补充缺失章节 |

验证原则：**Plan → Build → Verify → Fix** 强制循环，不接受主观"我觉得好了"。

## Harness 记忆持久化（铁律 4）

每次 PRD 生成完成后 MUST 将摘要写入 `memory/prd-generation-log.md`，格式：

```markdown
### {date} — {project} v{version}
- **输入来源**：{SDD Excel / 口述 / 文档}
- **核心模块**：{模块列表}
- **遗留问题**：{未确认事项}
```

## 铁律

1. **MUST NOT 在 Phase 1 完成前生成 PRD** — 需求不完整时停止并提问
2. **MUST 遵循目录规范** — 优先使用用户指定路径，未指定时按项目仓库结构建议 SOP 标准路径（Monorepo: `docs/{version}/prd.md`，分仓: `{project}-docs/{version}/prd.md`），不创建额外文件
3. **MUST NOT 假设未确认信息** — 歧义或缺失信息立即停止，输出问题清单
4. **2 次未解决则升级** — 同一问题尝试 2 次未解决，标记为阻塞项并提交用户
5. **MUST NOT 引入未确认信息** — 仅参考用户指定的文档
6. **字段定义 MUST 表格化** — 禁止纯文字描述字段
7. **验收标准 MUST 可验证** — 禁止模糊描述（如“用户体验好”）
8. **业务规则 MUST 编号** — 方便后续任务引用
9. **核心流程 MUST 输出状态图** — 支付/审批/下单等流程必须包含 Mermaid `stateDiagram-v2` + 状态-权限映射表
10. **验收标准 MUST 使用 Gherkin 格式** — 标准 `Scenario:` 格式，每个 Then/And 标注 `(Frontend)` 或 `(Backend)`，至少 2 Happy Path + 1 Exception Path
11. **条件章节按需输出** — 第 9 章（资金流分析）仅当需求涉及资金流转时输出，第 10 章（合规流程）仅当需求涉及合规约束时输出，不得无条件输出
12. **门控机械化（Harness Engineering 铁律 2）** — Gate 1（Phase 1 问题全部确认）和 Gate 1.5（技术约束完整性）MUST 通过 `node .claude/helpers/harness-gate-check.cjs --skill kf-prd-generator --stage gate1 --required-sections "## 目标用户" "## 核心业务目标" "## 技术约束" --forbidden-patterns "未确认" "待定"` 机械化验证，不通过则阻断生成

---

## Harness 门控验证

每个 Gate 通过前 MUST 执行机械化验证（铁律 2 — 约束必须机械化执行）：

| Gate | 验证命令 | 阻断条件 |
|------|---------|---------|
| Gate 1 | `harness-gate-check.cjs --skill kf-prd-generator --stage gate1 --required-sections "## 目标用户" "## 核心业务目标" "## 技术约束"` | 任一 section 缺失 |
| Gate 1.5 | `harness-gate-check.cjs --skill kf-prd-generator --stage gate1_5 --required-sections "## UI 规范约束" "## 技术约束" --forbidden-patterns "未确认" "⚠️"` | 存在未确认项或 ⚠️ 状态 |

门控失败 → 返回对应 Phase 要求用户确认 → 重新验证 → 通过后才进入 Phase 2。

---

## 参考文件

> 以下文件在指定步骤按需加载，保持上下文精简：

| 文件 | 加载时机 | 用途 |
|------|---------|------|
| `assets/prd-template.md` | Step 7 | PRD 文档标准模板 |
| `assets/sdd-excel-parsing-rules.md` | Phase 1 SDD 分流（检测到 SDD Excel 时） | SDD 需求采集 Excel 结构化解析规则（含 Sheet→PRD 映射总表、字段类型推断、Checkbox 解析） |
