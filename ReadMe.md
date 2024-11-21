# Embedded Development Environment Docker Template
# 嵌入式开发环境 Docker 模板

## Overview (概述)
This project provides a modular and extensible Docker-based development environment template for embedded systems development (这个项目提供了一个模块化且可扩展的基于Docker的嵌入式系统开发环境模板).

## Architecture (架构)
The project follows a multi-stage build pattern with clear separation of concerns (项目遵循多阶段构建模式，具有清晰的关注点分离):

```plaintext
project_root/
├── docker/ # Docker build stages (Docker构建阶段)
│ ├── stage_1_base/ # Base system setup (基础系统设置)
│ ├── stage_2_tools/ # Development tools (开发工具)
│ ├── stage_3_sdk/ # SDK installation (SDK安装)
│ ├── stage_4_config/ # Environment configuration (环境配置)
│ └── stage_5_final/ # Final integration (最终整合)
├── scripts/ # Helper scripts (辅助脚本)
├── configs/ # Configuration files (配置文件)
└── volumes/ # Persistent data (持久化数据)
```

## Stage Details (阶段详情)

### Stage 1: Base Environment (基础环境)
- Ubuntu 22.04 base image (Ubuntu 22.04基础镜像)
- System updates and essential packages (系统更新和基础包)
- Basic system configuration (基本系统配置)

### Stage 2: Development Tools (开发工具)
- Compiler toolchain (编译工具链)
- Development utilities (开发工具)
- Debugging tools (调试工具)

### Stage 3: SDK Installation (SDK安装)
- SDK package management (SDK包管理)
- Dependency resolution (依赖解析)
- SDK configuration (SDK配置)

### Stage 4: Environment Configuration (环境配置)
- Environment variables setup (环境变量设置)
- User and permission configuration (用户和权限配置)
- Development environment customization (开发环境定制)

### Stage 5: Final Integration (最终整合)
- Workspace preparation (工作空间准备)
- Volume mount points (卷挂载点)
- Entry point configuration (入口点配置)

## Prerequisites (前置要求)
- Docker Engine 24.0+ (Docker引擎 24.0+)
- Docker Compose V2 (Docker Compose V2版本)
- Ubuntu 22.04 Host OS (Ubuntu 22.04主机操作系统)

## Quick Start (快速开始)
1. Clone the repository (克隆仓库)
   ```bash
   git clone <repository-url>
   cd <project-directory>
   ```

2. Configure environment variables (配置环境变量)
   ```bash
   cp .env.example .env
   # Edit .env file according to your needs
   ```

3. Build the development environment (构建开发环境)
   ```bash
   ./scripts/build.sh
   ```

4. Start the development environment (启动开发环境)
   ```bash
   ./scripts/start.sh
   ```

## Configuration (配置)
All configurations are managed through environment variables (所有配置通过环境变量管理):
- `.env`: Main configuration file (主配置文件)
- `configs/`: Stage-specific configurations (阶段特定配置)

## Volume Structure (卷结构)
- `volumes/src/`: Source code directory (源代码目录)
- `volumes/build/`: Build artifacts (构建产物)
- `volumes/sdk/`: SDK packages (SDK包)
- `volumes/tools/`: Development tools (开发工具)

## Customization (定制化)
Each stage can be customized by modifying the corresponding configuration files and scripts (每个阶段都可以通过修改相应的配置文件和脚本进行定制):
- Stage-specific Dockerfile (阶段特定的Dockerfile)
- Configuration files (配置文件)
- Installation scripts (安装脚本)

## Contributing (贡献)
1. Fork the repository (复刻仓库)
2. Create your feature branch (创建特性分支)
3. Commit your changes (提交更改)
4. Push to the branch (推送到分支)
5. Create a Pull Request (创建拉取请求)

## License (许可证)
MIT License (MIT许可证)

## Author (作者)
[PotterWhite] 

## Version History (版本历史)
- v1.0.0 (2024-11-20): Initial release (初始发布)
