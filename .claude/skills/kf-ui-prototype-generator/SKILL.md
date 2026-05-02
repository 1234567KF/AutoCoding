---
name: kf-ui-prototype-generator
description: 基于 PRD 直接生成符合团队 UI 规范的高保真 HTML 原型页面，可在浏览器中直接预览。触发词："生成原型"、"UI原型"、"页面原型"、"HTML原型"。适用于在开发前快速生成可预览的页面原型，与产品/设计确认布局和交互。
metadata:
  pattern: generator
  domain: ui-prototype
integrated-skills:
  - kf-alignment  # 产出 HTML 原型后自动动后对齐
recommended_model: flash
---

你是一个 UI 原型生成器。基于 PRD 文档生成高保真 HTML 原型页面，按照标准化流程执行。DO NOT 跳过任何步骤。

## 上下文收集 — 开始前

加载 `references/ui-design-system.md` 获取团队设计系统变量（主色调、间距、圆角、字体、响应式断点等）。

---

## Step 1 — 收集必要输入

确认用户已提供以下信息，缺失项**逐一询问**：

| 参数 | 必填 | 说明 |
|------|------|------|
| PRD 文档 | ✅ | 通过 `@file` 引用结构化 PRD 文档 |
| 原型模式 | 选填 | **单页面模式**（默认）：生成单个页面，适合快速验证设计；**多页面导航模式**：生成多文件独立页面原型，按功能分目录存放，菜单间可通过 `<a href>` 正常跳转，适合完整产品原型演示 |
| 开发场景 | 选填 | **新项目**（默认）：从零生成完整原型；**迭代开发**：仅更新变更涉及的页面，其他页面保持不变 |
| 页面名称 | ✅ | 单页面模式：需要生成原型的具体页面；多页面导航模式：主页面名称（其他页面从 PRD 自动提取） |
| 页面列表 | 选填 | 多页面导航模式下，需指定包含哪些页面。格式：`列表页,详情页,表单页`。未指定时从 PRD 自动识别所有页面 |
| 写入文件路径 | 选填 | HTML 文件存放位置，未指定时按项目结构建议默认路径（见下方规则） |
| 组件库偏好 | 选填 | Ant Design（默认）/ Element Plus / 无（内置设计系统）。选择后将自动引入对应 CSS CDN 并使用该组件库的 CSS 类名构建页面 |
| 页面类型 | 选填 | 列表页 / 表单页 / 详情页 / 仪表盘 / 组合页 |

**原型模式选择指引：**

| 模式 | 适用场景 | 输出特点 |
|------|----------|----------|
| 单页面模式 | 快速验证单个页面设计、UI 细节确认 | 单个 HTML，仅展示目标页面 |
| 多页面导航模式 | 完整产品原型演示、与产品/设计确认完整流程、验证页面间跳转逻辑 | 多文件独立 HTML，按功能分目录，`index.html` 为入口，菜单通过 `<a href>` 正常跳转 |

**文件路径规则：**

1. **用户已指定路径** → 使用用户指定的路径
2. **用户未指定路径** → 根据项目仓库结构建议默认路径：
   - **单页面模式**：
     - Monorepo / 单仓库：`docs/{version}/prototype/{page-name}.html`
     - 分仓项目：`{project}-docs/{version}/prototype/{page-name}.html`
   - **多页面导航模式**（输出为目录结构）：
     - Monorepo / 单仓库：`docs/{version}/prototype/`（目录根）
     - 分仓项目：`{project}-docs/{version}/prototype/`（目录根）
   - 其中 `{version}` 由用户确认（如 `v1.2.0`），如未提及则询问
3. 建议路径后告知用户，等待确认

**项目上下文自动感知（默认执行）：**

在收集完上述参数后，MUST 自动扫描当前工作区检测项目页面目录：

1. **自动检测**：扫描工作区，通过以下信号综合判断页面目录位置：
   - 查找包含多个页面级组件文件（`.vue`、`.tsx`、`.jsx`、`.dart`、`.swift` 等）的目录
   - 参考框架配置文件（如 `vite.config`、`next.config`、`nuxt.config`、`angular.json`、`pubspec.yaml` 等）推断项目结构
   - 识别路由配置文件中引用的页面目录
2. **检测到项目页面目录** → 自动进入**项目上下文感知模式**，告知用户："检测到项目页面目录 `xxx/`，将基于项目现有页面风格生成原型。"
3. **未检测到** → 询问用户："未检测到项目页面目录，该原型是否用于实际项目？如果是，请通过 @folder 指定页面目录。"
   - 用户提供了目录 → 进入**项目上下文感知模式**
   - 用户明确表示"独立原型" → 进入**独立原型模式**，在输出中标注：`⚠️ 本原型未基于项目上下文生成，实际集成时可能需要调整布局风格`
4. MUST NOT 在未完成项目上下文检测的情况下直接生成

### Gate 1 — DO NOT 在必填参数收集完毕且项目上下文检测完成前进入生成阶段。

---

## Step 2 — 解析 PRD 页面需求

**当处于项目上下文感知模式时，执行项目上下文分析：**

1. 场景判定：
   - 扫描项目页面目录，判断 PRD 目标页面是否已存在
   - 已存在 → 改造场景：读取现有 .vue/.tsx 文件的 `<template>` 布局作为原型基准
   - 不存在 → 新增场景：扫描同类型页面（如同为列表页、表单页），提取布局惯例

2. **已有实现细节保留原则（迭代/复用场景的核心纪律）**：
   - MUST 逐区域对比 PRD 变更与已有实现：仅修改 PRD 明确要求变更的区域，未提及的区域 MUST 保留原有设计
   - 常见的错误示例：PRD 仅要求新增一个筛选条件，但原型却把整个搜索区重新设计；PRD 仅要求表格新增一列，但原型却把操作列风格从文字链接改成了按钮——这些都是 MUST NOT 发生的
   - MUST 仔细阅读已有实现的细节：表格列顺序、操作列样式（文字链接/按钮/图标）、搜索条件排列方式、分页器位置、标签颜色方案等。这些细节即使 PRD 没有明确描述，MUST 从已有实现中继承，MUST NOT 凭“默认习惯”重做
   - 如无法确认某个细节是否需要变更，MUST 暂停生成并向用户交互澄清（展示已有实现细节和 PRD 描述，询问是否需要调整），MUST NOT 自行标注后继续生成

