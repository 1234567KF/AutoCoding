# UI 设计系统规范

> 适用范围：UI 原型生成
> 加载时机：上下文收集阶段、Step 3 — 生成 HTML 原型文件
> 使用方式：将以下 CSS 变量复制到 `:root` 中，所有样式通过变量引用

---

## 一、色彩系统

### 主色与辅色

| 用途 | CSS 变量 | 值 | 说明 |
|------|----------|------|------|
| 主色 | `--color-primary` | `#1677ff` | 品牌主色，按钮/链接/选中态 |
| 主色悬停 | `--color-primary-hover` | `#4096ff` | 主色交互态 |
| 主色按下 | `--color-primary-active` | `#0958d9` | 主色按下态 |
| 辅色 | `--color-secondary` | `#722ed1` | 辅助强调色 |

### 语义色

| 用途 | CSS 变量 | 值 | 说明 |
|------|----------|------|------|
| 成功 | `--color-success` | `#52c41a` | 成功状态、完成提示 |
| 警告 | `--color-warning` | `#faad14` | 警告状态、注意提示 |
| 错误 | `--color-error` | `#ff4d4f` | 错误状态、删除操作 |
| 信息 | `--color-info` | `#1677ff` | 信息提示（与主色一致） |

### 中性色

| 用途 | CSS 变量 | 值 | 说明 |
|------|----------|------|------|
| 标题文字 | `--color-text-primary` | `rgba(0, 0, 0, 0.88)` | 一级文字（colorTextHeading） |
| 正文文字 | `--color-text-secondary` | `rgba(0, 0, 0, 0.65)` | 二级文字（colorTextSecondary） |
| 辅助文字 | `--color-text-tertiary` | `rgba(0, 0, 0, 0.45)` | 三级文字（colorTextTertiary） |
| 占位符文字 | `--color-text-placeholder` | `rgba(0, 0, 0, 0.25)` | 输入框占位符（colorTextPlaceholder） |
| 禁用文字 | `--color-text-disabled` | `rgba(0, 0, 0, 0.25)` | 禁用态文字（colorTextDisabled） |
| 边框 | `--color-border` | `#d9d9d9` | 默认边框色（colorBorder） |
| 边框-次级 | `--color-border-secondary` | `#f0f0f0` | 次级边框/分割线（colorBorderSecondary） |
| 分割线 | `--color-divider` | `rgba(5, 5, 5, 0.06)` | 分割线/分隔区域（colorSplit） |
| 填充 | `--color-fill` | `rgba(0, 0, 0, 0.15)` | 填充色（colorFill） |
| 填充-次级 | `--color-fill-secondary` | `rgba(0, 0, 0, 0.06)` | 次级填充（colorFillSecondary） |
| 填充-三级 | `--color-fill-tertiary` | `rgba(0, 0, 0, 0.04)` | 三级填充/禁用背景（colorFillTertiary） |
| 背景 | `--color-bg-layout` | `#f5f5f5` | 页面底层背景（colorBgLayout） |
| 容器背景 | `--color-bg-container` | `#ffffff` | 卡片/容器背景（colorBgContainer） |
| 浮层背景 | `--color-bg-elevated` | `#ffffff` | 弹窗/下拉浮层背景（colorBgElevated） |
| 禁用容器背景 | `--color-bg-container-disabled` | `rgba(0, 0, 0, 0.04)` | 禁用态容器背景 |
| 遮罩 | `--color-bg-mask` | `rgba(0, 0, 0, 0.45)` | 弹窗遮罩层（colorBgMask） |

### 链接色

| 用途 | CSS 变量 | 值 | 说明 |
|------|----------|------|------|
| 链接 | `--color-link` | `#1677ff` | 默认链接色 |
| 链接悬停 | `--color-link-hover` | `#69b1ff` | 链接悬停态 |
| 链接按下 | `--color-link-active` | `#0958d9` | 链接按下态 |
| 高亮 | `--color-highlight` | `#ff4d4f` | 高亮/搜索匹配色 |

---

## 二、排版系统

| 用途 | CSS 变量 | 值 | 说明 |
|------|----------|------|------|
| 字体族 | `--font-family` | `-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, 'Noto Sans', sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji'` | Ant Design 标准字体栈 |
| 代码字体 | `--font-family-code` | `'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, Courier, monospace` | 等宽字体 |

### 字号阶梯

