# HarborPilot

<div align="center">

![Version](https://img.shields.io/badge/version-1.5.0-blue?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)
![Platform](https://img.shields.io/badge/host-Ubuntu-orange?style=flat-square)
![Docker](https://img.shields.io/badge/Docker-required-2496ED?style=flat-square&logo=docker&logoColor=white)
![Shell](https://img.shields.io/badge/shell-bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![Target](https://img.shields.io/badge/target-embedded%20Linux-lightgrey?style=flat-square)

**One-command Docker-based development environment for embedded Linux — multi-platform, reproducible, registry-backed.**

[Quick Start](doc/quick_start.md) · [中文文档](doc/readme_cn.md) · [Changelog](CHANGELOG.md)

</div>

---

## What is HarborPilot?

HarborPilot is a fully scripted toolchain for building, managing, and distributing **containerised cross-compilation development environments** for embedded Linux targets. Instead of asking every developer to manually install a toolchain, configure their system, and hope for consistency, HarborPilot lets you:

1. **Build** a reproducible Docker image from a multi-stage `Dockerfile` with a single command (`./harbor`)
2. **Push** the built image to a private Harbor registry automatically
3. **Spin up** a developer-ready container on any Ubuntu host in seconds (`ubuntu_only_entrance.sh start`)

The primary targets are Rockchip SoCs (RK3588s, RK3568, RV1126, RV1126bp), but the layered config system makes it straightforward to add new platforms.

---

## Key Features

| Feature | Details |
|---|---|
| **One-command build** | `./harbor` — select platform, build, tag, push, done |
| **Multi-platform** | RK3588s, RK3568 (20.04 / 22.04), RV1126, RV1126bp |
| **Three-layer config** | `defaults/` → `common.env` → `platform.env` — add a global flag by editing one file |
| **Harbor registry** | Automatic push + manifest verification after build |
| **Pre-flight checks** | Registry login check before build to fail fast with a clear prompt |
| **NVIDIA GPU support** | Optional per-platform — enabled for rk3588s by default |
| **distcc serverside** | Remote distributed compilation support (deprecated, see below) |
| **SSH + GDB ready** | Each container exposes platform-unique SSH and GDB ports |
| **Samba support** | Optional host ↔ container file sharing via CIFS |

---

## Architecture

```
HarborPilot/
│
├── harbor                          ← Entry point: build + tag + push
│
├── configs/
│   ├── defaults/                   ← Layer 1: global defaults (shared by all platforms)
│   │   ├── base.env
│   │   ├── tools.env
│   │   ├── workspace.env
│   │   ├── registry.env
│   │   ├── runtime.env
│   │   ├── proxy.env
│   │   └── ...
│   ├── platform-independent/
│   │   └── common.env              ← Layer 2: project version, maintainer info
│   └── platforms/
│       ├── rk3588s.env             ← Layer 3: platform-specific overrides only
│       ├── rk3568.env
│       ├── rk3568-ubuntu22.env
│       ├── rv1126.env
│       ├── rv1126bp.env
│       └── offline.env             ← Template for new platforms
│
├── docker/
│   ├── dev-env-clientside/         ← Multi-stage Dockerfile (5 stages)
│   │   ├── build.sh
│   │   └── Dockerfile
│   ├── dev-env-serverside/         ← ⚠ Deprecated
│   └── libs/                       ← Reusable Dockerfile fragments & scripts
│
└── project_handover/
    ├── clientside/ubuntu/
    │   ├── ubuntu_only_entrance.sh ← Container lifecycle manager (start/stop/recreate…)
    │   └── harbor.crt              ← Harbor CA certificate (install once per host)
    └── serverside/                 ← ⚠ Deprecated
```

### Three-Layer Config Loading

```
Layer 1  configs/defaults/*.env      Global defaults — inherited by every platform
   ↓
Layer 2  configs/platform-independent/common.env   Project version & constants
   ↓
Layer 3  configs/platforms/<platform>.env          Platform-specific overrides only
```

Later layers override earlier ones. A platform file only needs to contain values that **differ** from the defaults. Adding a new global flag? Edit `configs/defaults/tools.env` — all platforms inherit it automatically.

---

## Supported Platforms

| Platform | Ubuntu | SSH Port | GDB Port | Notes |
|---|---|---|---|---|
| `rk3588s` | 22.04 | 2109 | 2345 | NVIDIA GPU enabled by default |
| `rv1126bp` | 22.04 | 2119 | 2355 | |
| `rk3568` | 20.04 | 2129 | 2365 | |
| `rv1126` | 22.04 | 2139 | 2375 | |
| `rk3568-ubuntu22` | 22.04 | 2149 | 2385 | |
| `offline` | 22.04 | — | — | Template for new platforms |

---

## Quick Start

→ **[Full Quick Start Guide](doc/quick_start.md)**

```bash
# 1. Install Docker and trust the Harbor CA cert (once per host)
#    See doc/quick_start.md Steps 1–2

# 2. Log in to your Harbor registry
docker login <registry-ip>:<registry-port>

# 3. Build — select your platform interactively
./harbor

# 4. Start your container
./project_handover/clientside/ubuntu/ubuntu_only_entrance.sh start
```

---

## Deprecation Notice

| Component | Status |
|---|---|
| `project_handover/serverside/` | ⚠️ **Deprecated** — distcc serverside is no longer actively maintained. Scripts remain for reference but will not receive updates. |
| Windows host support | ❌ **Dropped** — only Ubuntu host is supported. |

---

## License

[MIT](LICENSE) © 2024 PotterWhite
