---
name: swarm-triple-orchestrator
type: coordinator
description: Swarm orchestrator for triple collaboration pattern
topology: hierarchical-mesh
maxAgents: 6
strategy: triple
memory: hybrid
hnsw: true
neural: true
---

# Triple Collaboration Swarm Orchestrator

## Architecture

```
                    ┌─────────────────┐
                    │   Orchestrator  │
                    │    (Judge)      │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
         ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
         │  Red   │    │  Blue   │    │ Memory  │
         │  Team  │    │  Team   │    │  Store  │
         └────────┘    └────────┘    └────────┘
```

## Execution Flow

### 1. Initialize Swarm
```bash
npx @claude-flow/cli@latest swarm init \
  --topology hierarchical-mesh \
  --max-agents 6 \
  --strategy triple
```

### 2. Spawn Agents
```bash
# Spawn Red Team
mcp__claude-flow__agent_spawn red-team --name="red-${SWARM_ID}"

# Spawn Blue Team
mcp__claude-flow__agent_spawn blue-team --name="blue-${SWARM_ID}"
```

## MCP Tools Used

| Tool | Purpose |
|------|---------|
| `swarm_init` | Initialize hierarchical-mesh swarm |
| `agent_spawn` | Create red/blue team agents |
| `memory_store` | Share findings between agents |
