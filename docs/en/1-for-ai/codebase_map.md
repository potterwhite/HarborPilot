# HarborPilot — Codebase Map (AI Agent Quick Reference)

> **⚠️ FOR AI AGENTS — READ THIS FIRST**
> This document is the single source of truth for codebase structure.
> **Do NOT do a full repo scan** — read this file instead.
>
> **Maintenance rule:** Any AI agent that modifies a file listed here MUST update
> the relevant section in this document in the same commit/session.
>
> Last updated: 2026-06-25 (Jetson Orin NX platform added; rv1126bp libs generalized)
> **Related:** [中文版 →](../../zh/1-for-ai/codebase_map.md)

---

## 1. Repository Root Layout

```
HarborPilot.git/
├── harbor                              ← Top-level entry point: build → tag → push
├── CLAUDE.md                           ← Claude Code session entry point
├── README.md                           ← Project README (EN)
├── CHANGELOG.md                        ← Auto-maintained by release-please
├── LICENSE                             ← MIT
├── release-please-config.json          ← Versioning automation config
│
├── configs/                            ← ★ Three-layer configuration system
│   ├── 1_defaults/                     ←   Layer 1: 6 stage-aligned default files
│   │   ├── 00_global.env               ←     Project version, metadata, SDK versions (stage-independent)
│   │   ├── 01_stage_1st_base.env       ←     OS, user, timezone, locale (stage 1)
│   │   ├── 02_stage_2nd_build.env      ←     BuildKit, dev tools, CUDA, OpenCV versions (stage 2)
│   │   ├── 03_stage_3rd_sdk.env        ←     Registry addresses + SDK switch & paths (stage 3)
│   │   ├── 04_stage_4th_proxy.env      ←     HTTP/HTTPS proxy, default off (stage 4)
│   │   └── 05_stage_5th_runtime.env    ←     Workspace, volumes, Samba, SSH/GDB/NVIDIA (stage 5)
│   ├── platforms/                               ←   Layer 2: per-platform overrides (only differences)
│   │   ├── rk3588-rk3588s_ubuntu-22.04.env      ←     PORT_SLOT=0, Ubuntu 22.04, NVIDIA GPU
│   │   ├── rv1126-rv1126bp_ubuntu-22.04.env      ←     PORT_SLOT=1, Ubuntu 22.04
│   │   ├── rk3568-rk3568_ubuntu-20.04.env        ←     PORT_SLOT=2, Ubuntu 20.04
│   │   ├── rv1126-rv1126_ubuntu-22.04.env        ←     PORT_SLOT=3, Ubuntu 22.04
│   │   ├── rk3568-rk3568_ubuntu-22.04.env        ←     PORT_SLOT=4, Ubuntu 22.04
│   │   ├── rk3588-rk3588s_ubuntu-24.04.env      ←     PORT_SLOT=5, Ubuntu 24.04, no NVIDIA
│   │   ├── rk3588-rk3588s_ubuntu-20.04.env      ←     PORT_SLOT=6, Ubuntu 20.04
│   │   └── jetson-orin-nx-16g-super_ubuntu-22.04.env ← PORT_SLOT=7, Ubuntu 22.04, Jetson cross-compile
│   ├── hosts/                                  ←   Layer 3: host-level overrides (optional, gitignored)
│   │   ├── .gitkeep                            ←     Keeps directory in git
│   │   └── README.md                           ←     Usage documentation
│   └── platform_schema.json            ←   JSON Schema for validating platform .env files
│
├── scripts/                            ← ★ Host-side utilities
│   ├── port_calc.sh                    ←   Port auto-calculation from PORT_SLOT
│   └── create_platform.sh              ←   Interactive + non-interactive platform wizard
│
├── docker/
│   ├── dev-env-clientside/             ← ★ Main build target (5-stage Dockerfile)
│   │   ├── Dockerfile                  ←   Monolithic 5-stage multi-stage build
│   │   ├── build.sh                    ←   Docker build entry: loads 3 layers → build args → build
│   │   ├── stage_1_base/scripts/       ←   Stage 1: apt sources, packages, user creation
│   │   ├── stage_2_tools/scripts/      ←   Stage 2: CUDA, OpenCV, dev tools, Node.js, Python
│   │   ├── stage_3_sdk/                ←   Stage 3: SDK init, helper scripts (templates)
│   │   ├── stage_4_config/             ←   Stage 4: env config, proxy (templates)
│   │   └── stage_5_final/              ←   Stage 5: workspace, entrypoint, tests (templates)
│
├── project_handover/                   ← ★ Client-side deployment package
│   └── clientside/ubuntu/
│       ├── ubuntu_only_entrance.sh     ←   Container lifecycle: start/stop/restart/recreate/remove
│       ├── harbor.crt                  ←   Harbor CA cert (install once per host)
│       └── scripts/                    ←   6 modular helper scripts
│
├── docs/                               ← ★ Documentation (bilingual)
│   ├── en/                             ←   English documentation tree
│   │   ├── assets/                     ←     Images for en docs (dark background)
│   │   ├── 00_INDEX.md                 ←     Navigation hub (EN)
│   │   ├── 1-for-ai/                  ←     AI agent reference files
│   │   ├── 2-progress/                ←     Phase tracking + phase plans
│   │   │   ├── phase4_aso_plan.md     ←       Phase 4: ASO & content distribution plan
│   │   │   └── phase5_mcp_ai_agent_plan.md ← Phase 5: MCP Server & AI Agent plan
│   │   ├── 3-highlights/              ←     Architecture analysis (competitive, config_layers, port-map)
│   │   └── 4-for-beginner/            ←     Quick start guide
│   └── zh/                             ←   Chinese documentation tree
│       ├── assets/                     ←     Images for zh docs (light background)
│       ├── 00_INDEX.md                 ←     Navigation hub (ZH)
│       ├── 1-for-ai/                  ←     AI agent reference files (ZH)
│       ├── 2-progress/                ←     Phase tracking (ZH) + NEED_TO_DO.md
│       │   └── task-logs/             ←       NEED_TO_DO_Archived-<Mon><Day>.<Year>.md files.
│       │                                        RULE: one file per calendar day.
│       │                                        When tasks are done → APPEND to today's archive file.
│       │                                        Do NOT create a second file for the same date.
│       │                                        NEED_TO_DO.md itself is NEVER deleted or git-mv'd.
│       ├── 3-highlights/              ←     Architecture analysis (ZH)
│       ├── 4-for-beginner/            ←     Quick start guide (ZH)
│       └── readme.md                  ←   Chinese README
│
└── .devcontainer/
    └── devcontainer.json               ←   VS Code Dev Container config for HarborPilot dev

[Phase 4 — Planned, not yet created]
mcp/
├── harborpilot_mcp_server.py           ←   MCP server: exposes platforms/config/build to AI
├── requirements.txt                    ←   mcp SDK dependency
├── claude_code_config.json             ←   Ready-to-paste MCP config for Claude Code
└── README.md                           ←   Setup guide + example AI prompts
```

