# Three-Layer Configuration System

> **Related:** [中文版 →](../../../../zh/4-reference/config_layers.md)

This document explains how HarborPilot's configuration system works, why it is structured as three layers, and how to use it when adding a new platform or a new global setting.

---

## The Problem It Solves

Early versions of HarborPilot had a flat structure:

```
configs/platforms/
├── rk3588s.env     # 180+ lines — everything
├── rk3568.env      # 180+ lines — 95% identical to rk3588s.env
├── rv1126.env      # 180+ lines — 95% identical to rk3588s.env
└── ...
```

Adding a new global flag meant editing every platform file. A new platform meant copying an entire 180-line file and changing five lines. Reading a file gave no signal about what was *actually* different for that platform.

---

## The Solution: Three-Layer Override

Borrowed from Ansible, Helm, Kubernetes, and Yocto — any system that needs "sensible defaults with targeted overrides":

```
Layer 1  configs/defaults/*.env          Global defaults — every platform inherits
   ↓  (later layers override earlier ones)
Layer 2  configs/platform-independent/common.env    Project version & constants
   ↓
Layer 3  configs/platforms/<platform>.env           Platform-specific overrides only
```

**The rule:** a platform file only contains values that *differ* from the defaults. If it's not in the platform file, the default is used.

---

## Layer 1 — Global Defaults (`configs/defaults/`)

Eleven files, each scoped to one concern. The ordinal prefix makes the load order explicit at a glance.

| File | Variables |
|---|---|
| `01_base.env` | `OS_VERSION`, `DEV_USERNAME`, `DEV_UID/GID`, `TIMEZONE`, `DEBIAN_FRONTEND` |
| `02_build.env` | `DOCKER_BUILDKIT` |
| `03_tools.env` | `INSTALL_CUDA/OPENCV/CMAKE`, tool versions (`CONAN_VERSION`, etc.), `GCC_OFFLINE_PACKAGE` |
| `04_workspace.env` | `WORKSPACE_ROOT` and all subdirectory paths, `WORKSPACE_BUILD_THREADS`, debug settings |
| `05_registry.env` | `HAVE_GITLAB_SERVER`, `HARBOR_SERVER_IP`, `HARBOR_SERVER_PORT`, `HAVE_HARBOR_SERVER`, `GITLAB_SERVER_IP`, `GITLAB_SERVER_PORT` |
| `06_sdk.env` | `INSTALL_SDK`, `CHIP_FAMILY=${PRODUCT_NAME}` (URLs depend on `CHIP_FAMILY`, set in Layer 3) |
| `07_volumes.env` | `VOLUMES_ROOT` (note: `HOST_VOLUME_DIR` has no universal default — must be set in Layer 3) |
| `08_samba.env` | `SAMBA_PUBLIC/PRIVATE_ACCOUNT_NAME/PASSWORD`, `ENABLE_VSC_INTEGRATION` |
| `09_runtime.env` | `ENABLE_SSH`, `ENABLE_SYSLOG`, `ENABLE_GDB_SERVER`, `ENABLE_CORE_DUMPS`, `USE_NVIDIA_GPU` |
| `11_proxy.env` | `HAS_PROXY` (default: `false`), `HTTP/HTTPS_PROXY_IP` |

**Loading order matters.** The files are sourced in numerical order (01 → 11). A variable defined in `05_registry.env` can reference `CONTAINER_NAME` only if it has already been set — it hasn't yet at Layer 1, which is why `REGISTRY_URL` is intentionally left out of Layer 1 and computed in Layer 3 instead.

---

## Layer 2 — Project Constants (`configs/platform-independent/common.env`)

Contains only values that are **project-wide and version-controlled**, not platform-specific:

```bash
PROJECT_VERSION="1.5.0"
PROJECT_RELEASE_DATE="2026-03-16"
PROJECT_MAINTAINER="[PotterWhite]"
PROJECT_LICENSE="MIT"
SDK_VERSION="1.1.2"
SDK_RELEASE_DATE="2025-06-30"
```

This file changes only when the project itself is released. It is never platform-specific and never contains infrastructure addresses.

---

## Layer 3 — Platform Overrides (`configs/platforms/<platform>.env`)

Each platform file contains **only what differs from the defaults**. The mandatory sections are:

### Always required (no defaults exist)

```bash
# Platform identity
PRODUCT_NAME="rk3568"
OS_VERSION="20.04"
OS_DISTRIBUTION="ubuntu"

# Derived names (depend on PRODUCT_NAME)
IMAGE_NAME="${PRODUCT_NAME}-dev-env"
CONTAINER_NAME=${PRODUCT_NAME}
LATEST_IMAGE_TAG=${PROJECT_VERSION}

# Port slot — all ports derived by port_calc.sh
PORT_SLOT="2"

# Registry URL (depends on CHIP_FAMILY and HARBOR_SERVER_IP)
HARBOR_SERVER_IP="192.168.3.67"
HARBOR_SERVER_PORT="9000"
REGISTRY_URL="${HARBOR_SERVER_IP}:${HARBOR_SERVER_PORT}/team_${CHIP_FAMILY}"

# GitLab server (for SDK repos)
HAVE_GITLAB_SERVER="TRUE"
GITLAB_SERVER_IP="192.168.3.67"
GITLAB_SERVER_PORT="22"

# SDK paths (depend on CHIP_FAMILY)
SDK_INSTALL_PATH="${WORKSPACE_ROOT}/sdk"
SDK_GIT_REPO="git@${GITLAB_SERVER_IP}:team_${CHIP_FAMILY}/${CHIP_FAMILY}_sdk.git"
SDK_GIT_KEY_FILE="SDK_${CHIP_FAMILY}_ED25519"

# Host volume path (host-machine-specific, no sensible default)
HOST_VOLUME_DIR="/mnt/.../volumes/rk3568"
```

### Optional overrides (only when different from defaults)

```bash
# rk3568 uses a China npm mirror; the default is false
NPM_USE_CHINA_MIRROR="true"

# rk3568 has proxy access; the default is false
HAS_PROXY="true"

# rk3568 SDK uses a non-main branch
SDK_GIT_DEFAULT_BRANCH="br_main_20250206"
```

That's all — everything else is inherited silently from Layer 1.

---

## Practical Impact

| Scenario | Before (flat) | After (three-layer) |
|---|---|---|
| Add a global flag | Edit N platform files | Edit one file in `defaults/` |
| Add a new platform | Copy 180-line file, change 5 lines | Write ~20 lines of overrides only |
| Customise one platform | Already there | Add one line in the platform file |
| Understand what makes a platform unique | Diff against every other file | Read the platform file — it *is* the diff |

---

## Where the Loading Happens

All three scripts that consume configuration implement identical loading logic:

```bash
# Layer 1 — source all defaults in order
for defaults_file in \
    "${DEFAULTS_DIR}/01_base.env" \
    "${DEFAULTS_DIR}/02_build.env" \
    ...
    "${DEFAULTS_DIR}/11_proxy.env"
do
    [ -f "${defaults_file}" ] && source "${defaults_file}"
done

# Layer 2
source "${PLATFORM_INDEPENDENT_ENV_PATH}"   # common.env via symlink

# Layer 3
source "${PLATFORM_ENV_PATH}"               # <platform>.env via symlink
```

The symlinks in `project_handover/` (`project_handover/.env` and `project_handover/.env-independent`) are set automatically by `./harbor` when you pick a platform.

Scripts that implement this pattern:

| Script | Role |
|---|---|
| `harbor` | Build orchestrator |
| `docker/dev-env-clientside/build.sh` | Docker image builder |
| `project_handover/clientside/ubuntu/ubuntu_only_entrance.sh` | Container lifecycle manager |

---

## Adding a New Platform

1. Copy an existing platform `.env` as a starting point or run `./scripts/create_platform.sh`
2. Fill in the **required** section (identity, ports, `HOST_VOLUME_DIR`, registry URL)
3. Add only the optional overrides that differ from defaults
4. Run `./harbor` — your new platform appears in the selection menu automatically

No changes to any script or default file are needed.

---

## Adding a New Global Default

1. Open the appropriate `configs/defaults/NN_<domain>.env` file
2. Add the variable with its default value
3. If you need a new *domain* that doesn't fit any existing file, create `configs/defaults/12_<domain>.env` and append it to the load list in all four scripts

The platform files that need a non-default value can then override it with a single line.
