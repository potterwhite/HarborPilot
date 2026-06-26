# 三层配置系统详解

> **Related:** [English Version →](../../en/3-highlights/config_layers.md)

本文档解释 HarborPilot 配置系统的工作原理、为什么采用三层结构，以及如何在新增平台或新增全局配置项时使用它。

---

## 它解决了什么问题？

HarborPilot 早期版本使用扁平结构：

```
configs/2_platforms/
├── rk3588s.env     # 180+ 行 — 所有配置都在这里
├── rk3568.env      # 180+ 行 — 与 rk3588s.env 95% 相同
├── rv1126.env      # 180+ 行 — 与 rk3588s.env 95% 相同
└── ...
```

新增一个全局 flag，需要修改每个平台文件。新增一个平台，需要复制整个 180 行文件再改 5 行。读某个平台文件，完全看不出它和其他平台有什么区别。

---

## 解决方案：三层覆盖（Three-Layer Override）

这套模式来自 Ansible、Helm、Kubernetes、Yocto 等工业级系统 —— 任何需要「合理默认值 + 精准覆盖」的场景都在用它：

```
Layer 1  configs/1_defaults/*.env          全局默认值 — 自动加载，用户不可见
   ↓  （后加载的层覆盖先加载的）
Layer 2  configs/2_platforms/<platform>.env 平台身份 — 自动加载，用户不可见
   ↓                                       （由 host 的 BASE_PLATFORM 决定）
Layer 3  configs/3_hosts/<hostname>.env     主机配置 — 用户唯一交互对象
```

**核心规则：** 平台文件里只写与默认值*不同*的内容。如果某个变量不在平台文件里，就自动使用默认值。主机文件里只写与平台配置*不同*的内容 —— 如果某个变量不在主机文件里，就使用平台值。

**关键设计决策：** Layer 1 和 Layer 2 是*支撑层* —— 它们的存在是为了减少重复，但用户永远不会直接选择它们。**Host 配置是用户的核心对象**：它通过 `BASE_PLATFORM` 声明使用哪个平台，并包含所有机器特定的覆盖。用户运行 `./harbor` 时只与 host 配置交互。

---

## Layer 1 — 全局默认值（`configs/1_defaults/`）

6 个阶段对齐的文件。文件名前缀的数字使加载顺序一目了然。

| 文件 | 包含的变量 | 备注 |
|---|---|---|
| `00_global.env` | `VERSION`、`PROJECT_VERSION`、`PROJECT_RELEASE_DATE`、`PROJECT_MAINTAINER`、`SDK_VERSION` | 与阶段无关的项目常量。`VERSION` 由 release-please 自动更新。 |
| `01_stage_1st_base.env` | `OS_VERSION`、`OS_VERSION_ID`、`DEV_USERNAME`、`DEV_UID/GID`、`TIMEZONE`、`DEBIAN_FRONTEND` | Stage 1：OS + 用户设置。 |
| `02_stage_2nd_build.env` | `DOCKER_BUILDKIT`、`INSTALL_CUDA/OPENCV/CMAKE`、工具版本号（`CONAN_VERSION` 等）、`GCC_OFFLINE_PACKAGE` | Stage 2：由旧 `02_build.env` + `03_tools.env` 合并。 |
| `03_stage_3rd_sdk.env` | `HAVE_GITLAB_SERVER`、`HARBOR_SERVER_IP`、`HARBOR_SERVER_PORT`、`HAVE_HARBOR_SERVER`、`GITLAB_SERVER_IP`、`GITLAB_SERVER_PORT`、`INSTALL_SDK`、`SDK_INSTALL_PATH`、`CHIP_FAMILY=${PRODUCT_NAME}` | Stage 3：由旧 `05_registry.env` + `06_sdk.env` 合并。 |
| `04_stage_4th_proxy.env` | `HAS_PROXY`（默认 `false`）、`HTTP/HTTPS_PROXY_IP` | Stage 4：由旧 `11_proxy.env` 重命名。 |
| `05_stage_5th_runtime.env` | `WORKSPACE_ROOT` 及子目录、`WORKSPACE_BUILD_THREADS`、调试配置、`VOLUMES_ROOT`、`SAMBA_*`、`ENABLE_SSH`、`ENABLE_GDB_SERVER`、`USE_NVIDIA_GPU`、`CONTAINER_SHM_SIZE` | Stage 5：由旧 `04_workspace.env` + `07_volumes.env` + `08_samba.env` + `09_runtime.env` 合并。 |

