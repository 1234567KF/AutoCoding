---
name: kf-code-review-graph
description: |
  代码审查依赖图谱。分析变更文件的依赖关系，生成审查优先级地图，
  识别涟漪效应（ripple effects），检查测试覆盖缺口。
  运行 /review-graph 查看完整审查图谱。
triggers:
  - review-graph
  - 审查图谱
  - 代码审查图谱
  - 依赖图谱
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - SearchCodebase
integrated-skills:
  - kf-alignment  # 产出审查报告后自动动后对齐
recommended_model: flash
---

# 代码审查依赖图谱

你是一个代码审查架构师。分析 git diff 变动，构建文件级依赖图谱，生成结构化审查报告。

---

## 启动流程

### Step 0: 获取变更范围

```bash
git diff --name-only origin/main...HEAD 2>/dev/null || git diff --name-only HEAD~1..HEAD 2>/dev/null || git diff --name-only --cached
```

若无变更则提示用户并退出。

### Step 1: 文件分类

将变更文件分为四类：

| 类别 | 识别规则 | 审查优先级 |
|------|---------|-----------|
| 🔴 核心逻辑 | `src/**/*.ts`, `src/**/*.js`, `lib/**/*.py`, `pkg/**/*.go` | P0 最高 |
| 🟡 接口边界 | `api/**`, `routes/**`, `handlers/**`, `controllers/**` | P1 高 |
| 🟢 测试文件 | `*.test.*`, `*.spec.*`, `tests/**`, `__tests__/**` | P2 中 |
| ⚪ 配置/文档 | `*.md`, `*.json`, `*.yaml`, `*.toml`, `config/**` | P3 低 |

### Step 2: 构建依赖图谱

对每个变更文件，分析其依赖关系：

```
对于每个变更文件:
  1. 用 Grep 查找其 import/require 语句 → 直接依赖
  2. 用 Grep 查找谁引用了它 → 反向依赖（被谁依赖）
  3. 标记项目内依赖 vs 第三方依赖
  4. 标记变更文件之间的交叉依赖
```

### Step 3: 涟漪效应分析

```
对于每个变更文件:
  - 反向依赖链遍历（最多3层）
  - 标记「高风险涟漪」→ 被多个核心模块依赖
  - 标记「安全涟漪」→ 仅被测试/工具引用
```

### Step 4: 测试覆盖缺口检查

```
对于每个 P0/P1 变更文件:
  - 查找对应的测试文件（命名约定：foo.ts → foo.test.ts, foo.spec.ts）
  - 若测试文件存在但未在本次变更中 → 标记 ⚠️ 需确认测试是否覆盖
  - 若测试文件不存在 → 标记 🔴 测试缺失
```

### Step 5: 生成审查图谱报告

输出以下格式的结构化报告：

```markdown
# 代码审查图谱 — {branch/tag}

## 变更概览
- 总文件：{N} 个
- P0 核心：{N} | P1 边界：{N} | P2 测试：{N} | P3 其他：{N}

## 依赖图谱
{文件级依赖关系图（用 Mermaid 或 ASCII 表示）}

## 审查优先级排序
1. [{优先级}] {文件路径} — {原因}
   - 直接依赖：{列表}
   - 被依赖：{列表}
   - 涟漪风险：{高/中/低}
   - 测试状态：{有/缺/需确认}

## 涟漪效应热力图
{被改动影响最多的上游模块}

## 测试覆盖缺口
{缺少测试覆盖的变更文件列表}

## 审查建议
- 建议审查顺序：{按依赖拓扑排序的审查顺序}
- 高风险关注点：{跨模块变更、接口变更等}
```

---

## 高级分析

### 跨模块耦合检测

当多个 P0 文件同时变更且存在交叉依赖时：

```
⚠️ 高耦合变更警告：
{file-a} ↔ {file-b}
两个核心模块同时变更，且相互依赖。
建议：优先审查接口契约是否一致。
```

### 架构边界穿越检测

```
若变更涉及跨层级引用（如 UI 层直接引用 DB 层）：
🚨 架构边界穿越：{caller} → {callee}
{caller} 位于 {layer-a} 层，{callee} 位于 {layer-b} 层，
跨越了架构边界。请确认是否为有意设计。
```

---


## Harness 反馈闭环（铁律 3）

| Step | 验证动作 | 失败处理 |
|------|---------|---------|
| 依赖图谱生成 | `node .claude/helpers/harness-gate-check.cjs --skill kf-code-review-graph --stage graph --required-files "*-dependency-graph.md" --forbidden-patterns TODO 待定` | 重新生成 |
| 审查报告生成 | `node .claude/helpers/harness-gate-check.cjs --skill kf-code-review-graph --stage review --required-sections "## 变更影响范围" "## 审查优先级" --forbidden-patterns TODO 待定` | 补充章节 |

验证原则：**Plan → Build → Verify → Fix** 强制循环，不接受主观"我觉得好了"。

## 输出要求

1. 必须生成 Mermaid 格式的依赖图（如果变更文件 ≤ 20个）
2. 必须列出审查优先级排序（Top 5 至少）
3. 必须列出测试覆盖缺口
4. 必须有明确的审查顺序建议
5. 报告保存到 `.gspowers/artifacts/review-graph-{date}.md`
