---
title: "HarborPilot Phase 4 — MCP Server & AI Agent Integration"
author: "PotterWhite + Claude"
date: "2026-03-27"
tags:
  - mcp
  - ai-agent
  - phase4
  - roadmap
status: "Draft — pending approval"
---

# HarborPilot Phase 4 — MCP Server & AI Agent Integration

> **Related:** [中文版 →](../../zh/2-progress/phase4_mcp_ai_agent_plan.md)
>
> **Goal**: Make HarborPilot the first-class interface between AI coding agents
> (Claude, Cursor, Copilot) and embedded Linux dev environment provisioning.
>
> **Priority order** (from NEED_TO_DO.md):
> 1. AI Agent can **read and use** HarborPilot (primary)
> 2. AI can **recommend** HarborPilot to others (secondary)
> 3. Human can **git clone and self-configure** (tertiary — already works today)

---

## 1. What is MCP? (Model Context Protocol — Plain Explanation)

### 1.1 The Core Problem MCP Solves

AI assistants like Claude know a lot, but they can't *do* things in your environment
unless they have a structured interface. Before MCP existed, connecting an AI to a tool
required custom API wrappers, system prompts full of instructions, or brittle shell
command injection.

**MCP is the standardized protocol for this connection.**

Think of it like this:
```
Without MCP:   AI (natural language) → ???  → your tool
With MCP:      AI (natural language) → MCP client → MCP server → your tool
```

### 1.2 Architecture (Three Roles)

```
┌─────────────────────────────────────────────────┐
│  AI Host (e.g., Claude Code, Cursor, Copilot)  │
│                                                  │
│   ┌─────────────┐                               │
│   │  MCP Client │◄──── built into the AI tool   │
│   └──────┬──────┘                               │
└──────────┼──────────────────────────────────────┘
           │ JSON-RPC over stdio / HTTP/SSE
           ▼
┌─────────────────────────────────────────────────┐
│  MCP Server  (you build this)                   │
│                                                  │
│   Exposes:                                       │
│   • Tools    → functions the AI can call        │
│   • Resources → files/data the AI can read      │
│   • Prompts  → reusable prompt templates        │
└─────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────┐
│  HarborPilot (your existing system)             │
│  • configs/*.env files                          │
│  • ./harbor script                              │
│  • create_platform.sh                          │
│  • ubuntu_only_entrance.sh                     │
└─────────────────────────────────────────────────┘
```

**The MCP Server is the adapter layer.** It translates AI intent into HarborPilot operations.

### 1.3 What MCP Is NOT

- MCP is **not** a new AI model — it's a communication protocol
- MCP is **not** a cloud service — it runs locally on your machine
- MCP is **not** invasive — your existing code doesn't change; you add a thin server on top

### 1.4 Transport Mechanisms

| Mode | How | Use Case |
|---|---|---|
| `stdio` | AI launches server as subprocess, communicates via stdin/stdout | Local tools (default for Claude Code) |
| `HTTP + SSE` | Server runs as HTTP daemon; AI connects to it | Remote/shared servers |

For HarborPilot, **stdio** is the natural choice: the MCP server runs locally on the
developer's Ubuntu machine, same machine running Docker.

### 1.5 What the AI Can Do via MCP

Once a MCP server is connected to Claude Code or Cursor, the AI can:
- **List platforms**: "Show me all configured platforms"
- **Read config**: "What is the CUDA version for rk3588s?"
- **Modify config**: "Enable CUDA for rk3568-ubuntu22"
- **Create platform**: "Create a new RK3566 Debian 12 platform at port slot 6"
- **Trigger build**: "Build the rk3588s image"
- **Check status**: "Is the rk3588s image pushed to the registry?"

All of this through natural language — no manual file editing required.

---

## 2. Why HarborPilot is Exceptionally Well-Suited for MCP

Most tools require significant refactoring to become MCP-compatible. HarborPilot
already has the right architecture:

