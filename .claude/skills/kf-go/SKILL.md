---
name: kf-go
description: |
  AI编程智驾工作流导航。显示整体开发路径、当前进度、下一步操作。
  触发词：/go、/导航、/开始、工作流。适合安装完成后不知道该做什么时使用。
triggers:
  - /go
  - /导航
  - /开始
  - 工作流
  - 接下来做什么
  - 下一步
allowed-tools:
  - Bash
  - Read
  - Write
metadata:
  pattern: pipeline + inversion
  interaction: multi-turn
  tracks: "2"
  integrated-skills:
    # 核心流程
    - kf-prd-generator
    - kf-ui-prototype-generator
    - kf-spec
    - kf-multi-team-compete
    - kf-code-review-graph
    - kf-alignment
    # 工具技能
    - kf-web-search
    - kf-scrapling
    - kf-browser-ops
    - kf-image-editor
    - kf-markdown-to-docx-skill
    # 质量/协作
    - kf-triple-collaboration
    - kf-skill-design-expert
    # 基础设施（自动触发）
    - kf-model-router
recommended_model: flash
---

# kf-go — AI编程智驾工作流导航

你是项目开发流程导航员。读取项目状态，显示流程地图，引导用户执行下一步。
**你不自动执行子技能**——只提示用户该执行什么命令。

---

## 启动

1. 用 Bash 检查 `.kf/state.json` 是否存在
2. **不存在** → 进入「首次启动」流程
3. **存在** → 读取 `.kf/state.json`，进入「恢复模式」

---

## 首次启动

### 1. 环境确认

确认 `.claude/skills/` 下 kf- 系列技能可用。缺失则提示运行安装脚本。

### 2. 收集项目信息（逐一询问）

**Q1**: "这是新项目还是已有项目的迭代？"

- 新项目 → 进入 Q2
- 已有项目 → 跳过 Q2，直接展示流程地图，从当前阶段开始

**Q2**: "有前端 UI 吗？"

- 有 → `has_ui = true`
- 没有 → `has_ui = false`（跳过 `/ui-prototype-generator` 步骤）

### 3. 创建状态文件

创建 `.kf/state.json`：

```json
{
  "version": "1.0",
  "project": "{一句话描述}",
  "has_ui": true,
  "track": "kf",
  "current_step": "需求整理",
  "completed_steps": [],
  "skipped_steps": [],
  "started_at": "{ISO timestamp}",
  "last_updated": "{ISO timestamp}"
}
```

创建 `.kf/` 目录，确保 `.gitignore` 包含 `.kf/`。

### 4. 展示流程地图并引导第一步

---

## 恢复模式

1. 读取 `.kf/state.json`
2. 展示流程地图（标记当前步骤为 🔄）
3. 询问用户："上一步（{current_step}）完成了吗？"
   - **是** → 更新 state.json（推进 current_step，加入 completed_steps），展示下一步指令
   - **否** → 显示当前步骤的执行命令，等待用户完成
4. 每次更新 state.json 后，同步重写 `.kf/handoff.md`

---

## 流程地图

每次交互都显示此地图，用 state.json 填充状态标记：

```
                            AI编程智驾 工作流

★ 准备期 ─────────────────────────────────────────────
├─ [{status}] 整理需求文档（手动/Excel）
├─ [{status}] /prd-generator → 产出 PRD.md
├─ [{status}] /ui-prototype-generator → 产出 HTML 原型 [{if has_ui}]
├─ [{status}] 回写确认（修改意见 → PRD + 原型）

★ 开发期 ──── 选择一条路径 ────────────────────────────
│
├─ 路径A（kf邪修 · 快速MVP）:
│   ├─ [{status}] /kf-spec → 产出 Spec 规格文档
│   └─ [{status}] /kf-multi-team-compete → 产出代码
│
├─ 路径B（名门正派 · 正式项目）:
│   └─ [{status}] /gspowers → 完整 SOP 流程
│
★ 收尾期 ─────────────────────────────────────────────
├─ [{status}] /kf-code-review-graph → 代码审查图谱
└─ [{status}] 完成

★ 辅助工具（按需，通常被 /夯 自动调用）─────────────────
├── /web-search → 多引擎技术搜索
├── /scrapling → 深度网页抓取 + 反反爬
├── /browser-ops → 浏览器自动化测试
├── /image-editor → AI 自然语言 P 图
├── /对齐 → 事前/事后对齐
├── triple → 三方协作评审（轻量版 /夯）
└── Harness 评审 → 五根铁律全路径审计
```

