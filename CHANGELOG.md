# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.1](https://github.com/potterwhite/HarborPilot/compare/v2.1.0...v2.1.1) (2026-06-29)


### 🐛 Fixed

* create PR instead of direct push for PROJECT_RELEASE_DATE ([7da3b53](https://github.com/potterwhite/HarborPilot/commit/7da3b53d779b0322d893b1c03d4c5e73d2c1630c))
* create PR instead of direct push for PROJECT_RELEASE_DATE ([85224dc](https://github.com/potterwhite/HarborPilot/commit/85224dceac450b7276d16f5c2c51e2cf08a51131))

## [2.1.0](https://github.com/potterwhite/HarborPilot/compare/v2.0.0...v2.1.0) (2026-06-29)


### ✨ Added

* add build CLI subcommand and extract shared build pipeline ([ea71afc](https://github.com/potterwhite/HarborPilot/commit/ea71afcb693b3a37087b0021b7f52b9af009b4fc))
* add container management CLI and refactor command structure ([41b0d0f](https://github.com/potterwhite/HarborPilot/commit/41b0d0f84fe1cf8eeb9ade86f5f2523eddeb4731))
* add SDK and extra volume questions to host config wizard ([2c0164f](https://github.com/potterwhite/HarborPilot/commit/2c0164f4bb2701f8edb54e571194d94366807e28))
* **entrance:** add CLI args for non-interactive host config creation ([d7ab0f1](https://github.com/potterwhite/HarborPilot/commit/d7ab0f10c536ce82b163b9d53c73031cbfd335c2))
* **ui:** expand host config wizard with all host-level questions ([62b0fe1](https://github.com/potterwhite/HarborPilot/commit/62b0fe1b5a5fbc11e690b0d0d3b0f87db880b768))


### 🐛 Fixed

* ${REGISTRY_URL} could not be parsed correctly with sed regular expression ([5c4f980](https://github.com/potterwhite/HarborPilot/commit/5c4f9801a6ca19ac655069bc2d380b3218daf2a2))
* add missing BASE_PLATFORM to TEMPLATE.env.example ([9400c00](https://github.com/potterwhite/HarborPilot/commit/9400c004fb7af4140530c403ab274eaa844a18a4))
* allow PORT_SLOT=0 to trigger auto-calculation ([4b8bc28](https://github.com/potterwhite/HarborPilot/commit/4b8bc28fee0e0fdb317405c883811a6b7f983686))
* initialize volumes and image name for container-start ([8c5382d](https://github.com/potterwhite/HarborPilot/commit/8c5382d24fabc41e1573fb9ac64b08f8ac371b43))
* keep Additional Toggles commented but update values from Layer 1 ([586021a](https://github.com/potterwhite/HarborPilot/commit/586021a623f084516d453373f4d3cad80e48c9af))
* sync Additional Toggles with Layer 1 defaults when generating host config ([fb2c33b](https://github.com/potterwhite/HarborPilot/commit/fb2c33b257f69f450358477794024c61b1d22f2a))
* **ui:** read all question defaults from Layer 1 config ([34a614e](https://github.com/potterwhite/HarborPilot/commit/34a614e3f4643c32a8e06f9ccc3e30ce197e0f0a))
* update Created date in generated host config to current date ([74c9733](https://github.com/potterwhite/HarborPilot/commit/74c9733acb756dbf2750ba49f4e6f9d69f3df7ea))
* use arithmetic assignment to avoid set -e exit in volume loop ([da56d40](https://github.com/potterwhite/HarborPilot/commit/da56d403a2af8f82f4202ef60e1e90c0878bbce3))

## [2.0.0](https://github.com/potterwhite/HarborPilot/compare/v1.13.0...v2.0.0) (2026-06-27)


### ⚠ BREAKING CHANGES

* Old project_handover/clientside/ directory removed. Container lifecycle now lives in scripts/libs/handover/ as a modular system. Entry point changed from ubuntu_only_entrance.sh to scripts/libs/handover/entrance.sh. Harbor script now handles both build and package workflows through a single entry point.

### ✨ Added

* **host:** add --host CLI flag for multi-host config support ([0df06de](https://github.com/potterwhite/HarborPilot/commit/0df06de1fb7bc2c84ea4e3522e5a0b518b1d818c))
* **platform:** add Jetson Orin NX platform support ([667c2da](https://github.com/potterwhite/HarborPilot/commit/667c2dabe938b4103131aa34cd14ff36f22ddb77))
* restructure handover as dynamic module ([c4d754e](https://github.com/potterwhite/HarborPilot/commit/c4d754e1e020a07933b628b56fe32d680763fbaf))


### 🐛 Fixed

* **config:** add Layer 1 fallbacks for all missing variables ([4bfdfad](https://github.com/potterwhite/HarborPilot/commit/4bfdfad61cf98bfe6bc090e683a64f81244a6ded))
* disable OpenCode by default due to slow curl-pipe-bash installer ([8c89ffa](https://github.com/potterwhite/HarborPilot/commit/8c89ffa8cda7b634ab6308155f5ec3186a080e0e))
* **entrance:** respect HOST_CONFIG in env_loader ([e1941b2](https://github.com/potterwhite/HarborPilot/commit/e1941b24195cfef203774e68f9ca58337117a7f5))
* **handover:** correct source paths in entrance.sh ([8eb6525](https://github.com/potterwhite/HarborPilot/commit/8eb65256c7081ed5ca05f430f5ba0b0465c0aa93))
* **handover:** resolve symlinks in SCRIPT_DIR to fix path resolution ([bb34177](https://github.com/potterwhite/HarborPilot/commit/bb3417752a2df4736a37cb969c940d8acbfe15a4))
* **handover:** restore default volume dir with symlink mechanism ([a08913d](https://github.com/potterwhite/HarborPilot/commit/a08913d0d8cee1342d3d4a6c6ba5ef4408a7f5c2))
* **harbor:** load host config for package mode too ([2767aa3](https://github.com/potterwhite/HarborPilot/commit/2767aa3c505e23d873d913a0453ade37703fd25b))
* **package:** load defaults before platform config in package mode ([97f3f5b](https://github.com/potterwhite/HarborPilot/commit/97f3f5b8b3ac6456671c4ad3f8653b6e459adf16))
* **port_calc:** PORT_SLOT always takes priority over Layer 1 fallbacks ([7a92bbc](https://github.com/potterwhite/HarborPilot/commit/7a92bbcdf890940cccccea13c7f0855f29312b25))
* **port_calc:** treat PORT_SLOT=0 as placeholder, not active mode ([9b16f95](https://github.com/potterwhite/HarborPilot/commit/9b16f9590f43b6666fd441abe1471064909b7a0b))
* remove debug `find /tmp/` commands from Dockerfile ([22a8acd](https://github.com/potterwhite/HarborPilot/commit/22a8acd0d06350e3f2e829e561c1451f78ef1e11))
* skip SDK env validation when INSTALL_SDK=false ([0715eab](https://github.com/potterwhite/HarborPilot/commit/0715eaba74a18579ca146e7611e725b022a42710))
* **ui:** auto-derive REGISTRY_URL, fix volume path bug, handle directory removal ([2e9458e](https://github.com/potterwhite/HarborPilot/commit/2e9458e2690033f7433bfbb5a78f8fe5da0f155c))
* **ui:** use dynamic padding for box menus to fix alignment ([a15e442](https://github.com/potterwhite/HarborPilot/commit/a15e442661c6042e2903ba45e9dc48326b90e525))
* **utils:** detect TLS error on docker login and show fix instructions ([89baad8](https://github.com/potterwhite/HarborPilot/commit/89baad8fd1077f6be44b6c276d0919d4cef7c281))
* **utils:** run docker login interactively, capture stderr separately ([4c92ee8](https://github.com/potterwhite/HarborPilot/commit/4c92ee85881ff21f5c556c19e5f1c751ac17c122))
* **volumes:** fix circular symlink, use directory directly when target equals default ([55f503f](https://github.com/potterwhite/HarborPilot/commit/55f503fc2e2c6ff5f6a1633debb01d0a29b717ab))

## [1.13.0](https://github.com/potterwhite/HarborPilot/compare/v1.12.0...v1.13.0) (2026-06-25)


### ✨ Added

* **config:** add per-component install flags for stage_2 tools ([1362d17](https://github.com/potterwhite/HarborPilot/commit/1362d17530541c77e8e1ea1e4bb73a35a7073eb4))
* **config:** add per-tool install flags for AI coding tools ([468a89a](https://github.com/potterwhite/HarborPilot/commit/468a89a27454d95475283c039076867ef46eb058))
* **config:** AI tools toggles + defaults reorganization + template-based host creation ([18aed3b](https://github.com/potterwhite/HarborPilot/commit/18aed3be6d4657571b15058cc7437eee71eda6f9))


### 🐛 Fixed

* **build:** include Layer 3 host config in build-arg collection ([0572830](https://github.com/potterwhite/HarborPilot/commit/0572830d847a97573ad536c8eb4f91b0e2d834f0))
* **build:** include Layer 3 host config in build-arg collection ([633f6a7](https://github.com/potterwhite/HarborPilot/commit/633f6a78ceb385e43389eaee338a94da04fbc18f))
* **ui:** use TEMPLATE.env.example when creating host configs ([528bbdf](https://github.com/potterwhite/HarborPilot/commit/528bbdf1b5cc827ec11f37ef4f09656e0d1b5280))

## [1.12.0](https://github.com/potterwhite/HarborPilot/compare/v1.11.2...v1.12.0) (2026-06-24)


### ✨ Added

* add BASE_PLATFORM to host config for platform auto-resolution ([7d2b162](https://github.com/potterwhite/HarborPilot/commit/7d2b162cc847008521308735a1d5c0837ea4eed8))
* **config:** add Configurations menu to ./harbor ([589349e](https://github.com/potterwhite/HarborPilot/commit/589349ee8e8741e667dcd103fc166856d1ef1c07))
* **ui:** add host configuration check and prompt ([055760a](https://github.com/potterwhite/HarborPilot/commit/055760ad72c34bb03e414267cb7d0fc29dd0a7e0))
* **ui:** add recommended options to prompt_simple() ([fce3deb](https://github.com/potterwhite/HarborPilot/commit/fce3debe5a5ba058586150e7cc8fc83f391c10a7))


### 🐛 Fixed

* **build:** add missing MIT license headers to scripts/lib/ ([d1920d9](https://github.com/potterwhite/HarborPilot/commit/d1920d9d8059329c80ca9dd46db174babb1756d8))
* **config:** move REGISTRY_URL and SDK_GIT_REPO from Layer 2 to Layer 3 ([967867f](https://github.com/potterwhite/HarborPilot/commit/967867f9403a36fc8f419a8c4a39c71fcfdf841a))
* rename remaining 3_host to 3_hosts across all files ([63f2cb0](https://github.com/potterwhite/HarborPilot/commit/63f2cb0d0eff9d3b921057a9f8453918ae3946ea))
* **ui:** fix question numbering and harbor exit on skip ([0ee1651](https://github.com/potterwhite/HarborPilot/commit/0ee16519f61f33fbdc8dd310ad2001d0533383ae))
* **ui:** reorder main menu and fix box alignment ([5c5a9e0](https://github.com/potterwhite/HarborPilot/commit/5c5a9e0a3ead147d7061ff409489d1442334ba5b))

## [1.11.2](https://github.com/potterwhite/HarborPilot/compare/v1.11.1...v1.11.2) (2026-06-11)


### 🐛 Fixed

* enable variable expansion in GPU section heredoc ([38e5814](https://github.com/potterwhite/HarborPilot/commit/38e5814fc7c17738765225f0e41a2a19e6dd890f))
* enable variable expansion in GPU section heredoc ([b356285](https://github.com/potterwhite/HarborPilot/commit/b356285c2aeb1b7e24489b85fe3d737fc70c6f01))

## [1.11.1](https://github.com/potterwhite/HarborPilot/compare/v1.11.0...v1.11.1) (2026-06-11)


### 🐛 Fixed

* ai-tools added (not tested yet) ([fdfc1ef](https://github.com/potterwhite/HarborPilot/commit/fdfc1ef4dafd5d442a563cc346c8deeced0b4576))
* ai-tools installation improvements and platform config updates ([2e80af8](https://github.com/potterwhite/HarborPilot/commit/2e80af88b94efd5b592db194dcd20f25110c30b0))

## [1.11.0](https://github.com/potterwhite/HarborPilot/compare/v1.10.0...v1.11.0) (2026-04-23)


### ✨ Added

* add support for EXTRA_VOLUME mounts and AI dev tools installation ([#20](https://github.com/potterwhite/HarborPilot/issues/20)) ([d25d2e5](https://github.com/potterwhite/HarborPilot/commit/d25d2e529a9abb2d5c3885fb9648295c930818c4))

## [1.10.0](https://github.com/potterwhite/HarborPilot/compare/v1.9.0...v1.10.0) (2026-03-30)


### ✨ Added

* Phase 3 fix + Phase 4 ASO steps 4.1–4.4 complete ([8636718](https://github.com/potterwhite/HarborPilot/commit/8636718d8bb7bbcfe7ff829e9d7c92118ddbb6d2))
* Phase 3 fixes + Phase 4 ASO strategy (4.1–4.4 done) ([#17](https://github.com/potterwhite/HarborPilot/issues/17)) ([8636718](https://github.com/potterwhite/HarborPilot/commit/8636718d8bb7bbcfe7ff829e9d7c92118ddbb6d2))

## [1.9.0](https://github.com/potterwhite/HarborPilot/compare/v1.8.0...v1.9.0) (2026-03-28)


### ✨ Added

* add harbor main menu, handover packaging, and docs bilingual restructuring ([#15](https://github.com/potterwhite/HarborPilot/issues/15)) ([0606d08](https://github.com/potterwhite/HarborPilot/commit/0606d086f599314cbbfcdf7d9f3a2dcd7785bdce))

## [1.8.0](https://github.com/potterwhite/HarborPilot/compare/v1.7.1...v1.8.0) (2026-03-27)


### ✨ Added

* CHIP_FAMILY/CHIP_EXTRACT_NAME migration, harbor grouping, competitive analysis, Phase 4 MCP plan ([f198be9](https://github.com/potterwhite/HarborPilot/commit/f198be9af8b06d0ddfcd60e59e8f4493fae3dfa1))

## [1.7.1](https://github.com/potterwhite/HarborPilot/compare/v1.7.0...v1.7.1) (2026-03-19)


### 🐛 Fixed

* Recalucate the $DEFAULTS_DIR in ubuntu_only_entrance.sh ([#11](https://github.com/potterwhite/HarborPilot/issues/11)) ([ad469b6](https://github.com/potterwhite/HarborPilot/commit/ad469b67f255634248b2c82be5b307aa764f8d1a))

## [1.7.0](https://github.com/potterwhite/HarborPilot/compare/v1.6.2...v1.7.0) (2026-03-18)


### ✨ Added

* auto-write PROJECT_RELEASE_DATE on release ([#9](https://github.com/potterwhite/HarborPilot/issues/9)) ([5a4850e](https://github.com/potterwhite/HarborPilot/commit/5a4850e96837cc5285fa88a3eb91169fda35ae6c))

## [1.6.2](https://github.com/potterwhite/HarborPilot/compare/v1.6.1...v1.6.2) (2026-03-18)


### 🐛 Fixed

* add x-release-please-version marker and sync VERSION to 1.6.1 ([#7](https://github.com/potterwhite/HarborPilot/issues/7)) ([eaf57bd](https://github.com/potterwhite/HarborPilot/commit/eaf57bde50e5f303ff3fe838c63b03aba9050ab3))

## [1.6.1](https://github.com/potterwhite/HarborPilot/compare/v1.6.0...v1.6.1) (2026-03-18)


### 🐛 Fixed

* **build:** abort on SIGINT and harden CI versioning pipeline ([#5](https://github.com/potterwhite/HarborPilot/issues/5)) ([a268ac8](https://github.com/potterwhite/HarborPilot/commit/a268ac82e72d557d7c137f2c21951aa6f3cb4cae))

* **build:** replace faulty interactive `docker login` probe with a passive `~/.docker/config.json` credential check — eliminates spurious authentication prompts when already logged in
* **config:** correct `package-name` in `release-please-config.json` from `ArcForge` to `HarborPilot`

### ⚙️CI

* extract top-level `VERSION` variable in `common.env` so release-please can bump it automatically via `extra-files`, removing the need for manual version edits
* clear `PROJECT_RELEASE_DATE` — the CI pipeline now writes the date at release time instead of committing a static value 

---

## [1.6.0](https://github.com/potterwhite/HarborPilot/compare/v1.5.0...v1.6.0) (2026-03-18)


### ✨ Added

* complete redesign with layered config system and RK3588s support ([#1](https://github.com/potterwhite/HarborPilot/issues/1)) ([847b184](https://github.com/potterwhite/HarborPilot/commit/847b184aa85842d70504dab22fa635f04c87db69))

## [1.5.0](https://github.com/potterwhite/HarborPilot/compare/v1.4.0...v1.5.0) (2026-03-18)

### ✨ Added
* complete redesign with layered config system and RK3588s support ([#1](https://github.com/potterwhite/HarborPilot/issues/1)) ([847b184](https://github.com/potterwhite/HarborPilot/commit/847b184aa85842d70504dab22fa635f04c87db69))
- Layered config system with 11 domain-scoped default files (configs/defaults/*.env)
- RK3588s platform support (configs/platforms/rk3588s.env)
- Release-please automation for automatic versioning and changelog
- License check GitHub Actions workflow
- Chinese documentation: README, Quick Start, Config Layers

### 🐛 Fixed
- Platform config inheritance issues (now uses layered approach)

### ⚡ Improved
- Renamed build-dev-env.sh to harbor for better UX
- Simplified platform configs (~20 lines each vs 150+ lines)
- README comprehensive rewrite with better structure

### 📚 Documentation
- Complete README overhaul with features table
- Quick start guide (doc/quick_start.md, doc/quick_start_cn.md)
- Config layers documentation (doc/config_layers.md, doc/config_layers_cn.md)

### Miscellaneous
- Remove legacy rk3588s.env and harbor-cert.pem


---


## [1.4.0] - 2025-12-04
- add rk3568-ubuntu22 as fifth platform

## [1.3.5] - 2025-11-27
- add libicu-dev for rk3568

## [1.3.4] - 2025-10-24
- update ubuntu`s clientside setup from scratch doc

## [1.3.3] - 2025-08-11
- fixed ubuntu`s clientside setup from scratch doc

## [1.3.2] - 2025-07-31
### Fixed
- volumes dir not tracking the real path of "project_handover/clientside/volumes". Replaced soft symbolic link with realpath to ensure the container mounts the correct directory.

Example: Before, a symlink like `/app/volumes -> /wrong/path` caused mounting issues. Now, using realpath resolves to the actual directory `/correct/path`, fixing the container's volume mount.

## [1.3.1] - 2025-07-29
### Fixed
- rv1126`s port map conflict with rk3588s

## [1.3.0] - 2025-07-26
### Added
- support for rv1126 as 4th platform

## [1.2.1] - 2025-07-14
### Fixed:
- Corrected the `volumes:/dev/ttyUSB0:/dev/ttyUSB0` entry in docker-compose.yml to prevent the creation of a directory instead of a special file when `/dev/ttyUSB0` is missing (e.g., when no serial cable is plugged in).

### Major Improvements:
- Restructured `project_handover` to eliminate multiple `clientside-${platform-name}` instances. Now uses a single platform with a volume soft link pointing to different directories based on the current platform. The volume directory can be configured via the `${HOST_VOLUME_DIR}` environment variable in the platform's `.env` file.


## [1.1.0] - 2025-06-30
### Added
- support for rk3568 as new platform which is 3rd of all
- Introduced `SDK_VERSION` and `SDK_RELEASE_DATE` in `configs/platform-independent/common.env` to separate the SDK version from the main project (image) version.

### Improved
- Corrected the logic in the `_push_and_verify_single_image()` function to properly display `docker push` progress instead of suppressing it.
- Enhanced the `1_specify_platform()` function with robust input validation to prevent errors when non-numeric values are entered.


## [01.0.2] - 2025-06-11
### Improved
- Node.js from 18.18.2 to 22.16.0 for vulnerability detect of trivy in harbor
- docker inspect method so that it can avoid server`s rejection:
```
unknown: current image with "Pending" status of vulnerability scanning cannot be pulled due to configured policy in 'Prevent images with vulnerability severity of "Critical" or higher from running.'
```

## [01.0.1] - 2025-06-10
### Added
- support for rv1126bp platform
- rk3588s.env and offline.env in configs
- verify_git_config.sh in /usr/local/bin
- pull_sdk_by_repo.sh in /usr/local/bin
- proxy.sh in /etc/profile.d/
- apt install repo in docker/dev-env-clientside/stage_2_tools/scripts/install_dev_tools.sh

### Modified
- split one .env into .env and common.env both
- the place where .env and common.env save
- these modifications are coming for different platforms merged in this repository at the same time

## [01.0.0] - 2025-04-03
### Improved
- Combined all five stages from the split five Dockerfiles into a single large Dockerfile, and the tests passed successfully.

## [0.7.0] - 2025-02-24
### Refactored
- clientside scripts

## [0.6.2] - 2025-02-19
### Added
- [Clientside]Added automatic Samba mount on clientside startup
- [Clientside]Added support for git-lfs file restoration when executing pull_sdk.sh script

### Changed
- Updated workspace subdirectory creation in 5th stage to strictly follow environment variables
- Updated pull_sdk.sh with the default branch name

### Fixed
- Enhanced workspace directory structure compliance with environment variables


## [0.6.1] - 2025-02-13
### Added
- Added Python 2.7 and its development packages:
  - python2.7
  - python2.7-dev
  - libpython2.7
  - libpython2.7-dev
- Added project_handover/scripts/archive_tarball.sh script to archive tarball of project_handover directory

### Changed
- Added libncursesw5 to system core packages in stage_1_base/scripts/setup_base.sh


## [0.5.9] - 2024-12-25
### Added
- Add tree command support via `apt install tree`
- Add man documentation support controlled by `.env` configuration
- Add cmake and ctest from buildroot (same location as qmake)
- Add branch name parameter support in pull_sdk.sh (defaults to 'main' if not specified)

### Fixed
- Fix version_of_dev_env.sh environment mismatched problem

### Changed
- Enhance pull_sdk.sh to support both 'all' parameter and specific branch names

## [0.5.8] - 2024-12-20
### Added

## [0.5.7.1] - 2024-12-19
### Added

### Changed
  remove container will remove image at the same time

## [0.5.7] - 2024-12-14
### Changed
- Reorganize the structure of project

### Added

## [0.5.6] - 2024-12-12
### Changed
- Utilize Harbor for docker image management instead of docker registry
- Add version_of_dev_env.sh to docker image

## [0.5.5] - 2024-12-09
### Added
- Add symbolic link "/usr/local/bin/qmake" to "/development/sdk/buildroot/output/rockchip_rk3588/host/bin/qmake"

## [0.5.4] - 2024-12-04
### Added
- Add /usr/bin/python symlink for python2.7
- Add /dev:/dev volume mount
- Add "upgrade_tool" symlink for Linux Upgrade Tool

### Changed
- Update gitlfs_tracker.sh notify message at the end

## [0.5.3] - 2024-12-03
### Fixed
- Fix bugs in project_handover/ubuntu/
- Fix "unable to rm" problem when executing pull_sdk.sh
- Fix owner of `${WORKSPACE_ROOT}` to `${DEV_USERNAME}`

## [0.5.1] - 2024-11-29
### Added
- Windows only entrance script
- Ubuntu only entrance script
### Improved
- build scripts build-dev-env.sh

## [0.5.0] - 2024-11-21

### Added
- Multi-stage build support
- Workspace volume mounting
- Basic development tools installation
- SDK installation support
- Environment configuration functionality
- Modular configuration system
- Build logging and error handling

### Changed
- Restructured project to use multi-stage builds
- Migrated environment variables to .env file
- Optimized build scripts
- Improved documentation structure
- Enhanced build process modularity
- Standardized configuration templates

### Fixed
- Certificate verification issues
- User permission issues
- Build script error handling
- Configuration file generation

### Security
- Enhanced base image security
- Implemented principle of least privilege
- Secure environment variable handling
- Minimized container attack surface

[0.5.0]: https://github.com/potterwhite/HarborPilot/releases/tag/v0.5.0

[0.5.1]: https://github.com/potterwhite/HarborPilot/releases/tag/v0.5.1

[0.5.3]: https://github.com/potterwhite/HarborPilot/releases/tag/v0.5.3

[0.5.4]: https://github.com/potterwhite/HarborPilot/releases/tag/v0.5.4

[0.5.5]: https://github.com/potterwhite/HarborPilot/releases/tag/v0.5.5

[0.5.6]: https://github.com/potterwhite/HarborPilot/releases/tag/v0.5.6

[0.5.7]: https://github.com/potterwhite/HarborPilot/releases/tag/v0.5.6

[0.5.7.1]: https://github.com/potterwhite/HarborPilot/releases/tag/v0.5.7.1

[0.5.8]: https://github.com/potterwhite/HarborPilot/releases/tag/v0.5.8

[0.5.9]: https://github.com/potterwhite/HarborPilot/releases/tag/v0.5.9

[0.6.1]: https://github.com/potterwhite/HarborPilot/releases/tag/v0.6.1

[0.6.2]: https://github.com/potterwhite/HarborPilot/releases/tag/v0.6.2

[0.7.0]: https://github.com/potterwhite/HarborPilot/releases/tag/v0.7.0

[01.0.0]: https://github.com/potterwhite/HarborPilot/releases/tag/v01.0.0

[01.0.1]: https://github.com/potterwhite/HarborPilot/releases/tag/v01.0.1

[01.0.2]: https://github.com/potterwhite/HarborPilot/releases/tag/v01.0.2

[1.2.1]: https://github.com/potterwhite/HarborPilot/releases/tag/v1.2.1

[1.3.0]: https://github.com/potterwhite/HarborPilot/releases/tag/v1.3.0

[1.3.1]: https://github.com/potterwhite/HarborPilot/releases/tag/v1.3.1

[1.3.2]: https://github.com/potterwhite/HarborPilot/releases/tag/v1.3.2

[1.3.3]: https://github.com/potterwhite/HarborPilot/releases/tag/v1.3.3

[1.3.4]: https://github.com/potterwhite/HarborPilot/releases/tag/v1.3.4

[1.3.5]: https://github.com/potterwhite/HarborPilot/releases/tag/v1.3.5

[1.4.0]: https://github.com/potterwhite/HarborPilot/releases/tag/v1.4.0
