# 三层配置系统详解

> **Related:** [English Version →](../../../../en/architecture/4-reference/config_layers.md)

本文档解释 HarborPilot 配置系统的工作原理、为什么采用三层结构，以及如何在新增平台或新增全局配置项时使用它。

---

## 它解决了什么问题？

HarborPilot 早期版本使用扁平结构：

```
configs/platforms/
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
Layer 1  configs/defaults/*.env          全局默认值 — 所有平台继承
   ↓  （后加载的层覆盖先加载的）
Layer 2  configs/platform-independent/common.env    项目版本与常量
   ↓
Layer 3  configs/platforms/<platform>.env           平台特有覆盖（只写差异部分）
```

**核心规则：** 平台文件里只写与默认值*不同*的内容。如果某个变量不在平台文件里，就自动使用默认值。

---

## Layer 1 — 全局默认值（`configs/defaults/`）

11 个文件，每个文件负责一个关注领域。文件名前缀的数字使加载顺序一目了然。

| 文件 | 包含的变量 |
|---|---|
| `01_base.env` | `OS_VERSION`、`DEV_USERNAME`、`DEV_UID/GID`、`TIMEZONE`、`DEBIAN_FRONTEND` |
| `02_build.env` | `DOCKER_BUILDKIT` |
| `03_tools.env` | `INSTALL_CUDA/OPENCV/CMAKE`、工具版本号（`CONAN_VERSION` 等）、`GCC_OFFLINE_PACKAGE` |
| `04_workspace.env` | `WORKSPACE_ROOT` 及所有子目录路径、`WORKSPACE_BUILD_THREADS`、调试配置 |
| `05_registry.env` | `HAVE_GITLAB_SERVER`、`HARBOR_SERVER_IP`、`HARBOR_SERVER_PORT`、`HAVE_HARBOR_SERVER`、`GITLAB_SERVER_IP`、`GITLAB_SERVER_PORT` |
| `06_sdk.env` | `INSTALL_SDK`、`CHIP_FAMILY=${PRODUCT_NAME}`（URL 依赖 `CHIP_FAMILY`，在 Layer 3 设置） |
| `07_volumes.env` | `VOLUMES_ROOT`（注意：`HOST_VOLUME_DIR` 无通用默认值，必须在 Layer 3 设置） |
| `08_samba.env` | `SAMBA_PUBLIC/PRIVATE_ACCOUNT_NAME/PASSWORD`、`ENABLE_VSC_INTEGRATION` |
| `09_runtime.env` | `ENABLE_SSH`、`ENABLE_SYSLOG`、`ENABLE_GDB_SERVER`、`ENABLE_CORE_DUMPS`、`USE_NVIDIA_GPU` |
| `11_proxy.env` | `HAS_PROXY`（默认 `false`）、`HTTP/HTTPS_PROXY_IP` |

**加载顺序至关重要。** 文件按数字顺序依次 source（01 → 11）。`05_registry.env` 里若要引用 `CONTAINER_NAME`，而该变量在 Layer 1 阶段尚未赋值 —— 这正是 `REGISTRY_URL` 故意不放在 Layer 1、而是在 Layer 3 里计算的原因。

---

## Layer 2 — 项目常量（`configs/platform-independent/common.env`）

只包含**项目级、纳入版本管理**的不变量，与平台无关：

```bash
PROJECT_VERSION="1.5.0"
PROJECT_RELEASE_DATE="2026-03-16"
PROJECT_MAINTAINER="[PotterWhite]"
PROJECT_LICENSE="MIT"
SDK_VERSION="1.1.2"
SDK_RELEASE_DATE="2025-06-30"
```

这个文件只在项目发布时才会变动，不含任何平台信息或基础设施地址。

---

## Layer 3 — 平台覆盖（`configs/platforms/<platform>.env`）

每个平台文件只包含**与默认值不同的内容**。必须填写的部分：

### 必写项（无默认值）

