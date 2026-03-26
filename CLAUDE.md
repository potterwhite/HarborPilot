# CLAUDE.md

This file provides essential guidance to Claude Code when working in this repository.
**For full context, always start by reading the docs** (see below).

## ⚠️ Session Start Protocol

**Before writing any code**, read these two files in order:

1. `docs/architecture/1-for-ai/guide.md` — working rules, commit format, key architecture facts
2. `docs/architecture/1-for-ai/codebase_map.md` — full codebase map (do NOT scan files instead)

Then check `docs/architecture/2-progress/progress.md` for current phase status.

Do **not** scan `docker/`, `scripts/`, or `configs/` before reading the above.

---

## Requirements

- All source code and comments must be in **English**
- Communicate with me in **Chinese**
- Do not end the session arbitrarily — always prompt the user for next steps

---

## Commands

```bash
# Build a platform image (interactive platform selection)
./harbor

# Start dev container (on client Ubuntu host)
./project_handover/clientside/ubuntu/ubuntu_only_entrance.sh start

# Create a new platform config (interactive wizard)
./scripts/create_platform.sh

# Create a new platform config (non-interactive, AI/CI-friendly)
./scripts/create_platform.sh --non-interactive \
    --name <name> --os <ubuntu|debian> --os-version <ver> \
    --harbor-ip <ip> [--port-slot <n>]

# Debug mode (verbose output)
V=1 ./harbor
```

---

## Documentation Map

| Need | File |
|---|---|
| Working rules + commit format | `docs/architecture/1-for-ai/guide.md` |
| Codebase structure | `docs/architecture/1-for-ai/codebase_map.md` |
| Phase progress + roadmap | `docs/architecture/2-progress/progress.md` |
| Active task backlog | `docs/architecture/2-progress/NEED_TO_DO.md` |
| Architecture vision + decisions | `docs/architecture/3-highlights/refactoring_plan.md` |
| Config system deep-dive | `docs/config_layers.md` |