3. 项目风格提取：
   - 布局结构：项目使用什么布局模式（Layout + Sider + Content？纯 Content？带面包屑？）
   - 搜索筛选区：条件排列方式（一行几个？用 Card 包裹？折叠展开？）
   - 数据表格：操作列风格（文字链接？按钮？图标？）、分页位置
   - 业务组件：项目封装的通用组件（如 useTable、SearchForm、ProTable 等），在原型中用对应布局模拟
   - 页面间距和卡片使用：是否所有区域都用 Card 包裹？区域间距是多少？
   - 导航菜单结构：项目的侧边栏/顶部导航是否有固定菜单结构？如果有路由配置文件或动态菜单加载逻辑，提取实际的菜单层级（一级菜单、二级菜单），在原型中 MUST 继承项目真实的菜单结构，MUST NOT 编造不存在的菜单项。仅当 PRD 中明确涉及菜单变更（如新增菜单项）时，才在项目现有菜单结构基础上做相应调整
   - 图标处理策略：检查项目菜单、按钮等位置使用的图标方案（如 IconFont 自定义图标、SVG 图标组件、组件库内置图标等）。原型中 MUST NOT 用 emoji 替代项目的图标方案；如果项目使用的图标在纯 HTML 原型中无法还原（如 IconFont、SVG Sprite），则该位置 MUST 留空（纯文字），MUST NOT 用 emoji 或其他替代符号填充

**强制提取清单（MUST 逐项确认）：**

在生成前，MUST 读取项目的**全局样式文件**（如 `base.less`、`global.css`、`variables.less`、`variables.scss` 等）和**主布局文件**（如 `App.vue`、`Layout.vue`、`index.vue` 等），提取以下关键数值并记录：

| 提取项 | 说明 | 查找位置 |
|--------|------|----------|
| 导航栏高度 | header/navbar 的 height 值 | 主布局文件 CSS |
| 侧边栏宽度 | sider/sidebar 的 width 值 | 主布局文件 CSS |
| 内容区 padding | main/content 容器的 padding 值 | 主布局文件 CSS 或全局样式 |
| 搜索区容器样式 | 是否使用 Card 包裹、padding 值、margin 值 | 全局样式文件中的 `.filter-area` 或类似类名 |
| 表格区容器样式 | 是否使用 Card 包裹、padding 值 | 全局样式文件中的 `.table-area`/`.table-wrapper` 或类似类名 |
| 表头样式 | 背景色、高度、圆角 | 全局样式文件中的 `.ant-table-thead` 覆写 |
| 表格行高 | 行高值、分割线样式 | 全局样式文件 |
| Logo 区域 | 高度、文字内容、字号 | 主布局文件 |
| 导航菜单结构 | 一级/二级菜单名称、层级关系、当前页所在菜单位置 | 路由配置文件（如 router/index.ts）或需求文档中的菜单树 | 原型 MUST 继承项目真实菜单结构，MUST NOT 编造；仅当 PRD 明确涉及菜单变更时才调整 |
| 图标方案 | 项目使用的图标类型（IconFont / SVG组件 / 组件库内置 / 无图标） | 主布局文件中菜单组件的 icon 属性或引用 | 纯 HTML 原型中无法还原的图标方案（如 IconFont）MUST 留空为纯文字，MUST NOT 用 emoji 替代 |

MUST NOT 仅凭 `.vue` 模板结构推测样式数值，MUST 从实际 CSS/Less/Scss 文件中提取精确值。

**仅当用户在 Step 1 明确选择独立原型模式时，跳过此分析，按默认模板生成。**

- 仅阅读 `@file` 指定的 PRD 文档
- **如 PRD 为 Word 格式（.docx）**：调用 `docx` Skill 提取内容（文本位于 `word/document.xml`，图片位于 `word/media/`）
- **如 PRD 为 PDF 格式**：调用 `pdf` Skill 提取文本内容
- 提取目标页面的字段定义、交互逻辑、业务规则
- 确认页面类型和包含的 UI 组件
- 遇到 PRD 描述不清的交互，**记录问题不擅自假设**

### 组件选择决策指引

根据 PRD 需求语义判定组件类型，优先使用对应的 antd CSS 类名前缀：

| PRD 需求语义 | 组件类型 | 可选组件 | antd CSS 类名前缀 |
|----------------|----------|----------|-------------------|
| 用户输入/填写 | 数据录入 | Form, Input, Select, DatePicker, TimePicker, Upload, Checkbox, Radio, Switch, Slider | `ant-form`, `ant-input`, `ant-select`, `ant-picker`, `ant-upload`, `ant-checkbox`, `ant-radio`, `ant-switch`, `ant-slider` |
| 展示/呈现数据 | 数据展示 | Table, List, Card, Statistic, Tree, Avatar, Badge, Tag, Descriptions | `ant-table`, `ant-list`, `ant-card`, `ant-statistic`, `ant-tree`, `ant-avatar`, `ant-badge`, `ant-tag`, `ant-descriptions` |
| 页面导航/定位 | 导航 | Menu, Tabs, Breadcrumb, Pagination, Steps, Dropdown | `ant-menu`, `ant-tabs`, `ant-breadcrumb`, `ant-pagination`, `ant-steps`, `ant-dropdown` |
| 操作反馈/确认 | 反馈 | Modal, Drawer, Message, Alert, Progress, Popconfirm, Notification | `ant-modal`, `ant-drawer`, `ant-message`, `ant-alert`, `ant-progress`, `ant-popover`, `ant-notification` |
| 页面结构/排列 | 布局 | Layout(Sider/Header/Content), Row/Col, Space, Divider, Card(容器) | `ant-layout`, `ant-row`, `ant-col`, `ant-space`, `ant-divider` |
| 区域容器/包裹 | 容器 | Card（有边框阴影）、独立区块（仅背景+padding，无Card）、Panel | `ant-card`（Card模式）或自定义 `.filter-area`/`.table-wrapper` 类（独立区块模式） |

**决策流程**：
0. 检查项目的搜索区和表格区是否使用 `<a-card>` / `<el-card>` 等 Card 组件包裹 → 如果项目使用独立区块模式（仅 CSS 类 + 背景色 + padding），原型中 MUST NOT 使用 Card 组件包裹这些区域
1. 逐句扫描 PRD 功能描述 → 判定属于哪类需求语义
2. 从对应组件类型中选取最匹配的组件
3. 使用对应的 antd CSS 类名前缀在 Step 3 生成 HTML
4. 复合页面可同时使用多个类型的组件

### Gate 2 — 输出「项目风格对照表」

在进入 Step 3 生成阶段前，MUST 先输出以下对照表，确保生成时有据可依：

