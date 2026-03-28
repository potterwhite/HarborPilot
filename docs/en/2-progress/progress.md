# HarborPilot — Project Progress

> Last updated: 2026-03-28 (Phase 4 ASO plan added; original Phase 4 MCP → Phase 5)
> **Related:** [中文版 →](../../zh/2-progress/progress.md)

---

## Overall Status

| Phase | Description | Status |
|---|---|---|
| **Phase 0** | Initial implementation — multi-stage Docker build | ✅ Done |
| **Phase 1** | Multi-platform support + config system | ✅ Done |
| **Phase 2** | AI docs system + developer experience | ✅ Done |
| **Phase 3** | Architecture modernization + code quality audit | 🔄 In Progress |
| **Phase 4** | ASO — AI Search Optimization & content distribution | 📋 Planned |
| **Phase 5** | MCP Server + AI Agent integration | 📋 Planned |

**Currently active:** Phase 3 — Code quality audit + systematic fixes

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
| **1.1** | ✅ PORT_SLOT auto-calculation system | `b9424fd` |
| **1.2** | ✅ Migrate all platforms to PORT_SLOT | `f633569` |
| **1.3** | ✅ Interactive platform creation wizard | `408d340` |
| **1.4** | ✅ Sort platform list by PORT_SLOT order | `2b5aa14` |
| **1.5** | ✅ Split GitLab/Harbor into separate IP+port vars | `2ca4cff` |
| **1.6** | ✅ Add OS_DISTRIBUTION field to platform config | `476caf1` |
| **1.7** | ✅ Fix apt source replacement for Ubuntu 22.04/24.04+ and Debian | `a53f597` |
| **1.8** | ✅ Fix libncursesw5 → libncursesw6 cross-version | `be98dcf` |
| **1.9** | ✅ Handle pre-existing UID/GID for Ubuntu 24.04 | `ebe08ca` |
| **1.10** | ✅ Skip python2.7 on Ubuntu ≥ 22.04, use libncurses-dev | `22b9086` |
| **1.11** | ✅ Replace sed template rendering with envsubst in all 3 stages | `306e121` |
| **1.12** | ✅ Add JSON Schema for platform configuration | `793a7f8` |
| **1.13** | ✅ Add .devcontainer/devcontainer.json | `8a7d52b` |
| **1.14** | ✅ Add --non-interactive mode to create_platform.sh | `ba33bf1` |

---

## Phase 2 — AI Documentation System (Done)

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

## Phase 3 — Architecture Modernization + Code Quality (In Progress)

Based on `refactoring_plan.md`, priorities:

| Item | Priority | Status |
|---|---|---|
| docker-compose.yaml use `${VAR}` + `.env` injection (no more hardcoded values) | P1 | ✅ Done — 8 values extracted to defaults |
| Extend devcontainer.json for end-user platforms | P2 | ⏳ |
| Merge `libs/iv_scripts/setup_base.sh` into clientside version (remove duplication) | P2 | ✅ Resolved — entire `docker/libs/` deleted |
| `setup_base.sh` → Ansible playbook (long-term) | P3 | ⏳ |
| Unified error format across all scripts | P3 | ⏳ |

### Code Quality Audit (2026-03-27)

