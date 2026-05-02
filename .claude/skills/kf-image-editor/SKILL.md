---
name: kf-image-editor
description: |
  AI 自然语言图片编辑。基于 Nano Banana（Gemini）MCP，无需打开任何图片编辑器，
  直接用中文描述即可完成 P图、改图、生图、风格迁移、老照片修复等操作。
  可被 kf-multi-team-compete（/夯）Stage 2/5 自动调用处理 UI 原型截图和方案配图。
  触发词："P图"、"改图"、"修图"、"生成图片"、"图片编辑"、"抠图"、"去水印"。
triggers:
  - P图
  - 改图
  - 修图
  - 生成图片
  - 图片编辑
  - 抠图
  - 去水印
  - 换背景
  - 老照片修复
allowed-tools:
  - Bash
  - Read
  - WebFetch
metadata:
  pattern: tool-wrapper
  interaction: multi-turn
  called_by:
    - kf-multi-team-compete  # Stage 2 UI 原型配图 / Stage 5 方案配图
recommended_model: flash
---

# AI 自然语言图片编辑

你是 AI 图片编辑专家。基于 Nano Banana MCP（Gemini 2.5 Flash Image），直接用自然语言完成图片操作，
无需打开任何图片编辑器或 UI 界面。

## 前置条件

使用前确认 Nano Banana MCP 已配置：

```bash
# 检查 MCP 是否在线
claude mcp list | grep nano-banana
```

如未配置，按以下步骤安装：

```bash
# 1. 获取 Gemini API Key: https://aistudio.google.com/
# 2. 添加 MCP 服务器
claude mcp add nano-banana -- npx -y @seungmanchoi/nano-banana-mcp
# 3. 在交互中设置环境变量 GEMINI_API_KEY
```

或手动在 `settings.json` 中添加：
```json
"mcpServers": {
  "nano-banana": {
    "command": "npx",
    "args": ["-y", "@seungmanchoi/nano-banana-mcp"],
    "env": {
      "GEMINI_API_KEY": "<your-api-key>"
    }
  }
}
```

---

## 核心能力

| 能力 | 说明 | 示例提示 |
|------|------|---------|
| 🎨 **文生图** | 从文字描述生成图片 | "生成一张山间日落的风景图" |
| ✏️ **图片编辑** | 用自然语言修改图片 | "把这张照片的背景换成海滩" |
| 🔗 **多图合成** | 融合多张图片 | "把图1的产品放到图2的场景中" |
| 🎭 **风格迁移** | 转换艺术风格 | "把这张照片转成吉卜力动画风格" |
| 🔧 **修复增强** | 老照片修复/超分辨率 | "修复这张老照片的划痕并增强清晰度" |
| 🏷️ **智能抠图** | 去除/替换背景 | "把背景去掉，换成纯白色" |

---

## 工作流

### Step 1: 理解用户意图

解析用户自然语言指令，识别操作类型：
- 包含"生成"/"画"/"创建" → 文生图
- 包含"改"/"P"/"修"/"换"/"去掉" → 图片编辑
- 包含"风格"/"转成"/"变成" → 风格迁移
- 包含"修复"/"增强"/"清晰" → 修复增强

### Step 2: 确认输入图片

- 如果用户提到了图片路径，先验证文件存在
- 如果用户说的是"这张图"但没给路径，追问确认
- 支持格式：PNG、JPG、WEBP、GIF

### Step 3: 执行操作

使用 Nano Banana MCP 的 `edit_image` 或 `generate_image` 工具：

```
# 编辑已有图片
edit_image(image_path, "用自然语言描述的修改")

# 从文字生成图片
generate_image("用自然语言描述想要的画面")

# 迭代编辑（在上一次结果基础上继续修改）
edit_last("进一步修改的描述")
```

### Step 4: 展示结果

- 输出编辑后的图片路径
- 询问用户是否满意，是否需要进一步修改
- 支持迭代编辑：用户可以连续说"再调亮一点"、"把天空变橙红色"

---

## 迭代编辑模式

核心优势：可以像和人说话一样连续改图，无需重新描述全部需求。

```
用户: "把这张产品图的背景换成白色"  →  edit_image(product.png, "换白色背景")
用户: "再调亮一点"                   →  edit_last("调亮一点")
用户: "产品周围加阴影"               →  edit_last("产品周围加阴影")
用户: "完美，导出"                   →  保存最终结果
```

---

## 自愈式错误处理

| 异常 | 自动处理 |
|------|---------|
| MCP 离线 | 提示用户运行 `claude mcp add nano-banana -- npx -y @seungmanchoi/nano-banana-mcp` |
| API Key 无效 | 引导用户到 https://aistudio.google.com/ 获取免费 Key |
| 图片格式不支持 | 自动用 `npx sharp` 或 Python PIL 转换格式后重试 |
| 生成效果不佳 | 换更具体的描述词重试，最多 3 次 |

---

## 与 /夯 联动

当被 `kf-multi-team-compete`（/夯）调用时：

- **Stage 2（编码实现）**：前端设计师 agent 生成 UI 原型截图后，调用本技能为方案配图、优化截图
- **Stage 5（方案汇总）**：前端设计师 agent 调用本技能为最终方案生成示意图、架构图配图

---

## 输出规范

```markdown

## Harness 反馈闭环（铁律 3）

| Step | 验证动作 | 失败处理 |
|------|---------|---------|
| MCP 连通检查 | `node .claude/helpers/harness-gate-check.cjs --skill kf-image-editor --stage connect --required-sections "## Nano Banana MCP Status" --forbidden-patterns "offline"` | 自动修复 MCP 连接 |
| 编辑结果验证 | `node .claude/helpers/harness-gate-check.cjs --skill kf-image-editor --stage result --required-files "edited-*.png" --forbidden-patterns "error"` | 重新编辑 |

验证原则：**Plan → Build → Verify → Fix** 强制循环。

## 图片编辑报告

### 操作摘要
- 类型：{文生图/图片编辑/风格迁移/修复增强}
- 输入：{原图路径 或 "无（文生图）"}
- 操作：{自然语言描述}

### 结果
- 输出路径：{图片路径}
- 迭代次数：{N} 次

### 下一步
- 是否满意？如需修改请直接描述
```