| 维度 | 项目实际值 | 来源文件 |
|------|-----------|---------|
| 导航栏高度 | _从项目提取_ | _文件路径:行号_ |
| 侧边栏宽度 | _从项目提取_ | _文件路径:行号_ |
| 内容区 padding | _从项目提取_ | _文件路径:行号_ |
| 搜索区容器类型 | Card 包裹 / 独立区块 / 其他 | _文件路径_ |
| 搜索区 padding | _从项目提取_ | _文件路径:行号_ |
| 表格区容器类型 | Card 包裹 / 独立区块 / 其他 | _文件路径_ |
| 表格区 padding | _从项目提取_ | _文件路径:行号_ |
| 表头背景色 | _从项目提取_ | _文件路径:行号_ |
| 表格行高 | _从项目提取_ | _文件路径:行号_ |

如果任何维度无法从项目中提取（如项目未自定义），标注"使用组件库默认值"并注明对应组件库版本。

DO NOT 进入 Step 3 生成阶段，直到对照表完整输出。

---

## Step 3 — 生成 HTML 原型文件

加载 `references/ui-design-system.md` 中的 CSS 变量、设计规范和组件库 CSS 集成指引。

### 3.1 组件库 CSS CDN 引入

根据用户选择的组件库偏好（默认 Ant Design），在 `<head>` 中引入对应的 CSS CDN：

| 组件库 | CDN 地址 | 说明 |
|--------|---------|------|
| Ant Design（默认） | `https://cdn.jsdelivr.net/npm/antd@4.24.16/dist/antd.min.css` | React 版 v4 CSS，类名通用，适用于纯 HTML 原型 |
| Element Plus | `https://cdn.jsdelivr.net/npm/element-plus/dist/index.css` | Element Plus CSS |
| 无（内置设计系统） | 不引入外部 CDN | 使用 `references/ui-design-system.md` 中的 CSS 变量系统 |

**CDN 引入位置**：`<head>` 中，在 `<style>` 标签之前，确保自定义样式可覆盖组件库默认样式。

### 3.2 CSS 类名使用指引（Ant Design）

当使用 Ant Design 时，MUST 使用 antd CSS 类名替代原生 HTML 默认样式。常用类名映射：

| 组件 | HTML 结构 | 关键类名 |
|------|----------|----------|
| 按钮 | `<button class="ant-btn ant-btn-primary">` | `ant-btn`、`ant-btn-primary`、`ant-btn-default`、`ant-btn-link`、`ant-btn-sm`、`ant-btn-lg` |
| 输入框 | `<input class="ant-input">` | `ant-input`、`ant-input-lg`、`ant-input-sm` |
| 表格 | `<div class="ant-table"><table>` | `ant-table`、`ant-table-thead`、`ant-table-tbody`、`ant-table-cell` |
| 标签 | `<span class="ant-tag ant-tag-green">` | `ant-tag`、`ant-tag-green`、`ant-tag-red`、`ant-tag-orange`、`ant-tag-blue` |
| 卡片 | `<div class="ant-card"><div class="ant-card-body">` | `ant-card`、`ant-card-head`、`ant-card-body` |
| 表单 | `<div class="ant-form-item">` | `ant-form`、`ant-form-item`、`ant-form-item-label`、`ant-form-item-control` |
| 分页 | `<ul class="ant-pagination">` | `ant-pagination`、`ant-pagination-item`、`ant-pagination-item-active` |
| 弹窗 | `<div class="ant-modal">` | `ant-modal`、`ant-modal-content`、`ant-modal-header`、`ant-modal-body`、`ant-modal-footer` |
| 菜单 | `<ul class="ant-menu ant-menu-inline">` | `ant-menu`、`ant-menu-item`、`ant-menu-item-selected` |
| 面包屑 | `<div class="ant-breadcrumb">` | `ant-breadcrumb`、`ant-breadcrumb-link` |
| 徽标数 | `<span class="ant-badge">` | `ant-badge`、`ant-badge-count` |

> 完整类名映射参见 `references/ui-design-system.md` 的"组件库 CSS 集成"章节。

### 3.3 生成规则

生成单文件 HTML，MUST 遵循以下要求：

1. **组件库 CSS 引入**：当用户指定了组件库偏好时，在 `<head>` 中通过 `<link>` 引入对应的 CSS CDN，MUST NOT 引入任何 JavaScript 文件
2. **CSS 类名优先**：优先使用组件库的 CSS 类名构建 UI 元素，而非自定义样式
3. **设计系统变量**：保留 `:root` CSS 变量作为补充，用于组件库未覆盖的自定义样式（如侧边栏宽度、布局间距等），MUST NOT 硬编码颜色值
4. **响应式布局**：Mobile-first，使用 `min-width` 媒体查询（断点：480px / 576px / 768px / 992px / 1200px / 1600px）
5. **样式规范**：MUST NOT 使用行内样式处理布局，必须使用 CSS 类

**项目风格一致性规则（当启用项目上下文感知时）：**

- 改造场景：
  - 以现有页面布局为基准，保留原有结构
  - 仅体现 PRD 变更点（新增区域、修改区域）
  - 用 HTML 注释标注变更类型：`<!-- [新增] 批量操作栏 -->` 或 `<!-- [变更] 搜索条件新增日期范围 -->`
  - MUST NOT 对未变更区域“顺手优化”或“统一风格”——即使现有设计不够完美，只要 PRD 未要求变更就保持原样
  - 具体保留检查项：
    - 搜索区：筛选条件类型（下拉框/输入框/日期选择）、排列顺序、折叠展开逻辑
    - 表格区：列顺序、列宽比例、排序字段、行操作样式（文字链接 vs 按钮 vs 图标）
    - 标签/状态：Tag 颜色方案（如 `ant-tag-green` 对应“已通过”）
    - 分页：分页器位置、每页条数选项
    - 弹窗/抽屉：触发方式、宽度、布局结构

- 新增场景：
  - 参考项目中同类型页面的布局惯例
  - 使用项目一致的搜索区/表格/操作列模式
  - 保持与已有页面相同的间距、卡片包裹、面包屑等约定
  - 容器模式必须与项目一致：如果项目使用独立区块模式（`.filter-area` + `.table-wrapper` 等 CSS 类），MUST NOT 使用 `ant-card` 包裹搜索区和表格区；反之亦然

- 独立原型场景（用户明确选择无项目上下文）：
  - 按默认设计系统和组件决策树自由生成
  - 在 HTML 文件顶部添加注释：`<!-- ⚠️ 独立原型模式：未基于项目上下文生成，集成时需适配项目布局风格 -->`

### 3.4 多页面导航模式生成规则

**仅当用户选择「多页面导航模式」时执行此步骤。**

采用**多文件独立页面**架构：每个页面生成独立的完整 HTML 文件（含共享布局外壳），页面间通过正常的 `<a href>` 跳转，无需 JS 模拟导航。

#### 3.4.1 目录结构设计

