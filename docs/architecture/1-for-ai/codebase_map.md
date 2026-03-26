# HarborPilot — Codebase Map (AI Agent Quick Reference)

> **⚠️ FOR AI AGENTS — READ THIS FIRST**
> This document is the single source of truth for codebase structure.
> **Do NOT do a full repo scan** — read this file instead.
>
> **Maintenance rule:** Any AI agent that modifies a file listed here MUST update
> the relevant section in this document in the same commit/session.
>
> Last updated: 2026-03-26 (initial creation — full file-by-file reference)

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
│   ├── defaults/                       ←   Layer 1: 11 domain-scoped default files
│   │   ├── 01_base.env                 ←     OS, user, timezone, locale
│   │   ├── 02_build.env                ←     Docker BuildKit settings
│   │   ├── 03_tools.env                ←     Dev tool switches & versions (CUDA, OpenCV, Node…)
│   │   ├── 04_workspace.env            ←     Workspace directory structure & build settings
│   │   ├── 05_registry.env             ←     Harbor / GitLab server addresses
│   │   ├── 06_sdk.env                  ←     SDK install switch (default: false)
│   │   ├── 07_volumes.env              ←     Docker volume root path
│   │   ├── 08_samba.env                ←     Samba share credentials
│   │   ├── 09_runtime.env              ←     SSH / GDB / syslog / NVIDIA switches
│   │   └── 11_proxy.env                ←     HTTP/HTTPS proxy (default: off)
│   ├── platform-independent/
│   │   └── common.env                  ←   Layer 2: project version, maintainer, dates
│   ├── platforms/                      ←   Layer 3: per-platform overrides (only differences)
│   │   ├── rk3588s.env                 ←     PORT_SLOT=0, Ubuntu 24.04, NVIDIA GPU
│   │   ├── rv1126bp.env                ←     PORT_SLOT=1, Ubuntu 22.04
│   │   ├── rk3568.env                  ←     PORT_SLOT=2, Ubuntu 20.04
│   │   ├── rv1126.env                  ←     PORT_SLOT=3, Ubuntu 22.04
│   │   ├── rk3568-ubuntu22.env         ←     PORT_SLOT=4, Ubuntu 22.04
│   │   └── rk3588s-ubuntu-24.env       ←     PORT_SLOT=5, Ubuntu 24.04, no NVIDIA
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
│   ├── clientside/ubuntu/
│   │   ├── ubuntu_only_entrance.sh     ←   Container lifecycle: start/stop/restart/recreate/remove
│   │   ├── docker-compose.yaml         ←   Static example (actual compose is generated dynamically)
│   │   └── harbor.crt                  ←   Harbor CA cert (install once per host)
│   └── scripts/
│       └── archive_tarball.sh          ←   Package handover as tar.gz
│
├── docs/                               ← ★ Documentation
│   ├── architecture/
│   │   ├── 00_INDEX.md                 ←   Navigation hub
│   │   ├── 1-for-ai/                  ←   AI agent reference files
│   │   ├── 2-progress/                ←   Phase tracking
│   │   └── 3-highlights/              ←   Architecture decisions & analysis
│   ├── config_layers.md               ←   Three-layer config explained (EN)
│   ├── config_layers_cn.md            ←   Three-layer config explained (ZH)
│   ├── quick_start.md                 ←   Setup guide (EN)
│   ├── quick_start_cn.md              ←   Setup guide (ZH)
│   ├── port-map-calculation.md        ←   Port formula documentation
│   └── readme_cn.md                   ←   Chinese README
│
└── .devcontainer/
    └── devcontainer.json               ←   VS Code Dev Container config for HarborPilot dev
