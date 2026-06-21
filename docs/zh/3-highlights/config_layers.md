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
Layer 1  configs/1_defaults/*.env          全局默认值 — 所有平台继承
   ↓  （后加载的层覆盖先加载的）
Layer 2  configs/2_platforms/<platform>.env 平台特有覆盖（只写差异部分）
   ↓
Layer 3  configs/3_host/<hostname>.env     主机级覆盖（可选，自动加载，gitignore）
```

**核心规则：** 平台文件里只写与默认值*不同*的内容。如果某个变量不在平台文件里，就自动使用默认值。主机文件里只写与平台配置*不同*的内容 —— 如果某个变量不在主机文件里，就使用平台值。

---

## Layer 1 — 全局默认值（`configs/1_defaults/`）

12 个文件，每个文件负责一个关注领域。文件名前缀的数字使加载顺序一目了然。

| 文件 | 包含的变量 |
|---|---|
| `00_project.env` | `VERSION`、`PROJECT_VERSION`、`PROJECT_RELEASE_DATE`、`PROJECT_MAINTAINER`、`SDK_VERSION` |
| `01_base.env` | `OS_VERSION`、`DEV_USERNAME`、`DEV_UID/GID`、`TIMEZONE`、`DEBIAN_FRONTEND` |
| `02_build.env` | `DOCKER_BUILDKIT` |
| `03_tools.env` | `INSTALL_CUDA/OPENCV/CMAKE`、工具版本号（`CONAN_VERSION` 等）、`GCC_OFFLINE_PACKAGE` |
| `04_workspace.env` | `WORKSPACE_ROOT` 及所有子目录路径、`WORKSPACE_BUILD_THREADS`、调试配置 |
| `05_registry.env` | `HAVE_GITLAB_SERVER`、`HARBOR_SERVER_IP`、`HARBOR_SERVER_PORT`、`HAVE_HARBOR_SERVER`、`GITLAB_SERVER_IP`、`GITLAB_SERVER_PORT` |
| `06_sdk.env` | `INSTALL_SDK`、`CHIP_FAMILY=${PRODUCT_NAME}`（URL 依赖 `CHIP_FAMILY`，在 Layer 2 设置） |
| `07_volumes.env` | `VOLUMES_ROOT`（注意：`HOST_VOLUME_DIR` 无通用默认值，必须在 Layer 2 或 3 设置） |
| `08_samba.env` | `SAMBA_PUBLIC/PRIVATE_ACCOUNT_NAME/PASSWORD`、`ENABLE_VSC_INTEGRATION` |
| `09_runtime.env` | `ENABLE_SSH`、`ENABLE_SYSLOG`、`ENABLE_GDB_SERVER`、`ENABLE_CORE_DUMPS`、`USE_NVIDIA_GPU` |
| `11_proxy.env` | `HAS_PROXY`（默认 `false`）、`HTTP/HTTPS_PROXY_IP` |

**加载顺序至关重要。** 文件按数字顺序依次 source（00 → 11）。`05_registry.env` 里若要引用 `CONTAINER_NAME`，而该变量在 Layer 1 阶段尚未赋值 —— 这正是 `REGISTRY_URL` 故意不放在 Layer 1、而是在 Layer 2 里计算的原因。

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
| **SDK** | `SDK_INSTALL_PATH`、`SDK_GIT_REPO`、`SDK_GIT_KEY_FILE`、`SDK_GIT_DEFAULT_BRANCH` | 平台特定的 SDK |

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

# SDK  [CHIP_FAMILY 将同硅片变体归为一组]
SDK_INSTALL_PATH="${WORKSPACE_ROOT}/sdk"
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

## Layer 3 — 主机级覆盖（`configs/3_host/<hostname>.env`）

这一层是**可选的**，由**主机名自动加载**。它解决了同一平台配置在不同硬件、网络或路径的机器上运行的问题。

### 如何开始

```bash
# 1. 获取主机名
hostname

# 2. 复制模板
cp configs/3_host/TEMPLATE.env.example configs/3_host/$(hostname).env

# 3. 编辑配置
nano configs/3_host/$(hostname).env
```

### 应该放什么

| 类别 | 变量 | 原因 |
|------|------|------|
| **网络** | `HAS_PROXY`、`HTTP_PROXY_IP`、`HTTPS_PROXY_IP`、`NPM_USE_CHINA_MIRROR` | 网络环境 |
| **服务器** | `HAVE_GITLAB_SERVER`、`GITLAB_SERVER_*`、`HAVE_HARBOR_SERVER`、`HARBOR_SERVER_*` | 服务器可达性 |
| **硬件** | `USE_NVIDIA_GPU`、`CONTAINER_SHM_SIZE` | 机器特定硬件 |
| **路径** | `HOST_VOLUME_DIR`、`EXTRA_VOLUME_*` | 宿主机文件系统路径 |

### 示例：主机文件

```bash
# configs/3_host/my-desktop.env

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

# 硬件
USE_NVIDIA_GPU="true"
CONTAINER_SHM_SIZE="1g"

# 路径
HOST_VOLUME_DIR="/mnt/ssd/docker-volumes/${PRODUCT_NAME}"
EXTRA_VOLUME_0="/home/james/notes:/volumes_notes"
EXTRA_VOLUME_1="/home/james/projects:/volumes_projects"
```

### Git 策略

主机配置文件被 **gitignore** 忽略 —— 它们是每台机器本地的，不应提交到仓库。`configs/3_host/` 目录中只有 `TEMPLATE.env.example`、`README.md` 和 `.gitkeep` 被追踪。

这保护了：
- 用户特定路径（`/home/james/...`）
- 网络配置（代理 IP、服务器地址）
- 硬件详情（GPU 可用性）

---

## 变量优先级

后面的层覆盖前面的。如果某个变量在所有层中都没有设置，则为空。

```
00_project.env  →  01_base.env  →  ...  →  11_proxy.env  →  <platform>.env  →  <hostname>.env
     ↑                                          ↑                ↑                  ↑
  版本/维护者/SDK版本                        服务器IP、        平台ID、        代理设置、
                                          OS版本、          端口槽位、       卷挂载路径、
                                          代理默认值        SDK配置         GPU、服务器
```

**示例：HAS_PROXY 优先级链**

| 场景 | defaults/11_proxy | platforms/rk3588.env | host/my-desktop.env | 结果 |
|---|---|---|---|---|
| 无主机文件 | `"false"` | *(未设置)* | *(文件不存在)* | `"false"` |
| 主机文件有代理 | `"false"` | *(未设置)* | `"true"` | `"true"` |
| 平台设置代理（旧风格） | `"false"` | `"true"` | *(未设置)* | `"true"` |

**示例：GITLAB_SERVER_IP 优先级链**

| 场景 | defaults/05_registry | platforms/rk3588.env | host/my-desktop.env | 结果 |
|---|---|---|---|---|
| 无主机文件 | `"192.168.0.19"` | *(未设置)* | *(文件不存在)* | `"192.168.0.19"` |
| 主机覆盖 | `"192.168.0.19"` | *(未设置)* | `"192.168.3.67"` | `"192.168.3.67"` |

---

## 实际效果对比

| 场景 | 重构前（扁平） | 三层覆盖后 |
|---|---|---|
| 新增一个全局 flag | 改 N 个平台文件 | 只改 `defaults/` 里的一个文件 |
| 新增一个平台 | 复制 180 行文件，改 5 行 | 写 ~20 行覆盖内容 |
| 某平台特殊化某选项 | 早就在文件里了 | 在平台文件里加一行 |
| 不同机器不同 GPU 配置 | 复制平台文件 | 添加主机覆盖文件 |
| 读懂某平台的差异 | 需要和其他平台 diff | 直接读平台文件，它*就是* diff |
| 团队共享配置 | 提交所有内容 | 提交 defaults + platform，host 是私有的 |

---

## 加载逻辑在哪里实现

所有消费配置的脚本都实现了相同的三层加载逻辑：

```bash
# Layer 1 — 按顺序 source 所有默认文件
for defaults_file in \
    "${DEFAULTS_DIR}/00_project.env" \
    "${DEFAULTS_DIR}/01_base.env" \
    ...
    "${DEFAULTS_DIR}/11_proxy.env"
do
    [ -f "${defaults_file}" ] && source "${defaults_file}"
done

# Layer 2
source "${PLATFORM_ENV_PATH}"               # 通过 symlink 指向 <platform>.env

# Layer 3 — 可选，按主机名自动加载
HOST_CONFIG="${CONFIGS_DIR}/3_hosts/$(hostname).env"
[ -f "${HOST_CONFIG}" ] && source "${HOST_CONFIG}"
```

`project_handover/` 下的 symlink（`.env`）在你运行 `./harbor` 选择平台时自动创建。

实现了此模式的脚本：

| 脚本 | 角色 |
|---|---|
| `harbor` | 构建编排入口 |
| `docker/dev-env-clientside/build.sh` | Docker 镜像构建 |
| `project_handover/clientside/ubuntu/ubuntu_only_entrance.sh` | 容器生命周期管理 |

---

## 如何新增一个平台

1. 复制现有平台 `.env` 作为起点，或运行 `./scripts/create_platform.sh`
2. 填写**必写项**（平台身份、端口槽位、SDK 路径）
3. 只添加与默认值不同的可选覆盖项
4. 运行 `./harbor` — 新平台会自动出现在选择菜单中

**不需要**修改任何脚本或默认文件。

---

## 如何新增一个全局默认值

1. 打开对应领域的 `configs/1_defaults/NN_<domain>.env` 文件
2. 添加变量及其默认值
3. 如需新建领域文件，创建 `configs/1_defaults/12_<domain>.env`，并将其追加到四个脚本的加载列表中

需要非默认值的平台文件，只需在平台文件里加一行覆盖即可。

---

## 如何添加主机级覆盖

1. 运行 `hostname` 获取机器名
2. 复制模板：`cp configs/3_host/TEMPLATE.env.example configs/3_host/$(hostname).env`
3. 编辑文件，取消注释并设置你需要的变量
4. 系统自动加载此文件 —— 无需修改脚本

详见 `configs/3_host/README.md` 中的示例和故障排除。

---

## 另请参阅

- [主机配置模板](../../configs/3_host/TEMPLATE.env.example)
- [主机配置指南](../../configs/3_host/README.md)
- [平台配置](../../configs/2_platforms/)
- [默认配置](../../configs/1_defaults/)
