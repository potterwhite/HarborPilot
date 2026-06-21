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
Layer 3  configs/3_host/<hostname>.env     Host-level overrides (optional, gitignored)
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

Each platform file contains **only what differs from the defaults**. Platform files define the **platform identity** and **SDK configuration**.

### What belongs in Platform files

| Category | Variables | Reason |
|----------|-----------|--------|
| **Platform Identity** | `CHIP_FAMILY`, `CHIP_EXTRACT_NAME`, `OS_DISTRIBUTION`, `OS_VERSION`, `PRODUCT_NAME` | Defines the platform uniquely |
| **Derived Names** | `IMAGE_NAME`, `CONTAINER_NAME`, `LATEST_IMAGE_TAG` | Depend on `PRODUCT_NAME` |
| **Port Slot** | `PORT_SLOT` | Platform-specific port allocation |
| **Registry URL** | `REGISTRY_URL` | Depends on `CHIP_FAMILY` |
| **SDK** | `SDK_INSTALL_PATH`, `SDK_GIT_REPO`, `SDK_GIT_KEY_FILE`, `SDK_GIT_DEFAULT_BRANCH` | Platform-specific SDK |

### Example: Platform file (rk3588-ubuntu-22.04.env)

```bash
# Platform Identity  [REQUIRED — no defaults]
CHIP_FAMILY="rk3588"
CHIP_EXTRACT_NAME="rk3588s"
OS_DISTRIBUTION="ubuntu"
OS_VERSION="22.04"
OS_VERSION_ID="22-04"
PRODUCT_NAME="${CHIP_FAMILY}-${CHIP_EXTRACT_NAME}_${OS_DISTRIBUTION}-${OS_VERSION_ID}"

# Derived from PRODUCT_NAME (keep in sync)
IMAGE_NAME="${PRODUCT_NAME}-dev-env"
LATEST_IMAGE_TAG=${PROJECT_VERSION}
CONTAINER_NAME=${PRODUCT_NAME}

# Registry URL  [depends on HARBOR_SERVER_IP from host/defaults]
REGISTRY_URL="${HARBOR_SERVER_IP}:${HARBOR_SERVER_PORT}/team_${CHIP_FAMILY}"

# SDK  [CHIP_FAMILY groups same-silicon variants together]
SDK_INSTALL_PATH="${WORKSPACE_ROOT}/sdk"
SDK_GIT_REPO="git@${GITLAB_SERVER_IP:-192.168.0.19}:team_${CHIP_FAMILY}/${PRODUCT_NAME}_sdk.git"
SDK_GIT_KEY_FILE="SDK_${CHIP_FAMILY}_ED25519"
SDK_GIT_DEFAULT_BRANCH="main"

# Container Runtime  [ports auto-calculated from PORT_SLOT]
PORT_SLOT="0"
```

### What does NOT belong in Platform files

These are **host-specific** and should be in Layer 3:

- `HOST_VOLUME_DIR` — host filesystem path
- `EXTRA_VOLUME_*` — user-specific volume mounts
- `HAS_PROXY`, `HTTP_PROXY_IP`, `HTTPS_PROXY_IP` — network environment
- `NPM_USE_CHINA_MIRROR` — network environment
- `USE_NVIDIA_GPU`, `CONTAINER_SHM_SIZE` — hardware-specific
- `GITLAB_SERVER_*`, `HARBOR_SERVER_*` — server connectivity
- `HAVE_GITLAB_SERVER`, `HAVE_HARBOR_SERVER` — server availability

---

## Layer 3 — Host-Level Overrides (`configs/3_host/<hostname>.env`)

This layer is **optional** and **auto-loaded by hostname**. It solves the problem of running the same platform on different machines with different hardware, network, or paths.

### How It Works

The system runs `hostname` and looks for `configs/3_host/<hostname>.env`. If the file exists, it is sourced after the platform file. If it doesn't exist, the system skips this layer entirely.

### Getting Started

```bash
# 1. Get your hostname
hostname

# 2. Copy the template
cp configs/3_host/TEMPLATE.env.example configs/3_host/$(hostname).env

# 3. Edit with your settings
nano configs/3_host/$(hostname).env
```

### What belongs in Host files