---

## 2. Top-Level Scripts — Detailed Reference

### `harbor` (repo root)
The **master orchestrator**. Interactive host selection → 3-layer config loading → build → tag → push → cleanup.

**Execution flow:**
1. `0_show_main_menu()` — Top-level menu: [1] Build & Push, [2] Package Handover, [3] Configurations
2. `_show_config_menu()` (if Configurations selected) — Create platform, create host (based on existing platform), or back
3. `_select_host_config()` (if Build selected) — Lists host configs with their BASE_PLATFORM, user picks by number. Also offers "Create new host config" wizard.
4. `_load_config_layers()` — Loads all 3 layers:
   - Layer 1: sources all `configs/1_defaults/*.env` in order (00→05)
   - Layer 2: sources platform from `BASE_PLATFORM` in host config (or .env symlink for legacy)
   - Layer 3: sources `configs/3_hosts/$(hostname).env` (overrides platform)
5. `port_calc.sh` — derives SSH/GDB ports from PORT_SLOT
6. `0_check_registry_login()` — Verifies Docker is logged into Harbor; prompts interactive login if not
7. `2_build_images()` → calls `docker/dev-env-clientside/build.sh`
8. `3_prepare_version_info()` — Gets final image ID
9. `4_tag_images()` — Tags with version + latest (local or registry)
10. `5_push_images()` — Pushes + verifies manifest digest
11. `6_cleanup_images()` — Removes intermediate images (keeps final)

