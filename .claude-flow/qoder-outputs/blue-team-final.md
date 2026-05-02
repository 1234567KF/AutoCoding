# 蓝队（稳健工程师）方案：Claude Code 终端 UX 改进

> **角色**：蓝队负责从可维护性、工期可控、团队能力匹配角度实现改进方案
>
> **原则**：稳健可靠——成熟方案、最小依赖、跨平台兼容
>
> **日期**：2026-05-02

---

## 一、方案概述

针对 `docs/Claude-Trae-UX对比调研报告.md` 中识别的 Claude Code TUI 四大痛点（Thinking 隐藏、无流式输出、长内容无折叠、TUI 渲染限制），蓝队从**配置层 + 脚本层 + 文档层**三个维度实施 5 项改进，全部零外部依赖、跨平台兼容。

| 编号 | 改进项 | 类型 | 文件数 | 状态 |
|------|--------|------|--------|------|
| T1 | 启用 Thinking + 流式输出配置 | 配置 | 1 | 完成 |
| T2 | claude-stream wrapper 脚本 | 脚本 | 2 (.ps1 + .sh) | 完成 |
| T3 | claude-fold 输出折叠工具 | 脚本 | 2 (.ps1 + .sh) | 完成 |
| T4 | 全局 CLAUDE.md UX 使用技巧 | 文档 | 1 | 完成 |
| T5 | 项目级 UX 配置 | 配置 | 1 | 完成 |

---

## 二、核心思路

### 2.1 设计哲学

- **零外部依赖**：所有脚本仅依赖 Claude Code CLI 自身 + 操作系统内置工具（PowerShell/bash/sed/grep）
- **双平台脚本**：每个工具同时提供 `.ps1`（Windows）和 `.sh`（Linux/Mac/WSL）版本
- **纯文本处理**：折叠工具使用正则/字符串匹配而非 JSON 解析器，兼容 Claude Code 各版本输出格式变化
- **渐进改进**：不改动 Claude Code 核心，通过配置 + wrapper 低成本落地

### 2.2 架构

```
用户
  │
  ├─ 方式 A: claude-stream "问题" | claude-fold   ← 推荐（流式+折叠一气呵成）
  │
  ├─ 方式 B: claude --output-format stream-json "问题"  ← 原生方式
  │
  └─ 方式 C: 直接 claude "问题"  ← 配置已固化 alwaysThinkingEnabled + verbose
```

---

## 三、T1-T5 实现说明

### T1: 启用 Thinking + 流式输出配置

**文件**：`D:\AutoCoding\.claude\settings.json`

**改动**：在已有 `settings.json` 中追加三项配置，不覆盖任何已有字段：

```json
"alwaysThinkingEnabled": true,
"verbose": true,
"outputStyle": "default"
```

**效果**：
- `alwaysThinkingEnabled`：Thinking 过程始终可见，无需手动 `ctrl+o ctrl+e`
- `verbose`：详细输出模式，工具调用过程透明
- `outputStyle`：输出风格保持默认（稳定兼容）

**稳健性**：
- 仅追加字段，原有 hooks、permissions、env、model 等配置完整保留
- 非破坏性：若 Anthropic 后续调整字段语义，删除这 3 行即回滚
- 已验证：settings.json 结构合法，所有已有 hook 链完整

---

### T2: claude-stream wrapper 脚本

**文件**：
- `D:\AutoCoding\.claude\scripts\claude-stream.ps1`
- `D:\AutoCoding\.claude\scripts\claude-stream.sh`

**功能**：封装 `claude --output-format stream-json --include-partial-messages`，提供：
1. claude 可用性前置检查（给出安装指引）
2. `-PostProcess` / `--post-process` 管道模式，链式调用 claude-fold
3. 所有参数透传，行为等价原生 claude

**用法示例**：
```powershell
# 直接使用
.\claude-stream.ps1 "分析项目架构"

# 管道到折叠工具
.\claude-stream.ps1 "分析项目" | .\claude-fold.ps1

# 后处理模式
claude-stream --post-process < transcript.json
```

**稳健性**：
- 使用 `Start-Process -Wait` (PowerShell) / `exec` (bash)，退出码透传
- claude 不可用时给出明确错误消息而非静默失败
- `-PostProcess` 模式下优雅降级：fold 脚本不存在时原样输出并警告

