# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- Remove legacy n8.env and harbor-cert.pem


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
- rv1126`s port map conflict with n8

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
- n8.env and offline.env in configs
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