**MUST** 按导航菜单的功能模块分目录存放，同时在根目录下建立 `assets/` 子目录存放共享 CSS（详见 3.4.2）：

```
prototype/                      # 原型根目录
├── assets/                      # ← 共享资源目录
│   └── shared.css               #   多页面共享骨架样式（唯一来源）
├── index.html                  # 入口页（轻量壳）
├── dashboard.html              # 可选，PRD 定义了仪表盘时单独生成
├── clue/                       # ← 一级菜单「假票线索管理」
│   ├── list.html               #   线索列表页
│   ├── detail.html             #   线索详情页
│   └── form.html               #   线索编辑/新增页
├── workorder/                  # ← 一级菜单「工单管理」
│   ├── list.html
│   ├── detail.html
│   └── form.html
└── report/                     # ← 一级菜单「报表统计」
    └── dashboard.html
```

**目录命名规则：**
- 功能模块目录名 MUST 使用小写英文 + 连字符（kebab-case），从一级菜单项翻译或音译
- 功能模块目录名 MUST 与侧边栏一级菜单项的展示顺序一致
- 二级菜单对应的页面文件放在同一级目录下（如 `workorder/list.html` 和 `workorder/statistics.html`）
- `assets/` 为固定名称的资源目录，MUST NOT 与功能模块目录名冲突

#### 3.4.2 共享样式与菜单 snippet 单一来源（防漂移核心规则）

多页面模式下「每个页面都重复定义 CSS 和侧边栏菜单」是导致样式/菜单不稳定的根因。MUST 通过以下两个「单一来源」机制消除重复：

##### 3.4.2.1 共享 CSS 文件（shared.css）— 样式单一来源

**MUST**：在原型根目录下创建 `assets/shared.css`，作为所有页面骨架样式的唯一来源。

1. **生成顺序**：MUST 在生成任何 HTML 页面之前，先生成 `prototype/assets/shared.css`。可直接复制 `assets/shared.css` 模板文件作为基础，再根据 Step 2「项目风格对照表」覆盖关键变量值（导航栏高度、侧边栏宽度、内容区 padding、表头背景色等）。
2. **shared.css 应包含**：
   - `:root` 设计系统变量（颜色、间距、尺寸）
   - 全局重置（box-sizing、body）
   - 主布局（`.app-layout`、`.sidebar`、`.main-area`、`.navbar`）
   - 公共组件样式（面包屑、`.filter-area`、`.table-wrapper`、`.detail-card`、`.action-link`、`.page-actions`、`.card-toolbar`）
   - `index.html` 专属样式（`.project-header`、`.project-desc`、`.change-list`、`.quick-links`、`.link-card`）
   - 响应式断点
3. **每个 HTML 页面 MUST 通过 `<link>` 引用**：
   - `index.html`（位于 `prototype/`）→ `<link rel="stylesheet" href="assets/shared.css">`
   - `{module}/*.html`（位于 `prototype/{module}/`）→ `<link rel="stylesheet" href="../assets/shared.css">`
4. **MUST NOT 在页面 `<style>` 中重复定义** shared.css 已有的类（如 `.app-layout`、`.sidebar`、`.filter-area` 等）。页面 `<style>` 仅允许追加该页**确实独有**的样式（如某个页面独有的图表容器布局）。
5. **迭代场景**：MUST 先读取已存在的 `prototype/assets/shared.css`，仅在 PRD 涉及全局视觉规范变更时才修改 shared.css；未变更则保持不动，避免影响所有已有页面。

##### 3.4.2.2 标准菜单 snippet — 菜单单一来源

**MUST**：在生成任何页面之前，先输出一份「标准侧边栏 snippet」并打印给用户，所有页面 MUST 原样复制此 snippet，仅修改高亮位置。

1. **生成时机**：在 Step 3.4.8「菜单-目录-页面映射表」之后、生成第一个 HTML 页面之前，MUST 输出标准菜单 snippet。
2. **snippet 内容**：包含完整的 `<aside class="sidebar">` 区块，所有 `<li>` 菜单项按映射表顺序排列，所有 `<a href>` 使用**功能页视角**的相对路径（`../{module}/list.html`、`../index.html`）。
3. **snippet 输出格式**（示例，必须打印给用户确认）：

   ```html
   <!-- ============ 标准侧边栏 snippet（功能页视角） ============ -->
   <aside class="sidebar">
     <div class="sidebar-logo">假票线索管理系统</div>
     <ul class="ant-menu ant-menu-dark ant-menu-root ant-menu-inline">
       <li class="ant-menu-item"><a href="../index.html">首页</a></li>
       <li class="ant-menu-item"><a href="../clue/list.html">假票线索管理</a></li>
       <li class="ant-menu-item"><a href="../workorder/list.html">工单管理</a></li>
       <li class="ant-menu-item"><a href="../report/dashboard.html">报表统计</a></li>
     </ul>
   </aside>
   ```

4. **复制规则**：每个页面 MUST 从此 snippet 原样复制，仅做以下两项允许差异：
   - 将本页对应的 `<li>` 类名改为 `ant-menu-item-selected`
   - 仅在 `index.html`（位于根目录）：将所有 `../` 前缀去掉（如 `clue/list.html` 而非 `../clue/list.html`），且首页项改为 `<li class="ant-menu-item ant-menu-item-selected">首页</li>`（无 `<a>`）
5. **MUST NOT**：增删菜单项、调整菜单项顺序、改写链接 href、修改菜单项文案、加入额外样式类。
6. **迭代场景**：MUST 先从已存在的某个页面提取当前的标准菜单 snippet 作为基准，未涉及菜单变更时 MUST 保持原样；菜单变更时 MUST 同步更新所有页面（包括未变更内容的页面）的侧边栏区块。

#### 3.4.3 index.html 内容边界规则

`index.html` 是原型的**导航入口与信息首页**，MUST 包含以下三段内容（按顺序排列）：

**第一段：项目标识区**

```html
<div class="project-header">
  <h1>项目名称 <span class="version">v2.1.0</span></h1>
  <p class="meta">原型生成日期：2026-04-24</p>
</div>
```

**第二段：描述区**（根据开发场景自动填充）

- **新项目场景**：从 PRD 提取项目背景 + 功能概述
  ```html
  <div class="project-desc">
    <h2>项目背景</h2>
    <p>假票线索管理系统用于对假票线索进行录入、审核、分派和跟踪。</p>
    <h2>功能概述</h2>
    <ul>
      <li>假票线索管理：线索录入、审核、分派、跟踪</li>
      <li>工单管理：工单创建、处理、流转、归档</li>
    </ul>
  </div>
  ```

