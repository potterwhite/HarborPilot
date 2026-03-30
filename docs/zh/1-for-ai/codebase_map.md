# HarborPilot — 代码库地图（AI Agent 快速参考）

> **⚠️ 面向 AI AGENT — 请先阅读本文**
> 本文档是代码库结构的唯一事实来源。
> **不要进行全量代码扫描** — 请阅读本文件代替。
>
> **维护规则：** 任何修改本文中所列文件的 AI Agent，必须在同一次提交/会话中更新本文档的相关章节。
>
> 最后更新：2026-03-28（新增 Phase 4 ASO 计划；task-logs 存档规则已文档化；MCP 重新编号为 Phase 5）
> **Related:** [English Version →](../../en/1-for-ai/codebase_map.md)

---

## 1. 仓库根目录布局

```
HarborPilot.git/
├── harbor                              ← 顶级入口：构建 → 打 tag → 推送
├── CLAUDE.md                           ← Claude Code 会话入口
├── README.md                           ← 项目 README（英文）
├── CHANGELOG.md                        ← 由 release-please 自动维护
├── LICENSE                             ← MIT
├── release-please-config.json          ← 版本自动化配置
│
├── configs/                            ← ★ 三层配置系统
│   ├── defaults/                       ←   Layer 1：11 个按领域划分的默认文件
│   │   ├── 01_base.env                 ←     OS、用户、时区、语言
│   │   ├── 02_build.env                ←     Docker BuildKit 设置
│   │   ├── 03_tools.env                ←     开发工具开关与版本（CUDA、OpenCV、Node…）
│   │   ├── 04_workspace.env            ←     工作区目录结构与构建设置
│   │   ├── 05_registry.env             ←     Harbor / GitLab 服务器地址
│   │   ├── 06_sdk.env                  ←     SDK 安装开关（默认：false）
│   │   ├── 07_volumes.env              ←     Docker volume 根路径
│   │   ├── 08_samba.env                ←     Samba 共享凭证
│   │   ├── 09_runtime.env              ←     SSH / GDB / syslog / NVIDIA 开关
│   │   └── 11_proxy.env                ←     HTTP/HTTPS 代理（默认：关）
│   ├── platform-independent/
│   │   └── common.env                  ←   Layer 2：项目版本、维护者、日期
│   ├── platforms/                               ←   Layer 3：每平台覆盖（只写差异）
│   │   ├── rk3588-rk3588s_ubuntu-22.04.env      ←     PORT_SLOT=0，Ubuntu 22.04，NVIDIA GPU
│   │   ├── rv1126-rv1126bp_ubuntu-22.04.env      ←     PORT_SLOT=1，Ubuntu 22.04
│   │   ├── rk3568-rk3568_ubuntu-20.04.env        ←     PORT_SLOT=2，Ubuntu 20.04
│   │   ├── rv1126-rv1126_ubuntu-22.04.env        ←     PORT_SLOT=3，Ubuntu 22.04
│   │   ├── rk3568-rk3568_ubuntu-22.04.env        ←     PORT_SLOT=4，Ubuntu 22.04
│   │   └── rk3588-rk3588s_ubuntu-24.04.env      ←     PORT_SLOT=5，Ubuntu 24.04，无 NVIDIA
│   └── platform_schema.json            ←   平台 .env 文件的 JSON Schema
│
├── scripts/                            ← ★ 宿主机工具
│   ├── port_calc.sh                    ←   从 PORT_SLOT 自动计算端口
│   └── create_platform.sh              ←   交互式 + 非交互式平台创建向导
│
├── docker/
│   ├── dev-env-clientside/             ← ★ 主构建目标（5 阶段 Dockerfile）
│   │   ├── Dockerfile                  ←   单体 5 阶段多阶段构建
│   │   ├── build.sh                    ←   Docker build 入口：加载 3 层 → 构建参数 → 构建
│   │   ├── stage_1_base/scripts/       ←   Stage 1：apt 源替换、包安装、用户创建
│   │   ├── stage_2_tools/scripts/      ←   Stage 2：CUDA、OpenCV、开发工具、Node.js、Python
│   │   ├── stage_3_sdk/                ←   Stage 3：SDK 初始化、辅助脚本（模板）
│   │   ├── stage_4_config/             ←   Stage 4：环境变量配置、代理（模板）
│   │   └── stage_5_final/              ←   Stage 5：工作区、入口点、测试（模板）
│
├── project_handover/                   ← ★ 客户端部署包
│   └── clientside/ubuntu/
│       ├── ubuntu_only_entrance.sh     ←   容器生命周期：start/stop/restart/recreate/remove
│       ├── harbor.crt                  ←   Harbor CA 证书（每台宿主机安装一次）
│       └── scripts/                    ←   6 个模块化辅助脚本
│
├── docs/                               ← ★ 文档（双语分离）
│   ├── en/                             ←   英文文档树
│   │   ├── assets/                     ←     英文文档图片（暗背景）
│   │   ├── 00_INDEX.md                 ←     导航中心（英文）
│   │   ├── 1-for-ai/                  ←     AI Agent 参考文件
│   │   ├── 2-progress/                ←     阶段追踪 + 各阶段计划
│   │   │   ├── phase4_aso_plan.md     ←       Phase 4：ASO 内容分发计划
│   │   │   └── phase5_mcp_ai_agent_plan.md ← Phase 5：MCP Server 计划
│   │   ├── 3-highlights/              ←     架构分析（竞品、config_layers、port-map）
│   │   └── 4-for-beginner/            ←     快速上手指南
│   └── zh/                             ←   中文文档树
│       ├── assets/                     ←     中文文档图片（亮背景）
│       ├── 00_INDEX.md                 ←     导航中心（中文）
│       ├── 1-for-ai/                  ←     AI Agent 参考文件（中文）
│       ├── 2-progress/                ←     阶段追踪（中文）+ NEED_TO_DO.md
│       │   ├── phase4_aso_plan.md     ←       Phase 4：ASO 内容分发计划（中文版）
│       │   ├── phase5_mcp_ai_agent_plan.md ← Phase 5：MCP Server 计划（中文版）
│       │   └── task-logs/             ←       NEED_TO_DO_Archived-<英文月><日>.<年>.md 存档文件。
│       │                                        规则：同一天只能有一个文件。
│       │                                        归档时追加到当天已有文件末尾，严禁新建同一天的第二个文件。
│       │                                        NEED_TO_DO.md 本身永久保留，绝不删除或 git mv。
│       ├── 3-highlights/              ←     架构分析（中文）
│       ├── 4-for-beginner/            ←     快速上手指南（中文）
│       └── readme.md                  ←   中文 README
│
└── .devcontainer/
    └── devcontainer.json               ←   VS Code Dev Container 配置（用于开发 HarborPilot 本身）

[Phase 4 — 计划中，尚未创建]
mcp/
├── harborpilot_mcp_server.py           ←   MCP 服务器：将平台/配置/构建能力暴露给 AI
├── requirements.txt                    ←   mcp SDK 依赖
├── claude_code_config.json             ←   可直接粘贴的 Claude Code MCP 配置
└── README.md                           ←   安装指南 + AI 提示词示例
```

