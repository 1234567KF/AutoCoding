# AutoCoding - AI Programming Autopilot

> Let AI autonomously drive the entire programming process, from environment setup to code delivery, with zero manual intervention.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**AutoCoding** is a comprehensive AI programming workstation that integrates Claude Code, gspowers SOP navigation, ruflo multi-agent parallel execution, and other tools, enabling AI to autonomously complete the entire process from environment setup to code delivery.

---

## Core Features

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

---

## Quick Start

### Prerequisites

- Claude Code installed
- Node.js >= 18
- Git

### Method 1: AI Auto Installation (Recommended)

Give this project to AI to read, and AI will automatically complete all configuration:

```
1. Copy the project folder to a new environment
2. Open Claude Code in the project directory
3. Let AI read INSTALL.md
4. AI automatically completes all installation (only Token configuration requires user involvement)
```

### Method 2: Manual Installation

```powershell
# Install Claude Code
irm https://claude.ai/install.ps1 | iex

# Install ruflo
npm install -g ruflo

# Install gspowers
git clone https://github.com/fshaan/gspowers.git ~/.claude/skills/gspowers
```

See [INSTALL.md](docs/INSTALL.md) for details

---

## Feature Triggers

| Trigger | Function | Source |
|---------|----------|--------|
| `/gspowers` | Start SOP process navigation | gspowers |
| `/office-hours` | YC-style product拷问 | gspowers |
| `/subagent-dev` | Sub-agent TDD development | gspowers |
| `/pipeline-dev` | Multi-module assembly line development | gspowers |
| `安全审计` (Security Audit) | Multi-agent security scan | ruflo |
| `架构评审` (Architecture Review) | Multi-agent system architecture evaluation | ruflo |
| `triple [task]` | Universal triple collaboration | ruflo |
| `TDD` | Enable test-first mode | Extension |

---

## Document Structure

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Project introduction (you are here) |
| [MANUAL.md](docs/MANUAL.md) | Complete user manual (for humans) |
| [INSTALL.md](docs/INSTALL.md) | AI execution installation guide (for AI) |
| [CHANGELOG.md](CHANGELOG.md) | Version change log |

---

## Directory Structure

```
AutoCoding/
├── README.md              # Project entry
├── README_en.md           # English entry
├── AICoding.md            # Single-file entry
├── CHANGELOG.md           # Version history
├── CONTRIBUTING.md        # Contribution guide
├── LICENSE                # MIT license
│
├── docs/                  # Documentation
│   ├── MANUAL.md          # Complete manual
│   ├── MANUAL_en.md       # English manual
│   ├── INSTALL.md         # AI installation guide
│   ├── FEATURES.md        # Feature list
│   └── CREDITS.md         # Third-party credits
│
├── assets/                # Static assets
│   └── posters/           # Promotional posters
│
├── .claude/               # Claude Code config
│   ├── CLAUDE.md
│   ├── settings.json
│   └── skills/            # Skills
│
├── templates/             # Configuration templates
│   ├── settings.json.template
│   ├── config.yaml.template
│   ├── tdd-config.yaml.template
│   ├── pre-commit.template
│   ├── pipeline-example.md
│   └── wiki-template.md
│
└── gspowers-pipeline-patch/  # Pipeline extension
    ├── pipeline.md
    ├── execute-patch.md
    └── install-pipeline.ps1
```

---

## Contributing

Issues and Pull Requests are welcome!

See [CONTRIBUTING.md](CONTRIBUTING.md)

---

## License

MIT License - See [LICENSE](LICENSE)