**加载顺序至关重要。** 文件按数字顺序依次 source（00 → 05）。`03_stage_3rd_sdk.env` 里若要引用 `CONTAINER_NAME`，而该变量在 Layer 1 阶段尚未赋值 —— 这正是 `REGISTRY_URL` 故意不放在 Layer 1、而是在 Layer 2 里计算的原因。

---

## Layer 2 — 平台覆盖（`configs/2_platforms/<platform>.env`）

每个平台文件只包含**与默认值不同的内容**。平台文件定义**平台身份**和**SDK 配置**。

### 平台文件应该包含什么

| 类别 | 变量 | 原因 |
|------|------|------|
| **平台身份** | `CHIP_FAMILY`、`CHIP_EXTRACT_NAME`、`OS_DISTRIBUTION`、`OS_VERSION`、`PRODUCT_NAME` | 定义平台唯一性 |
| **衍生名称** | `IMAGE_NAME`、`CONTAINER_NAME`、`LATEST_IMAGE_TAG` | 依赖 `PRODUCT_NAME` |
| **端口槽位** | `PORT_SLOT` | 平台特定的端口分配 |
| **Registry URL** | `REGISTRY_URL` | 依赖 `CHIP_FAMILY` |
| **SDK** | `SDK_GIT_REPO`、`SDK_GIT_KEY_FILE`、`SDK_GIT_DEFAULT_BRANCH` | 平台特定的 SDK 公式（由 `create_platform.sh` 自动生成） |

### 示例：平台文件（rk3588-ubuntu-22.04.env）

```bash
# 平台身份  [必填 — 无默认值]
CHIP_FAMILY="rk3588"
CHIP_EXTRACT_NAME="rk3588s"
OS_DISTRIBUTION="ubuntu"
OS_VERSION="22.04"
OS_VERSION_ID="22-04"
PRODUCT_NAME="${CHIP_FAMILY}-${CHIP_EXTRACT_NAME}_${OS_DISTRIBUTION}-${OS_VERSION_ID}"

# 从 PRODUCT_NAME 派生（保持同步）
IMAGE_NAME="${PRODUCT_NAME}-dev-env"
LATEST_IMAGE_TAG=${PROJECT_VERSION}
CONTAINER_NAME=${PRODUCT_NAME}

# Registry URL  [依赖 host/defaults 中的 HARBOR_SERVER_IP]
REGISTRY_URL="${HARBOR_SERVER_IP}:${HARBOR_SERVER_PORT}/team_${CHIP_FAMILY}"

# SDK  [自动生成 — 仅在 INSTALL_SDK=true 时使用]
SDK_GIT_REPO="git@${GITLAB_SERVER_IP:-192.168.0.19}:team_${CHIP_FAMILY}/${PRODUCT_NAME}_sdk.git"
SDK_GIT_KEY_FILE="SDK_${CHIP_FAMILY}_ED25519"
SDK_GIT_DEFAULT_BRANCH="main"

# 容器运行时  [端口由 PORT_SLOT 自动计算]
PORT_SLOT="0"
```

### 平台文件不应该包含什么

这些是**主机特定的**，应该放在 Layer 3：

- `HOST_VOLUME_DIR` — 宿主机文件系统路径
- `EXTRA_VOLUME_*` — 用户特定的卷挂载
- `HAS_PROXY`、`HTTP_PROXY_IP`、`HTTPS_PROXY_IP` — 网络环境
- `NPM_USE_CHINA_MIRROR` — 网络环境
- `USE_NVIDIA_GPU`、`CONTAINER_SHM_SIZE` — 硬件特定
- `GITLAB_SERVER_*`、`HARBOR_SERVER_*` — 服务器连接
- `HAVE_GITLAB_SERVER`、`HAVE_HARBOR_SERVER` — 服务器可用性

---

## Layer 3 — 主机配置（`configs/3_hosts/<hostname>.env`）

这是 HarborPilot 中**用户唯一交互的核心对象**。每个主机配置声明它使用哪个平台，并包含所有机器特定的覆盖。

### 工作原理

系统运行 `hostname` 并查找 `configs/3_hosts/<hostname>.env`。如果文件存在：
1. 读取 `BASE_PLATFORM` 确定要加载哪个平台文件
2. 加载平台文件（Layer 2）
3. 加载主机配置（Layer 3 覆盖）

如果文件不存在，`./harbor` 会引导你创建一个。

### 如何开始