---

### T3: claude-fold 输出折叠格式化工具

**文件**：
- `D:\AutoCoding\.claude\scripts\claude-fold.ps1`
- `D:\AutoCoding\.claude\scripts\claude-fold.sh`

**功能**：对 Claude Code `stream-json` 输出的 NDJSON 做行级后处理：

| 输入行模式 | 输出折叠 | ANSI 色 |
|-----------|---------|---------|
| `"type":"tool_use","name":"Read"` | `[Read: 文件名] (完整路径)` | 青色 |
| `"type":"tool_use","name":"Write\|Edit"` | `[Edit: 文件名] (完整路径)` | 绿色 |
| `"type":"tool_use","name":"Bash"` | `[Bash: 命令摘要]` | 黄色 |
| `"type":"tool_result"` (长内容) | 前 N 行 + 折叠提示 | 黄色折叠线 |
| 其他 JSON / 非 JSON 行 | 原样透传 | — |

**关键设计决策**：

1. **不依赖 jq**：PowerShell 版用 `ConvertFrom-Json`（内置），Bash 版用 `sed` 正则提取（POSIX）。Bash 版拒绝 jq 是因为调研报告明确指出"不引入外部依赖"。
2. **PS5.1 兼容**：避免 `??` null coalescing 运算符（PS7+），改用 `if/elseif` 链。
3. **ANSI 色彩可禁用**：`-NoColor` 开关（PowerShell）或 `NO_COLOR=1` 环境变量（Bash）。
4. **截断行数可配置**：`-MaxBashLines N`（PowerShell）/ `FOLD_BASH_LINES=N`（Bash），默认 20。

**已知局限**：
- Bash 版 `sed` 正则提取对嵌套 JSON 字符串有限制（极深层嵌套可能误匹配），但对 Claude Code 实际输出格式覆盖良好。
- 不支持增量流式折叠（需完整行输入），但不影响管道使用。

---

### T4: 全局 CLAUDE.md UX 使用技巧

**文件**：`C:\Users\KF\.claude\CLAUDE.md`

**改动**：在文件末尾追加 ~55 行 "Claude Code UX 加速技巧" 章节，包含：

1. **快捷键速查表**：`ctrl+o ctrl+e`、`ctrl+o`、`/compact`、`ctrl+c`
2. **流式输出模式**：wrapper 和原生两种调用方式
3. **折叠长输出**：`claude-stream | claude-fold` 管道组合
4. **配置固化**：settings.json 中 alwaysThinkingEnabled/verbose 的作用和副作用
5. **Claude Code vs IDE 插件选择**：终端 TUI 适合深度代码操作，VS Code 插件天然展示 Thinking
6. **省 Token 三板斧**：`/compact`、Thinking 按需查看、分阶段提问
7. **常见问题排查表**：快捷键无效、字符蹦出、verbose 不显示