---

## 2. 顶级脚本 — 详细参考

### `harbor`（仓库根目录）
**主编排器**。交互式选择平台 → 加载 3 层配置 → 构建 → 打 tag → 推送 → 清理。

**执行流程：**
1. `1_specify_platform()` — 按 PORT_SLOT 排序列出平台，用户按编号选择。也可选择"创建新平台"，此时调用 `create_platform.sh`。
2. Layer 1：按顺序 source `configs/defaults/*.env`（01→11）
3. Layer 2：source `common.env`
4. Layer 3：source 所选 `<platform>.env`
5. `port_calc.sh` — 从 PORT_SLOT 派生 SSH/GDB 端口
6. `0_check_registry_login()` — 验证 Docker 已登录 Harbor；未登录则提示交互式登录
7. `1_1_setup_volume_soft_link()` — 创建 HOST_VOLUME_DIR 软链接
8. `2_build_images()` → 调用 `docker/dev-env-clientside/build.sh`
9. `3_prepare_version_info()` — 获取最终镜像 ID
10. `4_tag_images()` — 打 version + latest 标签（本地或 registry）
11. `5_push_images()` — 推送 + 验证 manifest digest
12. `6_cleanup_images()` — 删除中间镜像（保留最终镜像）

**关键行为：**
- 每步（构建/打 tag/推送/清理）都有 `prompt_with_timeout` — 用户可用 'n' 跳过，10 秒后自动继续
- `V=1` 开启 `set -x` 调试模式
- Registry 推送包含 manifest 检查 + SHA256 digest 验证