| Property | Why It Matters for MCP |
|---|---|
| **Key=value `.env` config** | Trivially readable and writable by an MCP server |
| **Non-interactive mode** (`create_platform.sh --non-interactive`) | MCP tools need CLI commands that don't block on user input |
| **JSON Schema** (`configs/platform_schema.json`) | AI can validate config before calling build |
| **Three-layer inheritance** | AI only needs to write 15 lines to create a new platform |
| **PORT_SLOT formula** | AI can safely assign ports without collision risk |
| **Deterministic build** (`./harbor` with symlinks) | MCP tool calls are reproducible |

**HarborPilot needs almost zero refactoring to become MCP-compatible.** The work is
writing the MCP server adapter, not changing the underlying system.

---

## 3. Phase 4 Implementation Plan

### Phase 4.1 — MCP Server Scaffold (Step 1)

**Goal**: A minimal MCP server that exposes HarborPilot's config as **Resources**.

**What to build**:
- `mcp/harborpilot_mcp_server.py` — Python MCP server using the `mcp` SDK
- Expose all `.env` files as readable Resources
- Expose `platform_schema.json` as a Resource
- Expose `codebase_map.md` and `guide.md` as Resources (AI context injection)

**Why Python**: The official MCP SDK (`mcp` package) has the best Python support.
Node.js is also well-supported. Bash is not (no official SDK).

**Installation**:
```bash
pip install mcp
# or
uv add mcp
```

**Server skeleton** (stdio transport):
```python
#!/usr/bin/env python3
"""HarborPilot MCP Server — exposes config and build tools to AI agents."""

import json
import subprocess
from pathlib import Path
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp import types

REPO_ROOT = Path(__file__).parent.parent
CONFIG_DIR = REPO_ROOT / "configs"
PLATFORMS_DIR = CONFIG_DIR / "platforms"

app = Server("harborpilot")

@app.list_resources()
async def list_resources():
    resources = []
    # Expose all platform .env files
    for env_file in PLATFORMS_DIR.glob("*.env"):
        resources.append(types.Resource(
            uri=f"harborpilot://platforms/{env_file.stem}",
            name=f"Platform: {env_file.stem}",
            description=f"Platform config for {env_file.stem}",
            mimeType="text/plain",
        ))
    return resources

@app.read_resource()
async def read_resource(uri: str):
    if uri.startswith("harborpilot://platforms/"):
        platform = uri.removeprefix("harborpilot://platforms/")
        env_path = PLATFORMS_DIR / f"{platform}.env"
        if env_path.exists():
            return types.TextResourceContents(
                uri=uri,
                mimeType="text/plain",
                text=env_path.read_text(),
            )
    raise ValueError(f"Unknown resource: {uri}")

if __name__ == "__main__":
    import asyncio
    asyncio.run(stdio_server(app))
```

**Deliverables**:
- `mcp/harborpilot_mcp_server.py`
- `mcp/requirements.txt` (or `pyproject.toml`)
- `mcp/README.md` — how to connect to Claude Code / Cursor

**Commit target**: `feat: add MCP server scaffold with platform config resources`

---

### Phase 4.2 — MCP Tools: Read Operations (Step 2)

**Goal**: AI can query the current state of platforms and config without modifying anything.

**Tools to expose**:

| Tool Name | Arguments | Returns |
|---|---|---|
| `list_platforms` | — | Array of `{name, chip_family, chip_extract, os_version, port_slot, ssh_port, gdb_port}` |
| `get_platform_config` | `platform_name: str` | Full parsed key=value config dict |
| `get_defaults` | `layer: "base"\|"tools"\|...` | Key=value dict for that defaults file |
| `check_port_slot_available` | `slot: int` | `{available: bool, conflicts_with: str\|null}` |
| `validate_platform_config` | `config_dict: dict` | `{valid: bool, errors: list[str]}` |

**Implementation note**: Tools call existing shell utilities where possible:
```python
@app.call_tool()
async def call_tool(name: str, arguments: dict):
    if name == "list_platforms":
        return _parse_all_platforms()
    elif name == "get_platform_config":
        return _parse_env_file(PLATFORMS_DIR / f"{arguments['platform_name']}.env")
    # ...
```