**Key behaviors:**
- Each step (build/tag/push/cleanup) has a `prompt_with_timeout` — user can skip with 'n', auto-proceeds after 10s
- `V=1` enables `set -x` for debug
- Registry push includes manifest inspection + SHA256 digest verification

### `scripts/port_calc.sh`
Sourced after Layer 3 in every config loader. Two mutually exclusive modes:
- **MODE A** (recommended): Set `PORT_SLOT` in platform .env → all ports derived:
  - `CLIENT_SSH_PORT = 2109 + PORT_SLOT × 10`
  - `GDB_PORT = 2345 + PORT_SLOT × 10`
- **MODE B** (legacy): Set `CLIENT_SSH_PORT` and `GDB_PORT` explicitly (no PORT_SLOT)
- **Mixing modes → FATAL error** with remediation instructions showing both options
- Validates PORT_SLOT is non-negative integer
- MODE B validates all required ports are present
- Cleans up internal `_*` variables after calculation

### `scripts/create_platform.sh`
Interactive wizard + non-interactive CLI for creating new platform `.env` files.
- **Interactive mode**: `./scripts/create_platform.sh` — color prompts, displays existing platforms with slots, auto-assigns next available PORT_SLOT, shows port preview, asks confirmation
- **Non-interactive mode**: `./scripts/create_platform.sh --non-interactive --name <name> --os <os> --os-version <ver> --harbor-ip <ip> [--port-slot <n>] [--nvidia] [--proxy-http <url>] [--install-cuda] [--install-opencv] [--npm-china-mirror] [--extra-volume <host:container>]` (`--extra-volume` is repeatable for 0..N mounts)
- Validates: name format (`[a-zA-Z0-9_-]+`), no duplicate, PORT_SLOT collision warning
- Generated `.env` includes all sections with proper `${VAR}` self-references

---

## 3. Docker Build Pipeline — Stage by Stage

### `docker/dev-env-clientside/build.sh`
Build entry point. Called by `harbor`.
- `func_1_1_setup_env()` — 3-layer config loading (identical to harbor), collects all env vars into `BUILD_ARGS[]` array. Scans all `.env` files for variable names, reads current (resolved) values.
- Builds with: `docker build --no-cache --progress=plain --network=host`
- Output logged to `build_log.txt`
- Uses `PIPESTATUS[0]` to catch docker build failures through tee

### `docker/dev-env-clientside/Dockerfile`
Single monolithic Dockerfile, 5 stages. Each stage has sub-stages for template processing.

**Stage 1 (`stage_1st_base`):** Base OS setup
- FROM `ubuntu:${OS_VERSION}`
- ~70+ ARGs persisted as ENV for cross-stage propagation
- Runs `setup_base.sh`: apt source replacement (China mirrors), essential packages, user creation, locale, timezone
- **OS-specific**: Ubuntu 24.04 DEB822 apt format; UID/GID 1000 collision handling

**Stage 2 (`stage_2nd_tools`):** Development tools
- `install_dev_tools.sh`: build-essential, cmake, gdb, valgrind, clang, minicom (3 configs), doxygen, git+lfs, Node.js, Python packages
- `install_cuda.sh` (conditional on `INSTALL_CUDA=true`)
- `install_opencv.sh` (conditional on `INSTALL_OPENCV=true`, builds from source with optional CUDA)
- `gitlfs_tracker.sh`: installed to `/usr/local/bin/` — scans large files for Git LFS tracking
- **Platform-specific**: rv1126bp gets extra libs (libmpc-dev, libgmp-dev). OS 20.04 gets Python 2.7.

