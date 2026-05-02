# AutoCoding - Complete User Manual

> **Version**: v1.3
>
> This manual is for users to read and understand AutoCoding's complete features and usage methods.
> To let AI auto-install, please read [INSTALL.md](INSTALL.md)

---

## 一、Framework Features

### One-Line Positioning

**AutoCoding** — Let AI autonomously drive the entire programming process, from environment setup to code delivery, with zero manual intervention. You don't even need programming experience — just understand the general process, what each phase produces, and what the goals are.

### Core Features

| # | Feature | Description |
|---|---------|-------------|
| 1 | **Claude Autopilot** | Claude Code + Yolo mode, AI autonomous decision-making without frequent confirmations |
| 2 | **gspowers SOP Navigation** | Industry consensus skill rules framework, standardized development process |
| 3 | **ruflo Multi-Agent Parallel** | Session memory integration, multi-agent parallel/relay execution |
| 4 | **RTK Token Saving** | Save 60-90% Token consumption, significantly reducing costs |
| 5 | **markitdown Universal Read** | Markdown/HTML/document conversion, any format can be processed |
| 6 | **TDD Test-First** | Mandatory test-first mode, guaranteed quality |
| 7 | **Universal Triple Collaboration** | Shop around, multi-angle review, more comprehensive decisions |
| 8 | **Pipeline Assembly Line** | Complex tasks split into modules and steps, automatic dependency orchestration, batch verification |

### Detailed Description

#### 1. Claude Autopilot

```
Traditional mode: User → Confirm → Execute → Confirm → ...
Autopilot mode: User → AI autonomously completes → Reports result
```

After enabling Yolo mode in Claude Code, AI can:
- Automatically execute file operations, terminal commands
- Automatically handle popups, exceptions, interrupts
- Resolve issues independently without interruption

#### 2. gspowers SOP Navigation

gspowers is an industry consensus skill rules framework providing standardized development process:

```
/gspowers → /office-hours → /plan-eng-review → /brainstorm → /subagent-dev → /review → /ship
```

Each step has clear deliverables and acceptance criteria.

#### 3. ruflo Multi-Agent Parallel

ruflo integrates session memory and supports multiple agents in parallel/relay mode:

- **Parallel**: Same task, multiple agents executing simultaneously from different angles
- **Relay**: Previous agent output becomes next agent input
- **Memory**: Cross-session memory, no knowledge loss

#### 4. RTK Token Saving

RTK (Rust Token Killer) saves 60-90% Token by filtering and compressing command output:

| Operation | Normal Consumption | RTK Consumption | Savings |
|-----------|-------------------|------------------|---------|
| `ls` / `tree` | 2,000 | 400 | -80% |
| `git status` | 3,000 | 600 | -80% |
| `npm test` | 25,000 | 2,500 | -90% |

#### 5. markitdown Universal Read

markitdown enables Markdown/HTML/document conversion:

- Markdown → HTML (GitHub style)
- Code highlighting, GFM table support
- Any document format convertable to AI-readable format

#### 6. TDD Test-First

gspowers TDD extension enforces test-first mode:

```
RED → GREEN → REFACTOR

1. Write test first (RED)
2. Write implementation to pass test (GREEN)
3. Refactor and optimize (REFACTOR)
```

#### 7. Universal Triple Collaboration

ruflo's `triple` mechanism supports multi-angle parallel review:

```
triple Security Audit
├── Agent-A: Code security scan
├── Agent-B: Dependency vulnerability check
└── Agent-C: Configuration risk assessment
```

#### 8. Pipeline Assembly Line

gspowers Pipeline extension supports multi-module dependency assembly line:

```
Scenario: E-commerce system
├── User Service (no dependencies)
├── Product Service (depends on User Service)
├── Order Service (depends on User Service + Product Service)
└── Payment Service (depends on Order Service)

Pipeline automatically:
1. Batch 1: User Service
2. Gate verification passed
3. Batch 2: Product Service
...and so on
```

---

## 二、Project Development Workflow

> Complete flow from requirements to code delivery

### Preparation Phase

```
1. Organize requirements documents (business flow tables, etc.)
2. Produce SDD requirements collection sheet
3. /prd-generator → Generate structured PRD document
4. /ui-prototype-generator → Generate UI prototype
5. Confirm prototype with client, collect revision notes and Q&A
6. Have AI backfill PRD and prototype with revision notes
```

### Path Selection

After preparation, choose a development path based on project needs:

#### Path 1 — kf Series (Fast + Hammer, recommended for MVP)

```
6. /kf-spec → Select MVP mode, generate Spec document
7. /kf-multi-team-compete (/夯) → Red/Blue/Green teams compete concurrently,
   producing merged optimal code (built-in integration test agent automatically
   invokes kf-code-review-graph for code review)
```