- **迭代开发场景**：从 PRD 提取本轮变更项列表
  ```html
  <div class="project-desc">
    <h2>本轮迭代：v2.1.0</h2>
    <ul class="change-list">
      <li class="change-added">[新增] 线索批量导入功能</li>
      <li class="change-modified">[变更] 工单列表新增「紧急程度」筛选条件</li>
      <li class="change-fixed">[修复] 报表统计日期选择器交互优化</li>
    </ul>
    <p class="change-note">仅上述变更项涉及页面已更新，其他页面保持不变。</p>
  </div>
  ```

**第三段：快捷入口区**

每个一级菜单模块一个卡片，链接到该模块的默认页面：

```html
<div class="quick-links">
  <a href="clue/list.html" class="link-card">
    <div class="card-title">假票线索管理</div>
    <div class="card-desc">线索录入、审核、分派</div>
  </a>
  <a href="workorder/list.html" class="link-card">
    <div class="card-title">工单管理</div>
    <div class="card-desc">工单处理、流转、归档</div>
  </a>
</div>
```

**禁止规则：**

- `index.html` MUST NOT 包含复杂业务内容（数据图表、业务表格、复杂表单一律禁止）
- 当 PRD 定义了仪表盘/首页看板时，MUST 单独生成 `dashboard.html`，而非将内容塞进 `index.html`

#### 3.4.4 每个页面的完整结构

每个功能页面都是**独立的完整 HTML 文件**，包含共享的布局外壳（侧边栏、顶栏）：

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <title>页面标题 - UI 原型</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/antd@4.24.16/dist/antd.min.css">
  <!-- 共享骨架样式（MUST 引用，MUST NOT 重复定义骨架类） -->
  <link rel="stylesheet" href="../assets/shared.css">
</head>
<body>
  <div class="app-layout">
    <!-- 共享侧边栏：每个页面都包含，当前页对应的菜单项加 ant-menu-item-selected -->
    <aside class="sidebar">
      <ul class="ant-menu ant-menu-dark ant-menu-inline">
        <li class="ant-menu-item"><a href="../index.html">首页</a></li>
        <li class="ant-menu-item ant-menu-item-selected">
          <a href="list.html">假票线索管理</a>
        </li>
        <li class="ant-menu-item"><a href="../workorder/list.html">工单管理</a></li>
      </ul>
    </aside>
    <div class="main-area">
      <!-- 顶栏：面包屑静态定义 -->
      <nav class="navbar">
        <div class="ant-breadcrumb">
          <span class="ant-breadcrumb-link"><a href="../index.html">首页</a></span>
          <span class="ant-breadcrumb-separator">/</span>
          <span class="ant-breadcrumb-link"><a href="list.html">假票线索管理</a></span>
          <span class="ant-breadcrumb-separator">/</span>
          <span class="ant-breadcrumb-link">线索列表</span>
        </div>
      </nav>
      <!-- 内容区：页面特有内容 -->
      <main class="page-content">...</main>
    </div>
  </div>
</body>
</html>
```

#### 3.4.5 侧边栏菜单链接规则

每个页面的侧边栏 MUST 包含完整的菜单结构，通过 `<a href>` 使用**相对路径**链接：

| 当前页面所在目录 | 链接到同级页面 | 链接到其他模块 | 链接到 index |
|----------------|--------------|--------------|-------------|
| `clue/` | `list.html`、`detail.html` | `../workorder/list.html` | `../index.html` |
| `workorder/` | `list.html`、`detail.html` | `../clue/list.html` | `../index.html` |

**菜单高亮规则：**
- 当前页面对应的菜单项 MUST 添加 `ant-menu-item-selected` 类
- 其他菜单项 MUST NOT 添加此类
- 如果页面是某一级菜单的子页面，则该一级菜单项也 MUST 添加 `ant-menu-item-selected`

#### 3.4.6 面包屑规则

每个页面的面包屑 MUST 在 HTML 中**静态定义**（不依赖 JS 动态生成）：

- 首页链接指向 `index.html`（使用相对路径）
- 中间层级链接指向对应的列表页（使用相对路径）
- 最后一项为当前页面标题，不加链接

#### 3.4.7 页面间跳转规则

所有页面间跳转 MUST 使用正常的 `<a href>` 链接，MUST NOT 使用 JS 模拟导航：

```html
<!-- 列表页操作列 → 跳转到同目录下的详情页 -->
<td>
  <a class="action-link" href="detail.html">详情</a>
  <a class="action-link" href="form.html">编辑</a>
</td>

