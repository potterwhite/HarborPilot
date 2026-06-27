# Host-Level Configuration (Layer 3)

> **Related:** [中文版 →](../../zh/3-highlights/config_layers.md)

This directory contains host-specific configuration overrides. Each file is named after the host's hostname and contains only values that differ from the platform config.

---

## Quick Start

```bash
# 1. Get your hostname
hostname

# 2. Copy the template (include platform name in filename)
cp TEMPLATE.env.example $(hostname)_<PLATFORM_NAME>.env

# 3. Edit with your settings
nano $(hostname)_<PLATFORM_NAME>.env
```

### Naming Convention

Host config files follow this pattern:

```
{hostname}_{PLATFORM_NAME}.env
```

- `{hostname}` — your machine's hostname (`hostname` command)
- `{PLATFORM_NAME}` — full platform name from `configs/2_platforms/` (without `.env`)

Examples:
```
Anastasia_jetson-orin-nx-16g-super_ubuntu-22.04.env
Anastasia_rk3588-rk3588s_ubuntu-22.04.env
Anastasia_rv1126bp_ubuntu-22.04.env
```

### Multiple Host Configs Per Machine

One machine can have multiple host configs — one per platform. Use `--host` to select:

```bash
# Interactive menu (lists all host configs)
./harbor

# Direct selection (skip menu)
./harbor --host Anastasia_jetson-orin-nx-16g-super_ubuntu-22.04
./harbor --host Anastasia_rk3588-rk3588s_ubuntu-22.04
```

The `--host` value must match a filename (without `.env`) in this directory.

---

## How It Works

The three-layer configuration system loads settings in this order:

```
Layer 1: configs/1_defaults/*.env     → Global defaults
Layer 2: configs/2_platforms/*.env    → Platform overrides
Layer 3: configs/3_hosts/<hostname>.env → Host overrides (this directory)
```

Later layers override earlier ones. If a variable is not set in your host file, the platform value is used.

---

## What to Put Here

Only add values that **differ** from your platform config:

| Category | Variables | Example |
|----------|-----------|---------|
| **Network** | `HAS_PROXY`, `NPM_USE_CHINA_MIRROR` | Corporate proxy settings |
| **Servers** | `GITLAB_SERVER_*`, `HARBOR_SERVER_*`, `REGISTRY_URL` | Server reachability + registry URL |
| **SDK** | `SDK_GIT_REPO` | GitLab repo URL (depends on GITLAB_SERVER_IP) |
| **Hardware** | `USE_NVIDIA_GPU`, `CONTAINER_SHM_SIZE` | GPU availability |
| **Paths** | `HOST_VOLUME_DIR`, `EXTRA_VOLUME_*` | User-specific paths |

---

## Example: Minimal Host Config

```bash
# configs/3_hosts/my-desktop_jetson-orin-nx-16g-super_ubuntu-22.04.env

BASE_PLATFORM="jetson-orin-nx-16g-super_ubuntu-22.04"

# This host has NVIDIA GPU
USE_NVIDIA_GPU="true"
CONTAINER_SHM_SIZE="1g"

# Custom volume path
HOST_VOLUME_DIR="/mnt/ssd/docker-volumes/${PRODUCT_NAME}"
```

---

## Example: Full Host Config

```bash
# configs/3_hosts/office-workstation_rk3588-rk3588s_ubuntu-22.04.env

BASE_PLATFORM="rk3588-rk3588s_ubuntu-22.04"

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
HOST_VOLUME_DIR="/mnt/nvme/docker-volumes/${PRODUCT_NAME}"
EXTRA_VOLUME_0="/home/james/notes:/volumes_notes"
EXTRA_VOLUME_1="/home/james/projects:/volumes_projects"
```

---

## Git Policy

Host config files are **gitignored** — they are local to each machine and should NOT be committed. Only `TEMPLATE.env.example` and `README.md` are tracked.

This protects:
- User-specific paths (`/home/james/...`)
- Network configurations (proxy IPs, server addresses)
- Hardware details (GPU availability)

---

## Troubleshooting

### "Where is my host config loaded?"

Check if the file exists:
```bash
ls -la configs/3_hosts/$(hostname)_*.env
```

Or with a specific platform:
```bash
ls -la configs/3_hosts/$(hostname)_jetson-orin-nx-16g-super_ubuntu-22.04.env
```

### "What values are active?"

Run the config loader with debug output:
```bash
V=1 ./harbor
```

### "I want to share my config with the team"

Don't commit your host file. Instead:
1. Add the variable to `TEMPLATE.env.example` (with comments)
2. Document the variable in `docs/en/3-highlights/config_layers.md`
3. Tell your team to update their host files

---

## See Also

- [Three-Layer Configuration System](../../en/3-highlights/config_layers.md)
- [Platform Configuration](../2_platforms/)
- [Default Configuration](../1_defaults/)
