---
name: kf-alignment
description: 对齐工作流 — "懂"原则。动前谈理解打算，动后谈diff。确保 AI 和用户在同一认知层面。触发词："对齐"、"/alignment"、"说下你的理解"、"谈下打算"、"说下diff"。
metadata:
  principle: 懂
  source: AICoding原则.docx
recommended_model: pro
---

# kf-alignment — 懂原则：默契对齐

> **核心原则**：懂默契的最高境界。你懂我，我懂你。坦诚相见。提高对齐颗粒度。
> **工作方式**：动前谈理解、打算；动后谈 diff。动前说方向，动后说咋想。

---

## 工作流

### Phase 1 — 动前对齐（Before Action）

接到任务后，执行前，必须先输出：

```
## 我的理解

[用自己的话复述：要做什么、为什么做、约束条件]

## 我的打算

[打算怎么做：分几步、用什么技术方案、关键决策点]

## 边界确认

- 范围：[本期做什么]
- 排除：[本期不做什么]
- 风险：[可能遇到的问题]
```

**等待用户确认后再开始执行。**

### Phase 2 — 动后复盘（After Action）

完成任务后，必须输出：

```
## 实际做了什么

[实际执行的动作清单]

## 与计划差异

| 计划 | 实际 | 原因 |
|------|------|------|
| [计划做什么] | [实际做了什么] | [为什么变了] |

## 关键决策

[执行过程中做的关键决策及原因]

## 遗留问题

[未解决的问题、后续建议]
```

---

## 触发方式

### 显式触发

```
对齐                        # AI 输出当前对话的理解和打算
说下你的理解                 # AI 复述对当前上下文的理解
谈下打算                     # AI 说明接下来打算做什么
说下 diff                    # AI 复盘刚才做的改动和原因
/alignment                  # 完整对齐流程
```

### 隐式触发

在以下场景 AI 应主动对齐：
- 用户给出新任务时 → 先复述理解
- 任务执行完毕时 → 输出 diff 复盘
- 方案有变更时 → 说明差异和原因
- 对话跨度较长（>5轮）→ 主动总结当前状态

---

## 文档产出自动对齐（Hook 技术）

以下技能**产出文档后**，必须自动触发 kf-alignment 做动后复盘：

| 技能 | 产出文档类型 | 对齐时机 |
|------|-------------|---------|
| `kf-prd-generator` | PRD.md | 文档写入后 → 输出"与需求的对齐 diff" |
| `kf-spec` | Spec 规格文档 | 文档写入后 → 输出"与 PRD 的对齐 diff" |
| `kf-ui-prototype-generator` | HTML 原型 | 原型生成后 → 输出"与 PRD/设计稿的对齐 diff" |
| `kf-code-review-graph` | 审查报告 | 报告生成后 → 输出"变更范围对齐 diff" |

### Hook 机制

通过 `settings.json` 的 `PostToolUse` Hook 监听文件写入事件。
当匹配到产出文档路径时，自动注入对齐提醒到会话上下文：

```json
{
  "matcher": "Write|Edit",
  "hooks": [{
    "type": "command",
    "command": "node .claude/helpers/alignment-hook.cjs check"
  }]
}
```

Hook 脚本检测到文档产出后，输出 `system-reminder` 格式的提醒，
促使 AI 在下一轮对话中主动执行动后对齐。

### 无 Hook 环境下的手动触发

如果 Hook 未配置，用户可在文档产出后手动触发：
```
说下 diff    # AI 复盘刚才产出的文档与原始需求的差异
```

## Harness 反馈闭环（铁律 3）

每个 Phase 完成后 MUST 执行机械化验证：

| Phase | 验证动作 | 失败处理 |
|-------|---------|---------|
| Phase 1 动前对齐 | `node .claude/helpers/harness-gate-check.cjs --skill kf-alignment --stage phase1 --required-sections "## 我的理解" "## 我的打算" "## 边界确认" --forbidden-patterns TODO 待定` | 补充缺失章节 |
| Phase 2 动后复盘 | `node .claude/helpers/harness-gate-check.cjs --skill kf-alignment --stage phase2 --required-sections "## 实际做了什么" "## 与计划差异" "## 关键决策" "## 遗留问题"` | 补充缺失章节 |

验证原则：**Plan → Build → Verify → Fix** 强制循环，不接受主观"我觉得好了"。

## 集成

本 Skill 与以下 Skill 配合使用：
- `kf-spec`：Step 1 澄清阶段本质就是对齐；产出 Spec 后自动对齐
- `kf-prd-generator`：产出 PRD 后自动对齐
- `kf-multi-team-compete`：裁判和汇总师的评分融合
- `kf-code-review-graph`：审查前后对齐改动范围
