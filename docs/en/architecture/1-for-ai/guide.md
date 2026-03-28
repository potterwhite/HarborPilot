# HarborPilot — AI Agent Guide

> **Target audience:** AI coding agents (Claude Code, Cursor, etc.)
> **Read this before touching any code.**
> **Related:** [中文版 →](../../../../zh/architecture/1-for-ai/guide.md)

---

## 1. Reading Order (every session)

1. **This file** — understand how to work in this repo
2. **[`codebase_map.md`](codebase_map.md)** — full codebase structure (replaces scanning, saves 50%+ time)
3. **[`../2-progress/progress.md`](../2-progress/progress.md)** — current phase status and active tasks
4. **Relevant reference doc** — only if your task requires it (`../config_layers.md`, etc.)

---

## 2. Non-Negotiable Rules

### Code
- All source code and comments must be in **English**
- Communicate with the human in **Chinese**
- Do **not** end the session — always prompt the user for next steps

### Commits
- **One commit per STEP** — do not accumulate changes and commit at the end
- Follow the commit message format below exactly
- Never commit broken code or untested changes

### Documentation
- After modifying any file listed in `codebase_map.md`, update that file in the same commit
- When a phase step is completed, update the status in `progress.md`

---

## 3. Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

**Type** (required): `feat` · `fix` · `docs` · `refactor` · `perf` · `test` · `build` · `chore`

**Subject** (required): English, ≤70 chars, present tense, no leading capital
- ✅ `fix: handle pre-existing UID/GID in func_create_user for Ubuntu 24.04`
- ✅ `feat: add --non-interactive mode to create_platform.sh`
- ✅ `refactor: replace sed template rendering with envsubst in all 3 stages`
- ❌ `Fixed bugs and updated stuff`

**Body** (recommended): bullet points explaining what and why

**Footer** (recommended): `Phase X.Y Step Z complete.`

---

## 4. How to Handle Human Requests

### "Build a new feature"
1. Ask clarifying questions (affected scripts, config changes, platform impact)
2. Write a plan in `docs/architecture/` — **no code yet**
3. Wait for approval
4. Implement step by step, one commit per step

### "There's a bug"
1. Reproduce and understand the root cause
2. Fix it — test across affected platforms (check OS_VERSION conditionals)
3. Commit with `fix:` prefix

### "Refactor / optimize something"
1. Write a refactor plan in `docs/architecture/`
2. Wait for approval
3. Execute step by step

### "Add a new platform"
1. Use `create_platform.sh --non-interactive` or the wizard
2. Verify PORT_SLOT does not collide with existing platforms
3. Test build with `./harbor` (or at minimum verify config loads cleanly)

---

## 5. Common Pitfalls

| ❌ Wrong | ✅ Right |
|---|---|
| Edit 10 files then do one big commit | Commit after each logical step |
| Start coding without reading codebase_map | Read codebase_map first |
| Edit code, forget to update codebase_map | Always sync codebase_map in same commit |
| Vague commit message "fix bugs" | Specific: `fix: handle pre-existing UID/GID in func_create_user` |
| Hardcode a port number in a script | Use PORT_SLOT and port_calc.sh for all port derivation |
| Hardcode platform-specific values in defaults/ | Put overrides in `configs/platforms/<name>.env` only |
| Add a new config variable only to one platform | Add default in `configs/defaults/`, override per-platform |
| Modify a `*_template` file without testing envsubst | Always verify rendered output matches intent |
| Forget OS_VERSION conditionals | Ubuntu 20.04 / 22.04 / 24.04 have different packages and apt formats |
| Use `sed` for template rendering | Use `envsubst` — the sed-based system has been removed |
| Use `OS_VERSION` in PRODUCT_NAME / CONTAINER_NAME | Use `OS_VERSION_ID` (dots→dashes) — docker compose forbids dots in project names |

---

## 6. Key Architecture Facts

1. **Three-Layer Config Inheritance**: `configs/defaults/*.env` (Layer 1, global) → `configs/platform-independent/common.env` (Layer 2, project constants) → `configs/platforms/<platform>.env` (Layer 3, overrides). Last layer wins. A platform file only contains what **differs** from defaults.

2. **PORT_SLOT is the single source of port truth**: `CLIENT_SSH_PORT = 2109 + PORT_SLOT × 10`, `GDB_PORT = 2345 + PORT_SLOT × 10`. Calculated by `scripts/port_calc.sh`. Never hardcode ports — always set PORT_SLOT.

3. **Template rendering uses `envsubst`**: All `*_template` files in stages 3/4/5 are rendered via `envsubst` (from `gettext-base`). The `sed`-based system has been removed.

4. **5-Stage Dockerfile**: `stage_1st_base` (OS + packages + user) → `stage_2nd_tools` (CUDA, OpenCV, dev tools) → `stage_3rd_sdk` (SDK init + helper scripts) → `stage_4th_config` (env vars + proxy) → `stage_5th_final` (workspace + entrypoint + labels).

5. **`harbor` is the top-level orchestrator**: Loads all 3 config layers, runs `port_calc.sh`, then calls `build.sh` → tag → push → cleanup. It is the only entry point for builds.

6. **`ubuntu_only_entrance.sh` is the client entry point**: Loads the same 3 config layers, dynamically generates `docker-compose.yaml` from env vars (including conditional NVIDIA GPU), manages container lifecycle (`start`/`stop`/`restart`/`recreate`/`remove`).

7. **Platform configs use `${VAR}` self-references**: e.g. `IMAGE_NAME="${PRODUCT_NAME}-dev-env"`. These are bash variable expansions evaluated at `source` time, not template placeholders.

8. **Versioning is automated**: `release-please` bumps `VERSION` in `configs/platform-independent/common.env` (via `x-release-please-version` marker) and maintains `CHANGELOG.md`.

9. **OS-specific conditionals are critical**: Ubuntu 24.04 uses DEB822 apt format. Ubuntu 20.04 needs `libncurses5-dev` not `libncurses-dev`. `bsdextrautils` is not available on 20.04. UID 1000 is pre-occupied on 24.04. Always check OS_VERSION in any package-related code.

10. **`docker/libs/` has been removed**: The directory contained deprecated code (old `setup_base.sh`, `sed`-based template processor, unused `.df` Dockerfile modules). All functionality now lives in the stage-specific scripts under `docker/dev-env-clientside/`.

---

## 7. Development Commands

```bash
# Build a platform image (interactive selection)
./harbor

# Start dev container on client Ubuntu host
./project_handover/clientside/ubuntu/ubuntu_only_entrance.sh start

# Container lifecycle: stop / restart / recreate / remove
./project_handover/clientside/ubuntu/ubuntu_only_entrance.sh <command>

# Create a new platform (interactive wizard)
./scripts/create_platform.sh

# Create a new platform (non-interactive, AI/CI-friendly)
./scripts/create_platform.sh --non-interactive \
    --name rk3566-debian12 --os debian --os-version 12 \
    --harbor-ip 192.168.3.68 --port-slot 6

# Debug mode (verbose)
V=1 ./harbor

# Validate platform config schema
# (use platform_schema.json with any JSON Schema validator)
```