**Commit target**: `feat: add MCP read tools (list_platforms, get_platform_config, validate)`

---

### Phase 4.3 — MCP Tools: Write Operations (Step 3)

**Goal**: AI can create new platforms and modify existing config.

**Tools to expose**:

| Tool Name | Arguments | Action |
|---|---|---|
| `create_platform` | `name, os, os_version, harbor_ip, port_slot, [nvidia, proxy, cuda, opencv]` | Calls `create_platform.sh --non-interactive` |
| `set_platform_variable` | `platform_name, variable, value` | Modifies a single variable in the platform `.env` |
| `enable_feature` | `platform_name, feature: "cuda"\|"opencv"\|"proxy"\|"nvidia"` | Sets relevant vars to true/configured |

**Safety constraints** (built into the MCP server, not the shell scripts):
- `create_platform` checks for PORT_SLOT collision before calling the script
- `set_platform_variable` validates against JSON Schema before writing
- Write operations produce a diff summary that the AI returns to the user for confirmation

**Commit target**: `feat: add MCP write tools (create_platform, set_variable, enable_feature)`

---

### Phase 4.4 — MCP Tools: Build Operations (Step 4)

**Goal**: AI can trigger builds and check results.

**Tools to expose**:

| Tool Name | Arguments | Action |
|---|---|---|
| `build_platform` | `platform_name: str, dry_run: bool=True` | Calls `./harbor` in non-interactive mode |
| `check_image_exists` | `platform_name: str` | Checks local Docker images for the platform |
| `get_build_log` | `platform_name: str` | Returns last `build_log.txt` contents |

**Critical design decision — `dry_run` default**:

Build operations are **slow and irreversible**. The MCP tool should:
1. Default to `dry_run=True` — validate config and show what *would* be built
2. Require explicit `dry_run=False` to actually trigger the build
3. Return estimated build time based on platform features (CUDA/OpenCV add ~30min)

**Non-interactive `./harbor` mode** (prerequisite):
The current `./harbor` script uses interactive prompts (`prompt_with_timeout`). For MCP
calls, these must be bypassable. Implementation options:
- **Option A**: Add `--yes` flag to `./harbor` that auto-confirms all prompts
- **Option B**: Set `HARBORPILOT_NON_INTERACTIVE=1` env var that the script checks

Option B is less invasive (no flag parsing changes).

**Commit target**: `feat: add MCP build tools (build_platform dry_run, check_image, get_log)`

---

### Phase 4.5 — Claude Code Integration & Documentation (Step 5)

**Goal**: A developer can say "add HarborPilot MCP server" in Claude Code and be running
in under 5 minutes.

**Deliverables**:

1. **`mcp/claude_code_config.json`** — ready-to-paste MCP config for Claude Code:
```json
{
  "mcpServers": {
    "harborpilot": {
      "command": "python3",
      "args": ["/path/to/HarborPilot.git/mcp/harborpilot_mcp_server.py"],
      "env": {}
    }
  }
}
```

2. **`mcp/README.md`** — setup guide covering:
   - Prerequisites (Python 3.10+, `pip install mcp`)
   - Claude Code setup (`claude mcp add`)
   - Cursor setup (MCP config location)
   - Example prompts that work well with the server

3. **Prompt examples** (ship with the server as MCP Prompts):
   - "List all platforms and show their port assignments"
   - "Create a new RK3566 Debian 12 platform"
   - "Check if the rk3588s image is up to date in the registry"
   - "Enable CUDA for rk3568-ubuntu22 and rebuild"

4. **`docs/en/2-progress/progress.md`** — update Phase 4 status

**Commit target**: `feat: add Claude Code MCP integration guide and example prompts`

---

## 4. What NOT to Build in Phase 4