| 级别 | CSS 变量 | 值 | 行高 | 用途 |
|------|----------|------|------|------|
| H1 | `--font-size-h1` | `38px` | `46px` | 页面主标题（fontSizeHeading1） |
| H2 | `--font-size-h2` | `30px` | `38px` | 章节标题（fontSizeHeading2） |
| H3 | `--font-size-h3` | `24px` | `32px` | 卡片标题（fontSizeHeading3） |
| H4 | `--font-size-h4` | `20px` | `28px` | 小标题（fontSizeHeading4） |
| H5 | `--font-size-h5` | `16px` | `24px` | 段落标题（fontSizeHeading5） |
| 正文 | `--font-size-base` | `14px` | `22px` | 默认正文（fontSize） |
| 正文-大 | `--font-size-lg` | `16px` | `24px` | 大号正文（fontSizeLG） |
| 辅助 | `--font-size-sm` | `12px` | `20px` | 辅助说明文字（fontSizeSM） |

### 字重

| 用途 | CSS 变量 | 值 |
|------|----------|------|
| 常规 | `--font-weight-normal` | `400` |
| 中等 | `--font-weight-medium` | `500` |
| 加粗 | `--font-weight-bold` | `600` |

---

## 三、间距系统

基准网格：**4px**。所有间距值必须为 4 的整数倍。

| CSS 变量 | 值 | 典型用途 |
|----------|------|----------|
| `--spacing-xxs` | `4px` | 图标与文字间距（paddingXXS） |
| `--spacing-xs` | `8px` | 紧凑元素间距（paddingXS） |
| `--spacing-sm` | `12px` | 表单项内间距（paddingSM） |
| `--spacing-base` | `16px` | 默认元素间距（padding） |
| `--spacing-md` | `20px` | 中等间距（paddingMD） |
| `--spacing-lg` | `24px` | 卡片内边距（paddingLG） |
| `--spacing-xl` | `32px` | 区块间距（paddingXL） |
| `--spacing-xxl` | `48px` | 页面级区域分隔（marginXXL） |

### 圆角

| CSS 变量 | 值 | 用途 |
|----------|------|------|
| `--border-radius-xs` | `2px` | 极小组件（borderRadiusXS） |
| `--border-radius-sm` | `4px` | 小型组件（标签、徽标）（borderRadiusSM） |
| `--border-radius-base` | `6px` | 默认组件（按钮、输入框）（borderRadius） |
| `--border-radius-lg` | `8px` | 大型组件（卡片、弹窗）（borderRadiusLG） |

---

## 四、组件规范

### 按钮

| 属性 | 主按钮 | 默认按钮 | 文字按钮 |
|------|--------|----------|----------|
| 背景色 | `var(--color-primary)` | `var(--color-bg-container)` | 透明 |
| 文字色 | `#fff` | `var(--color-text-primary)` | `var(--color-primary)` |
| 边框 | 无 | `1px solid var(--color-border)` | 无 |
| 高度 | `32px` | `32px` | `32px` |
| 内边距 | `4px 16px` | `4px 16px` | `4px 8px` |
| 圆角 | `var(--border-radius-base)` | `var(--border-radius-base)` | `var(--border-radius-base)` |

### 输入框

| 属性 | 值 |
|------|------|
| 高度 | `32px` |
| 内边距 | `4px 12px` |
| 边框 | `1px solid var(--color-border)` |
| 聚焦边框 | `1px solid var(--color-primary)` |
| 圆角 | `var(--border-radius-base)` |
| 占位符色 | `var(--color-text-placeholder)` |

### 卡片

| 属性 | 值 |
|------|------|
| 背景 | `var(--color-bg-container)` |
| 边框 | `1px solid var(--color-border)` |
| 圆角 | `var(--border-radius-lg)` |
| 内边距 | `var(--spacing-lg)` |
| 阴影 | `0 1px 2px -2px rgba(0,0,0,0.16), 0 3px 6px 0 rgba(0,0,0,0.12), 0 5px 12px 4px rgba(0,0,0,0.09)` |

### 导航栏

| 属性 | 值 |
|------|------|
| 高度 | `48px` |
| 背景 | `var(--color-bg-container)` |
| 底部边框 | `1px solid var(--color-divider)` |
| 内边距 | `0 var(--spacing-lg)` |

### 阴影系统

