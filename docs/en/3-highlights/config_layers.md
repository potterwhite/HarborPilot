# Three-Layer Configuration System

> **Related:** [中文版 →](../../zh/3-highlights/config_layers.md)

This document explains how HarborPilot's configuration system works, why it is structured as three layers, and how to use it when adding a new platform or a new global setting.

---

## The Problem It Solves

Early versions of HarborPilot had a flat structure:

```
configs/2_platforms/
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
Layer 1  configs/1_defaults/*.env          Global defaults — every platform inherits
   ↓  (later layers override earlier ones)
Layer 2  configs/2_platforms/<platform>.env Platform-specific overrides only
   ↓
Layer 3  configs/3_host/<hostname>.env      Host-level overrides (optional, gitignored)
```

**The rule:** a platform file only contains values that *differ* from the defaults. If it's not in the platform file, the default is used. A host file only contains values that *differ* from the platform — if it's not in the host file, the platform value is used.

---

## Layer 1 — Global Defaults (`configs/1_defaults/`)

Twelve files, each scoped to one concern. The ordinal prefix makes the load order explicit at a glance.

| File | Variables |
|---|---|
| `00_project.env` | `VERSION`, `PROJECT_VERSION`, `PROJECT_RELEASE_DATE`, `PROJECT_MAINTAINER`, `SDK_VERSION` |
| `01_base.env` | `OS_VERSION`, `DEV_USERNAME`, `DEV_UID/GID`, `TIMEZONE`, `DEBIAN_FRONTEND` |
| `02_build.env` | `DOCKER_BUILDKIT` |
| `03_tools.env` | `INSTALL_CUDA/OPENCV/CMAKE`, tool versions (`CONAN_VERSION`, etc.), `GCC_OFFLINE_PACKAGE` |
| `04_workspace.env` | `WORKSPACE_ROOT` and all subdirectory paths, `WORKSPACE_BUILD_THREADS`, debug settings |
| `05_registry.env` | `HAVE_GITLAB_SERVER`, `HARBOR_SERVER_IP`, `HARBOR_SERVER_PORT`, `HAVE_HARBOR_SERVER`, `GITLAB_SERVER_IP`, `GITLAB_SERVER_PORT` |
| `06_sdk.env` | `INSTALL_SDK`, `CHIP_FAMILY=${PRODUCT_NAME}` (URLs depend on `CHIP_FAMILY`, set in Layer 2) |
| `07_volumes.env` | `VOLUMES_ROOT` (note: `HOST_VOLUME_DIR` has no universal default — must be set in Layer 2 or 3) |
| `08_samba.env` | `SAMBA_PUBLIC/PRIVATE_ACCOUNT_NAME/PASSWORD`, `ENABLE_VSC_INTEGRATION` |
| `09_runtime.env` | `ENABLE_SSH`, `ENABLE_SYSLOG`, `ENABLE_GDB_SERVER`, `ENABLE_CORE_DUMPS`, `USE_NVIDIA_GPU` |
| `11_proxy.env` | `HAS_PROXY` (default: `false`), `HTTP/HTTPS_PROXY_IP` |

**Loading order matters.** The files are sourced in numerical order (00 → 11). A variable defined in `05_registry.env` can reference `CONTAINER_NAME` only if it has already been set — it hasn't yet at Layer 1, which is why `REGISTRY_URL` is intentionally left out of Layer 1 and computed in Layer 2 instead.

---

## Layer 2 — Platform Overrides (`configs/2_platforms/<platform>.env`)

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

## Layer 3 — Host-Level Overrides (`configs/3_host/<hostname>.env`)

