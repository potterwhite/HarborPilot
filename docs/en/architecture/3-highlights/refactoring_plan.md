---
title: "HarborPilot Refactoring Plan"
author: "Claude Opus 4.6 (co-analysis with PotterWhite)"
date: "2026-03-24"
tags:
  - refactoring
  - architecture
  - Docker
  - Ansible
  - DevContainers
  - AI-friendly
status: "Draft (pending discussion and finalisation)"
---

# HarborPilot Refactoring Plan

> **Related:** [中文版 →](../../../../zh/architecture/3-highlights/refactoring_plan.md)

## 1. Current Architecture Overview

```
HarborPilot.git/
│
├── configs/                          # ★ Config layers (three-tier inheritance)
│   ├── defaults/                     #   Layer 1: global defaults
│   │   ├── 01_base.env               #     - OS, username, password, timezone
│   │   ├── 02_build.env              #     - Build arguments
│   │   ├── 03_tools.env              #     - Tool versions (CUDA, OpenCV, Conan...)
│   │   ├── 04_workspace.env          #     - Workspace directory structure
│   │   ├── 05_registry.env           #     - Harbor/GitLab addresses
│   │   ├── 06_sdk.env                #     - SDK Git repository
│   │   ├── 07_volumes.env            #     - Docker volumes
│   │   ├── 08_samba.env              #     - Samba share config
│   │   ├── 09_runtime.env            #     - SSH/GDB ports and runtime settings
│   │   └── 11_proxy.env              #     - HTTP proxy
│   ├── platform-independent/
│   │   └── common.env                #   Layer 2: project-level constants (version, maintainer)
│   └── platforms/                    #   Layer 3: platform-specific overrides (only differences)
│       ├── rk3588s.env               #     - RK3588S (Ubuntu 24.04)
│       ├── rk3568.env                #     - RK3568
│       ├── rk3568-ubuntu22.env
│       ├── rv1126.env
│       ├── rv1126bp.env
│       └── rk3588s-ubuntu-24.env
│
├── scripts/                          # ★ Host-side scripts
│   ├── port_calc.sh                  #   Auto port calculation (PORT_SLOT → SSH/GDB ports)
│   └── create_platform.sh            #   Create new platform config wizard
│
├── docker/
│   ├── dev-env-clientside/           # ★ Main build target (client dev environment)
│   │   ├── build.sh                  #   Docker build entry (load 3 layers → build)
│   │   ├── Dockerfile                #   5-stage multi-stage build
│   │   ├── stage_1_base/             #   Stage 1: base OS + package installation
│   │   │   └── scripts/
│   │   │       └── setup_base.sh     #     apt source replace + packages + user/timezone
│   │   ├── stage_2_tools/            #   Stage 2: dev tools (CUDA, OpenCV, toolchain)
│   │   │   └── scripts/
│   │   │       ├── install_dev_tools.sh
│   │   │       ├── install_cuda.sh
│   │   │       ├── install_opencv.sh
│   │   │       └── gitlfs_tracker.sh
│   │   ├── stage_3_sdk/              #   Stage 3: SDK install (template rendering → git clone)
│   │   │   ├── configs/*_template    #     Script templates (${VAR} placeholders)
│   │   │   └── scripts/
│   │   │       └── install_sdk.sh_template
│   │   ├── stage_4_config/           #   Stage 4: write env vars / proxy config into container
│   │   │   ├── configs/*_template
│   │   │   └── scripts/configure_env.sh
│   │   └── stage_5_final/            #   Stage 5: workspace init + entrypoint
│   │       ├── configs/*_template
│   │       └── scripts/
│   │           ├── setup_workspace.sh_template
│   │           └── entrypoint.sh_template
│   │
│   └── libs/                         # ★ Deleted (all code migrated to stage scripts)
│
├── project_handover/                 # ★ Deliverable (actual deployment)
│   ├── clientside/
│   │   ├── .env -> ../configs/platforms/<platform>.env   (symlink)
│   │   ├── .env-independent -> ../configs/platform-independent/common.env
│   │   ├── volumes -> /path/to/host/volumes              (symlink)
│   │   └── ubuntu/
│   │       ├── docker-compose.yaml  #   Container runtime config (image, ports, volumes, env)
│   │       ├── harbor.crt           #   Harbor TLS certificate
│   │       └── ubuntu_only_entrance.sh
│   └── scripts/
│       └── archive_tarball.sh       #   Package deliverable
│
└── docs/                             # ★ Documentation (bilingual, en/ and zh/ trees)
    ├── en/                           #   English docs
    └── zh/                           #   Chinese docs
```

---

## 2. Core Problem Diagnosis

### Problem 1: Fragile Template Rendering System (Stage 3/4/5 `${VAR}` substitution)

**Before**: Each `*_template` file was substituted variable-by-variable via `env | cut` + `sed` during Docker build.
**Risk**: Variable values containing special characters (`/`, `&`, `\n`) would cause sed to fail; hard to debug; this logic was duplicated across three stages.
**Resolution**: ✅ **Done** — `envsubst` (from `gettext-base`) now handles all substitution. The sed-based system has been removed.