Characteristics: AI autonomous decision-making, fast delivery, multi-team competition碾压.

#### Path 2 — gspowers Orthodox School (Stable)

```
6. /gspowers → Follow SOP process step by step
   /gspowers → /office-hours → /plan-eng-review → /brainstorm
   → /subagent-dev → /review → /ship
```

Characteristics: Standardized process, acceptance criteria at each step, suitable for large formal projects.

### First-Time Installation

> Only needed once per environment

**Option 1: Single File Entry (Simplest)**

Download `AICoding.md` from the repository, drop it into your AI IDE, and say "execute installation".
See repo root [AICoding.md](AICoding.md) for details.

**Option 2: Manual Initialization**

```powershell
cd D:\your-new-project
ruflo init --minimal --skip-claude
claude
```

---

## 三、Feature Triggers Quick Reference

| Trigger | Function | Source |
|---------|----------|--------|
| `安全审计` (Security Audit) | Multi-agent security vulnerability scan + triple confrontation | ruflo |
| `架构评审` (Architecture Review) | Multi-agent system architecture evaluation + triple confrontation | ruflo |
| `triple [task]` | Universal triple collaboration (any task) | kf-triple-collaboration |
| `/gspowers` | Start SOP process navigation | gspowers |
| `/office-hours` | YC-style product inquiry | gspowers |
| `/brainstorm` | Socratic design refinement | gspowers |
| `/subagent-dev` | Sub-agent TDD development | gspowers |
| `/review` | Code review | gspowers |
| `/ship` | Publish PR | gspowers |
| `/review-graph` | Code review dependency graph | kf-code-review-graph |
| `/web-search [query]` | Multi-engine smart search | kf-web-search |
| `/browser-ops` | Browser automation | kf-browser-ops |
| `/夯 [task]` | Multi-team competition review | kf-multi-team-compete |
| `/对齐` / `Explain your understanding` | Alignment workflow | kf-alignment |
| `模型路由` / `Save mode` | Smart model routing | kf-model-router |
| `spec coding` | Spec-driven development | kf-spec |
| `/prd-generator` | PRD document generation | kf-prd-generator |

---

## 四、Memory Sharing Explanation

### 4.1 Memory Hierarchy

```
Global Memory (~/.claude-flow/data/)
    ↓
Project-Level Memory (.claude-flow/data/)
    ↓
Agent Sharing (agents within the same project share memory)
```

### 4.2 Agent Memory Sharing Within Same Project

When `agentScopes.defaultScope: project`, all agents started in the same project share that project's memory context. Memory is isolated between different projects, avoiding bloated global memory.

---

## 五、Directory Structure

```
~$USERPROFILE/
├── .claude/
│   ├── skills/
│   │   ├── gstack/              # GStack (Product Flow Framework)
│   │   └── gspowers/           # gspowers (SOP Navigation)
│   └── settings.json
├── .claude-flow/                 # ruflo Global Configuration
│   ├── config.yaml             # Global configuration (memory path, agent config)
│   └── data/                    # Global memory storage (cross-project sharing)

Project Local (AutoCoding/):
├── .claude/
│   ├── CLAUDE.md              # Project instructions
│   ├── settings.json          # Project configuration
│   └── skills/                # Project-local skills
│       ├── kf-spec/    # Spec-driven development
│       ├── kf-code-review-graph/ # Code review dependency graph
│       ├── kf-web-search/     # Multi-engine search
│       ├── kf-browser-ops/    # Browser automation
│       ├── kf-multi-team-compete/ # Multi-team competition
│       ├── kf-alignment/      # Alignment workflow
│       ├── kf-model-router/   # Model routing
│       ├── kf-prd-generator/  # PRD generation
│       ├── kf-triple-collaboration/ # Triple collaboration
│       ├── kf-ui-prototype-generator/ # UI prototype
│       ├── kf-skill-design-expert/ # Skill design
│       ├── gspowers/          # SOP navigation (upstream)
│       └── gstack/            # Product flow (upstream)
```

---

## 六、Quick Reference

```powershell
# Post-installation verification
claude-flow --version          # ruflo version
claude mcp list                  # MCP tool list (should include ruflo)
git --version                   # Git version
node --version                  # Node.js version

# New project initialization
cd D:\project
ruflo init --minimal --skip-claude

# Start Claude Code
claude

# Common triggers
安全审计 (Security Audit)              # ruflo triple collaboration
架构评审 (Architecture Review)          # ruflo triple collaboration
/gspowers                        # gspowers SOP
/triple [task]                   # Universal triple collaboration
```

---

## 七、Version Compatibility

