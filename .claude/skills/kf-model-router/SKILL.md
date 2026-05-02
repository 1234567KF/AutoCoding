---
name: kf-model-router
description: 模型智能路由 — "省"原则。自动切换模型：计划阶段用 pro（深度思考），执行阶段用 flash（高效落地）。技能启动时自动触发，用户无感。触发词："模型路由"、"切换模型"、"省模式"。
metadata:
  principle: 省
  source: AICoding原则.docx
integrated-skills:
  - kf-spec            # Step 0 自动切换到 pro
  - kf-multi-team-compete  # 裁判用 pro，各队 agent 用 flash
  - kf-alignment        # 深度对齐自动切换到 pro
  - kf-prd-generator    # 产出 PRD 后切换回 flash
---

# kf-model-router — 省原则：模型智能路由

> **核心原则**：最好的模型和最性价比的模型搭配，结合工具方法稳固 ROI。
> **管理原则**：想的美，做的实。计划用 pro（深度推理），执行用 flash（高效落地）。
> **切换方式**：自动切换，用户无感。

---

## 模型路由规则（自动应用）

| 阶段 | 自动切换模型 | 原因 |
|------|------------|------|
| **计划/设计** | pro（deepseek-v4-pro） | 需要深度推理、架构决策、权衡取舍 |
| **执行/编码** | flash（deepseek-v4-flash） | 效率优先，常规编码任务不需要极致推理 |
| **代码审查** | flash（deepseek-v4-flash） | 模式匹配为主，性价比高 |
| **文档生成** | flash（deepseek-v4-flash） | 结构化输出，低成本 |
| **Bug 排查** | pro（deepseek-v4-pro） | 需要深度上下文理解和推理链 |
| **简单问答** | 轻量模型（Haiku 级） | 极低成本，快速响应 |

---

## 自动触发机制

### 方式 1：技能 Frontmatter 声明（推荐）

其他技能在 SKILL.md frontmatter 中通过 `integrated-skills` 声明依赖 kf-model-router 后，
该技能启动时自动检查当前模型是否匹配推荐模型，不匹配则自动执行 `/set-model`：

```yaml
# 示例：kf-spec 的 SKILL.md
integrated-skills:
  - kf-model-router   # Step 0 自动切换到 pro
```

技能在不同阶段需要不同模型时，通过阶段标注实现：

```yaml
# 示例：kf-multi-team-compete 的 SKILL.md
integrated-skills:
  - kf-model-router   # 裁判/汇总自动用 pro，各队 agent 用 flash
```

### 方式 2：Hook 自动检测

通过 `settings.json` 的 `PreToolUse` Hook 监听技能调用事件，
当匹配到声明了 `recommended_model` 的技能时，自动注入模型切换：

```json
{
  "matcher": "Skill",
  "hooks": [{
    "type": "command",
    "command": "node .claude/helpers/model-router-hook.cjs auto-route"
  }]
}
```

Hook 脚本逻辑：
1. 读取被调用技能的 SKILL.md frontmatter
2. 提取 `recommended_model` 字段
3. 对比当前模型，不匹配则自动执行 `/set-model`
4. 任务完成后自动切回默认模型（flash）

### 方式 3：手动触发（调试/覆盖）

```
/set-model pro     # 手动切换到 pro（深度推理）
/set-model flash   # 手动切换到 flash（高效执行）
模型路由           # AI 分析当前任务并推荐模型
省模式             # 自动进入执行模式（flash）
```

---

## 各技能模型需求一览

| 技能 | 推荐模型 | 触发时机 |
|------|---------|---------|
| `kf-spec` | pro（Step 0-1），flash（Step 2-6） | Step 0 自动切 pro |
| `kf-multi-team-compete` | pro（裁判+汇总），flash（各队 agent） | 启动时自动分配 |
| `kf-alignment` | pro | 启动时自动切 pro |
| `kf-prd-generator` | flash | 启动时自动切 flash |
| `kf-code-review-graph` | flash | 启动时自动切 flash |
| `kf-web-search` | flash | 启动时自动切 flash |
| `kf-browser-ops` | flash | 启动时自动切 flash |
| `kf-triple-collaboration` | pro（协调）+ flash（各方） | 启动时自动分配 |
| `kf-skill-design-expert` | pro | 启动时自动切 pro |
| `kf-go` | flash | 启动时自动切 flash |
| `kf-ui-prototype-generator` | flash | 启动时自动切 flash |

---

## ROI 参考

| 模型 | 相对成本 | 适用场景 |
|------|---------|---------|
| deepseek-v4-pro | 100% | 架构设计、复杂 Bug、需求澄清 |
| deepseek-v4-flash | ~33% | 日常编码、代码审查、文档 |
| 轻量模型（Haiku 级） | ~10% | 简单问答、格式转换、信息提取 |

**建议配比**：pro 20% + flash 70% + 轻量 10%，综合成本 ~50%。
自动切换由 kf-model-router Hook 实现，默认开启。

---

## 集成

本 Skill 被以下 Skill **自动调用**：
- `kf-spec`：Step 0 技术选型 → 自动切 pro
- `kf-multi-team-compete`：裁判/汇总用 pro，agent 用 flash
- `kf-alignment`：深度对齐 → 自动切 pro
- `kf-prd-generator`：产出 PRD 后自动切回 flash
- 其他所有声明 `recommended_model` 的技能