```bash
# 方式 1：使用向导（推荐）
./harbor  →  选择 "Create new host config"

# 方式 2：手动设置
hostname
cp configs/3_hosts/TEMPLATE.env.example configs/3_hosts/$(hostname).env
nano configs/3_hosts/$(hostname).env
```

### 应该放什么

| 类别 | 变量 | 原因 |
|------|------|------|
| **平台引用** | `BASE_PLATFORM` | **必填** — 决定加载哪个平台 |
| **路径** | `HOST_VOLUME_DIR`、`EXTRA_VOLUME_*` | 宿主机文件系统路径 |
| **硬件** | `USE_NVIDIA_GPU`、`CONTAINER_SHM_SIZE` | 机器特定硬件 |
| **网络** | `HAS_PROXY`、`HTTP_PROXY_IP`、`HTTPS_PROXY_IP`、`NPM_USE_CHINA_MIRROR` | 网络环境 |
| **服务器** | `HAVE_GITLAB_SERVER`、`GITLAB_SERVER_*`、`HAVE_HARBOR_SERVER`、`HARBOR_SERVER_*` | 服务器可达性 |
| **SDK 覆盖** | `SDK_GIT_REPO`、`SDK_GIT_KEY_FILE`、`SDK_GIT_DEFAULT_BRANCH` | 当 GitLab IP 或密钥类型与平台默认值不同时覆盖 |

### 示例：主机文件

```bash
# configs/3_hosts/my-desktop.env

# 平台引用（必填）
BASE_PLATFORM="rk3588-rk3588s_ubuntu-24.04"

# 路径
HOST_VOLUME_DIR="/mnt/ssd/docker-volumes/${PRODUCT_NAME}"
EXTRA_VOLUME_0="/home/james/notes:/volumes_notes"
EXTRA_VOLUME_1="/home/james/projects:/volumes_projects"

# 硬件
USE_NVIDIA_GPU="true"
CONTAINER_SHM_SIZE="1g"

# 网络
HAS_PROXY="true"
HTTP_PROXY_IP="192.168.3.67"
HTTPS_PROXY_IP="192.168.3.67"
NPM_USE_CHINA_MIRROR="true"

# 服务器
HAVE_GITLAB_SERVER="TRUE"
GITLAB_SERVER_IP="192.168.3.67"
GITLAB_SERVER_PORT="80"
HARBOR_SERVER_IP="192.168.3.67"
HARBOR_SERVER_PORT="9000"

# SDK 覆盖（可选 — 仅当 GitLab IP 或密钥类型与平台默认值不同时需要）
# SDK_GIT_REPO="git@192.168.3.67:team_rk3588/rk3588-rk3588s_ubuntu-24.04_sdk.git"
# SDK_GIT_KEY_FILE="SDK_rk3588_RSA"
```

### Git 策略

主机配置文件被 **gitignore** 忽略 —— 它们是每台机器本地的，不应提交到仓库。`configs/3_hosts/` 目录中只有 `TEMPLATE.env.example`、`README.md` 和 `.gitkeep` 被追踪。

这保护了：
- 用户特定路径（`/home/james/...`）
- 网络配置（代理 IP、服务器地址）
- 硬件详情（GPU 可用性）

---

## 变量优先级

后面的层覆盖前面的。如果某个变量在所有层中都没有设置，则为空。

```
00_global.env  →  01_stage_1st_base.env  →  ...  →  05_stage_5th_runtime.env  →  <platform>.env  →  <hostname>.env
     ↑                                                  ↑                           ↑                  ↑
  版本/维护者/SDK版本                                服务器IP、                    平台ID、        代理设置、
                                                  OS版本、                      端口槽位、       卷挂载路径、
                                                  代理默认值                    SDK配置         GPU、服务器
```

**示例：HAS_PROXY 优先级链**

| 场景 | defaults/04_stage_4th_proxy | platforms/rk3588.env | host/my-desktop.env | 结果 |
|---|---|---|---|---|
| 无主机文件 | `"false"` | *(未设置)* | *(文件不存在)* | `"false"` |
| 主机文件有代理 | `"false"` | *(未设置)* | `"true"` | `"true"` |
| 平台设置代理（旧风格） | `"false"` | `"true"` | *(未设置)* | `"true"` |

**示例：GITLAB_SERVER_IP 优先级链**

| 场景 | defaults/03_stage_3rd_sdk | platforms/rk3588.env | host/my-desktop.env | 结果 |
|---|---|---|---|---|
| 无主机文件 | `"192.168.0.19"` | *(未设置)* | *(文件不存在)* | `"192.168.0.19"` |
| 主机覆盖 | `"192.168.0.19"` | *(未设置)* | `"192.168.3.67"` | `"192.168.3.67"` |

