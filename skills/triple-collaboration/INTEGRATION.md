# Triple 扩展集成指南

## 概念

Triple Collaboration 是一种**评审扩展模式**，可以叠加在任何技能之上，实现多角度评审。

## 与 Pipeline 的关系

| 模式 | 触发词 | 扩展对象 | 核心机制 |
|------|--------|----------|----------|
| Pipeline | `/pipeline` | `subagent-dev` | 批次编排 |
| Triple | `/triple` | **任意技能** | 三方评审 |

## 使用场景

### 场景1: 独立三方评审
```
用户: /triple
系统: 启动红蓝评审流程...
```

### 场景2: Triple + Pipeline
```
用户: /pipeline-dev + /triple
```

### 场景3: Triple + 任意技能
```
用户: /sparc + /triple
```

## Agent 角色定义

### Red Team (红队)
- **能力**: attack_analysis, risk_finding, vulnerability_assessment
- **任务**: 识别风险、攻击面、弱点

### Blue Team (蓝队)
- **能力**: defense_eval, security_assessment, robustness_testing
- **任务**: 评估防御能力、稳定性、安全性

### Judge (裁判)
- **能力**: synthesis, decision_making, consensus_building
- **任务**: 协调双方、汇总决策