### `scripts/port_calc.sh`
在每个配置加载器中 Layer 3 之后 source。两种互斥模式：
- **MODE A**（推荐）：在平台 .env 中设置 `PORT_SLOT` → 所有端口自动派生：
  - `CLIENT_SSH_PORT = 2109 + PORT_SLOT × 10`
  - `GDB_PORT = 2345 + PORT_SLOT × 10`
- **MODE B**（遗留）：显式设置 `CLIENT_SSH_PORT` 和 `GDB_PORT`（无 PORT_SLOT）
- **混用两种模式 → 致命错误**，并显示两种选项的修复说明
- 验证 PORT_SLOT 为非负整数
- MODE B 验证所有必须端口已设置
- 计算后清除内部 `_*` 变量

### `scripts/create_platform.sh`
交互式向导 + 非交互式 CLI，用于创建新平台 `.env` 文件。
- **交互模式**：`./scripts/create_platform.sh` — 彩色提示，显示现有平台及其插槽，自动分配下一个可用 PORT_SLOT，展示端口预览，要求确认
- **非交互模式**：`./scripts/create_platform.sh --non-interactive --name <名称> --os <os> --os-version <版本> --harbor-ip <ip> [--port-slot <n>] [--nvidia] [--proxy-http <url>] [--install-cuda] [--install-opencv] [--npm-china-mirror]`
- 验证：名称格式（`[a-zA-Z0-9_-]+`）、无重复、PORT_SLOT 冲突警告
- 生成的 `.env` 包含所有章节及正确的 `${VAR}` 自引用

---

## 3. Docker 构建流水线 — 逐阶段说明

### `docker/dev-env-clientside/build.sh`
构建入口。由 `harbor` 调用。
- `func_1_1_setup_env()` — 3 层配置加载（与 harbor 相同），将所有环境变量收集到 `BUILD_ARGS[]` 数组。扫描所有 `.env` 文件获取变量名，读取当前（已解析的）值。
- 构建参数：`docker build --no-cache --progress=plain --network=host`
- 输出记录到 `build_log.txt`
- 使用 `PIPESTATUS[0]` 在 tee 管道中捕获 docker build 失败

### `docker/dev-env-clientside/Dockerfile`
单体 Dockerfile，5 个阶段。每个阶段有用于模板处理的子阶段。

**Stage 1（`stage_1st_base`）：** 基础 OS 设置
- FROM `ubuntu:${OS_VERSION}`
- ~70+ ARG 持久化为 ENV 以供跨阶段传递
- 运行 `setup_base.sh`：apt 源替换（中国镜像）、基础包安装、用户创建、语言环境、时区
- **OS 特定**：Ubuntu 24.04 使用 DEB822 apt 格式；UID/GID 1000 冲突处理

**Stage 2（`stage_2nd_tools`）：** 开发工具
- `install_dev_tools.sh`：build-essential、cmake、gdb、valgrind、clang、minicom（3 个配置）、doxygen、git+lfs、Node.js、Python 包
- `install_cuda.sh`（条件：`INSTALL_CUDA=true`）
- `install_opencv.sh`（条件：`INSTALL_OPENCV=true`，从源码构建，可选 CUDA）
- `gitlfs_tracker.sh`：安装到 `/usr/local/bin/` — 扫描大文件以供 Git LFS 追踪
- **平台特定**：rv1126bp 需要额外库（libmpc-dev、libgmp-dev）。OS 20.04 需要 Python 2.7。