---

## 实际效果对比

| 场景 | 重构前（扁平） | 三层覆盖后 |
|---|---|---|
| 新增一个全局 flag | 改 N 个平台文件 | 只改 `defaults/` 里的一个文件 |
| 新增一个平台 | 复制 180 行文件，改 5 行 | 写 ~20 行覆盖内容 |
| 新增一台机器 | 无此概念 | 创建 host config，设置 BASE_PLATFORM |
| 不同机器不同 GPU 配置 | 复制平台文件 | 添加主机覆盖文件 |
| 读懂某平台的差异 | 需要和其他平台 diff | 直接读平台文件，它*就是* diff |
| 团队共享配置 | 提交所有内容 | 提交 defaults + platform，host 是私有的 |
| 用户选择构建目标 | 选择 platform | 选择 host（platform 自动解析） |

---

## 加载逻辑在哪里实现

所有消费配置的脚本都实现了相同的三层加载逻辑：

```bash
# Layer 1 — 按顺序 source 所有默认文件
for defaults_file in \
    "${DEFAULTS_DIR}/00_global.env" \
    "${DEFAULTS_DIR}/01_stage_1st_base.env" \
    ...
    "${DEFAULTS_DIR}/05_stage_5th_runtime.env"
do
    [ -f "${defaults_file}" ] && source "${defaults_file}"
done

# Layer 2 + 3 — 主机驱动的平台解析
HOST_CONFIG="${CONFIGS_DIR}/3_hosts/$(hostname).env"
if [ -f "${HOST_CONFIG}" ]; then
    # 读取 BASE_PLATFORM（不 source 整个文件）
    base_platform=$(grep -E '^BASE_PLATFORM=' "${HOST_CONFIG}" | head -1 | sed 's/^BASE_PLATFORM=//;s/^"//;s/"$//' | tr -d "'")

    if [ -n "${base_platform}" ]; then
        # 新路径：由 host config 决定平台
        source "${CONFIGS_DIR}/2_platforms/${base_platform}.env"
    else
        # 旧路径：从 .env 软链接加载平台
        source "${PLATFORM_ENV_PATH}"
    fi

    # 在 platform 之后加载 host config（host 覆盖 platform）
    source "${HOST_CONFIG}"
else
    # 没有 host config — 使用 .env 软链接（旧行为）
    source "${PLATFORM_ENV_PATH}"
fi
```

实现了此模式的脚本：

| 脚本 | 角色 |
|---|---|
| `harbor` | 构建编排入口 |
| `docker/dev-env-clientside/build.sh` | Docker 镜像构建 |
| `scripts/libs/config.sh` | 容器环境加载器 |

---

## 如何新增一个平台

1. 复制现有平台 `.env` 作为起点，或运行 `./scripts/create_platform.sh`
2. 填写**必写项**（平台身份、端口槽位、SDK 路径）
3. 只添加与默认值不同的可选覆盖项
4. 创建一个引用此平台的 host config（设置 `BASE_PLATFORM`）

**不需要**修改任何脚本或默认文件。平台对用户不可见 — 用户通过引用它的 host config 来使用它。

---

## 如何新增一个全局默认值

1. 打开对应领域的 `configs/1_defaults/NN_<domain>.env` 文件
2. 添加变量及其默认值
3. 如需新建领域文件，创建 `configs/1_defaults/06_<domain>.env`，并将其追加到所有脚本的加载列表中

需要非默认值的平台文件，只需在平台文件里加一行覆盖即可。

---

## 如何添加新主机

Host 配置是用户的核心对象。要添加新机器：

```bash
# 方式 1：使用向导（推荐）
./harbor  →  选择 "Create new host config"

# 方式 2：手动设置
hostname
cp configs/3_hosts/TEMPLATE.env.example configs/3_hosts/$(hostname).env
nano configs/3_hosts/$(hostname).env
```

至少设置 `BASE_PLATFORM` 和 `HOST_VOLUME_DIR`。详见 `configs/3_hosts/README.md` 中的示例。

---

## 另请参阅

- [主机配置模板](../../configs/3_hosts/TEMPLATE.env.example)
- [主机配置指南](../../configs/3_hosts/README.md)
- [平台配置](../../configs/2_platforms/)
- [默认配置](../../configs/1_defaults/)
