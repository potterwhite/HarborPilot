# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [1.1.2] - 2025-06-30
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
- [Clientside][Serverside]Added PROJECT_RELEASE_DATE environment variable and its output display in both clientside and serverside commands
- [Clientside]Added automatic Samba mount on clientside startup
- [Serverside]Added git-lfs installation and configuration
- [Clientside]Added support for git-lfs file restoration when executing pull_sdk.sh script

### Changed
- Updated workspace subdirectory creation in 5th stage to strictly follow environment variables
- Modified SSH port configuration to differentiate between clientside and serverside
- Updated pull_sdk.sh with the default branch name

### Fixed
- Enhanced workspace directory structure compliance with environment variables
- Improved SSH port isolation between clientside and serverside containers


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
- Added version_of_dev_env.sh script for environment version tracking in serverside image


## [0.5.9] - 2024-12-25
### Added
- Add tree command support via `apt install tree`
- Add man documentation support controlled by `.env` configuration
- Add cmake and ctest from buildroot (same location as qmake)
- Add branch name parameter support in pull_sdk.sh (defaults to 'main' if not specified)

### Fixed
- Fix version_of_dev_env.sh environment mismatched problem
- Fix distcc_watcher.sh disable functionality not working properly

### Changed
- Enhance pull_sdk.sh to support both 'all' parameter and specific branch names

## [0.5.8] - 2024-12-20
### Added
- Add distcc_switcher.sh script to docker image
- Fix host name of serverside container

## [0.5.7.1] - 2024-12-19
### Added
- Add distccd server support but only in frontground
- Add a tool in serverside that could start harbor (not completed)

### Changed
- Host tools (e.g., ubuntu_only_entrance.sh && serverside_only_entrance.sh)
  remove container will remove image at the same time

## [0.5.7] - 2024-12-14
### Changed
- Reorganize the structure of project

### Added
- Add distcc support with clientside docker image
- Add serverside docker image for distccd server
  (and the sdk the buildroot is using internal toolchain so distccd server is not used in this version)

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

[0.5.0]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v0.5.0

[0.5.1]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v0.5.1

[0.5.3]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v0.5.3

[0.5.4]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v0.5.4

[0.5.5]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v0.5.5

[0.5.6]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v0.5.6

[0.5.7]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v0.5.6

[0.5.7.1]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v0.5.7.1

[0.5.8]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v0.5.8

[0.5.9]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v0.5.9

[0.6.1]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v0.6.1

[0.6.2]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v0.6.2

[0.7.0]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v0.7.0

[01.0.0]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v01.0.0

[01.0.1]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v01.0.1

[01.0.2]: https://github.com/potterwhite/DockerDevEnvTemplate/releases/tag/v01.0.2