### Problem 2: `libs/` Modules Not Actually Used — ✅ Resolved

**Before**: The `libs/` directory has been completely deleted. All functionality has been migrated to the stage-specific scripts under `docker/dev-env-clientside/`. `envsubst` replaced the `sed` template system.
**Result**: Eliminated duplicate maintenance and source of confusion.

### Problem 3: `docker-compose.yaml` Manually Maintained, Disconnected from `.env` Config — ✅ Resolved

**Before**: The dynamic generator in `ubuntu_only_entrance.sh` is now fully variable-driven. Eight previously hardcoded values (restart policy, privileged, serial device, shm_size, NVIDIA settings, Samba permissions) have been extracted to `configs/defaults/` and can be overridden per platform.
**Result**: Compose config is 100% driven by the three-layer config system.

### Problem 4: Shell Scripts Carrying Configuration Management Responsibility

**Current state**: What `setup_base.sh` does (detecting distro, installing packages, creating users, configuring timezone) is fundamentally **configuration management** — which is exactly what Ansible was designed for, with all edge cases already handled.

---

## 3. External Tools — One-by-One Analysis

### Tool 1: Docker Compose (immediately usable, low cost)

**What it can replace**:
- `project_handover/clientside/ubuntu/docker-compose.yaml` is already in use, but not at full potential
- Compose supports `.env` file variable injection, allowing `${IMAGE_NAME}`, `${CLIENT_SSH_PORT}`, `${VOLUMES_ROOT}` in the compose file to be auto-read from your `.env` layers

**Specific improvement**:
```yaml
# After refactoring docker-compose.yaml
services:
  dev-env:
    image: ${REGISTRY_URL}/${IMAGE_NAME}:${PROJECT_VERSION}
    container_name: ${CONTAINER_NAME}
    ports:
      - "${CLIENT_SSH_PORT}:22"
      - "${GDB_PORT}:${GDB_PORT}"
    volumes:
      - ${HOST_VOLUME_DIR}:${WORKSPACE_ROOT}/docker_volumes
```
Then `docker compose --env-file configs/platforms/rk3588s.env up`.

**Pros**: Zero learning curve, you're already using Compose, just extend it
**Cons**: Cannot solve package installation inside the Dockerfile, only handles runtime config

---

### Tool 2: Ansible (moderate cost, high return)

**What it can replace**: Everything in `setup_base.sh` — package installation, user creation, timezone config, apt source replacement

**Greatest value**: Ansible's `ansible.builtin.apt` module **natively handles all your cross-distro issues**:
```yaml
# Replace your func_install_system_core()
- name: Install core packages
  ansible.builtin.apt:
    name:
      - sudo
      - apt-transport-https
      - ca-certificates
      - libncursesw6
    state: present
    update_cache: yes

# Replace your func_replace_apt_source()
- name: Replace apt source (Ubuntu 24.04+)
  ansible.builtin.copy:
    content: |
      Types: deb
      URIs: http://mirrors.aliyun.com/ubuntu
      Suites: {{ ansible_distribution_release }} ...
    dest: /etc/apt/sources.list.d/ubuntu.sources
  when: ansible_distribution_version is version('24.04', '>=')
```

**Ansible usage in Docker** (integrating with your build flow):
```dockerfile
# Stage 1 refactoring approach
FROM ubuntu:${OS_VERSION} AS stage_1st_base
RUN apt-get update && apt-get install -y ansible
COPY ansible/playbook_base.yml /tmp/
RUN ansible-playbook /tmp/playbook_base.yml --connection=local
```

**Pros**:
- Native cross-distro (ubuntu/debian/alpine/rhel in one playbook)
- Idempotent (safe to run multiple times)
- Far more readable than shell scripts
- Community role library (Ansible Galaxy) for reuse

**Cons**:
- Learning curve (YAML + Ansible concepts)
- Slightly longer Docker build time (need to install Ansible itself)
- Slightly larger image size

---

### Tool 3: Dev Containers (devcontainer.json)

**What it can replace**: The entire purpose of `project_handover/clientside/ubuntu/` — let developers start a standardised development environment with one click

**What it is**: VS Code / GitHub Codespaces open standard; one `devcontainer.json` file describes the dev environment (base image, mounts, port forwarding, VS Code extensions)

**Integration approach**:
```
.devcontainer/
├── devcontainer.json          # Describe dev environment (references your Dockerfile)
└── docker-compose.yaml        # Optional: references your compose file
```
```json
{
  "name": "RK3588S Dev Env",
  "dockerComposeFile": "../project_handover/clientside/ubuntu/docker-compose.yaml",
  "service": "dev-env",
  "workspaceFolder": "/development",
  "forwardPorts": [2109, 2345],
  "extensions": ["ms-vscode.cpptools", "ms-python.python"]
}
```

**Pros**:
- Native VS Code support, excellent UX (one-click container launch)
- Fully compatible with your existing Dockerfile + Compose, minimal changes
- Makes your tool AI-code-assistant friendly (GitHub Copilot, Cursor natively understand devcontainer.json)