**Stage 3（`stage_3rd_sdk`）：** SDK 初始化
- 模板处理：`envsubst` 渲染 `*_template` 文件
- `install_sdk.sh`：创建 SDK 目录、git init、添加远端、安装 git-lfs、在 `/usr/local/bin/` 创建 SDK 工具软链接（Qt 工具、构建工具、调试工具）
- 安装到 `/usr/local/bin/` 的辅助脚本：`pull_sdk.sh`、`push_sdk.sh`、`verify_git_config.sh`、`verify_ssh_key.sh`、`version_of_dev_env.sh`、`analyze_dir_structure.sh`
- 仅在 `INSTALL_SDK=true` 时运行

**Stage 4（`stage_4th_config`）：** 环境配置
- `envsubst` 渲染 `env_config.conf_template` → `/etc/profile.d/env_config.sh`
- 条件代理：若 `HAS_PROXY=true`，渲染 `proxy.sh_template` → `/etc/profile.d/proxy.sh`
- `configure_env.sh`：将配置复制到 profile.d，source 以验证

**Stage 5（`stage_5th_final`）：** 工作区 + 入口点
- `envsubst` 渲染 `entrypoint.conf_template` → `/etc/entrypoint.conf`
- `envsubst` 渲染 `workspace.conf_template` → `/etc/workspace.conf`
- `setup_workspace.sh`：创建 `/development/` 及子目录：`i_src`、`ii_build`、`iii_logs`、`iv_temp`、`v_docs`、`vi_tools`
- `entrypoint.sh`：启动 SSH（条件）、打印 GDB 信息（条件）、`exec "$@"`
- Docker 标签：BUILD_DATE、VERSION、IMAGE_NAME、PLATFORM
- 测试：`test_permissions.sh`（用户存在）、`test_workspace.sh`（目录存在）
- WORKDIR `/development`，CMD `["/bin/bash"]`

---

## 4. 配置系统 — 变量参考

### Layer 1：`configs/defaults/`（10 个文件）

| 文件 | 关键变量 | 备注 |
|---|---|---|
| `01_base.env` | `OS_DISTRIBUTION=ubuntu`、`OS_VERSION=22.04`、`DEV_USERNAME=developer`、`DEV_GROUP=developer`、`DEV_UID/GID=1000`、`TIMEZONE=Asia/Hong_Kong`、`DEBIAN_FRONTEND=noninteractive` | 密码默认：`123` |
| `02_build.env` | `DOCKER_BUILDKIT=1` | 单变量 |
| `03_tools.env` | `INSTALL_CUDA=false`、`INSTALL_OPENCV=false`、`INSTALL_HOST_CMAKE=true`、`NPM_USE_CHINA_MIRROR=false`、`CUDA_VERSION=12.0`、`OPENCV_VERSION=4.9.0`、`CONAN_VERSION=2.0.17` | 版本锁定以确保可复现 |
| `04_workspace.env` | `WORKSPACE_ROOT=/development`，子目录：`i_src`…`vi_tools`，`WORKSPACE_BUILD_THREADS=4`、`WORKSPACE_LOG_LEVEL=INFO`、`WORKSPACE_DEBUG_PORT=3000` | 6 个工作区子目录 |
| `05_registry.env` | `HAVE_GITLAB_SERVER=TRUE`、`HAVE_HARBOR_SERVER=TRUE`、`HARBOR_SERVER_PORT=9000` | `REGISTRY_URL` 在 Layer 3 中使用 `CHIP_FAMILY` |
| `06_sdk.env` | `INSTALL_SDK=false`、`CHIP_FAMILY=${PRODUCT_NAME}` | `CHIP_FAMILY` 将同芯片的变体归组；`REGISTRY_URL` 和 `SDK_GIT_REPO` 使用 `${CHIP_FAMILY}` |
| `07_volumes.env` | `VOLUMES_ROOT=${WORKSPACE_ROOT}` | `HOST_VOLUME_DIR` 无默认值 — 每平台**必须**设置 |
| `08_samba.env` | `SAMBA_SERVER_IP=""`、`SAMBA_PUBLIC_ACCOUNT_NAME/PASSWORD=sambashare`、`SAMBA_FILE_MODE=0777`、`SAMBA_DIR_MODE=0777` | 默认 Samba 凭证 + 权限 |
| `09_runtime.env` | `ENABLE_SSH=true`、`ENABLE_GDB_SERVER=true`、`USE_NVIDIA_GPU=false`、`ENABLE_CORE_DUMPS=true`、`CONTAINER_RESTART_POLICY=unless-stopped`、`CONTAINER_PRIVILEGED=true`、`CONTAINER_SERIAL_DEVICE=/dev/ttyUSB0`、`CONTAINER_SHM_SIZE=8g`、`NVIDIA_VISIBLE_DEVICES=all`、`NVIDIA_DRIVER_CAPABILITIES=all` | 端口由 port_calc.sh 计算；compose 运行时覆盖 |
| `11_proxy.env` | `HAS_PROXY=false`、`HTTP_PROXY_IP`、`HTTPS_PROXY_IP` | 代理 IP 有默认值但 HAS_PROXY 默认关闭 |

