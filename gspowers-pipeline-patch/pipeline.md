# 多模块流水线开发（Pipeline Development）

> 本模块基于 [gspowers](https://github.com/fshaan/gspowers) 框架扩展，遵循 MIT 许可证。

## 什么是 Pipeline 模式

当项目包含**多个有依赖关系的模块**时，普通的 `subagent-dev` 无法处理模块间的执行顺序和依赖验证。Pipeline 模式通过**依赖解析**和**批次编排**，实现：

1. 自动分析模块依赖拓扑
2. 按批次顺序执行（依赖模块先完成，才能执行依赖它的模块）
3. 批次间门控验证（通过才允许下一批次）
4. 状态追踪和断点恢复

---

## 触发条件

满足以下任一条件即进入 Pipeline 模式：

1. **用户显式触发**：
   ```
   /pipeline-dev
   或
   多模块开发
   或
   流水线开发
   ```

2. **implementation-plan.md 包含 modules 配置**

---

## state.json 扩展字段

Pipeline 模式需要在 state.json 中新增 `pipeline` 节点：

```json
{
  "version": "1.2",
  "pipeline": {
    "enabled": true,
    "modules": {
      "user-service": {
        "name": "user-service",
        "display_name": "用户服务",
        "path": "services/user",
        "depends_on": [],
        "status": "pending",
        "batch": 1,
        "test_results": null,
        "artifacts": []
      }
    },
    "batches": [
      ["user-service"],
      ["product-service"],
      ["order-service"]
    ],
    "current_batch": 1,
    "started_at": "2026-04-27T10:00:00Z",
    "batch_results": []
  }
}
```

---

## 模块定义格式

### 格式1：YAML 格式（推荐）

```yaml
pipeline:
  enabled: true
  modules:
    - name: user-service
      display_name: 用户服务
      path: services/user
      description: 用户注册、登录、认证
      depends_on: []
    - name: product-service
      display_name: 商品服务
      path: services/product
      description: 商品 CRUD、库存管理
      depends_on: [user-service]
    - name: order-service
      display_name: 订单服务
      path: services/order
      description: 订单创建、状态流转
      depends_on: [user-service, product-service]
    - name: payment-service
      display_name: 支付服务
      path: services/payment
      description: 支付、退款
      depends_on: [order-service]
```

---

## 依赖解析算法

### 步骤1：从 implementation-plan.md 提取模块配置

1. 用 Read 工具读取 `.gspowers/artifacts/implementation-plan.md`
2. 尝试 YAML 解析：
   - 查找 `pipeline:` 或 `modules:` 关键字
   - 提取所有模块定义
3. 如果没有显式配置，询问用户

### 步骤2：构建有向无环图（DAG）

### 步骤3：拓扑排序 + 批次划分

```
批次划分规则：
- 批次1：无依赖的模块（入度为0）
- 批次2：依赖已完成的批次1模块的模块
- 批次3：依赖已完成的批次1+2模块的模块
```

### 步骤4：循环依赖检测

```javascript
function hasCycle(graph) {
  const visited = new Set();
  const recStack = new Set();
  function dfs(node) {
    if (recStack.has(node)) return true;
    if (visited.has(node)) return false;
    visited.add(node);
    recStack.add(node);
    for (const neighbor of graph[node]) {
      if (dfs(neighbor)) return true;
    }
    recStack.delete(node);
    return false;
  }
  for (const node of Object.keys(graph)) {
    if (dfs(node)) return true;
  }
  return false;
}
```

---

## 状态追踪

| 状态 | 说明 |
|------|------|
| `pending` | 等待执行 |
| `running` | 执行中 |
| `passed` | 通过 |
| `failed` | 失败 |
| `skipped` | 跳过 |

---

## 门控验证器

每个批次执行完成后，必须进行门控验证：

### 验证规则

1. **批次内并行**：同一批次内的模块可以并行执行
2. **门控检查**：批次完成后，检查该批次所有模块状态
   - 全部 `passed` → 允许进入下一批次
   - 任何 `failed` → 终止流水线，提示用户修复

---

## 执行流程

```
批次1 开始
  ├── [并行] user-service: running
  └── [并行] 等待...

批次1 完成
  ├── user-service: passed
  └── 门控检查: 通过

批次2 开始
  ├── [并行] product-service: running
  └── 门控检查: 通过
...
```

---

## 触发词

| 触发词 | 说明 |
|--------|------|
| `/pipeline-dev` | 显式启动多模块流水线 |
| `多模块开发` | 同上 |
| `流水线开发` | 同上 |

---

## 与原有 subagent-dev 的关系

| 方面 | subagent-dev（单模块） | pipeline-dev（多模块） |
|------|------------------------|------------------------|
| 适用场景 | 单个功能/模块开发 | 多模块有依赖的系统 |
| 执行方式 | 串行 | 批次并行 + 批次串行 |
| 依赖处理 | 无 | DAG 解析 + 门控验证 |
| 状态粒度 | 整体 pass/fail | 模块级状态追踪 |
| 恢复能力 | 无 | 支持断点恢复 |
