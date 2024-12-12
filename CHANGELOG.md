
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.6] - 2024-12-12
### Changed
- Utilize Harbor for docker image management instead of docker registry
- Add version_of_dev_env.sh to docker image

## [0.5.5] - 2024-12-09
### Added
- symbolic link "/usr/local/bin/qmake" to "/development/sdk/buildroot/output/rockchip_rk3588/host/bin/qmake"

## [0.5.4] - 2024-12-04
### Added
- /usr/bin/python symlink for python2.7
- /dev:/dev volume mount
- "upgrade_tool" symlink for Linux Upgrade Tool

### Changed
- gitlfs_tracker.sh notify message at the end

## [0.5.3] - 2024-12-03
### Fixed
- some bugs in project_handover/ubuntu/
- fixed "unable to rm" problem when executing pull_sdk.sh
- change owner of `${WORKSPACE_ROOT}` to `${DEV_USERNAME}`

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