This layer is **optional** and **auto-loaded by hostname**. It solves the problem of running the same platform on different machines with different hardware (e.g., one machine has NVIDIA GPU, another doesn't).

### How It Works

The system runs `hostname` and looks for `configs/3_host/<hostname>.env`. If the file exists, it is sourced after the platform file. If it doesn't exist, the system skips this layer entirely.

```bash
# Example: configs/3_host/my-desktop.env
USE_NVIDIA_GPU="true"
CONTAINER_SHM_SIZE="1g"
HOST_VOLUME_DIR="/mnt/ssd/volumes/rk3588"
```

### What to Put Here

- `USE_NVIDIA_GPU` — whether this specific machine has an NVIDIA GPU
- `CONTAINER_SHM_SIZE` — shared memory size (GPU workloads need more)
- `HOST_VOLUME_DIR` — host-specific volume mount path
- `EXTRA_VOLUMES_LIST` — additional volume mounts for this machine
- Any variable that differs between machines sharing the same platform config

### Git Policy

Host config files are `.gitignored` — they are local to each machine and should NOT be committed. Only `.gitkeep` and `README.md` in the `configs/3_host/` directory are tracked.

---

## Variable Precedence

Later layers override earlier ones. If a variable is not set in any layer, it is empty.

```
00_project.env  →  01_base.env  →  ...  →  11_proxy.env  →  <platform>.env  →  <hostname>.env
     ↑                                          ↑                ↑                  ↑
  version/maintainer                        server IPs,      GPU on/off,
  SDK versions                              OS version,      volume paths,
                                            port slot        per-machine tweaks
```

**Example: USE_NVIDIA_GPU precedence chain**

| Scenario | defaults/09_runtime | platforms/rk3588.env | host/my-desktop.env | Result |
|---|---|---|---|---|
| No host file | `"false"` | *(not set)* | *(file missing)* | `"false"` |
| Host file, no GPU var | `"false"` | `"true"` | *(has SHM_SIZE only)* | `"true"` |
| Host overrides GPU | `"false"` | `"true"` | `"false"` | `"false"` |

---

## Practical Impact

| Scenario | Before (flat) | After (three-layer) |
|---|---|---|
| Add a global flag | Edit N platform files | Edit one file in `defaults/` |
| Add a new platform | Copy 180-line file, change 5 lines | Write ~20 lines of overrides only |
| Customise one platform | Already there | Add one line in the platform file |
| Different GPU per machine | Duplicate platform file | Add host override file |
| Understand what makes a platform unique | Diff against every other file | Read the platform file — it *is* the diff |

---

## Where the Loading Happens

All three scripts that consume configuration implement identical loading logic:

```bash
# Layer 1 — source all defaults in order
for defaults_file in \
    "${DEFAULTS_DIR}/00_project.env" \
    "${DEFAULTS_DIR}/01_base.env" \
    ...
    "${DEFAULTS_DIR}/11_proxy.env"
do
    [ -f "${defaults_file}" ] && source "${defaults_file}"
done

# Layer 2
source "${PLATFORM_ENV_PATH}"               # <platform>.env via symlink

# Layer 3 — optional, auto-loaded by hostname
HOST_CONFIG="${CONFIGS_DIR}/host/$(hostname).env"
[ -f "${HOST_CONFIG}" ] && source "${HOST_CONFIG}"
```

The symlink in `project_handover/` (`project_handover/.env`) is set automatically by `./harbor` when you pick a platform.

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

1. Open the appropriate `configs/1_defaults/NN_<domain>.env` file
2. Add the variable with its default value
3. If you need a new *domain* that doesn't fit any existing file, create `configs/1_defaults/12_<domain>.env` and append it to the load list in all four scripts

The platform files that need a non-default value can then override it with a single line.

---

## Adding a Host-Level Override

1. Run `hostname` to find your machine name
2. Create `configs/3_host/<your-hostname>.env`
3. Add only the variables that differ from the platform config
4. The system auto-loads this file — no script changes needed

```bash
# Example: configs/3_host/my-desktop.env
USE_NVIDIA_GPU="true"
CONTAINER_SHM_SIZE="1g"
HOST_VOLUME_DIR="/mnt/ssd/volumes/rk3588"
```