**Cons**:
- Tied to VS Code ecosystem (though the spec is open)
- Does not solve cross-platform issues in the Dockerfile itself

---

### Tool 4: `envsubst` (immediately usable, replaces current template rendering)

**What it can replace**: The `env | cut | sed` template rendering logic duplicated three times across Stage 3/4/5

**Resolution**: ✅ **Done** — `envsubst` now handles all template rendering. One line replaces 70+ lines of complex sed substitution loops.

---

### Tool 5: Nix / NixOS (long-term, high difficulty, disruptive)

**What it can replace**: The entire build system

**What it is**: Declarative package manager that eliminates "works on my machine" by cryptographically locking all dependencies, guaranteeing complete reproducibility.

**Relationship to your project**: Nix can replace the entire Docker dev environment with `nix develop`, without needing Docker. A `flake.nix` would be the combination of your `.env` + `Dockerfile` + `docker-compose.yaml`.

**Pros**: True "arbitrary config changes adapt to any build", lighter weight
**Cons**: Steep learning curve, embedded ecosystem support not as strong as Yocto, limited resources

---

## 4. Refactoring Priority Recommendations

Ranked by **benefit/cost ratio**:

```
Priority 1 (done, low cost):
  ├── Replace sed template rendering with envsubst in three stages ✅
  │     - Change: Dockerfile Stage 3/4/5 RUN set -a... blocks
  │     - Benefit: Eliminate 70+ lines of duplicate code, fix special char bugs
  └── docker-compose.yaml: adopt .env variable injection ✅
        - Change: Replace hardcoded values in compose file with ${VAR}
        - Benefit: No manual compose editing when switching platforms

Priority 2 (medium-term, worth investing):
  ├── Add .devcontainer/devcontainer.json ✅
  │     - Change: Add new directory and file, does not affect existing code
  │     - Benefit: VS Code one-click dev, AI-friendly, modern project appearance
  └── ~~Merge libs/iv_scripts/setup_base.sh into clientside version~~ ✅ Done (deleted, stage_1 version is the sole source)

Priority 3 (long-term, architectural upgrade):
  └── setup_base.sh → Ansible playbook
        - Change: Rewrite Stage 1 package installation logic
        - Benefit: Native cross-distro, readability++, reuse community roles

Priority 4 (exploratory, depends on project direction):
  └── Not limiting to Docker: Vagrant + Ansible
        - Support VMware, VirtualBox, KVM
        - High cost, only if there is a clear requirement
```

---

## 5. Making the Tool AI-Operable Infrastructure

This is the most important section. The question: **users can use it directly, but AI agents should also be able to use it**.

### Current Problems
For an AI agent (like Claude Code) to help a user create a new RK3568 Ubuntu 24.04 platform, it currently needs to:
1. Understand the three-layer config system
2. Understand which fields are required
3. Manually write the `.env` file
4. Know whether to modify the compose file

All of this is **implicit knowledge** for the AI — requires reading code to understand.

### Improvement Direction: Explicit Configuration Schema

**Option A: JSON Schema** ✅ Done
A `platform_schema.json` in `configs/` describes each field's meaning, type, whether required, and valid value ranges. The AI can then generate correct `.env` files without reading all the code.

**Option B: Platform Wizard (upgraded `create_platform.sh`)** ✅ Done
Added `--non-interactive` mode. Two modes coexist: humans use the menu, AI uses parameters.

### AI-Friendly Project Checklist

| Feature | Status | Notes |
|------|----------|----------|
| Config has schema documentation | ✅ JSON Schema | `configs/platform_schema.json` |
| Operations can run non-interactively | ✅ Done | `create_platform.sh --non-interactive` |
| Clear entry command | ✅ Done | `build.sh`, `./harbor` |
| Clear error messages | ⚠️ Partial | Unified format is P3 |
| devcontainer.json | ✅ Done | `.devcontainer/devcontainer.json` |
| Config and implementation separated | ✅ Done | Core architecture, keep as-is |

---

## 6. Conclusion: What to Do, What Not to Do

### Do
- **Continue the three-layer config system** — this is HarborPilot's most valuable part, and the "intent layer" AI can operate
- **JSON Schema** ✅ — minimal cost, maximum value
- **Use envsubst instead of sed** ✅ — this was the easiest technical debt to fix
- **devcontainer.json** ✅ — modernises the project

### Don't Do (for now)
- **Full migration to Ansible** — unless there's a clear multi-distro requirement, current shell scripts are sufficient
- **Support non-Docker virtualisation** — Vagrant/KVM direction, high cost, no concrete requirement
- **Implement a Yocto-like layer system yourself** — your goal is a development environment, not a system builder; these are different problems

### One-line Summary
> **HarborPilot's core value is already established: config-driven embedded development environments. What's needed now is not a ground-up rewrite, but using existing tools to fill execution-layer gaps (envsubst ✅, devcontainer ✅, JSON Schema ✅), making it infrastructure that AI agents can operate.**