**Stage 3 (`stage_3rd_sdk`):** SDK initialization
- Template processing: `envsubst` renders `*_template` files
- `install_sdk.sh`: creates SDK dir, git init, adds remote, installs git-lfs, creates symlinks in `/usr/local/bin/` for SDK tools (Qt tools, build tools, debug tools)
- Helper scripts installed to `/usr/local/bin/`: `pull_sdk.sh`, `push_sdk.sh`, `verify_git_config.sh`, `verify_ssh_key.sh`, `version_of_dev_env.sh`, `analyze_dir_structure.sh`
- Only runs if `INSTALL_SDK=true`

**Stage 4 (`stage_4th_config`):** Environment configuration
- `envsubst` renders `env_config.conf_template` → `/etc/profile.d/env_config.sh`
- Conditional proxy: if `HAS_PROXY=true`, renders `proxy.sh_template` → `/etc/profile.d/proxy.sh`
- `configure_env.sh`: copies config to profile.d, sources to verify

**Stage 5 (`stage_5th_final`):** Workspace + entrypoint
- `envsubst` renders `entrypoint.conf_template` → `/etc/entrypoint.conf`
- `envsubst` renders `workspace.conf_template` → `/etc/workspace.conf`
- `setup_workspace.sh`: creates `/development/` with subdirs: `i_src`, `ii_build`, `iii_logs`, `iv_temp`, `v_docs`, `vi_tools`
- `entrypoint.sh`: starts SSH (conditional), prints GDB info (conditional), `exec "$@"`
- Docker labels: BUILD_DATE, VERSION, IMAGE_NAME, PLATFORM
- Tests: `test_permissions.sh` (user exists), `test_workspace.sh` (dirs exist)
- WORKDIR `/development`, CMD `["/bin/bash"]`

---

## 4. Configuration System — Variable Reference

### Layer 1: `configs/1_defaults/` (6 files)

| File | Key Variables | Notes |
|---|---|---|
| `00_global.env` | `VERSION`, `PROJECT_VERSION`, `PROJECT_MAINTAINER`, `PROJECT_RELEASE_DATE`, `SDK_VERSION` | Stage-independent project constants. `VERSION` is auto-bumped by release-please (`x-release-please-version` marker). |
| `01_stage_1st_base.env` | `OS_DISTRIBUTION=ubuntu`, `OS_VERSION=22.04`, `OS_VERSION_ID=22-04`, `DEV_USERNAME=developer`, `DEV_GROUP=developer`, `DEV_UID/GID=1000`, `TIMEZONE=Asia/Hong_Kong`, `DEBIAN_FRONTEND=noninteractive` | `OS_VERSION_ID`: dots-to-dashes, safe for PRODUCT_NAME/CONTAINER_NAME (docker compose forbids dots). Password defaults: `123` |
| `02_stage_2nd_build.env` | `DOCKER_BUILDKIT=1`, `INSTALL_CUDA=false`, `INSTALL_OPENCV=false`, `INSTALL_HOST_CMAKE=true`, `NPM_USE_CHINA_MIRROR=false`, `CUDA_VERSION=12.0`, `OPENCV_VERSION=4.9.0`, `CONAN_VERSION=2.0.17` | Merged from old `02_build.env` + `03_tools.env`. Version pinning for reproducibility. |
| `03_stage_3rd_sdk.env` | `HAVE_GITLAB_SERVER=TRUE`, `HAVE_HARBOR_SERVER=TRUE`, `HARBOR_SERVER_PORT=9000`, `INSTALL_SDK=false`, `SDK_INSTALL_PATH=${WORKSPACE_ROOT}/sdk`, `CHIP_FAMILY=${PRODUCT_NAME}` | Merged from old `05_registry.env` + `06_sdk.env`. `REGISTRY_URL` uses `CHIP_FAMILY` in Layer 3. `CHIP_FAMILY` groups same-silicon variants; `SDK_GIT_KEY_FILE`, `SDK_GIT_DEFAULT_BRANCH` are set per platform (Layer 2); `SDK_GIT_REPO` is computed in Layer 3 (host) because it depends on `GITLAB_SERVER_IP`. |
| `04_stage_4th_proxy.env` | `HAS_PROXY=false`, `HTTP_PROXY_IP`, `HTTPS_PROXY_IP` | Renamed from old `11_proxy.env`. Proxy IPs have defaults but HAS_PROXY is off. |
| `05_stage_5th_runtime.env` | `WORKSPACE_ROOT=/development`, subdirs: `i_src`...`vi_tools`, `WORKSPACE_BUILD_THREADS=4`, `WORKSPACE_LOG_LEVEL=INFO`, `WORKSPACE_DEBUG_PORT=3000`, `VOLUMES_ROOT=${WORKSPACE_ROOT}`, `HOST_VOLUME_DIR`, `SAMBA_*`, `ENABLE_SSH=true`, `ENABLE_GDB_SERVER=true`, `USE_NVIDIA_GPU=false`, `CONTAINER_SHM_SIZE=8g`, `NVIDIA_VISIBLE_DEVICES=all` | Merged from old `04_workspace.env` + `07_volumes.env` + `08_samba.env` + `09_runtime.env`. `HOST_VOLUME_DIR` must be set in platform override. `EXTRA_VOLUME_N` uses `<host>:<container>` format; indices must be contiguous from 0. Ports from port_calc.sh. |