| CSS 变量 | 值 | 用途 |
|----------|------|------|
| `--box-shadow` | `0 6px 16px 0 rgba(0,0,0,0.08), 0 3px 6px -4px rgba(0,0,0,0.12), 0 9px 28px 8px rgba(0,0,0,0.05)` | 下拉/弹出层阴影（boxShadow） |
| `--box-shadow-card` | `0 1px 2px -2px rgba(0,0,0,0.16), 0 3px 6px 0 rgba(0,0,0,0.12), 0 5px 12px 4px rgba(0,0,0,0.09)` | 卡片阴影（boxShadowCard） |
| `--box-shadow-tertiary` | `0 1px 2px 0 rgba(0,0,0,0.03), 0 1px 6px -1px rgba(0,0,0,0.02), 0 2px 4px 0 rgba(0,0,0,0.02)` | 轻量阴影（boxShadowTertiary） |

---

## 五、响应式断点

与 Ant Design 官方保持一致的 6 级断点体系：

| CSS 变量 | 断点值 | 最大值 | 适用设备 |
|----------|--------|--------|----------|
| `--breakpoint-xs` | `480px` | `575px` | 手机竖屏（screenXS） |
| `--breakpoint-sm` | `576px` | `767px` | 手机横屏（screenSM） |
| `--breakpoint-md` | `768px` | `991px` | 平板竖屏（screenMD） |
| `--breakpoint-lg` | `992px` | `1199px` | 平板横屏/小桌面（screenLG） |
| `--breakpoint-xl` | `1200px` | `1599px` | 桌面（screenXL） |
| `--breakpoint-xxl` | `1600px` | — | 大桌面（screenXXL） |

**媒体查询规则**：Mobile-first，使用 `min-width` 升级：

```css
/* 默认样式 = 手机 */
.container { padding: var(--spacing-base); }

@media (min-width: 480px)  { /* 手机竖屏+ xs */ }
@media (min-width: 576px)  { /* 手机横屏+ sm */ }
@media (min-width: 768px)  { /* 平板+ md */ }
@media (min-width: 992px)  { /* 小桌面+ lg */ }
@media (min-width: 1200px) { /* 桌面+ xl */ }
@media (min-width: 1600px) { /* 大桌面+ xxl */ }
```

---

## 六、暗色模式适配

通过覆写 CSS 变量实现暗色模式，MUST NOT 使用独立的暗色样式表。

```css
@media (prefers-color-scheme: dark) {
  :root {
    --color-text-primary: rgba(255, 255, 255, 0.88);
    --color-text-secondary: rgba(255, 255, 255, 0.65);
    --color-text-tertiary: rgba(255, 255, 255, 0.45);
    --color-text-disabled: rgba(255, 255, 255, 0.25);
    --color-border: #424242;
    --color-divider: #303030;
    --color-bg-layout: #141414;
    --color-bg-container: #1f1f1f;
  }
}
```

**适配规则**：
- 主色和语义色在暗色模式下保持不变，仅调整中性色
- 阴影在暗色模式下使用 `rgba(0, 0, 0, 0.3)` 加强对比
- 所有颜色引用 MUST 使用 CSS 变量，确保暗色模式自动生效

---

## 七、组件库 CSS 集成

### 为什么选择 antd@4（而非 v5）

- antd v5 使用 CSS-in-JS（`@ant-design/cssinjs`），不提供独立 CSS 文件，无法通过 CDN 引入
- antd v4 提供独立的 `antd.min.css`，包含所有组件的完整样式
- antd v4 的 CSS 类名（`ant-btn`、`ant-table` 等）是通用的，与 Ant Design Vue 的类名一致
- 原型仅用于评审和 Spec 文档生成，“贴近就行”不需要完全还原

### CDN 引入方式

```html
<!-- 在 <head> 中，<style> 标签之前引入，确保自定义样式可覆盖 -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/antd@4.24.16/dist/antd.min.css">
```

**优先级关系**：组件库 CSS 作为基层样式，`:root` CSS 变量 + 自定义 `<style>` 作为覆盖层。引入顺序决定优先级：

```
antd.min.css ← 基层（组件库默认样式）
    ↓ 被覆盖
<style>:root { ... } + 自定义类</style> ← 覆盖层（布局、侧边栏、间距等）
```

### 常用 Ant Design CSS 类名映射表

#### 基础组件