| Idea | Why Skip It |
|---|---|
| Web UI / dashboard | Not in scope — HarborPilot is a CLI tool; a UI is a separate product |
| Cloud-hosted MCP server | Security risk (credentials in `.env`); local stdio is sufficient |
| Automatic image publishing on MCP call | Too dangerous without explicit user confirmation |
| MCP server that rewrites Dockerfiles | Out of scope; config layer is the right abstraction |
| Support for non-Claude AI tools | The MCP protocol is universal; Claude Code support covers Cursor/Copilot too |

---

## 5. Future: "AI Recommends HarborPilot" (Phase 5 Concept)

This is the NEED_TO_DO item: "AI can recommend HarborPilot to others."

Current thinking (not scheduled for Phase 4):

### 5.1 Discoverability via MCP Registries
Anthropic and the community maintain MCP server registries (similar to npm/PyPI for MCP
servers). Publishing `harborpilot-mcp` to these registries means:
- An AI assistant can suggest "I found an MCP server for embedded Linux dev environments"
- Claude Code users can browse available MCP servers

### 5.2 README + GitHub Topic Tags
The most reliable way to be "recommended by AI":
- AI models are trained on GitHub data
- Correct `README.md` keywords + `topics` in `github.com/...` settings signal what the
  tool does to both humans and AI training data
- Topics to add: `embedded-linux`, `docker`, `devenv`, `cross-compilation`, `rockchip`,
  `mcp-server`

### 5.3 This is a Phase 5 Item
Phase 4 builds the technical capability. Phase 5 is marketing/discoverability.
Do not mix them — build it first, market it second.

---

## 6. Phase 4 Timeline and Commit Plan

| Step | Description | Est. Commits | Prerequisite |
|---|---|---|---|
| **4.1** | MCP server scaffold + Resources | 1 | Python 3.10+, `mcp` SDK |
| **4.2** | Read tools (list, get, validate) | 1 | 4.1 |
| **4.3** | Write tools (create, modify) | 1-2 | 4.2, `create_platform.sh --non-interactive` (✅ done) |
| **4.4** | Build tools (dry_run first) | 1-2 | 4.3, `harbor --yes` or `HARBORPILOT_NON_INTERACTIVE` |
| **4.5** | Claude Code integration guide | 1 | 4.4 |

**Total estimated commits**: 6–8

**Phase 4 success criteria**:
- A developer can open Claude Code, say "show me my HarborPilot platforms", and get a
  formatted list — without typing any commands
- A developer can say "create a new RK3566 Debian 12 platform at port slot 6" and
  Claude Code creates the `.env` file correctly
- The MCP server README has a 5-minute setup guide that works on first try

---

## 7. Files to Create/Modify in Phase 4

| File | Action | Notes |
|---|---|---|
| `mcp/harborpilot_mcp_server.py` | Create | Main server implementation |
| `mcp/requirements.txt` | Create | `mcp>=1.0.0` |
| `mcp/claude_code_config.json` | Create | Ready-to-paste config snippet |
| `mcp/README.md` | Create | Setup guide + example prompts |
| `harbor` | Modify | Add `HARBORPILOT_NON_INTERACTIVE` check to bypass prompts |
| `docs/en/2-progress/progress.md` | Modify | Add Phase 4 section |
| `docs/en/00_INDEX.md` | Modify | Add `mcp/README.md` entry |
| `docs/en/1-for-ai/codebase_map.md` | Modify | Add `mcp/` directory section |

---

## 8. For the Next AI Agent: How to Start Phase 4

If you are an AI agent starting Phase 4 implementation, do this in order:

1. Read `docs/en/1-for-ai/guide.md` and `codebase_map.md` (session protocol)
2. Check `progress.md` — if Phase 4 Step X is marked ✅, skip to Step X+1
3. Install the MCP SDK: `pip install mcp` (or `uv add mcp`)
4. Start with **Phase 4.1** — scaffold only, no tools yet
5. Test: `python3 mcp/harborpilot_mcp_server.py` should start without error
6. Then proceed to 4.2 (read tools), commit, test, then 4.3, etc.
7. **One commit per step** — do not accumulate changes

The fastest path to a working demo is Phase 4.1 + 4.2 (read-only). This is safe to
ship immediately and delivers immediate value to Claude Code users.
