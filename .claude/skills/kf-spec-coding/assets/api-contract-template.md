# 接口契约：SPEC_TITLE

> 关联 Spec：[spec.md](./spec.md) vVERSION

---

## 名称 / 概念变更对照表

<!-- 仅在涉及业务术语重命名时填写，否则删除本标题 -->

| 原术语（旧系统） | 新术语（本系统） | 影响范围 | 变更类型 |
|----------------|----------------|--------|--------|
| OLD_TERM | NEW_TERM | API路径 / 字段名 / 页面文案 | 路径重命名 / 字段重命名 / 仅文案变更 |

---

## API 总览

<!-- 状态枚举：新增 / 路径重命名（原 xxx 重命名）/ 已有接口新增入口 / 复用（字段变更） -->

| 编号 | 方法 | 路径 | 描述 | 状态 | 备注 |
|------|------|------|------|------|------|
| API-001 | METHOD | `/api/v1/RESOURCE` | API_DESCRIPTION | 新增 | — |

---

## API-001：API_TITLE

| 字段 | 值 |
|------|-----|
| 路径 | `METHOD /api/v1/RESOURCE` |
| 描述 | API_DESCRIPTION |
| 认证 | Bearer Token / 无 |

### 请求体

```json
{
  "field_name": "FIELD_TYPE — 字段说明"
}
```

### 响应体

```json
{
  "code": 0,
  "data": {
    "field_name": "FIELD_TYPE — 字段说明"
  }
}
```

### 字段映射（API ↔ 数据库 ↔ 业务规则）

| API 字段 | 类型 | 数据库表.字段 | PRD 规则编号 | 前端组件 | 备注 |
|---------|------|-------------|------------|---------|------|
| FIELD_NAME | FIELD_TYPE | TABLE_NAME.COLUMN_NAME | R00X | INPUT_COMPONENT | _映射说明_ |

### 错误码

| HTTP 状态码 | 业务错误码 | 说明 | 触发条件 |
|------------|-----------|------|---------|
| 400 | INVALID_PARAM | 参数校验失败 | _具体条件_ |

---

## OpenAPI 3.0 扩展字段说明

本文件中的 Schema 使用以下 `x-ai-*` 自定义扩展字段，用于 AI 编码时自动映射前端组件和数据库字段：

| 扩展字段 | 用途 | 示例值 |
|---------|------|--------|
| `x-ai-frontend-component` | 前端渲染组件类型 | `Input`, `Select`, `DatePicker` |
| `x-ai-db-column` | 映射的数据库表.字段 | `t_order.order_no` |
| `x-ai-validation` | 校验规则表达式 | `^1[3-9]\\d{9}$` |