| Tool | Recommended Version | Compatibility Notes |
|------|---------------------|--------------------|
| Claude Code | Latest | Main interface |
| ruflo | v3.x | Multi-agent + memory |
| gstack | Latest | Product flow |
| gspowers | Latest | SOP navigation |
| superpowers | Latest | Development execution |

> This manual is designed for long-term use. The core mechanism is the collaboration between Claude Code + ruflo, and the collaboration logic remains unchanged regardless of tool version updates.

---

## 八、Troubleshooting

### Issue: A tool cannot be detected

```powershell
# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Manual refresh
refreshenv 2>$null || Write-Host "Please reopen terminal"
```

### Issue: ruflo MCP not working

```powershell
# Restart MCP
claude mcp remove ruflo
claude mcp add ruflo -- npx -y ruflo@latest mcp start

# Check status
claude mcp list
```

### Issue: gspowers not found

```powershell
# Check directory
Get-ChildItem "$env:USERPROFILE\.claude\skills" -Directory
```

---

## 九、TDD Test-First Mode

### 9.1 What is TDD

TDD (Test-Driven Development) test-first development:

```
RED → GREEN → REFACTOR

1. Write test first (RED) - Test will fail because code isn't written yet
2. Write implementation to pass test (GREEN) - Write simplest code to pass
3. Refactor and optimize (REFACTOR) - Optimize code while ensuring tests still pass
```

### 9.2 TDD Triggers

| Trigger | AI Behavior |
|---------|-------------|
| `TDD` | Enable TDD mode, all development follows test-first |
| `遵循 TDD` (Follow TDD) | Same |
| `测试先行` (Test First) | Same |
| `关闭 TDD` (Turn Off TDD) | Restore normal development mode |

### 9.3 TDD Effect

```
You: "Implement user registration feature, following TDD"
    ↓
AI:
  1. Write test: UserRegister.test.ts
  2. Run test → Fail (RED)
  3. Write implementation: UserRegister.ts
  4. Run test → Pass (GREEN)
  5. Refactor and optimize
  6. Prompt you: "✅ TDD complete, coverage 95%, submit?"
```

---

## 十、Pipeline Multi-Module Assembly Line

### 10.1 What is Pipeline Mode

When a project contains **multiple modules with dependencies**, Pipeline mode automatically handles:

1. Analyze module dependency topology
2. Execute in batch order (dependent modules must complete first before modules that depend on them)
3. Gate verification between batches (only proceed if verified)
4. Status tracking and breakpoint recovery

### 10.2 Typical Scenario

```
Scenario: E-commerce system
├── User Service (no dependencies)
├── Product Service (depends on User Service)
├── Order Service (depends on User Service + Product Service)
└── Payment Service (depends on Order Service)

Pipeline automatically:
Batch 1: User Service → Gate verification passed
Batch 2: Product Service → Gate verification passed
Batch 3: Order Service → Gate verification passed
Batch 4: Payment Service → Complete
```

### 10.3 Trigger Methods

```
/pipeline-dev
多模块开发 (Multi-module development)
流水线开发 (Assembly line development)
```

---

## 十一、AI Automated Skill Expansion

### 11.1 What is Skill Expansion

When the user authorizes "Allow AI to automatically expand skills", AI can automatically extend functionality.

### 11.2 Trigger Condition

```
User says "允许 AI 自动扩充技能" (Allow AI to automatically expand skills) or similar expression
```

### 11.3 Expanded Functions

| Trigger | AI Action |
|---------|-----------|
| `TDD` | Enable TDD development mode (test-first) |
| `生成 Wiki` (Generate Wiki) | Compress context, generate project Wiki |
| `遵循 TDD + feature name` | TDD mode implement feature |
| `关闭 TDD` (Turn Off TDD) | Restore normal development mode |

---

## 十二、Security Level Description

| Level | Applicable Scenario | Risk Level | Description |
|-------|---------------------|------------|-------------|
| **L1 Observation Mode** | New project/unfamiliar code | Low | allowPermissions=false, confirm each item |
| **L2 Development Mode** | Daily development/debugging | Medium | allowPermissions=true, sensitive operations need confirmation |
| **L3 Yolo Mode** | Rapid prototyping/experimental projects | High | allowPermissions=true, all auto-approve |
| **L4 Controlled Yolo** | Trusted codebase + CI/CD | Medium | allowPermissions=true + audit log |

---

## 十三、Document Index

| Document | Description |
|----------|-------------|
| [README.md](../README.md) | Project introduction (GitHub homepage) |
| [MANUAL.md](MANUAL.md) | Complete user manual (you are here) |
| [INSTALL.md](INSTALL.md) | AI execution installation guide |
| [CHANGELOG.md](../CHANGELOG.md) | Version change log |
| [FEATURES.md](FEATURES.md) | Framework features introduction |