### Layer 2: `configs/2_platforms/<name>.env`

Only override what differs. Required fields: `PRODUCT_NAME`, `OS_VERSION`, `OS_VERSION_ID`, `PORT_SLOT`, `HOST_VOLUME_DIR`.

**Current platforms:**

| Platform file | Slot | CHIP_FAMILY | CHIP_EXTRACT_NAME | PRODUCT_NAME | SSH | GDB | Ubuntu | NVIDIA | Proxy | GitLab |
|---|---|---|---|---|---|---|---|---|---|---|
| `rk3588-rk3588s_ubuntu-22.04` | 0 | rk3588 | rk3588s | rk3588-rk3588s_ubuntu-22-04 | 2109 | 2345 | 22.04 | ✅ | — | — |
| `rv1126-rv1126bp_ubuntu-22.04` | 1 | rv1126 | rv1126bp | rv1126-rv1126bp_ubuntu-22-04 | 2119 | 2355 | 22.04 | — | ✅ | ✅ 192.168.3.67 |
| `rk3568-rk3568_ubuntu-20.04` | 2 | rk3568 | rk3568 | rk3568-rk3568_ubuntu-20-04 | 2129 | 2365 | 20.04 | — | ✅ | ✅ 192.168.3.67 |
| `rv1126-rv1126_ubuntu-22.04` | 3 | rv1126 | rv1126 | rv1126-rv1126_ubuntu-22-04 | 2139 | 2375 | 22.04 | — | ✅ | ✅ 192.168.3.67 |
| `rk3568-rk3568_ubuntu-22.04` | 4 | rk3568 | rk3568 | rk3568-rk3568_ubuntu-22-04 | 2149 | 2385 | 22.04 | — | ✅ | ✅ 192.168.3.67 |
| `rk3588-rk3588s_ubuntu-24.04` | 5 | rk3588 | rk3588s | rk3588-rk3588s_ubuntu-24-04 | 2159 | 2395 | 24.04 | — | ✅ | ✅ 192.168.3.67 |
| `rk3588-rk3588s_ubuntu-20.04` | 6 | rk3588 | rk3588s | rk3588-rk3588s_ubuntu-20-04 | 2169 | 2405 | 20.04 | — | — | — |
| `jetson-orin-nx-16g-super_ubuntu-22.04` | 7 | jetson | orin-nx-16g-super | jetson-orin-nx-16g-super_ubuntu-22-04 | 2179 | 2415 | 22.04 | — | ✅ | ✅ 192.168.3.67 |

### `configs/platform_schema.json`
JSON Schema for platform `.env` validation. Required: `PRODUCT_NAME`, `OS_VERSION`, `OS_VERSION_ID`, `PORT_SLOT`. Defines enums (OS_VERSION: 20.04/22.04/24.04/11/12), ranges (PORT_SLOT: 0–99), patterns (PRODUCT_NAME: `[a-zA-Z0-9_-]+`). Conditional: if `HAVE_GITLAB_SERVER=TRUE` → requires `GITLAB_SERVER_IP` + `GITLAB_SERVER_PORT`. `additionalProperties: true`.

