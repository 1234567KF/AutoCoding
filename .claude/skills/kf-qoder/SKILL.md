---
name: kf-qoder
description: Qoder scheduling engine - task decomposition, adaptive agent routing, topology-aware coordination
type: skill
color: "#00E5FF"
capabilities:
  - task_decomposition
  - expert_routing
  - adaptive_topology
  - agent_orchestration
  - result_fusion
  - token_optimization
---

# Qoder Scheduling Engine

Qoder is a **radically innovative scheduling engine** for Claude Code multi-agent orchestration that treats task scheduling as a graph problem with real-time adaptive topology switching.

## Three Modules

### Module 1: Qoder Engine (Core)
- **Task DAG**: Event-sourced directed acyclic graph for dependency management
- **Decomposer**: Template + heuristic-based task breakdown
- **Router**: Multi-dimensional agent scoring (capability 30%, pattern 30%, performance 20%, token 10%, cost 10%)
- **Merger**: 5 strategies (consensus, weighted, sequential, expert, voting)

### Module 2: Agent Runtime
- **Spawner**: Agent lifecycle management with simulated spawn/completion
- **Communicator**: Gossip, broadcast, handoff, Byzantine fault detection
- **ContextManager**: Token budget slicing with TF-IDF relevance scoring

### Module 3: IDE Bridge
- **FileInterface**: Unified Read/Write/Edit/Glob/Grep abstraction
- **ToolInvoker**: Retry logic, batching, metrics
- **ResultPresenter**: Streaming progressive display
- **ProjectIndexer**: Lightweight symbol/import indexing

## Quick Start

```bash
# Single task execution
node .claude/qoder/qoder-main.js "Build a REST API with auth and tests"

# Demo suite (4 scenarios)
node .claude/qoder/qoder-main.js --demo

# Topology switching showcase
node .claude/qoder/qoder-main.js --topology

# Custom token budget
node .claude/qoder/qoder-main.js "Fix login bug" --budget 25000

# Run individual modules
node .claude/qoder/qoder-engine.js "Build API"
node .claude/qoder/agent-runtime.js
node .claude/qoder/ide-bridge.js
```

## Architecture

```
User Request
    │
    ▼
┌──────────────────────────────────────┐
│  Qoder Engine (Module 1)             │
│  ┌──────────┐ ┌────────┐ ┌────────┐ │
│  │Decomposer│→│ Router │→│ Merger │ │
│  │(DAG)     │ │(Score) │ │(Fuse)  │ │
│  └──────────┘ └────────┘ └────────┘ │
└──────────────┬───────────────────────┘
               │ Task DAG
               ▼
┌──────────────────────────────────────┐
│  Agent Runtime (Module 2)            │
│  ┌────────┐ ┌───────┐ ┌──────────┐  │
│  │Spawner │→│Comms  │→│ContextMgr│  │
│  └────────┘ └───────┘ └──────────┘  │
└──────────────┬───────────────────────┘
               │ Tool calls
               ▼
┌──────────────────────────────────────┐
│  IDE Bridge (Module 3)               │
│  ┌────────┐ ┌────────┐ ┌─────────┐  │
│  │FileIO  │ │Tools   │ │Presenter│  │
│  └────────┘ └────────┘ └─────────┘  │
└──────────────────────────────────────┘
```

## Key Innovations

1. **Event-sourced DAG**: Every mutation recorded for replay/time-travel debugging
2. **Dynamic topology switching**: Automatically transitions between hierarchical/mesh/pipeline
3. **Context slicing**: TF-IDF relevance scoring ensures agents only get relevant context
4. **Byzantine fault detection**: Real-time detection of misbehaving/malicious agents
5. **Auto-degradation**: DAG self-simplifies when approaching token budget limits

## Integration Points

- Uses existing `router.js` patterns for task-to-agent matching
- Hooks into `SubagentStart`/`SubagentStop` lifecycle events
- Compatible with `TeamCreate`, `SendMessage`, `TaskCreate/TaskUpdate`
- Works alongside adaptive/hierarchical/mesh swarm coordinators
