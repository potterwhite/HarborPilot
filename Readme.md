# Docker Development Environment Template

A template for creating consistent development environments using Docker, specifically designed for embedded development.

## Project Structure

```plaintext
DockerDevEnvTemplate/
├── docker/
│   ├── configs/
│   │   └── bashrc                 # Custom bash configuration
│   ├── scripts/
│   │   ├── entrypoint.sh         # Container entry point script
│   │   ├── install_tools.sh      # Install development tools and SDK
│   │   └── setup_gui.sh          # GUI support setup
│   └── Dockerfile                # Container image definition
├── volumes/
│   ├── src/                      # Source code directory (mounted)
│   ├── build/                    # Build output directory (mounted)
│   ├── configs/                  # Configuration files (mounted)
│   └── sdk/                      # SDK packages (mounted)
├── scripts/
│   ├── build.sh                  # Build docker image
│   └── run.sh                    # Run docker container
├── .env                          # Environment variables
├── .dockerignore                 # Docker build ignore rules
├── docker-compose.yml            # Docker compose configuration
└── start_dev.sh                  # Development environment startup script
```

## Environment Variables

All configurations are centralized in `.env`:

```bash
# Project configuration
PROJECT_NAME=rk3588s-n8          # Project/container name
TAG=1.0                          # Image tag
DOCKER_BUILDKIT=1                # Enable BuildKit

# Working directory configuration
CONTAINER_VOLUME_ROOT=/host_disk          # Container working directory

# SDK configuration
SDK_PKG_NAME=rk3588s-linux_20240913.tar.xz  # SDK package name
SDK_INSTALL_DIR=/opt/rk3588s     # SDK installation directory
```

## Quick Start

1. Clone this repository
2. Place your SDK package in `volumes/sdk/`
3. Run the startup script:
   ```bash
   ./start_dev.sh
   ```

## Variable Passing Chain

The environment variables are passed through multiple stages:
1. `.env` defines the initial values
2. `docker-compose.yml` reads from `.env` and passes to Dockerfile via build args
3. Dockerfile receives them using ARG directive
4. Finally set as ENV in Dockerfile for runtime usage

## Features

- Centralized configuration in `.env`
- Consistent development environment
- Automated SDK installation during build
- Volume mapping for persistent data
- GUI application support
- USB device mapping

## Volume Structure

The `volumes` directory contains:
- `src/`: Source code (read-write)
- `build/`: Build outputs (read-write)
- `configs/`: Configuration files (read-only)
- `sdk/`: SDK packages (read-only)

## Common Issues

1. Build context too large:
   - Check `.dockerignore` configuration
   - Ensure only necessary files are included

2. SDK installation fails:
   - Verify SDK package exists in `volumes/sdk/`
   - Check package name matches `SDK_PKG_NAME` in `.env`

3. Permission denied for USB devices:
   ```bash
   # Add your user to the dialout group (Linux)
   sudo usermod -a -G dialout $USER
   ```

4. X11 display issues:
   - Windows: Ensure VcXsrv is running
   - macOS: Ensure XQuartz is running

## Customization

1. Modify `.env` for project-specific settings
2. Update `install_tools.sh` for additional development tools
3. Adjust volume mappings in `docker-compose.yml`
4. Customize `bashrc` for shell environment

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

MIT