**稳健性**：
- 仅追加内容，不修改已有指令
- 章节使用 `---` 分隔线明确边界
- 包含官方 issue 编号 (#8477, #22977, #31578) 便于溯源

---

### T5: 项目级 UX 配置

**文件**：`D:\AutoCoding\.claude\settings.json`（同 T1）

**配置项完整清单**：

```json
{
  "model": "deepseek-v4-pro",       // 已存在 - 模型选择
  "alwaysThinkingEnabled": true,    // 新增 - Thinking 始终可见
  "verbose": true,                  // 新增 - 详细输出模式
  "outputStyle": "default",         // 新增 - 输出风格
  "env": {
    "CLAUDECODENOFLICKER": "1"      // 已存在 - 防闪烁
    // ... 其他已有环境变量
  }
}
```

**与 T1 的关系**：T1 和 T5 共同完成 settings.json 的 UX 配置。如 settings.json 不存在，会参考 `templates/settings.json.template` 创建（已有基础配置，仅追加 UX 字段）。

---

## 四、方案优势（5 点）

1. **零外部依赖**：所有脚本仅使用操作系统内置工具（PowerShell/bash/sed/grep），无需 pip/npm/jq。在锁权限企业 Windows 和极简 Linux 服务器上均可运行。
2. **双平台完整覆盖**：Windows PowerShell 5.1+ 和 Linux/Mac bash 3.2+ 各有一套等效实现，避免"Windows 能用 Mac 不行"的团队分裂问题。
3. **非侵入式**：不改动 Claude Code 源码、不注入 hook、不修改模型参数。所有行为通过 wrapper 层叠加，回滚仅需删除 3 个文件 + 3 行配置。
4. **低认知负担**：用户只需记住 `claude-stream` 一个命令即可获得流式输出；`claude-fold` 作为管道过滤器自然融入 Unix 管道哲学。
5. **文档闭环**：从调研报告（问题识别）到配置固化（settings.json）到使用技巧（CLAUDE.md）到脚本实现（scripts/），形成完整的"发现问题 -> 设计方案 -> 落地工具 -> 文档告知"链条。

---

## 五、方案风险（5 点）

1. **`alwaysThinkingEnabled` 已知回归 bug #22977**：Anthropic v2.1.31 中 verbose 模式不再显示 Thinking 块。若用户恰好使用受影响版本，T1 配置将不生效。缓解：CLAUDE.md 中已记录此已知问题及升级指引；脚本层面的 claude-stream 不依赖此配置。
2. **`--output-format stream-json` 格式未公开承诺稳定**：Claude Code 的 stream-json 输出格式没有 Anthropic 官方文档承诺向后兼容，未来版本可能改变 JSON schema。缓解：claude-fold 使用宽松正则匹配，对字段增减比 JSON 解析器更容忍；核心功能（流式输出）不受 schema 变化影响。
3. **Bash 版 claude-fold 的 sed 提取有边界情况**：对极深层嵌套 JSON（如 tool_use 的 input 中包含含引号的 JSON 字符串），sed 正则可能提取不完整。缓解：此类场景 Claude Code 实际输出中极罕见；不影响不需要折叠的普通文本；可后续补充 Python fallback（需团队评审是否引入依赖）。
4. **Windows PowerShell 5.1 的 UTF-8 编码问题**：默认代码页 437/936 下 ANSI 转义码可能显示乱码。缓解：claude-fold.ps1 提供 `-NoColor` 开关；Win10 1809+ 已支持 `[console]::OutputEncoding = [System.Text.Encoding]::UTF8`，可在 wrapper 中自动设置。
5. **全局 CLAUDE.md 覆盖多项目**：`C:\Users\KF\.claude\CLAUDE.md` 影响用户所有项目，UX 技巧章节中的配置建议（如 `alwaysThinkingEnabled`）可能与其他项目的保守配置策略冲突。缓解：章节明确标注"项目级 settings.json"；强调 Thinking 的 token 消耗副作用；用户可按需注释。

---

## 六、文件清单

| 文件路径 | 操作 | 行数 |
|---------|------|------|
| `D:\AutoCoding\.claude\settings.json` | 追加 3 行 UX 配置 | +3 |
| `D:\AutoCoding\.claude\scripts\claude-stream.ps1` | 新建 | 50 |
| `D:\AutoCoding\.claude\scripts\claude-stream.sh` | 新建 | 42 |
| `D:\AutoCoding\.claude\scripts\claude-fold.ps1` | 覆盖 | 87 |
| `D:\AutoCoding\.claude\scripts\claude-fold.sh` | 覆盖 | 121 |
| `C:\Users\KF\.claude\CLAUDE.md` | 追加 UX 技巧章节 | +55 |
| `D:\AutoCoding\.claude-flow\qoder-outputs\blue-team-final.md` | 新建（本文件） | — |

---

## 七、快速验证

```powershell
# 1. 验证配置生效
Select-String -Path .\.claude\settings.json -Pattern "alwaysThinkingEnabled|verbose|outputStyle"

# 2. 验证流式 wrapper 工作
.\claude\scripts\claude-stream.ps1 -p "hello" 2>&1 | Select-Object -First 5

# 3. 验证折叠工具管道
echo '{"type":"tool_use","name":"Read","input":{"file_path":"/tmp/test.txt"}}' | .\claude\scripts\claude-fold.ps1

# 4. 验证全局 CLAUDE.md
Select-String -Path $env:USERPROFILE\.claude\CLAUDE.md -Pattern "UX 加速"
```