```

---

## 2. Top-Level Scripts — Detailed Reference

### `harbor` (repo root)
The **master orchestrator**. Interactive platform selection → 3-layer config loading → build → tag → push → cleanup.

**Execution flow:**
1. `1_specify_platform()` — Lists platforms sorted by PORT_SLOT, user picks by number. Also offers "Create new platform" which calls `create_platform.sh`.
2. Layer 1: sources all `configs/defaults/*.env` in order (01→11)
3. Layer 2: sources `common.env`
4. Layer 3: sources selected `<platform>.env`
5. `port_calc.sh` — derives SSH/GDB ports from PORT_SLOT
6. `0_check_registry_login()` — Verifies Docker is logged into Harbor; prompts interactive login if not
7. `1_1_setup_volume_soft_link()` — Symlinks HOST_VOLUME_DIR
8. `2_build_images()` → calls `docker/dev-env-clientside/build.sh`
9. `3_prepare_version_info()` — Gets final image ID
10. `4_tag_images()` — Tags with version + latest (local or registry)
11. `5_push_images()` — Pushes + verifies manifest digest
12. `6_cleanup_images()` — Removes intermediate images (keeps final)

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
- **Non-interactive mode**: `./scripts/create_platform.sh --non-interactive --name <name> --os <os> --os-version <ver> --harbor-ip <ip> [--port-slot <n>] [--nvidia] [--proxy-http <url>] [--install-cuda] [--install-opencv] [--npm-china-mirror]`
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

### Layer 1: `configs/defaults/` (11 files)

| File | Key Variables | Notes |
|---|---|---|
| `01_base.env` | `OS_DISTRIBUTION=ubuntu`, `OS_VERSION=22.04`, `DEV_USERNAME=developer`, `DEV_UID/GID=1000`, `TIMEZONE=Asia/Hong_Kong` | Password defaults: `123` |
| `02_build.env` | `DOCKER_BUILDKIT=1` | Single variable |
| `03_tools.env` | `INSTALL_CUDA=false`, `INSTALL_OPENCV=false`, `INSTALL_HOST_CMAKE=true`, `NPM_USE_CHINA_MIRROR=false`, `CUDA_VERSION=12.0`, `OPENCV_VERSION=4.9.0`, `CONAN_VERSION=2.0.17` | Version pinning for reproducibility |
| `04_workspace.env` | `WORKSPACE_ROOT=/development`, subdirs: `i_src`…`vi_tools`, `BUILD_THREADS=4`, `LOG_LEVEL=INFO`, `DEBUG_PORT=3000` | 6 workspace subdirectories |
| `05_registry.env` | `HAVE_GITLAB_SERVER=TRUE`, `HAVE_HARBOR_SERVER=TRUE`, `HARBOR_SERVER_PORT=9000` | `REGISTRY_URL` depends on CONTAINER_NAME |
| `06_sdk.env` | `INSTALL_SDK=false` | SDK paths are platform-dependent |
| `07_volumes.env` | `VOLUMES_ROOT=${WORKSPACE_ROOT}` | `HOST_VOLUME_DIR` has no default — REQUIRED per platform |
| `08_samba.env` | `SAMBA_PUBLIC_ACCOUNT_NAME/PASSWORD=sambashare`, `SAMBA_FILE_MODE=0777`, `SAMBA_DIR_MODE=0777` | Default Samba credentials + permissions |
| `09_runtime.env` | `ENABLE_SSH=true`, `ENABLE_GDB_SERVER=true`, `USE_NVIDIA_GPU=false`, `ENABLE_CORE_DUMPS=true`, `CONTAINER_RESTART_POLICY=unless-stopped`, `CONTAINER_PRIVILEGED=true`, `CONTAINER_SERIAL_DEVICE=/dev/ttyUSB0`, `CONTAINER_SHM_SIZE=8g`, `NVIDIA_VISIBLE_DEVICES=all`, `NVIDIA_DRIVER_CAPABILITIES=all` | Ports from port_calc.sh; compose overrides for container runtime |
| `11_proxy.env` | `HAS_PROXY=false`, `HTTP_PROXY_IP`, `HTTPS_PROXY_IP` | Proxy IPs have defaults but HAS_PROXY is off |

### Layer 2: `configs/platform-independent/common.env`

| Variable | Value | Notes |
|---|---|---|
| `VERSION` | `1.7.1` | Auto-bumped by release-please (`x-release-please-version` marker) |
| `PROJECT_VERSION` | `$VERSION` | Alias used throughout the build |
| `PROJECT_MAINTAINER` | PotterWhite | |
| `PROJECT_RELEASE_DATE` | 2026-03-19 | Manual update |
| `SDK_VERSION` | 1.1.2 | |

### Layer 3: `configs/platforms/<name>.env`

Only override what differs. Required fields: `PRODUCT_NAME`, `OS_VERSION`, `PORT_SLOT`, `HOST_VOLUME_DIR`.

**Current platforms:**

| Platform | Slot | SSH | GDB | Ubuntu | NVIDIA | Proxy | GitLab |
|---|---|---|---|---|---|---|---|
| `rk3588s` | 0 | 2109 | 2345 | 24.04 | ✅ | — | — |
| `rv1126bp` | 1 | 2119 | 2355 | 22.04 | — | ✅ | ✅ 192.168.3.67 |
| `rk3568` | 2 | 2129 | 2365 | 20.04 | — | ✅ | ✅ 192.168.3.67 |
| `rv1126` | 3 | 2139 | 2375 | 22.04 | — | ✅ | ✅ 192.168.3.67 |
| `rk3568-ubuntu22` | 4 | 2149 | 2385 | 22.04 | — | ✅ | ✅ 192.168.3.67 |
| `rk3588s-ubuntu-24` | 5 | 2159 | 2395 | 24.04 | — | ✅ | ✅ 192.168.3.67 |

### `configs/platform_schema.json`
JSON Schema for platform `.env` validation. Required: `PRODUCT_NAME`, `OS_VERSION`, `PORT_SLOT`. Defines enums (OS_VERSION: 20.04/22.04/24.04/11/12), ranges (PORT_SLOT: 0–99), patterns (PRODUCT_NAME: `[a-zA-Z0-9_-]+`). Conditional: if `HAVE_GITLAB_SERVER=TRUE` → requires `GITLAB_SERVER_IP` + `GITLAB_SERVER_PORT`. `additionalProperties: true`.

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

### `project_handover/scripts/archive_tarball.sh`
Creates tar.gz for distribution: `archive_tarball.sh all|client|server [ubuntu|windows|all]`
- Follows symlinks, excludes `volumes/*` except `.gitkeep`, date-stamped filenames

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
- Version source of truth: `VERSION` in `configs/platform-independent/common.env`
- `x-release-please-version` marker enables auto-bump
- Changelog sections: feat→✨, fix→🐛, perf→⚡, revert→🔙. Docs/style/chore/refactor hidden.
- `.devcontainer/devcontainer.json` — VS Code Dev Container for developing HarborPilot itself (not for end users). Forwards ports 2109+2345, installs C++ / CMake / Python / Git extensions.

---

## 8. Key Architectural Patterns

1. **Three-Layer Config Inheritance** — Defaults provide sensible values for 90% of variables. Platform files only override the differences. Adding a new platform requires ~15–20 lines. Layer 2 (common.env) holds project-wide constants like version.

2. **PORT_SLOT-Based Port Allocation** — A single integer determines all port mappings. Prevents port collisions between platforms. Formula is defined once in `port_calc.sh` and referenced everywhere.

3. **Template → envsubst → Final File** — `*_template` files use `${VAR}` placeholders. A template-processor intermediate stage in the Dockerfile runs `envsubst` with all build args exported. This replaces the previous error-prone `sed` approach.

4. **Config as the Single Source of Truth** — No script contains hardcoded platform-specific values. Everything flows from the 3-layer config. Changing a default propagates to all platforms automatically.

5. **Dynamic docker-compose Generation** — `ubuntu_only_entrance.sh` writes `docker-compose.yaml` from shell variables at runtime, enabling NVIDIA GPU support and platform-specific port mappings without manual compose editing.

6. **Conditional Feature Installation** — CUDA, OpenCV, Python 2.7, npm China mirrors, proxy — all gated by boolean env vars. The Dockerfile checks these and skips irrelevant stages, keeping images small for platforms that don't need them.
