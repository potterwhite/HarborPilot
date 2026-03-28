<div align="center">
  <h1>HarborPilot</h1>
  <p><i>One-Command Docker Development Environment for Embedded Linux — Multi-Platform, Reproducible, Registry-Backed</i></p>
</div>

<p align="center">
  <img src="docs/en/assets/dark-background.png" alt="HarborPilot Banner" width="100%"/>
</p>

<p align="center">
  <a href="https://github.com/potterwhite/HarborPilot/releases">
    <img src="https://img.shields.io/github/v/release/potterwhite/HarborPilot?color=blue&label=version">
  </a>
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License"/>
  <img src="https://img.shields.io/badge/host-Ubuntu-orange?style=flat-square" alt="Host Platform"/>
  <img src="https://img.shields.io/badge/Docker-required-2496ED?style=flat-square&logo=docker&logoColor=white" alt="Docker"/>
  <img src="https://img.shields.io/badge/shell-bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white" alt="Shell"/>
  <img src="https://img.shields.io/badge/target-Rockchip%20%7C%20ARM%20SoC-lightgrey?style=flat-square" alt="Target"/>
</p>

<p align="center">
  <strong>English</strong> | <a href="docs/zh/readme.md">简体中文</a>
</p>

---

## What problem does HarborPilot solve?

**Are you building Docker development environments for embedded Linux boards?**
Boards like RK3588, RK3588S, RK3568, RV1126 — or any ARM-based SoC running Ubuntu or Debian?

The typical pain points:
- Every developer has a slightly different toolchain installed → builds fail on different machines
- Supporting multiple chip families means maintaining multiple diverging Dockerfiles
- Adding Ubuntu 24.04 support breaks what worked on 20.04 (apt format, UID collisions, pip PEP 668)
- Port collisions when running containers for multiple platforms simultaneously
- Pushing images to a private Harbor registry requires glue scripts nobody documents

**HarborPilot solves all of this** with a single-command build pipeline, a three-layer configuration system that lets new platforms inherit all defaults in under 20 lines, and automatic port allocation that guarantees zero collisions.

---

## What is HarborPilot?

HarborPilot is a fully scripted toolchain for building, managing, and distributing
**containerised cross-compilation development environments** for embedded Linux targets.

- **One command to build** — `./harbor` selects a platform, builds a 5-stage Docker image, tags it, and pushes it to your private Harbor registry
- **One command to run** — `ubuntu_only_entrance.sh start` brings up a fully-configured container on any Ubuntu host in seconds
- **A three-layer config system** — change one global default and every platform inherits it automatically; a new platform needs fewer than 20 lines of config
- **PORT_SLOT-based port allocation** — a single integer derives SSH and GDB ports automatically, eliminating manual port management

Primary targets: Rockchip SoCs (RK3588S, RK3568, RV1126, RV1126bp) on Ubuntu 20.04 / 22.04 / 24.04.
Architecture is platform-agnostic — adding a Debian platform or a different chip family takes minutes.

---

## Key Features

| Feature | Details |
|---|---|
| **One command to build** | `./harbor` — select platform → build → tag → push → verify manifest |
| **One command to run** | `ubuntu_only_entrance.sh start` — fully configured container in seconds |
| **New platform in 20 lines** | Three-layer config: `defaults/` → `common.env` → `platform.env` · only overrides needed |
| **Zero port conflicts** | `PORT_SLOT` formula — SSH and GDB ports derived automatically, never collide |
| **Registry lifecycle** | Auto push + manifest digest verification — not just "hope it uploaded" |
| **Chip-family grouping** | `CHIP_FAMILY` drives Harbor project, SDK repo, SSH keys — RK3588 variants share one team |
| **AI-operable config** | `.env` files are the intent layer — AI agents can read, modify, then call `./harbor` |
| **Embedded-first defaults** | GDB server, serial passthrough, OpenCV, optional CUDA — all pre-wired |
| **Cross-distro support** | Ubuntu 20.04 / 22.04 / 24.04 handled correctly (DEB822, UID 1000, PEP 668) |
| **envsubst templates** | All stage configuration rendered via `envsubst` — no fragile sed pipelines |

---

## How does the three-layer config work?

```
Layer 1:  configs/defaults/*.env        ← Global defaults (OS, tools, ports, registry…)
Layer 2:  configs/platform-independent/common.env  ← Project version & constants
Layer 3:  configs/platforms/<name>.env  ← Per-platform overrides only (≤20 lines)
```

Last layer wins. A new platform file only contains what **differs** from the defaults — typically:
`PRODUCT_NAME`, `OS_VERSION`, `PORT_SLOT`, `HOST_VOLUME_DIR`, and any chip-specific overrides.

**PORT_SLOT** is the single source of port truth:
- `CLIENT_SSH_PORT = 2109 + PORT_SLOT × 10`
- `GDB_PORT = 2345 + PORT_SLOT × 10`

Add a new platform with `./scripts/create_platform.sh` (interactive) or `--non-interactive` for CI.

→ Deep dive: [docs/en/3-highlights/config_layers.md](docs/en/3-highlights/config_layers.md)

---

## Repository Structure