---

## 5. Client-Side Deployment

### `project_handover/clientside/ubuntu/ubuntu_only_entrance.sh`
Container lifecycle manager. Commands: `start`/`stop`/`restart`/`recreate`/`remove`/`-h`.

**Key behavior:**
- `1_0_gen_environment_variables()` — Loads same 3-layer config as `harbor` + `port_calc.sh`
- `3_3_generate_compose_config()` — Dynamically generates `docker-compose.yaml` from env vars:
  - Image: `${REGISTRY_URL}/${IMAGE_NAME}:latest` (or local if no registry)
  - Ports: `${CLIENT_SSH_PORT}:22` and `${GDB_PORT}:${GDB_PORT}`
  - Conditional NVIDIA GPU: `deploy.resources.reservations.devices` with `nvidia` driver
  - Samba CIFS volume mount
  - TTY + privileged + USB passthrough
- `start` → interactive menu: enter running container / restart / recreate
- `1_2_check_docker_login()` — Harbor login with retry
- `2_4_retrieve_latest_image()` — Pull from registry

---

## 6. SDK Helper Scripts (installed to `/usr/local/bin/`)

| Script | Purpose |
|---|---|
| `pull_sdk.sh` | Pull SDK from git: single branch or all branches, safety checks (clean workdir, remote URL match) |
| `push_sdk.sh` | Push SDK changes: status check, branch creation, interactive confirmation |
| `verify_git_config.sh` | Verify/set git user.name and user.email interactively |
| `verify_ssh_key.sh` | Verify/initialize SSH keys for SDK access, updates `~/.ssh/config` |
| `version_of_dev_env.sh` | Print dev env version and release date |
| `analyze_dir_structure.sh` | SDK directory analysis: top 20 largest files, dir sizes, extension stats |
| `gitlfs_tracker.sh` | Scan for large files, auto-track with Git LFS (default threshold: 100MB) |

---

## 7. Versioning & Release

- **release-please** manages `CHANGELOG.md` and version bumps
- Config: `release-please-config.json` — `release-type: simple`
- Version source of truth: `VERSION` in `configs/1_defaults/00_global.env`
- `x-release-please-version` marker enables auto-bump
- Changelog sections: feat→✨, fix→🐛, perf→⚡, revert→🔙. Docs/style/chore/refactor hidden.
- `.devcontainer/devcontainer.json` — VS Code Dev Container for developing HarborPilot itself (not for end users). Forwards ports 2109+2345, installs C++ / CMake / Python / Git extensions.

---

## 8. Key Architectural Patterns

1. **Three-Layer Config Inheritance** — Defaults provide sensible values for 90% of variables. Platform files only override the differences. Adding a new platform requires ~15–20 lines. Host-level overrides (Layer 3, optional) allow per-machine customization without duplicating platform configs.

2. **PORT_SLOT-Based Port Allocation** — A single integer determines all port mappings. Prevents port collisions between platforms. Formula is defined once in `port_calc.sh` and referenced everywhere.

3. **Template → envsubst → Final File** — `*_template` files use `${VAR}` placeholders. A template-processor intermediate stage in the Dockerfile runs `envsubst` with all build args exported. This replaces the previous error-prone `sed` approach.

4. **Config as the Single Source of Truth** — No script contains hardcoded platform-specific values. Everything flows from the 3-layer config. Changing a default propagates to all platforms automatically.

5. **Dynamic docker-compose Generation** — `ubuntu_only_entrance.sh` writes `docker-compose.yaml` from shell variables at runtime, enabling NVIDIA GPU support and platform-specific port mappings without manual compose editing.

6. **Conditional Feature Installation** — CUDA, OpenCV, Python 2.7, npm China mirrors, proxy — all gated by boolean env vars. The Dockerfile checks these and skips irrelevant stages, keeping images small for platforms that don't need them.
