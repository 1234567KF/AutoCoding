---
name: kf-browser-ops
description: |
  浏览器自动化操作。打开页面、截图、填写表单、点击元素、验证状态、
  复现Bug、跑用户流程。优先使用 gstack 内置 browse，降级到 Playwright。
  可被 kf-multi-team-compete（/夯）Stage 3 自动调用做 UI 自动化测试。
  运行 /browser-ops 获取操作指引。
triggers:
  - browser-ops
  - 浏览器操作
  - 浏览器自动化
  - 自动复现
  - 跑测试用例
allowed-tools:
  - Bash
  - Read
  - WebFetch
  - AskUserQuestion
metadata:
  called_by:
    - kf-multi-team-compete  # Stage 3 自动调用做 UI 测试
recommended_model: flash
---

# 浏览器自动化操作

你是一个浏览器自动化专家。使用真实浏览器完成页面操作、测试验证、Bug复现。

---

## 引擎选择

自动检测并选择最优引擎：

```bash
# 检测 gstack browse 是否可用
if command -v gstack &> /dev/null || [ -d ".claude/skills/gstack/browse" ]; then
  echo "GSTACK_AVAILABLE=true"
else
  echo "GSTACK_AVAILABLE=false"
fi

# 检测 Playwright 是否安装
if npx playwright --version &> /dev/null 2>&1; then
  echo "PLAYWRIGHT_AVAILABLE=true"
else
  echo "PLAYWRIGHT_AVAILABLE=false"
fi
```

| 条件 | 引擎 | 说明 |
|------|------|------|
| gstack 项目内已配置 | gstack browse (`$B`) | 优先，headless Chromium，~100ms/命令 |
| Playwright 已全局安装 | Playwright | 备选，多浏览器支持 |
| 都没有 | 自动安装 Playwright | `npm install -g playwright && npx playwright install chromium` |

---

## gstack browse 模式（首选）

### 基础命令

```bash
# 页面导航
$B goto <url>              # 打开页面
$B status                   # 检查浏览器状态
$B wait --networkidle       # 等待网络空闲
$B wait --delay 2000        # 等待指定毫秒

# 信息获取
$B snapshot -i              # 获取交互元素（按钮、表单等）
$B snapshot -a -o /tmp/annotated.png  # 带标注截图
$B screenshot               # 截图
$B text                     # 获取页面文本
$B links                    # 获取所有链接
$B forms                    # 获取表单字段

# 交互操作
$B click @e3                # 点击元素（引用ID来自snapshot）
$B fill @e4 "value"         # 填写表单
$B select @e5 "option"      # 选择下拉框
$B check @e6                # 勾选复选框

# 断言验证
$B is visible @e7           # 检查元素可见
$B is hidden @e8            # 检查元素隐藏
$B is enabled @e9           # 检查元素可用
$B is disabled @e10         # 检查元素禁用
$B text contains "expected" # 检查文本包含

# Cookie管理
$B cookie-import-browser    # 从Chrome导入Cookie（需认证的站点）
```

---

## Playwright 模式（备选/进阶）

### 安装

```bash
npm install -g playwright
npx playwright install chromium
```

### 交互脚本模板

```javascript
// browser-script.cjs - 可复用浏览器操作脚本
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 }
  });
  const page = await context.newPage();

  // 操作流程
  await page.goto('TARGET_URL');
  // ... 用户指定的操作 ...

  await page.screenshot({ path: '/tmp/browser-screenshot.png', fullPage: true });
  await browser.close();
})();
```

---

## 常见任务模板

### 任务1: Bug复现

```
用户描述："在登录页输入错误密码3次后页面崩溃"

执行：
1. $B goto https://example.com/login
2. $B snapshot -i → 找到用户名、密码输入框、提交按钮的引用ID
3. $B fill @user "test@example.com"
4. $B fill @pass "wrongpassword"
5. $B click @submit
6. $B wait --delay 2000
7. 重复步骤5-6共三次
8. $B screenshot → 捕获崩溃状态
9. 输出：崩溃截图 + 复现步骤 + 控制台错误日志
```

### 任务2: UI功能验证

```
用户描述："验证注册流程是否正常"

执行：
1. $B goto https://example.com/register
2. $B snapshot -i
3. 按注册表单顺序填写所有字段
4. $B click @submit
5. $B wait --networkidle
6. $B text contains "注册成功" → 断言成功消息
7. 截图保存成功状态
8. 输出：验证结果（通过/失败） + 截图证据
```

### 任务3: 响应式布局检查

```
用户描述："检查首页在移动端的显示"

执行：
1. 使用 Playwright 设置 viewport 为 375x812 (iPhone X)
2. $B goto https://example.com
3. $B screenshot → 保存移动端截图
4. 使用 Playwright 设置 viewport 为 1920x1080
5. $B goto https://example.com
6. $B screenshot → 保存桌面端截图
7. 对比两份截图，标记布局问题
```

---

## 自愈式错误处理

遇到以下情况时**不要中断**，自动修复：

| 异常 | 自动处理 |
|------|---------|
| 元素未找到 | 等待2秒后重新 `snapshot -i`，尝试通过文本匹配找新引用ID |
| 页面加载超时 | `$B wait --networkidle` 后重试，或 `$B goto` 重新加载 |
| 弹窗阻挡 | `$B dialog-accept` 或 `$B dialog-dismiss` |
| Cookie过期 | `$B cookie-import-browser` 重新导入 |
| 导航后元素变化 | 自动重新 `snapshot -i` 获取新引用 |

---

## 输出规范

每次操作完成后输出：

```markdown

## Harness 反馈闭环（铁律 3）

| Step | 验证动作 | 失败处理 |
|------|---------|---------|
| 测试执行 | `node .claude/helpers/harness-gate-check.cjs --skill kf-browser-ops --stage test --required-files "test-results.json" --forbidden-patterns "FAIL"` | 修复后重测 |
| 报告生成 | `node .claude/helpers/harness-gate-check.cjs --skill kf-browser-ops --stage report --required-sections "## 测试结果" "## 失败用例" "## 截图"` | 补充报告 |

验证原则：**Plan → Build → Verify → Fix** 强制循环。

## 浏览器操作报告

### 执行摘要
- 目标：{用户描述的任务}
- 结果：{成功/失败}
- 引擎：{gstack/Playwright}

### 操作步骤
1. {步骤1 + 截图引用}
2. {步骤2 + 截图引用}
...

### 验证结果
- {断言1}: {通过/失败}
- {断言2}: {通过/失败}

### 证据
- 截图：{路径}
- 控制台日志：{如有异常}

### 发现的问题（如有）
- {问题描述 + 截图 + 复现步骤}
```
