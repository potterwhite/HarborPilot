# Docker Development Environment Template

A template for creating consistent development environments using Docker.

## Project Structure

```plaintext
DockerDevEnvTemplate/
├── docker/
│ ├── Dockerfile # Container image definition
│ └── scripts/
│ ├── install_tools.sh # Install development tools
│ ├── entrypoint.sh # Container entry point script
│ └── setup_gui.sh # GUI support setup
├── configs/
│ └── bashrc # Custom bash configuration
├── scripts/
│ ├── build.sh # Build docker image
│ └── run.sh # Run docker container
├── .env # Environment variables
├── docker-compose.yml # Docker compose configuration
└── start_dev.sh # Development environment startup script
```

## Quick Start

1. Clone this repository
2. Run the startup script:
   ```bash
   ./start_dev.sh
   ```

## Creating a New Project

When using this template for a new project, modify these files:

1. `.env`:
   ```bash
   # Change project specific variables
   PROJECT_NAME=your-project-name
   TAG=latest
   ```

2. `docker-compose.yml`:
   ```yaml
   # Modify volume mappings for your project
   volumes:
     - ./your-source:/work/your-source:rw
     - ./your-config:/work/your-config:ro
   ```

3. `docker/Dockerfile`:
   ```dockerfile
   # Add your project specific dependencies
   RUN apt-get install -y your-packages

   # Add your project specific setup steps
   COPY your-config /work/your-config
   ```

4. `docker/scripts/install_tools.sh`:
   ```bash
   # Add or remove development tools based on your needs
   apt-get install -y \
       your-tool-1 \
       your-tool-2
   ```

## Features

- Consistent development environment across team members
- GUI application support (optional)
- Customizable tool installation
- Volume mapping for source code and configurations
- Support for USB device mapping

## Optional Features

### GUI Support
For GUI applications (like VSCode):
1. Windows: Install VcXsrv
2. macOS: Install XQuartz
3. Start X server before running GUI applications

### USB Device Support
Default mappings in `docker-compose.yml`:

```yaml
devices:
  - "/dev/ttyUSB0:/dev/ttyUSB0"
  - "/dev/ttyACM0:/dev/ttyACM0"
```
Modify according to your device needs.

## Common Issues

1. Permission denied for USB devices:
   ```bash
   # Add your user to the dialout group (Linux)
   sudo usermod -a -G dialout $USER
   ```

2. X11 display issues:
   - Windows: Make sure VcXsrv is running
   - macOS: Make sure XQuartz is running

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

MIT