```
HarborPilot/
│
├── harbor                            ← Entry point: build → tag → push → verify
│
├── configs/
│   ├── defaults/                     ← Layer 1 · 10 domain-scoped default files
│   │   ├── 01_base.env               OS, user, timezone, locale
│   │   ├── 02_build.env              Docker BuildKit settings
│   │   ├── 03_tools.env              Dev tool switches & versions (CUDA, OpenCV, Node…)
│   │   ├── 04_workspace.env          Workspace paths & build settings
│   │   ├── 05_registry.env           Harbor / GitLab server address
│   │   ├── 06_sdk.env                SDK install switch
│   │   ├── 07_volumes.env            Volume root path
│   │   ├── 08_samba.env              Samba credentials
│   │   ├── 09_runtime.env            SSH / GDB / NVIDIA / serial switches
│   │   └── 11_proxy.env              HTTP/HTTPS proxy (off by default)
│   ├── platform-independent/
│   │   └── common.env                ← Layer 2 · project version & constants
│   └── platforms/
│       ├── rk3588-rk3588s_ubuntu-22.04.env   ← Layer 3 · platform overrides only
│       ├── rk3588-rk3588s_ubuntu-24.04.env
│       ├── rk3568-rk3568_ubuntu-20.04.env
│       ├── rk3568-rk3568_ubuntu-22.04.env
│       ├── rv1126-rv1126_ubuntu-22.04.env
│       └── rv1126-rv1126bp_ubuntu-22.04.env
│
├── docker/
│   └── dev-env-clientside/           ← 5-stage Dockerfile
│       ├── Dockerfile                   base → tools → sdk → config → final
│       └── build.sh
│
├── scripts/
│   ├── create_platform.sh            ← Platform wizard (interactive + non-interactive)
│   └── port_calc.sh                  ← PORT_SLOT → SSH/GDB port calculation
│
├── project_handover/
│   └── clientside/ubuntu/
│       ├── ubuntu_only_entrance.sh   ← Container lifecycle manager
│       └── harbor.crt                ← Harbor CA cert (install once per host)
│
└── docs/                             ← Bilingual documentation (EN + ZH)
    ├── en/
    │   ├── 1-for-ai/                 AI agent reference files
    │   ├── 2-progress/               Phase tracking & roadmap
    │   ├── 3-highlights/             Architecture decisions & analysis
    │   └── 4-for-beginner/           Quick start guide
    └── zh/                           Chinese mirror of docs/en/
```

---

## Supported Platforms

| Platform | Ubuntu | SSH Port | GDB Port | Notes |
|---|---|---|---|---|
| `rk3588-rk3588s_ubuntu-22.04` | 22.04 | 2109 | 2345 | NVIDIA GPU supported |
| `rv1126-rv1126bp_ubuntu-22.04` | 22.04 | 2119 | 2355 | |
| `rk3568-rk3568_ubuntu-20.04` | 20.04 | 2129 | 2365 | |
| `rv1126-rv1126_ubuntu-22.04` | 22.04 | 2139 | 2375 | |
| `rk3568-rk3568_ubuntu-22.04` | 22.04 | 2149 | 2385 | |
| `rk3588-rk3588s_ubuntu-24.04` | 24.04 | 2159 | 2395 | Without NVIDIA GPU |

---

## Quick Start

→ **Full guide: [docs/en/4-for-beginner/quick_start.md](docs/en/4-for-beginner/quick_start.md)**

```bash
# 1. Install Docker and trust the Harbor CA cert  (once per host)
#    → see docs/en/4-for-beginner/quick_start.md

# 2. Log in to your Harbor registry
docker login <registry-ip>:<registry-port>

# 3. Build — pick your target platform interactively
./harbor

# 4. Start your development container
./project_handover/clientside/ubuntu/ubuntu_only_entrance.sh start
```

**Non-interactive (CI / scripted):**
```bash
./scripts/create_platform.sh --non-interactive \
    --name rk3566-debian12 --os debian --os-version 12 \
    --harbor-ip 192.168.3.68 --port-slot 6
```

---

## FAQ

**Q: Can I use this for a chip family not listed above?**
A: Yes. Run `./scripts/create_platform.sh` to add a new platform in minutes. The wizard auto-assigns a PORT_SLOT to avoid conflicts and generates the config file with all required fields.

**Q: Does it work with Ubuntu 24.04?**
A: Yes. HarborPilot handles Ubuntu 24.04's DEB822 apt format, pre-occupied UID 1000, and pip's externally-managed-environment restriction automatically.

**Q: Can I use it without a Harbor registry?**
A: Yes. Set `HAVE_HARBOR_SERVER=FALSE` in your platform config and images stay local.

**Q: Is the Dockerfile AI-readable?**
A: The `.env` config files are the intent layer — AI agents can read and modify them directly, then invoke `./harbor` to build. The `docs/en/1-for-ai/` directory contains a full codebase map and working rules specifically for AI agents.

---

## Deprecation Notices

| Component | Status |
|---|---|
| Windows host | ❌ **Dropped** — Ubuntu host only. |

---

## License

[MIT](LICENSE) © 2024 PotterWhite