<!-- 详情页/表单页 → 返回列表页 -->
<a class="ant-btn ant-btn-default" href="list.html">← 返回列表</a>
```

**相对路径规则：**
- 同一模块内的页面（同目录下）：直接使用文件名，如 `detail.html`
- 跨模块跳转：使用 `../模块目录/文件名`，如 `../workorder/list.html`
- 返回入口：使用 `../index.html`

#### 3.4.8 菜单-目录-页面映射表

MUST 输出以下映射关系表，确保目录结构与导航一致：

| 一级菜单项 | 目录名 | 包含页面 | 默认页面（快捷入口指向） |
|-----------|--------|---------|---------------------|
| 假票线索管理 | `clue/` | list.html, detail.html, form.html | `clue/list.html` |
| 工单管理 | `workorder/` | list.html, detail.html, form.html | `workorder/list.html` |
| 报表统计 | `report/` | dashboard.html | `report/dashboard.html` |

#### 3.4.9 迭代开发增量更新规则

当用户选择「迭代开发」场景时，MUST 遵循以下增量规则：

1. **导航目录必须基于已有结构**：
   - MUST 先读取项目中已有的原型目录结构（或已有前端页面的路由配置），提取当前完整的菜单-目录映射关系
   - 仅当 PRD 变更项中明确涉及菜单结构变化（新增菜单项、删除菜单项、菜单重命名）时，才在已有目录结构基础上做相应调整
   - MUST NOT 因迭代而重新生成全部目录结构，未变更的菜单-目录映射 MUST 保持不变
2. **仅生成/覆盖变更涉及的页面文件**，未变更的页面文件 MUST NOT 覆盖
3. `index.html` 仅在变更项列表有更新时才更新描述区，导航结构不变时侧边栏不更新
4. 如果变更涉及菜单结构变化（新增/删除菜单项），MUST 同步更新所有页面的侧边栏菜单
5. MUST 在生成前明确告知用户：本次将覆盖哪些文件、保留哪些文件不变
6. 迭代生成时，MUST 读取已有原型文件中未变更页面的 HTML，确保侧边栏菜单、面包屑、页面布局外壳等共享部分与已有页面保持一致，MUST NOT 因重新生成而导致共享部分风格漂移

---

## Step 4 — 添加交互模拟

为原型添加必要的交互效果：
- 表单校验提示（必填项、格式校验）
- 按钮状态切换（loading、disabled）
- 弹窗开关控制
- 表格分页模拟
- 空状态和加载状态展示

### 多页面导航模式交互（仅当选择此模式时）

**必须实现的交互：**

1. **菜单导航**：侧边栏菜单项使用 `<a href>` 链接到对应页面（相对路径）
2. **菜单高亮**：当前页面对应的菜单项必须添加 `ant-menu-item-selected` 类
3. **面包屑导航**：每个页面静态定义面包屑，上级链接使用 `<a href>` 指向对应页面
4. **行内操作跳转**：列表页的「详情」「编辑」等操作使用 `<a href>` 跳转到对应页面
5. **返回按钮**：详情页/表单页的「返回」按钮使用 `<a href>` 返回列表页
6. **跨模块跳转**：所有跨模块链接使用正确的相对路径（如 `../workorder/list.html`）

---

## Step 5 — 标注说明

- 在 HTML 注释中标注各区域对应的 PRD 章节（如 `<!-- PRD章节: 4.1 产品管理列表页 -->`）
- 标注需确认的设计决策点

---

## Step 6 — 自检验证

生成完成后，逐项自检：

### 通用验证项

- [ ] HTML 文件可直接在浏览器打开预览，无报错
- [ ] 页面布局与 PRD 描述一致
- [ ] 所有表单字段与 PRD 字段定义对应
- [ ] 交互效果可操作（弹窗、校验、分页）
- [ ] 使用 CSS 变量引用设计系统，非硬编码
- [ ] 响应式布局在手机/平板/桌面三种宽度下正常显示
- [ ] 组件选择符合 Step 2 决策指引，类名前缀使用正确
- [ ] HTML 注释清晰标注 PRD 对应章节
- [ ] 单个 HTML 文件不超过 800 行

### 多页面导航模式验证项（仅当选择此模式时）

- [ ] `prototype/assets/shared.css` 已生成，包含设计变量、主布局、公共组件、index 专属样式、响应式断点
- [ ] `index.html` 引用 `assets/shared.css`（无 `../` 前缀）
- [ ] 所有 `{module}/*.html` 引用 `../assets/shared.css`（带 `../` 前缀）
- [ ] 页面 `<style>` 块中 MUST NOT 重复定义 shared.css 已有的骨架类（`.app-layout`、`.sidebar`、`.navbar`、`.filter-area`、`.table-wrapper`、`.detail-card`、`.quick-links`、`.link-card` 等）
- [ ] 所有功能页（不包括 index）侧边栏 `<aside class="sidebar">` 区块 HTML 文本逐字比对一致，仅 `ant-menu-item-selected` 位置不同
- [ ] 菜单项数量、顺序、文案、`href` 在所有页面间一致
- [ ] 目录结构已按一级菜单分目录存放
- [ ] `index.html` 包含项目标识区、描述区、快捷入口区三段内容
- [ ] `index.html` 不包含复杂业务内容（图表、表格、表单）
- [ ] 每个页面都是独立的完整 HTML 文件（含布局外壳）
- [ ] 侧边栏菜单项使用 `<a href>` 链接，非 JS 事件
- [ ] 当前页面对应菜单项已添加 `ant-menu-item-selected` 类
- [ ] 面包屑静态定义，上级链接使用 `<a href>` 指向对应页面
- [ ] 列表页「详情」「编辑」使用 `<a href>` 跳转
- [ ] 详情页/表单页「返回」使用 `<a href>` 返回列表页
- [ ] 所有相对路径正确（同级、跨模块、返回入口）
- [ ] 迭代开发场景下，未变更页面未被覆盖
- [ ] 迭代开发场景下，`shared.css` 未被不必要地修改

> **下游衔接**：产出的 HTML 原型文件可被 kf-spec 通过 `@file` 引用加载，作为页面结构和视觉设计的参考依据（可选，非自动调用）。

---

## Step 7 — 质量审查

生成完成后，MUST 执行以下两维度审查，逐项核查并输出审查报告。**审查不通过时，MUST 修正后重新审查，直到全部通过。**

### 7.1 组件使用正确性审查

逐页面检查生成的 HTML，验证组件使用是否符合 PRD 语义和 Ant Design CSS 类名规范：

| 检查项 | 审查方法 | 常见问题 |
|--------|----------|----------|
| 数据录入组件匹配 | PRD 描述「下拉选择」→ `ant-select`（非滚动列表）；「输入」→ `ant-input`（非 textarea 除非明确要求多行）；「日期」→ `ant-picker`（非普通 input） | 下拉变滚动列表、Select 变 Radio 组、Input 变 Textarea |
| 数据展示组件匹配 | PRD 描述「标签」→ `ant-tag`；「统计数值」→ `ant-statistic`；「描述列表」→ `ant-descriptions`（非普通 table） | Tag 变 Badge、Descriptions 变 Table |
| 反馈组件匹配 | PRD 描述「弹窗确认」→ `ant-modal`（非 Drawer）；「抽屉面板」→ `ant-drawer`（非 Modal）；「气泡确认」→ `ant-popover` | Modal 变 Drawer、Popconfirm 变 Modal |
| 导航组件匹配 | PRD 描述「标签页切换」→ `ant-tabs`（非 Radio 组）；「步骤条」→ `ant-steps`（非自定义 CSS） | Tabs 变 Radio、Steps 变手写序号 |
| CSS 类名正确性 | 检查所有 `ant-*` 类名是否存在于 Ant Design v4 的 CSS 类名体系中 | 编造不存在的类名、v3/v5 类名混用 |
| 组件嵌套结构 | 检查组件嵌套是否符合 antd DOM 结构要求（如 `ant-table` > `table` > `thead`/`tbody`） | 表格缺少 `ant-table` 容器、表单缺少 `ant-form-item` 包裹 |

**审查方法**：针对每个页面，逐区域对照 PRD 原文描述与生成的 HTML 代码，确认「PRD 说的」和「HTML 做的」一一对应。

### 7.2 需求细节实现一致性审查

逐条对照 PRD 功能需求，验证原型的实现细节是否与 PRD 描述完全一致：

| 检查项 | 审查方法 | 常见问题 |
|--------|----------|----------|
| 字段完整性 | PRD 列出的每个字段都出现在原型中（搜索区、表格列、表单项、详情项） | 遗漏字段、字段顺序与 PRD 不一致 |
| 筛选条件实现 | PRD 描述的每个筛选条件都实现，且类型正确（下拉/输入/日期/级联等） | 遗漏筛选条件、条件类型不符 |
| 操作按钮完整 | PRD 描述的每个操作按钮都出现（新增、批量操作、行操作等） | 遗漏按钮、按钮文字与 PRD 不一致 |
| 业务状态展示 | PRD 定义的每个状态值都有对应的 Tag 展示，且颜色方案合理 | 状态遗漏、Tag 颜色与业务语义不符 |
| 交互流程实现 | PRD 描述的交互流程（如：点击A→弹出B→确认后C）在原型中可走通 | 交互步骤缺失、流程顺序错误 |
| 数据规则体现 | PRD 定义的校验规则（必填、格式、范围）在表单中有体现 | 必填标记缺失、校验提示缺失 |
| 布局要求实现 | PRD 描述的区域划分、排列方式在原型中正确体现 | 区域缺失、排列方向错误 |

### 7.3 迭代场景额外审查项

当用户选择「迭代开发」场景时，额外审查：

| 检查项 | 审查方法 |
|--------|----------|
| 未变更区域保留 | 逐区域对比新原型与已有实现，未变更区域 MUST 完全一致 |
| 组件类型漂移 | 已有实现中用 `ant-select` 的，迭代后 MUST NOT 变成滚动列表或 Radio 组 |
| 操作列风格漂移 | 已有实现中操作列是文字链接的，迭代后 MUST NOT 变成按钮 |
| 标签颜色漂移 | 已有实现中某状态用 `ant-tag-green` 的，迭代后 MUST NOT 变成其他颜色 |
| 侧边栏一致性 | 逐字比对所有功能页的 `<aside class="sidebar">` HTML 文本，除 `ant-menu-item-selected` 位置外 MUST 完全一致 |
| shared.css 引用一致 | 所有页面 MUST 通过 `<link>` 引用 `shared.css`，MUST NOT 在 `<style>` 重复定义骨架类 |

### 7.4 审查报告输出格式

```
## 原型质量审查报告

### 页面：{页面名称}

| # | 检查项 | 结果 | 问题描述 | 修复动作 |
|---|--------|------|----------|----------|
| 1 | 数据录入组件匹配 | ✅/❌ | _描述_ | _修复说明_ |
| 2 | ... | | | |

### 汇总
- 通过：X 项
- 不通过：Y 项
- 修复后需复审：Y 项
```

**审查通过条件**：所有检查项均为 ✅。存在 ❌ 项时，MUST 修正对应问题后重新审查，直至全部通过。

### 7.5 专家团/多 Agent 模式执行策略

当运行在专家团模式（Expert Mode）或多 Agent 模式下时，质量审查 MUST 由独立于生成者的审查专家 Agent 执行：

1. **审查独立性**：审查 Agent MUST NOT 由生成原型的同一个 Agent 担任，确保视角客观
2. **Agent 数量**：视工作量大小而定：
   - 原型页面 ≤ 3 个：派出 1 个审查 Agent 统一审查所有页面
   - 原型页面 4~8 个：可派出 2 个审查 Agent，按模块分工（如 A 审查线索模块，B 审查工单模块）
   - 原型页面 > 8 个：可派出 2~3 个审查 Agent，按模块分工并行审查
3. **审查 Agent 的输入**：
   - PRD 文档（原始需求）
   - 生成的 HTML 原型文件路径
   - 本 Skill 的 Step 7 审查清单（7.1~7.3）
   - 迭代场景下：已有原型文件路径（用于漂移对比）
4. **问题处理规则**：
   - **确定的问题**（组件类型错误、字段遗漏、PRD 描述与实现明显不符）：审查 Agent 直接修复，无需再次确认
   - **需澄清的问题**（PRD 描述模糊导致多种理解、已有实现细节含义不明确、变更范围存疑）：MUST 与用户交互澄清，展示具体疑问和可选方案，等待用户决策后继续
   - MUST NOT 将需澄清的问题标注后跳过，MUST 在审查阶段即时与用户交互
5. **修复后复审**：审查 Agent 修复确定的问题后，MUST 对修复后的页面重新执行审查清单，确认修复有效且未引入新问题

---

## 核心示例

> 以下为精简示例，展示引入 Ant Design CSS CDN 后的 HTML 原型标准结构。完整模板参见 `assets/ui-prototype-template.html`。

### 单页面模式示例

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>产品管理 - UI原型</title>
  <!-- 组件库 CSS CDN — 仅引入样式，不引入 JS -->
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/antd@4.24.16/dist/antd.min.css">
  <style>
    /* 补充设计系统变量 — 用于 antd 未覆盖的自定义样式 */
    :root {
      --sidebar-width: 220px;
      --navbar-height: 56px;
      --color-bg-page: #f5f6fa;
    }
    .page-header { display: flex; justify-content: space-between; align-items: center; }
  </style>