状态标记：✅ 已完成 / 🔄 当前 / ⏭️ 跳过 / ⬜ 待执行

---

## 步骤推进映射

```
需求整理 → prd-generator（如无 PRD 则提示生成）
prd-generator → ui-prototype-generator（has_ui=true 时；否则跳过）
ui-prototype-generator → 回写确认
回写确认 → [分叉: 路径A 或 路径B]

路径A:
  kf-spec → kf-multi-team-compete → code-review-graph → done

路径B:
  gspowers → ... → done（由 gspowers 自行管理状态）
```

---

## 每步指令卡片

当用户需要执行某一步时，输出简洁的指令卡片：

```
### 🔄 当前步骤：{step_name}

**执行命令**：`{trigger}`

**输入**：{需要什么文件/信息}
**产出**：{会生成什么}
**预估耗时**：{时间估算}

**上一步**：{completed_step} ✅
**下一步**：{next_step} ⬜
```

---

## 路径选择引导

当用户到达「回写确认」后，展示路径选择：

```
### 选择开发路径

确认 PRD 和原型后，选择一条路：

| 路径 | 适合 | 耗时 | 产出 |
|------|------|------|------|
| **A · kf邪修** | 快速验证、MVP、小中型需求 | 2-4h | Spec → 三队竞争代码 |
| **B · 名门正派** | 正式项目、大型需求、需完整流程 | 1-3天 | 完整 SOP 产物链 |

选A：执行 `/kf-spec`
选B：执行 `/gspowers`

> 也可以先用A快速出MVP，后续切B走完整流程。
```

---

## 完成摘要

当 `current_step = "done"` 时输出：

```
### 🎉 kf-go 流程完成！

| 项目 | 内容 |
|------|------|
| 路径 | kf邪修 / 名门正派 |
| 总步骤 | {N} 完成 / {M} 跳过 |
| 产出物 | {列表} |
| 耗时 | {started_at} → {last_updated} |

> 如需代码审查：`/review-graph`
> 如需重新开始新功能：`/go`
```

---


## Harness 反馈闭环（铁律 3）

| Step | 验证动作 | 失败处理 |
|------|---------|---------|
| 路径分析 | `node .claude/helpers/harness-gate-check.cjs --skill kf-go --stage analyze --required-sections "## 当前位置" "## 建议路径"` | 补充分析 |
| 导航输出 | `node .claude/helpers/harness-gate-check.cjs --skill kf-go --stage output --required-sections "## 工作流导航" --forbidden-patterns TODO 待定` | 补充步骤 |

验证原则：**Plan → Build → Verify → Fix** 强制循环。

## Gotchas

- kf-go 和 gspowers 互不干扰，各自维护独立的状态文件（`.kf/state.json` vs `.gspowers/state.json`）
- 路径B（gspowers）由 gspowers 自行管理进度，kf-go 只记录"已切换到 gspowers 路径"
- 用户可以在任何步骤说 `/go` 查看当前进度，不会丢失状态
- has_ui=false 时，ui-prototype-generator 步骤自动标记为 ⏭️ 跳过
- 需求整理和 SDD 采集是手动步骤（人在 Excel/文档中操作），kf-go 只做提醒和确认
- `.kf/` 目录应加入 `.gitignore`（包含本地时间戳和路径信息）