| 组件 | 关键类名 | HTML 示例 |
|------|----------|----------|
| 主按钮 | `ant-btn ant-btn-primary` | `<button class="ant-btn ant-btn-primary">提交</button>` |
| 默认按钮 | `ant-btn ant-btn-default` | `<button class="ant-btn ant-btn-default">取消</button>` |
| 文字按钮 | `ant-btn ant-btn-link` | `<a class="ant-btn ant-btn-link">详情</a>` |
| 危险按钮 | `ant-btn ant-btn-primary ant-btn-dangerous` | `<button class="ant-btn ant-btn-primary ant-btn-dangerous">删除</button>` |
| 小按钮 | `ant-btn ant-btn-sm` | `<button class="ant-btn ant-btn-primary ant-btn-sm">编辑</button>` |
| 输入框 | `ant-input` | `<input class="ant-input" placeholder="请输入">` |
| 文本域 | `ant-input` | `<textarea class="ant-input"></textarea>` |
| 下拉框 | `ant-select ant-select-single` | `<div class="ant-select ant-select-single">...</div>` |

#### 数据展示

| 组件 | 关键类名 | HTML 示例 |
|------|----------|----------|
| 表格容器 | `ant-table` | `<div class="ant-table"><div class="ant-table-container"><table>...</table></div></div>` |
| 表头 | `ant-table-thead` | `<thead class="ant-table-thead"><tr><th class="ant-table-cell">列名</th></tr></thead>` |
| 表体 | `ant-table-tbody` | `<tbody class="ant-table-tbody"><tr class="ant-table-row"><td class="ant-table-cell">数据</td></tr></tbody>` |
| 标签-绿 | `ant-tag ant-tag-green` | `<span class="ant-tag ant-tag-green">正常</span>` |
| 标签-红 | `ant-tag ant-tag-red` | `<span class="ant-tag ant-tag-red">异常</span>` |
| 标签-橙 | `ant-tag ant-tag-orange` | `<span class="ant-tag ant-tag-orange">待审核</span>` |
| 标签-蓝 | `ant-tag ant-tag-blue` | `<span class="ant-tag ant-tag-blue">进行中</span>` |
| 徽标数 | `ant-badge` | `<span class="ant-badge"><sup class="ant-badge-count">5</sup></span>` |

#### 布局与导航

| 组件 | 关键类名 | HTML 示例 |
|------|----------|----------|
| 卡片 | `ant-card` | `<div class="ant-card"><div class="ant-card-head"><div class="ant-card-head-title">标题</div></div><div class="ant-card-body">内容</div></div>` |
| 分页 | `ant-pagination` | `<ul class="ant-pagination"><li class="ant-pagination-item ant-pagination-item-active"><a>1</a></li></ul>` |
| 面包屑 | `ant-breadcrumb` | `<div class="ant-breadcrumb"><span class="ant-breadcrumb-link">首页</span><span class="ant-breadcrumb-separator">/</span><span class="ant-breadcrumb-link">列表</span></div>` |
| 暗色菜单 | `ant-menu ant-menu-dark ant-menu-inline` | `<ul class="ant-menu ant-menu-dark ant-menu-root ant-menu-inline"><li class="ant-menu-item ant-menu-item-selected">菜单项</li></ul>` |
| 菜单项 | `ant-menu-item` | `<li class="ant-menu-item">菜单文字</li>` |

#### 反馈与弹层

| 组件 | 关键类名 | HTML 示例 |
|------|----------|----------|
| 弹窗 | `ant-modal` | `<div class="ant-modal"><div class="ant-modal-content"><div class="ant-modal-header"><div class="ant-modal-title">标题</div></div><div class="ant-modal-body">内容</div><div class="ant-modal-footer"><button class="ant-btn ant-btn-default">取消</button><button class="ant-btn ant-btn-primary">确定</button></div></div></div>` |
| 弹窗遮罩 | `ant-modal-mask` | `<div class="ant-modal-mask"></div>` |
| 消息提示 | `ant-message` | `<div class="ant-message"><span class="ant-message-success">操作成功</span></div>` |

#### 表单布局

| 组件 | 关键类名 | HTML 示例 |
|------|----------|----------|
| 表单 | `ant-form ant-form-horizontal` | `<form class="ant-form ant-form-horizontal">...</form>` |
| 表单项 | `ant-form-item` | `<div class="ant-form-item"><div class="ant-form-item-label"><label>字段名</label></div><div class="ant-form-item-control"><input class="ant-input"></div></div>` |
| 必填标记 | `ant-form-item-required` | `<label class="ant-form-item-required">字段名</label>` |
| 校验错误 | `ant-form-item-has-error` | `<div class="ant-form-item ant-form-item-has-error">...</div>` |
| 错误提示 | `ant-form-item-explain-error` | `<div class="ant-form-item-explain-error">请输入必填字段</div>` |