</head>
<body>
  <!-- PRD章节: 4.1 产品管理列表页 -->
  <div class="page-container">
    <button class="ant-btn ant-btn-primary">新增产品</button>
    <div class="ant-table">
      <table><thead class="ant-table-thead"><!-- 表头 --></thead></table>
    </div>
  </div>
  <script>/* 交互模拟脚本（纯原生 JS，无框架依赖） */</script>
</body>
</html>
```

### 多页面导航模式示例

**index.html（入口页）：**

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>假票线索管理系统 - UI 原型</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/antd@4.24.16/dist/antd.min.css">
  <style>:root { --sidebar-width: 220px; --navbar-height: 48px; }</style>
</head>
<body>
  <div class="app-layout">
    <aside class="sidebar">
      <ul class="ant-menu ant-menu-dark ant-menu-inline">
        <li class="ant-menu-item ant-menu-item-selected">首页</li>
        <li class="ant-menu-item"><a href="clue/list.html">假票线索管理</a></li>
        <li class="ant-menu-item"><a href="workorder/list.html">工单管理</a></li>
      </ul>
    </aside>
    <div class="main-area">
      <nav class="navbar"><span class="navbar-title">假票线索管理系统</span></nav>
      <main class="page-content">
        <!-- 项目标识区 -->
        <div class="project-header">
          <h1>假票线索管理系统 <span class="version">v2.1.0</span></h1>
        </div>
        <!-- 描述区（新项目） -->
        <div class="project-desc">
          <p>假票线索管理系统用于对假票线索进行录入、审核、分派和跟踪。</p>
        </div>
        <!-- 快捷入口区 -->
        <div class="quick-links">
          <a href="clue/list.html" class="link-card">
            <div class="card-title">假票线索管理</div>
            <div class="card-desc">线索录入、审核、分派</div>
          </a>
          <a href="workorder/list.html" class="link-card">
            <div class="card-title">工单管理</div>
            <div class="card-desc">工单处理、流转、归档</div>
          </a>
        </div>
      </main>
    </div>
  </div>
</body>
</html>
```

