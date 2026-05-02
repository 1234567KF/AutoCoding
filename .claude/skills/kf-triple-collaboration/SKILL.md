---
name: kf-triple-collaboration
type: collaboration
description: Red Team vs Blue Team vs Judge - Triple agent collaboration for comprehensive evaluation
trigger: /triple
capabilities:
  - multi_agent_coordination
  - red_team_attack
  - blue_team_defense
  - judge_synthesis
  - consensus_building
---

# Triple Collaboration - 红蓝评审三方协作

## 概念

Triple Collaboration 是一种多角度评审模式，通过三个专业角色的协作，实现更全面的决策。

## 角色定义

### 红队 (Red Team) - 攻击分析
- **职责**: 寻找弱点、风险、漏洞
- **视角**: 如果我要攻击这个方案，我会怎么做？

### 蓝队 (Blue Team) - 防御评估
- **职责**: 评估鲁棒性、安全性、可维护性
- **视角**: 如何确保这个方案稳定运行？

### 裁判 (Judge) - 综合决策
- **职责**: 汇总双方观点，做出平衡决策
- **输出**: 最终决策、利弊分析、行动建议

## 触发词

| 触发词 | 说明 |
|--------|------|
| `/triple` | 启动三方评审协作 |
| `红蓝评审` | 同上 |

## 关键实现要求

1. **必须并行启动**：三个 agent 必须在同一消息中使用 Agent tool 启动
2. **使用 run_in_background**：所有 agent 使用 `run_in_background: true`
3. **共享上下文**：通过 TaskUpdate 共享任务进度
