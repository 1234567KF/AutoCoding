# Claude Code UX 配置说明

> 本文档说明 Claude Code 终端交互体验的优化配置，基于 [Claude-Trae-UX对比调研报告](Claude-Trae-UX对比调研报告.md)。

## 配置项速查

| 配置项 | 位置 | 作用 | 默认值 | 推荐值 | 风险 |
|--------|------|------|--------|--------|------|
| `alwaysThinkingEnabled` | settings.json | Thinking 过程始终可见 | false | **true** | Token 消耗略增 |
| `verbose` | settings.json | 详细输出模式，显示工具调用 | false | **true** | 终端输出量增加 |
| `outputStyle` | settings.json | 输出样式 | "default" | "default" | — |
| `--output-format stream-json` | CLI 参数 | 流式 JSON 输出 | (非流式) | **启用** | 需配合解析器 |
| `--include-partial-messages` | CLI 参数 | 边生成边展示 | (关闭) | **启用** | 输出可能碎片化 |

## Wrapper 脚本

### claude-stream
流式输出 wrapper，自动添加 `--output-format stream-json --include-partial-messages`：

```powershell
# Windows
.\.claude\scripts\claude-stream.ps1 "你的问题"

# 管道后处理模式
claude "问题" | .\.claude\scripts\claude-stream.ps1 -PostProcess
```

```bash
# Linux/macOS
./.claude/scripts/claude-stream.sh "你的问题"
```

### claude-fold
输出折叠格式化工具，自动折叠文件读取、编辑、长 Bash 输出：

```powershell
# Windows
claude "问题" --output-format stream-json | .\.claude\scripts\claude-fold.ps1
```

```bash
# Linux/macOS
claude "问题" --output-format stream-json | ./.claude/scripts/claude-fold.sh
```

## 快捷键

| 快捷键 | 功能 | 场景 |
|--------|------|------|
| `ctrl+o ctrl+e` | 查看 Thinking | 想知道 AI 推理时 |
| `ctrl+o` | 展开截断输出 | 看到 "+N lines" 提示时 |
| `ctrl+c` | 中断生成 | AI 跑偏时 |
| `/compact` | 压缩上下文 | 长会话变慢时 |

## 已知问题

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| `ctrl+o ctrl+e` 无效 | 旧版 Claude Code | `npm i -g @anthropic-ai/claude-code@latest` |
| verbose 不显示 Thinking | 已知回归 bug #22977 | 等待官方修复 / 升级到最新版 |
| 流式输出字符蹦出 | Thinking 与文本交错渲染 | 使用 `claude-fold` 折叠工具调用部分 |
| Bash 输出被截断 | TUI 渲染限制 | `ctrl+o` 展开，或管道到文件 |

## 回滚方法

如需回滚所有 UX 配置：

```powershell
# 恢复 settings.json（如果已备份）
cp .claude\settings.json.bak .claude\settings.json

# 或者手动删除新增的配置项
# alwaysThinkingEnabled, verbose, outputStyle
```
