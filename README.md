<div align="center">
  <h1>HarborPilot</h1>
  <p><i>One-Command Docker Development Environment for Embedded Linux — Multi-Platform, Reproducible, Registry-Backed</i></p>
</div>

<p align="center">
  <img src="https://github.com/potterwhite/HarborPilot/blob/a997a343a5e883e48cf6771df55a7efbcf3d9933/doc/assets/dark-background.png" alt="HarborPilot Banner" width="100%"/>
</p>

<p align="center">
  <a href="https://github.com/potterwhite/HarborPilot/releases">
    <!-- <img src="https://img.shields.io/badge/version-1.5.0-blue?style=flat-square" alt="version"/> -->
    <img src="https://img.shields.io/github/v/release/potterwhite/HarborPilot?color=blue&label=version">
  </a>
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License"/>
  <img src="https://img.shields.io/badge/host-Ubuntu-orange?style=flat-square" alt="Host Platform"/>
  <img src="https://img.shields.io/badge/Docker-required-2496ED?style=flat-square&logo=docker&logoColor=white" alt="Docker"/>
  <img src="https://img.shields.io/badge/shell-bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white" alt="Shell"/>
  <img src="https://img.shields.io/badge/target-Rockchip%20SoC-lightgrey?style=flat-square" alt="Target"/>
</p>

<p align="center">
  <strong>English</strong> | <a href="docs/zh/readme.md">简体中文</a>
</p>

---

## What is HarborPilot?

HarborPilot is a fully scripted toolchain for building, managing, and distributing **containerised cross-compilation development environments** for embedded Linux targets.

Instead of asking every developer to manually install a toolchain, configure their system, and hope for consistency, HarborPilot gives you:

- **One command to build** — `./harbor` selects a platform, builds a multi-stage Docker image, tags it, and pushes it to your private Harbor registry
- **One command to run** — `ubuntu_only_entrance.sh start` brings up a fully-configured container on any Ubuntu host in seconds
- **A layered config system** — change one global default and every platform inherits it automatically; a new platform needs fewer than 20 lines of config

The primary targets are Rockchip SoCs (RK3588s, RK3568, RV1126, RV1126bp), but the architecture is platform-agnostic.

---

## Key Features

| Feature | Details |
|---|---|
| **One command to build** | `./harbor` — select platform → build → tag → push → verify manifest |
| **One command to run** | `ubuntu_only_entrance.sh start` — fully configured container in seconds |
| **New platform in 15 lines** | Three-layer config: `defaults/` → `common.env` → `platform.env` · only overrides needed |
| **Zero port conflicts** | `PORT_SLOT` formula — SSH and GDB ports derived automatically, never collide |
| **Registry lifecycle** | Auto push + manifest digest verification — not just "hope it uploaded" |
| **Chip-family grouping** | `CHIP_FAMILY` drives Harbor project, SDK repo, SSH keys — RK3588 variants share one team |
| **AI-operable config** | `.env` files are the intent layer — AI agents can read, modify, then call `./harbor` |
| **Embedded-first defaults** | GDB server, serial passthrough, OpenCV, optional CUDA — all pre-wired |

---

## Repository Structure

```
HarborPilot/
│
├── harbor                            ← Entry point: build → tag → push → verify
│
├── configs/
│   ├── defaults/                     ← Layer 1 · 11 domain-scoped default files
│   │   ├── 01_base.env               OS, user, timezone
│   │   ├── 02_build.env              Docker BuildKit settings
│   │   ├── 03_tools.env              Dev tool switches & versions
│   │   ├── 04_workspace.env          Workspace paths & behaviour
│   │   ├── 05_registry.env           Harbor / GitLab server address
│   │   ├── 06_sdk.env                SDK install switch
│   │   ├── 07_volumes.env            Volume root path
│   │   ├── 08_samba.env              Samba credentials
│   │   ├── 09_runtime.env            SSH / GDB / NVIDIA switches
│   │   └── 11_proxy.env              Proxy (off by default)
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
│   └── dev-env-clientside/           Multi-stage Dockerfile (5 stages)
│       ├── Dockerfile
│       └── build.sh
│
├── project_handover/
│   └── clientside/ubuntu/
│       ├── ubuntu_only_entrance.sh   Container lifecycle manager
│       └── harbor.crt                Harbor CA cert (install once per host)
│
└── docs/
    ├── architecture/                 AI-first documentation system
    │   ├── 00_INDEX.md               Navigation hub
    │   ├── 1-for-ai/                 AI agent reference files
    │   ├── 2-progress/               Phase tracking
    │   ├── 3-highlights/             Architecture decisions & analysis
    │   └── 4-reference/              Reference docs (quick_start, config_layers, port-map)
```

> **How the three-layer config works →** [docs/en/architecture/4-reference/config_layers.md](docs/en/architecture/4-reference/config_layers.md)

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

Ports are auto-calculated from `PORT_SLOT` — adding a new platform is conflict-free by design.
Create a new platform with `./scripts/create_platform.sh` (interactive) or `--non-interactive` mode for CI.

---

## Quick Start

→ **Full guide: [docs/en/architecture/4-reference/quick_start.md](docs/en/architecture/4-reference/quick_start.md)**

```bash
# 1. Install Docker and trust the Harbor CA cert  (once per host)
#    → see docs/en/architecture/4-reference/quick_start.md

# 2. Log in to your Harbor registry
docker login <registry-ip>:<registry-port>

# 3. Build — pick your target platform interactively
./harbor

# 4. Start your development container
./project_handover/clientside/ubuntu/ubuntu_only_entrance.sh start
```

---

## Deprecation Notices

| Component | Status |
|---|---|
| Windows host | ❌ **Dropped** — Ubuntu host only. |

---

## License

[MIT](LICENSE) © 2024 PotterWhite