### Layer 2：`configs/platform-independent/common.env`

| 变量 | 值 | 备注 |
|---|---|---|
| `VERSION` | `1.7.1` | 由 release-please 自动更新（`x-release-please-version` 标记） |
| `PROJECT_VERSION` | `$VERSION` | 构建中全程使用的别名 |
| `PROJECT_MAINTAINER` | PotterWhite | |
| `PROJECT_RELEASE_DATE` | 2026-03-19 | 手动更新 |
| `SDK_VERSION` | 1.1.2 | |

### Layer 3：`configs/platforms/<name>.env`

只覆盖与默认值不同的内容。必填字段：`PRODUCT_NAME`、`OS_VERSION`、`PORT_SLOT`、`HOST_VOLUME_DIR`。

**当前平台：**

| 平台文件 | 插槽 | CHIP_FAMILY | CHIP_EXTRACT_NAME | PRODUCT_NAME | SSH | GDB | Ubuntu | NVIDIA | 代理 | GitLab |
|---|---|---|---|---|---|---|---|---|---|---|
| `rk3588-rk3588s_ubuntu-22.04` | 0 | rk3588 | rk3588s | rk3588-rk3588s_ubuntu-22.04 | 2109 | 2345 | 22.04 | ✅ | — | — |
| `rv1126-rv1126bp_ubuntu-22.04` | 1 | rv1126 | rv1126bp | rv1126-rv1126bp_ubuntu-22.04 | 2119 | 2355 | 22.04 | — | ✅ | ✅ 192.168.3.67 |
| `rk3568-rk3568_ubuntu-20.04` | 2 | rk3568 | rk3568 | rk3568-rk3568_ubuntu-20.04 | 2129 | 2365 | 20.04 | — | ✅ | ✅ 192.168.3.67 |
| `rv1126-rv1126_ubuntu-22.04` | 3 | rv1126 | rv1126 | rv1126-rv1126_ubuntu-22.04 | 2139 | 2375 | 22.04 | — | ✅ | ✅ 192.168.3.67 |
| `rk3568-rk3568_ubuntu-22.04` | 4 | rk3568 | rk3568 | rk3568-rk3568_ubuntu-22.04 | 2149 | 2385 | 22.04 | — | ✅ | ✅ 192.168.3.67 |
| `rk3588-rk3588s_ubuntu-24.04` | 5 | rk3588 | rk3588s | rk3588-rk3588s_ubuntu-24.04 | 2159 | 2395 | 24.04 | — | ✅ | ✅ 192.168.3.67 |

### `configs/platform_schema.json`
平台 `.env` 验证 JSON Schema。必填：`PRODUCT_NAME`、`OS_VERSION`、`PORT_SLOT`。定义枚举（OS_VERSION：20.04/22.04/24.04/11/12）、范围（PORT_SLOT：0–99）、模式（PRODUCT_NAME：`[a-zA-Z0-9_-]+`）。条件约束：若 `HAVE_GITLAB_SERVER=TRUE` → 需要 `GITLAB_SERVER_IP` + `GITLAB_SERVER_PORT`。`additionalProperties: true`。