**clue/list.html（功能页）：**

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <title>线索列表 - UI 原型</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/antd@4.24.16/dist/antd.min.css">
  <style>:root { --sidebar-width: 220px; --navbar-height: 48px; }</style>
</head>
<body>
  <div class="app-layout">
    <aside class="sidebar">
      <ul class="ant-menu ant-menu-dark ant-menu-inline">
        <li class="ant-menu-item"><a href="../index.html">首页</a></li>
        <li class="ant-menu-item ant-menu-item-selected"><a href="list.html">假票线索管理</a></li>
        <li class="ant-menu-item"><a href="../workorder/list.html">工单管理</a></li>
      </ul>
    </aside>
    <div class="main-area">
      <nav class="navbar">
        <div class="ant-breadcrumb">
          <span class="ant-breadcrumb-link"><a href="../index.html">首页</a></span>
          <span class="ant-breadcrumb-separator">/</span>
          <span class="ant-breadcrumb-link">假票线索管理</span>
        </div>
      </nav>
      <main class="page-content">
        <div class="ant-table"><table><!-- 列表内容 --></table></div>
      </main>
    </div>
  </div>
</body>
</html>
```

> 入口页完整模板参见 `assets/ui-prototype-index-template.html`，功能页完整模板参见 `assets/ui-prototype-page-template.html`。

---


## Harness 反馈闭环（铁律 3）

每个 Gate 完成后 MUST 执行机械化验证：

| Step | 验证动作 | 失败处理 |
|------|---------|---------|
| Gate 1 | `node .claude/helpers/harness-gate-check.cjs --skill kf-ui-prototype-generator --stage gate1 --required-sections "## PRD 文档" "## 页面名称" --forbidden-patterns TODO 待定` | 补充缺失参数 |
| Gate 2 | `node .claude/helpers/harness-gate-check.cjs --skill kf-ui-prototype-generator --stage gate2 --required-sections "## 项目风格对照表"` | 补充对照表 |
| Step 7 | `node .claude/helpers/harness-gate-check.cjs --skill kf-ui-prototype-generator --stage step7 --required-sections "## 原型质量审查报告" --forbidden-patterns "❌"` | 修正后重新审查 |

验证原则：**Plan → Build → Verify → Fix** 强制循环，不接受主观"我觉得好了"。

## 铁律

1. **MUST NOT 参考未提供的 PRD 文档** — 仅依据 `@file` 指定的文档
2. **MUST 遵循目录规范** — 优先使用用户指定路径，未指定时按项目仓库结构建议 SOP 标准路径（Monorepo: `docs/{version}/prototype/`，分仓: `{project}-docs/{version}/prototype/`）
3. **MUST NOT 在 PRD 描述不清时假设** — 记录问题等待确认
4. **2 次渲染问题未解决则停止** — 报告问题等待用户决策
5. **MUST 使用 CSS 变量** — 引用团队设计系统，禁止硬编码颜色值
6. **MUST 支持响应式布局** — Mobile-first，禁止行内样式处理布局
7. **单文件不超过 800 行** — 超过需拆分并说明
8. **MUST NOT 引入组件库 JavaScript 文件** — 原型仅使用 CSS 类名实现视觉外观，不依赖任何 JS 运行时（React / Vue / Angular 等）
9. **MUST 自动感知项目上下文** — MUST 在生成前自动扫描工作区检测项目页面目录，MUST NOT 跳过项目上下文检测直接按独立模式生成。检测到项目目录时，MUST 先分析项目现有页面风格再生成原型，MUST NOT 忽略项目已有的布局惯例凭空设计
10. **多页面导航模式 MUST 使用多文件独立页面架构** — 每个页面独立 HTML 文件，按功能分目录存放，`index.html` 为入口。页面间通过 `<a href>` 跳转，MUST NOT 使用 JS 模拟导航（如 `navigateTo()`）
11. **多页面导航模式 MUST 保持目录与菜单一致** — 目录名与一级菜单项对应，页面间侧边栏菜单完整且链接正确，当前页菜单项高亮
12. **index.html MUST 仅作轻量壳** — 包含项目标识区、描述区、快捷入口区三段内容，MUST NOT 包含复杂业务内容。仪表盘/首页看板必须单独生成 `dashboard.html`
13. **MUST 执行 Step 7 质量审查** — 生成完成后 MUST 执行组件正确性审查和需求细节一致性审查，审查不通过 MUST 修正直至通过。MUST NOT 跳过审查直接交付。专家团/多 Agent 模式下 MUST 派出独立审查 Agent 执行，确定问题直接修复，存疑问题 MUST 与用户交互澄清而非标注跳过
14. **迭代场景 MUST 保留已有实现** — MUST NOT 对未变更区域“顺手优化”，MUST NOT 改变已有实现的组件类型、操作列风格、标签颜色等细节。仅修改 PRD 明确要求变更的部分
15. **多页面模式 MUST 采用共享 CSS 单一来源** — MUST 先生成 `prototype/assets/shared.css` 再生成任何 HTML 页面；每个页面 MUST 通过 `<link>` 引用（index 用 `assets/shared.css`，功能页用 `../assets/shared.css`）；MUST NOT 在页面 `<style>` 中重复定义 shared.css 已有的骨架类（`.app-layout`/`.sidebar`/`.navbar`/`.filter-area`/`.table-wrapper` 等）
16. **多页面模式 MUST 采用菜单 snippet 单一来源** — MUST 在生成首个页面之前输出「标准侧边栏 snippet」并打印给用户；所有页面 MUST 原样复制该 snippet，仅允许修改 `ant-menu-item-selected` 位置（以及 index.html 去除 `../` 前缀）；MUST NOT 增删菜单项、改顺序、改链接、改文案

---

## 参考文件

> 以下文件在指定步骤按需加载，保持上下文精简：

| 文件 | 加载时机 | 用途 |
|------|----------|------|
| `references/ui-design-system.md` | 上下文收集、Step 3 | 团队设计系统变量（CSS 变量、响应式断点） |
| `assets/ui-prototype-template.html` | Step 3（单页面模式） | 单页面 HTML 原型标准结构模板 |
| `assets/shared.css` | Step 3（多页面导航模式） | 多页面共享骨架样式文件。MUST 先复制到 `prototype/assets/shared.css`再生成页面，所有页面通过 `<link>` 引用 |
| `assets/ui-prototype-index-template.html` | Step 3（多页面导航模式·入口页） | 多页面导航模式入口页模板（项目标识 + 描述 + 快捷入口） |
| `assets/ui-prototype-page-template.html` | Step 3（多页面导航模式·功能页） | 多页面导航模式功能页模板（完整布局 + 侧边栏 + 面包屑 + 内容区） |
