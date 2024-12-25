# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


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