---

## 5. 客户端部署

### `project_handover/clientside/ubuntu/ubuntu_only_entrance.sh`
容器生命周期管理器。命令：`start`/`stop`/`restart`/`recreate`/`remove`/`-h`。

**关键行为：**
- `1_0_gen_environment_variables()` — 加载与 `harbor` 相同的 3 层配置 + `port_calc.sh`
- `3_3_generate_compose_config()` — 从环境变量动态生成 `docker-compose.yaml`：
  - 镜像：`${REGISTRY_URL}/${IMAGE_NAME}:latest`（无 registry 时使用本地镜像）
  - 端口：`${CLIENT_SSH_PORT}:22` 和 `${GDB_PORT}:${GDB_PORT}`
  - 条件 NVIDIA GPU：带 `nvidia` 驱动的 `deploy.resources.reservations.devices`
  - Samba CIFS volume 挂载
  - TTY + 特权模式 + USB 直通
- `start` → 交互式菜单：进入运行中的容器 / 重启 / 重建
- `1_2_check_docker_login()` — 带重试的 Harbor 登录
- `2_4_retrieve_latest_image()` — 从 registry 拉取

---

## 6. SDK 辅助脚本（安装到 `/usr/local/bin/`）

| 脚本 | 用途 |
|---|---|
| `pull_sdk.sh` | 从 git 拉取 SDK：单分支或全部分支，安全检查（干净工作目录、远端 URL 匹配） |
| `push_sdk.sh` | 推送 SDK 变更：状态检查、创建分支、交互式确认 |
| `verify_git_config.sh` | 交互式验证/设置 git user.name 和 user.email |
| `verify_ssh_key.sh` | 验证/初始化 SDK 访问的 SSH 密钥，更新 `~/.ssh/config` |
| `version_of_dev_env.sh` | 打印开发环境版本和发布日期 |
| `analyze_dir_structure.sh` | SDK 目录分析：最大的 20 个文件、目录大小、扩展名统计 |
| `gitlfs_tracker.sh` | 扫描大文件，使用 Git LFS 自动追踪（默认阈值：100MB） |

---

## 7. 版本管理与发布

- **release-please** 管理 `CHANGELOG.md` 和版本更新
- 配置：`release-please-config.json` — `release-type: simple`
- 版本唯一来源：`configs/platform-independent/common.env` 中的 `VERSION`
- `x-release-please-version` 标记启用自动更新
- Changelog 章节：feat→✨，fix→🐛，perf→⚡，revert→🔙。docs/style/chore/refactor 隐藏。
- `.devcontainer/devcontainer.json` — VS Code Dev Container，用于开发 HarborPilot 本身（非最终用户使用）。转发端口 2109+2345，安装 C++ / CMake / Python / Git 扩展。

---

## 8. 关键架构模式

1. **三层配置继承** — 默认值为 90% 的变量提供合理初值。平台文件只覆盖差异。新增平台只需 ~15–20 行。Layer 2（common.env）保存版本等项目级常量。

2. **基于 PORT_SLOT 的端口分配** — 单个整数决定所有端口映射。防止平台间端口冲突。公式在 `port_calc.sh` 中定义一次，处处引用。

3. **模板 → envsubst → 最终文件** — `*_template` 文件使用 `${VAR}` 占位符。Dockerfile 中的模板处理中间阶段将所有构建参数导出后运行 `envsubst`。替代了之前易出错的 `sed` 方式。

4. **配置是唯一事实来源** — 没有脚本包含硬编码的平台特定值。一切由 3 层配置驱动。修改默认值即可自动传播到所有平台。

5. **动态 docker-compose 生成** — `ubuntu_only_entrance.sh` 在运行时从 shell 变量生成 `docker-compose.yaml`，无需手动编辑 compose 即可支持 NVIDIA GPU 和平台特定端口映射。

6. **条件化功能安装** — CUDA、OpenCV、Python 2.7、npm 中国镜像、代理 — 均由布尔环境变量控制。Dockerfile 检查这些变量并跳过无关阶段，让不需要这些功能的平台保持镜像小巧。