| Category | Variables | Reason |
|----------|-----------|--------|
| **Network** | `HAS_PROXY`, `HTTP_PROXY_IP`, `HTTPS_PROXY_IP`, `NPM_USE_CHINA_MIRROR` | Network environment |
| **Servers** | `HAVE_GITLAB_SERVER`, `GITLAB_SERVER_*`, `HAVE_HARBOR_SERVER`, `HARBOR_SERVER_*` | Server reachability |
| **Hardware** | `USE_NVIDIA_GPU`, `CONTAINER_SHM_SIZE` | Machine-specific hardware |
| **Paths** | `HOST_VOLUME_DIR`, `EXTRA_VOLUME_*` | Host filesystem paths |

### Example: Host file

```bash
# configs/3_host/my-desktop.env

# Network
HAS_PROXY="true"
HTTP_PROXY_IP="192.168.3.67"
HTTPS_PROXY_IP="192.168.3.67"
NPM_USE_CHINA_MIRROR="true"

# Servers
HAVE_GITLAB_SERVER="TRUE"
GITLAB_SERVER_IP="192.168.3.67"
GITLAB_SERVER_PORT="80"
HARBOR_SERVER_IP="192.168.3.67"
HARBOR_SERVER_PORT="9000"

# Hardware
USE_NVIDIA_GPU="true"
CONTAINER_SHM_SIZE="1g"

# Paths
HOST_VOLUME_DIR="/mnt/ssd/docker-volumes/${PRODUCT_NAME}"
EXTRA_VOLUME_0="/home/james/notes:/volumes_notes"
EXTRA_VOLUME_1="/home/james/projects:/volumes_projects"
```

### Git Policy

Host config files are **gitignored** — they are local to each machine and should NOT be committed. Only `TEMPLATE.env.example`, `README.md`, and `.gitkeep` in the `configs/3_host/` directory are tracked.

This protects:
- User-specific paths (`/home/james/...`)
- Network configurations (proxy IPs, server addresses)
- Hardware details (GPU availability)

---

## Variable Precedence

Later layers override earlier ones. If a variable is not set in any layer, it is empty.

```
00_project.env  →  01_base.env  →  ...  →  11_proxy.env  →  <platform>.env  →  <hostname>.env
     ↑                                          ↑                ↑                  ↑
  version/maintainer                        server IPs,      platform ID,     proxy settings,
  SDK versions                              OS version,      port slot,       volume paths,
                                            proxy default    SDK config       GPU, servers
```

**Example: HAS_PROXY precedence chain**

| Scenario | defaults/11_proxy | platforms/rk3588.env | host/my-desktop.env | Result |
|---|---|---|---|---|
| No host file | `"false"` | *(not set)* | *(file missing)* | `"false"` |
| Host file with proxy | `"false"` | *(not set)* | `"true"` | `"true"` |
| Platform sets proxy (old style) | `"false"` | `"true"` | *(not set)* | `"true"` |

**Example: GITLAB_SERVER_IP precedence chain**

| Scenario | defaults/05_registry | platforms/rk3588.env | host/my-desktop.env | Result |
|---|---|---|---|---|
| No host file | `"192.168.0.19"` | *(not set)* | *(file missing)* | `"192.168.0.19"` |
| Host overrides | `"192.168.0.19"` | *(not set)* | `"192.168.3.67"` | `"192.168.3.67"` |

---

## Practical Impact

| Scenario | Before (flat) | After (three-layer) |
|---|---|---|
| Add a global flag | Edit N platform files | Edit one file in `defaults/` |
| Add a new platform | Copy 180-line file, change 5 lines | Write ~20 lines of overrides only |
| Customise one platform | Already there | Add one line in the platform file |
| Different GPU per machine | Duplicate platform file | Add host override file |
| Understand what makes a platform unique | Diff against every other file | Read the platform file — it *is* the diff |
| Share config across team | Commit everything | Commit defaults + platform, host is private |

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
HOST_CONFIG="${CONFIGS_DIR}/3_hosts/$(hostname).env"
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
2. Fill in the **required** section (identity, port slot, SDK paths)
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
2. Copy the template: `cp configs/3_host/TEMPLATE.env.example configs/3_host/$(hostname).env`
3. Edit the file, uncommenting and setting only the variables you need
4. The system auto-loads this file — no script changes needed

See `configs/3_host/README.md` for detailed examples and troubleshooting.

---

## See Also

- [Host Configuration Template](../../configs/3_host/TEMPLATE.env.example)
- [Host Configuration Guide](../../configs/3_host/README.md)
- [Platform Configuration](../../configs/2_platforms/)
- [Default Configuration](../../configs/1_defaults/)