```bash
# 平台身份
PRODUCT_NAME="rk3568"
OS_VERSION="20.04"
OS_DISTRIBUTION="ubuntu"

# 衍生名称（依赖 PRODUCT_NAME）
IMAGE_NAME="${PRODUCT_NAME}-dev-env"
CONTAINER_NAME=${PRODUCT_NAME}
LATEST_IMAGE_TAG=${PROJECT_VERSION}

# 端口槽位 — 所有端口由 port_calc.sh 自动推导
PORT_SLOT="2"

# Registry URL（依赖 CHIP_FAMILY 和 HARBOR_SERVER_IP）
HARBOR_SERVER_IP="192.168.3.67"
HARBOR_SERVER_PORT="9000"
REGISTRY_URL="${HARBOR_SERVER_IP}:${HARBOR_SERVER_PORT}/team_${CHIP_FAMILY}"

# GitLab 服务器（用于 SDK 仓库）
HAVE_GITLAB_SERVER="TRUE"
GITLAB_SERVER_IP="192.168.3.67"
GITLAB_SERVER_PORT="22"

# SDK 路径（依赖 CHIP_FAMILY）
SDK_INSTALL_PATH="${WORKSPACE_ROOT}/sdk"
SDK_GIT_REPO="git@${GITLAB_SERVER_IP}:team_${CHIP_FAMILY}/${CHIP_FAMILY}_sdk.git"
SDK_GIT_KEY_FILE="SDK_${CHIP_FAMILY}_ED25519"

# 宿主机 Volume 路径（机器相关，无通用默认值）
HOST_VOLUME_DIR="/mnt/.../volumes/rk3568"
```

### 可选覆盖（仅在与默认值不同时才写）

```bash
# rk3568 需要国内 npm 镜像；默认是 false
NPM_USE_CHINA_MIRROR="true"

# rk3568 有代理访问；默认是 false
HAS_PROXY="true"

# rk3568 SDK 使用非 main 分支
SDK_GIT_DEFAULT_BRANCH="br_main_20250206"
```

仅此而已 —— 其他所有内容都从 Layer 1 静默继承。

---

## 实际效果对比

| 场景 | 重构前（扁平） | 三层覆盖后 |
|---|---|---|
| 新增一个全局 flag | 改 N 个平台文件 | 只改 `defaults/` 里的一个文件 |
| 新增一个平台 | 复制 180 行文件，改 5 行 | 写 ~20 行覆盖内容 |
| 某平台特殊化某选项 | 早就在文件里了 | 在平台文件里加一行 |
| 读懂某平台的差异 | 需要和其他平台 diff | 直接读平台文件，它*就是* diff |

---

## 加载逻辑在哪里实现

所有消费配置的脚本都实现了相同的三层加载逻辑：

```bash
# Layer 1 — 按顺序 source 所有默认文件
for defaults_file in \
    "${DEFAULTS_DIR}/01_base.env" \
    "${DEFAULTS_DIR}/02_build.env" \
    ...
    "${DEFAULTS_DIR}/11_proxy.env"
do
    [ -f "${defaults_file}" ] && source "${defaults_file}"
done

# Layer 2
source "${PLATFORM_INDEPENDENT_ENV_PATH}"   # 通过 symlink 指向 common.env

# Layer 3
source "${PLATFORM_ENV_PATH}"               # 通过 symlink 指向 <platform>.env
```

`project_handover/` 下的两个 symlink（`.env` 和 `.env-independent`）在你运行 `./harbor` 选择平台时自动创建。

实现了此模式的脚本：

| 脚本 | 角色 |
|---|---|
| `harbor` | 构建编排入口 |
| `docker/dev-env-clientside/build.sh` | Docker 镜像构建 |
| `project_handover/clientside/ubuntu/ubuntu_only_entrance.sh` | 容器生命周期管理 |

---

## 如何新增一个平台

1. 复制 `configs/platforms/offline.env` → `configs/platforms/<your-platform>.env`
2. 填写**必写项**（平台身份、端口、`HOST_VOLUME_DIR`、Registry URL）
3. 只添加与默认值不同的可选覆盖项
4. 运行 `./harbor` — 新平台会自动出现在选择菜单中

**不需要**修改任何脚本或默认文件。

---

## 如何新增一个全局默认值

1. 打开对应领域的 `configs/defaults/NN_<domain>.env` 文件
2. 添加变量及其默认值
3. 如需新建领域文件，创建 `configs/defaults/12_<domain>.env`，并将其追加到四个脚本的加载列表中

需要非默认值的平台文件，只需在平台文件里加一行覆盖即可。
