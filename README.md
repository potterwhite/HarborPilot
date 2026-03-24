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
  <strong>English</strong> | <a href="doc/readme_cn.md">简体中文</a>
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
| **One-command build** | `./harbor` — select platform, build, tag, push |
| **Multi-platform** | RK3588s · RK3568 (Ubuntu 20.04 / 22.04) · RV1126 · RV1126bp |
| **Three-layer config** | `defaults/` → `common.env` → `platform.env` · [learn more →](doc/config_layers.md) |
| **Registry pre-check** | Detects missing `docker login` before build and prompts the user — no surprise failures after a 30-minute build |
| **Harbor integration** | Auto push + manifest verification after every build |
| **NVIDIA GPU support** | Per-platform toggle; enabled by default for rk3588s |
| **SSH + GDB ready** | Each platform gets unique, non-conflicting port numbers |
| **Samba support** | Optional host ↔ container file sharing via CIFS |

---

## Repository Structure

```
HarborPilot/
│
├── harbor                            ← Entry point: build → tag → push
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
│   │   ├── 09_runtime.env            SSH / GDB / syslog switches
│   │   └── 11_proxy.env              Proxy (off by default)
│   ├── platform-independent/
│   │   └── common.env                ← Layer 2 · project version & constants
│   └── platforms/
│       ├── rk3588s.env               ← Layer 3 · platform overrides only
│       ├── rk3568.env
│       ├── rk3568-ubuntu22.env
│       ├── rv1126.env
│       ├── rv1126bp.env
│       └── offline.env               Template for new platforms
│
├── docker/
│   ├── dev-env-clientside/           Multi-stage Dockerfile (5 stages)
│   │   ├── Dockerfile
│   │   └── build.sh
│   └── libs/                         Reusable Dockerfile fragments & scripts
│
├── project_handover/
│   ├── clientside/ubuntu/
│   │   ├── ubuntu_only_entrance.sh   Container lifecycle manager
│   │   └── harbor.crt                Harbor CA cert (install once per host)
│
└── doc/
    ├── quick_start.md                Step-by-step setup guide (EN)
    ├── quick_start_cn.md             Step-by-step setup guide (ZH)
    ├── config_layers.md              Three-layer config system explained (EN)
    └── config_layers_cn.md           Three-layer config system explained (ZH)
```

> **How the three-layer config works →** [doc/config_layers.md](doc/config_layers.md)

---

## Supported Platforms

| Platform | Ubuntu | SSH Port | GDB Port | Notes |
|---|---|---|---|---|
| `rk3588s` | 22.04 | 2109 | 2345 | NVIDIA GPU enabled by default |
| `rv1126bp` | 22.04 | 2119 | 2355 | |
| `rk3568` | 20.04 | 2129 | 2365 | |
| `rv1126` | 22.04 | 2139 | 2375 | |
| `rk3568-ubuntu22` | 22.04 | 2149 | 2385 | |
| `offline` | 22.04 | — | — | Blank template for new platforms |

---

## Quick Start

→ **Full guide: [doc/quick_start.md](doc/quick_start.md)**

```bash
# 1. Install Docker and trust the Harbor CA cert  (once per host)
#    → see doc/quick_start.md

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
