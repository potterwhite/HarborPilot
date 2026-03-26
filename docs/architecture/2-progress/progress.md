# HarborPilot — Project Progress

> Last updated: 2026-03-26

---

## Overall Status

| Phase | Description | Status |
|---|---|---|
| **Phase 0** | Initial implementation — multi-stage Docker build | ✅ Done |
| **Phase 1** | Multi-platform support + config system | ✅ Done |
| **Phase 2** | AI docs system + developer experience | 🔄 In Progress |
| **Phase 3** | Architecture modernization (envsubst, devcontainer, schema) | ⏳ Pending |

**Currently active:** Phase 2 — Injecting AI-first documentation system

---

## Phase 0 — Initial Implementation

| Step | Description | Version / Commit |
|---|---|---|
| **0.1** | Single-platform Docker build (n8/rk3588s) | v0.5.0 |
| **0.2** | 5-stage Dockerfile: base → tools → SDK → config → final | v0.5.0 |
| **0.3** | Combined 5 separate Dockerfiles into single monolithic Dockerfile | v1.0.0 |
| **0.4** | Multi-platform support: rv1126bp, rk3588s | v1.0.1 |
| **0.5** | RK3568 support, SDK versioning separated from project version | v1.1.0 |
| **0.6** | Three-layer config system, release-please automation | v1.5.0–v1.6.0 |
| **0.7** | Chinese docs, quick start guide | v1.6.0 |

---

## Phase 1 — Port System + Platform Wizard + Cross-Platform Fixes

| Step | Description | Commit |
|---|---|---|
| **1.1** | PORT_SLOT auto-calculation system | `b9424fd` |
| **1.2** | Migrate all platforms to PORT_SLOT | `f633569` |
| **1.3** | Interactive platform creation wizard | `408d340` |
| **1.4** | Sort platform list by PORT_SLOT order | `2b5aa14` |
| **1.5** | Split GitLab/Harbor into separate IP+port vars | `2ca4cff` |
| **1.6** | Add OS_DISTRIBUTION field to platform config | `476caf1` |
| **1.7** | Fix apt source replacement for Ubuntu 22.04/24.04+ and Debian | `a53f597` |
| **1.8** | Fix libncursesw5 → libncursesw6 cross-version | `be98dcf` |
| **1.9** | Handle pre-existing UID/GID for Ubuntu 24.04 | `ebe08ca` |
| **1.10** | Skip python2.7 on Ubuntu ≥ 22.04, use libncurses-dev | `22b9086` |
| **1.11** | Replace sed template rendering with envsubst in all 3 stages | `306e121` |
| **1.12** | Add JSON Schema for platform configuration | `793a7f8` |
| **1.13** | Add .devcontainer/devcontainer.json | `8a7d52b` |
| **1.14** | Add --non-interactive mode to create_platform.sh | `ba33bf1` |

---

## Phase 2 — AI Documentation System (In Progress)

| Item | Status |
|---|---|
| Restructure `doc/` → `docs/architecture/` (3-tier: for-ai / progress / highlights) | ✅ Done |
| Create `ai_docs_system_template.md` (portable template v2) | ✅ Done |
| Create `CLAUDE.md` at repo root | ✅ Done |
| Create `guide.md` (AI agent working rules) | ✅ Done |
| Create `codebase_map.md` (full file-by-file reference) | ✅ Done |
| Create `progress.md` (this file) | ✅ Done |
| Create `NEED_TO_DO.md` (backlog) | ✅ Done |
| Create `00_INDEX.md` (navigation hub) | ✅ Done |
| Fix README.md `doc/` → `docs/` references | ✅ Done |

---

## Phase 3 — Architecture Modernization (Pending)

Based on `refactoring_plan.md`, priorities:

| Item | Priority | Status |
|---|---|---|
| docker-compose.yaml use `${VAR}` + `.env` injection (no more hardcoded values) | P1 | ⏳ |
| Extend devcontainer.json for end-user platforms | P2 | ⏳ |
| Merge `libs/iv_scripts/setup_base.sh` into clientside version (remove duplication) | P2 | ✅ Resolved — entire `docker/libs/` deleted |
| `setup_base.sh` → Ansible playbook (long-term) | P3 | ⏳ |
| Unified error format across all scripts | P3 | ⏳ |

---

## Future Ideas (Not Scheduled)

- Ansible-based Stage 1 for native cross-distro support
- Vagrant + Ansible for non-Docker virtualization
- CI/CD pipeline for automated platform image builds
- Nix flake as alternative to Docker (experimental)