| Fix | Commit | Notes |
|---|---|---|
| ✅ Dockerfile ARG cross-stage loss (CUDA/OpenCV never installed) | `0dd8a0c` | CRITICAL: 13 ARGs now in ENV block |
| ✅ eval injection in build.sh → `${!name}` | `2872784` | Security fix |
| ✅ UBUNTU_SERVER_IP orphan reference in Samba CIFS mount | `2872784` | Runtime bug fix, add SAMBA_SERVER_IP |
| ✅ Invalid bash expansion `${USE_NVIDIA_GPU,,:-false}` | `2872784` | Correctness fix |
| ✅ harbor: set -e, dead functions, dead code (~100 lines removed) | `0f0e12e` | |
| ✅ Shebangs moved to line 1 in 8 affected scripts | `d729c31` | |
| ✅ Chinese comments translated to English in 5 files | `d729c31` | |
| ✅ setup_workspace.sh: hardcoded "developer" → `${DEV_USERNAME}` | `d729c31` | |
| ✅ Stale documentation updated (UBUNTU_SERVER_IP, SERVER_SSH_PORT refs) | `3a06a79` | |
| ✅ OpenCV build fails: cmake not found (dev_tools ran after OpenCV) | `189a7f6` | Reorder: install dev_tools → OpenCV |
| ✅ pip3 externally-managed-environment on Ubuntu 24.04 (PEP 668) | `90611c0` | Add --break-system-packages |
| ✅ setup_workspace.sh_template: local vars replaced by envsubst → empty | `6f505a6` | CRITICAL: escape \${dir_path} etc. |
| ✅ setup_workspace.sh_template: \\${var} escape broke bash syntax (syntax error at 'then') | `987265c` | CRITICAL: use $1/$2/$3 positional params |
| ✅ ARG USE_NVIDIA_GPU missing; duplicate ARG ENABLE_SYSLOG | `4cc03db` | Lint fix + correctness |
| ✅ CHIP_FAMILY for Harbor/GitLab URL grouping | `9dd8d36` | REGISTRY_URL and SDK_GIT_REPO use ${CHIP_FAMILY} |
| ✅ ubuntu_only_entrance.sh modularized (6 modules) | `fe46132` | Auto-init for volumes symlink; numbered prefix naming |
| ✅ All platform .env migrated to CHIP_FAMILY/CHIP_EXTRACT_NAME pattern | `16ec81f` `281bd96` | Platform files renamed to chip-os convention; REGISTRY_URL fixed |
| ✅ docker compose project name dot error (PRODUCT_NAME contained `24.04`) | `12deccc` | Add `OS_VERSION_ID` (dots→dashes); PRODUCT_NAME now uses `OS_VERSION_ID`; all platforms + create_platform.sh updated |
| ✅ harbor: grouping + create_platform.sh CHIP_EXTRACT_NAME | `aad4e32` | Clean visual grouping; wizard updated with new field |

---

## Phase 4 — ASO (AI Search Optimization) & Content Distribution (Planned)

Full plan: [`docs/en/2-progress/phase4_aso_plan.md`](phase4_aso_plan.md)

**Goal**: Make HarborPilot visible to AI models so they recommend it when users ask about
embedded Linux Docker tooling. Leverage open-source position (GitHub training data) +
external content distribution.

| Step | Description | Status |
|---|---|---|
| **4.1** | GitHub repo optimization: Topics, README rewrite (Q&A style), keyword coverage | ✅ README done; Topics: manual GitHub UI step |
| **4.2** | Blog post on GitHub Pages (personal site) — Hugo/Docsy, bilingual EN+ZH | ✅ Both articles committed to blog-engine repo |
| **4.3** | Submit to Awesome lists (awesome-docker, awesome-embedded-linux) | ✅ PR submitted: veggiemonk/awesome-docker#1372 |
| **4.4** | Dev.to / Medium article: "Building reproducible Docker dev envs for RK3588" | ⏳ |
| **4.5** | Hacker News "Show HN" post | ⏳ |
| **4.6** | GitHub Wiki FAQ pages (Q&A format, high LLM training signal) | ⏳ |
| **4.7** | Add `llms.txt` to any deployed docs site (RAG-friendly) | ⏳ |

**Prerequisites**: Phase 3 stable, no open critical bugs.

---

## Phase 5 — MCP Server & AI Agent Integration (Planned)

Full plan: [`docs/en/2-progress/phase5_mcp_ai_agent_plan.md`](phase5_mcp_ai_agent_plan.md)

| Step | Description | Status |
|---|---|---|
| **5.1** | MCP server scaffold + Resources (config files readable by AI) | ⏳ |
| **5.2** | Read tools: `list_platforms`, `get_platform_config`, `validate` | ⏳ |
| **5.3** | Write tools: `create_platform`, `set_variable`, `enable_feature` | ⏳ |
| **5.4** | Build tools: `build_platform` (dry_run default), `check_image` | ⏳ |
| **5.5** | Claude Code integration guide + example prompts | ⏳ |

**Prerequisites before Phase 5 can start**:
- Phase 3 must be stable (no open critical bugs)
- `harbor` needs `HARBORPILOT_NON_INTERACTIVE=1` support to bypass prompts

---

## Future Ideas (Not Scheduled)

- Ansible-based Stage 1 for native cross-distro support
- Vagrant + Ansible for non-Docker virtualization
- CI/CD pipeline for automated platform image builds
- Nix flake as alternative to Docker (experimental)
