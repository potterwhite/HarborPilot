---
title: "HarborPilot 重构计划"
author: "Claude Opus 4.6（与 PotterWhite 协同分析）"
date: "2026-03-24"
tags:
  - 重构
  - 架构
  - Docker
  - Ansible
  - DevContainers
  - AI-friendly
status: "草案（待讨论后定稿）"
---

# HarborPilot 重构计划

## 一、当前架构全景图

```
HarborPilot.git/
│
├── configs/                          # ★ 配置层（三层继承）
│   ├── defaults/                     #   Layer 1: 全局默认值
│   │   ├── 01_base.env               #     - OS, 用户名, 密码, 时区
│   │   ├── 02_build.env              #     - 构建参数
│   │   ├── 03_tools.env              #     - 工具版本 (CUDA, OpenCV, Conan...)
│   │   ├── 04_workspace.env          #     - 工作区目录结构
│   │   ├── 05_registry.env           #     - Harbor/GitLab 地址
│   │   ├── 06_sdk.env                #     - SDK Git 仓库
│   │   ├── 07_volumes.env            #     - Docker volumes
│   │   ├── 08_samba.env              #     - Samba 共享配置
│   │   ├── 09_runtime.env            #     - SSH/GDB 端口等运行时
│   │   └── 11_proxy.env              #     - HTTP 代理
│   ├── platform-independent/
│   │   └── common.env                #   Layer 2: 项目级常量（版本号、维护者）
│   └── platforms/                    #   Layer 3: 平台特定覆盖（只写差异）
│       ├── rk3588s.env               #     - RK3588S (Ubuntu 24.04)
│       ├── rk3568.env                #     - RK3568
│       ├── rk3568-ubuntu22.env
│       ├── rv1126.env
│       ├── rv1126bp.env
│       └── rk3588s-ubuntu-24.env
│
├── scripts/                          # ★ 宿主机脚本
│   ├── port_calc.sh                  #   端口自动计算（PORT_SLOT → SSH/GDB端口）
│   └── create_platform.sh            #   创建新平台配置向导
│
├── docker/
│   ├── dev-env-clientside/           # ★ 主要构建目标（客户端开发环境）
│   │   ├── build.sh                  #   Docker build 入口（加载三层配置→构建）
│   │   ├── Dockerfile                #   5-stage 多阶段构建
│   │   ├── stage_1_base/             #   Stage 1: 基础 OS + 包安装
│   │   │   └── scripts/
│   │   │       └── setup_base.sh     #     apt source替换 + 包安装 + 用户/时区配置
│   │   ├── stage_2_tools/            #   Stage 2: 开发工具（CUDA, OpenCV, dev工具链）
│   │   │   └── scripts/
│   │   │       ├── install_dev_tools.sh
│   │   │       ├── install_cuda.sh
│   │   │       ├── install_opencv.sh
│   │   │       └── gitlfs_tracker.sh
│   │   ├── stage_3_sdk/              #   Stage 3: SDK 安装（模板渲染 → git clone）
│   │   │   ├── configs/*_template    #     脚本模板（${VAR} 占位符）
│   │   │   └── scripts/
│   │   │       └── install_sdk.sh_template
│   │   ├── stage_4_config/           #   Stage 4: 环境变量/代理配置写入容器
│   │   │   ├── configs/*_template
│   │   │   └── scripts/configure_env.sh
│   │   └── stage_5_final/            #   Stage 5: 工作区初始化 + entrypoint
│   │       ├── configs/*_template
│   │       └── scripts/
│   │           ├── setup_workspace.sh_template
│   │           └── entrypoint.sh_template
│   │
│   └── libs/                         # ★ 已删除（全部代码已迁移至 stage 脚本）
│
├── project_handover/                 # ★ 交付物（实际部署用）
│   ├── clientside/
│   │   ├── .env -> ../configs/platforms/<platform>.env   (symlink)
│   │   ├── .env-independent -> ../configs/platform-independent/common.env
│   │   ├── volumes -> /path/to/host/volumes              (symlink)
│   │   └── ubuntu/
│   │       ├── docker-compose.yaml  #   容器运行配置（image, ports, volumes, env）
│   │       ├── harbor.crt           #   Harbor TLS 证书
│   │       └── ubuntu_only_entrance.sh
│   └── scripts/
│       └── archive_tarball.sh       #   打包交付物
│
├── harbor/                           # Harbor Registry 相关（未展开）
│
└── doc/                              # ★ 文档
    ├── config_layers.md              #   三层配置说明（英文）
    ├── config_layers_cn.md           #   三层配置说明（中文）
    ├── quick_start.md
    ├── quick_start_cn.md
    ├── port-map-calculation.md
    └── readme_cn.md
```

---

## 二、当前架构的核心问题诊断

### 问题 1：模板渲染系统脆弱（Stage 3/4/5 的 `${VAR}` 替换）

**现状**：每个 `*_template` 文件在 Docker build 时通过 `env | cut` + `sed` 逐变量替换。
**风险**：变量值含特殊字符（`/`, `&`, `\n`）会导致 sed 出错；调试困难；且这个逻辑在三个 stage 里重复了三次。
**改进方向**：使用 `envsubst`（`gettext-base` 包，已安装）统一替换，或迁移到 Jinja2（Ansible 原生支持）。

### 问题 2：`libs/` 模块未被真正使用 — ✅ 已解决

**现状**：`libs/` 目录已被完整删除。所有功能已迁移至 `docker/dev-env-clientside/` 下的 stage 脚本。`envsubst` 替换了 `sed` 模板系统。
**结果**：消除了重复维护和混淆源。

### 问题 3：`docker-compose.yaml` 是手动维护的，与 `.env` 配置脱节 — ✅ 已解决

**现状**：`ubuntu_only_entrance.sh` 的动态生成器已完全变量化。8 个原硬编码值（restart policy、privileged、serial device、shm_size、NVIDIA settings、Samba permissions）已抽取到 `configs/defaults/` 中，可按平台覆盖。
**结果**：compose 配置 100% 由三层配置系统驱动。

### 问题 4：Shell 脚本承担了配置管理职责

**现状**：`setup_base.sh` 在做的事（检测 distro、安装包、创建用户、配置时区）本质上是**配置管理**，而 Ansible 专门为此而生，且已经处理好了所有边缘情况。

---

## 三、可借力的外部工具——逐一分析

### 工具 1：Docker Compose（立即可用，低成本）

**能替代你什么**：
- `project_handover/clientside/ubuntu/docker-compose.yaml` 已经在用，但没有发挥全部潜力
- Compose 支持 `.env` 文件变量注入，可以让 compose 文件里的 `${IMAGE_NAME}`、`${CLIENT_SSH_PORT}`、`${VOLUMES_ROOT}` 从你的 `.env` 层自动读取

**具体改进**：
```yaml
# docker-compose.yaml 改造后
services:
  dev-env:
    image: ${REGISTRY_URL}/${IMAGE_NAME}:${PROJECT_VERSION}
    container_name: ${CONTAINER_NAME}
    ports:
      - "${CLIENT_SSH_PORT}:22"
      - "${GDB_PORT}:${GDB_PORT}"
    volumes:
      - ${HOST_VOLUME_DIR}:${WORKSPACE_ROOT}/docker_volumes
```
然后 `docker compose --env-file configs/platforms/rk3588s.env up` 即可。

**优点**：零学习成本，你已经在用 Compose，只需扩展
**缺点**：不能解决 Dockerfile 内部的包安装问题，只管运行时配置

---

### 工具 2：Ansible（中等成本，高回报）

**能替代你什么**：`setup_base.sh` 里的所有内容——包安装、用户创建、时区配置、apt source 替换

**最大价值**：Ansible 有 `ansible.builtin.apt` 模块，它**原生处理了你所有的跨发行版问题**：
```yaml
# 替代你的 func_install_system_core()
- name: Install core packages
  ansible.builtin.apt:
    name:
      - sudo
      - apt-transport-https
      - ca-certificates
      - libncursesw6          # 版本问题？Ansible 的 package facts 可以处理
    state: present
    update_cache: yes

# 替代你的 func_replace_apt_source()
- name: Replace apt source (Ubuntu 24.04+)
  ansible.builtin.copy:
    content: |
      Types: deb
      URIs: http://mirrors.aliyun.com/ubuntu
      Suites: {{ ansible_distribution_release }} ...
    dest: /etc/apt/sources.list.d/ubuntu.sources
  when: ansible_distribution_version is version('24.04', '>=')
```

**Ansible 在 Docker 中的用法**（与你的构建流程集成）：
```dockerfile
# Stage 1 改造方案
FROM ubuntu:${OS_VERSION} AS stage_1st_base
RUN apt-get update && apt-get install -y ansible
COPY ansible/playbook_base.yml /tmp/
RUN ansible-playbook /tmp/playbook_base.yml --connection=local
```

**优点**：
- 原生跨发行版（ubuntu/debian/alpine/rhel 同一个 playbook）
- 幂等性（可以重复执行）
- 可读性远超 shell 脚本
- 社区 role 库（Ansible Galaxy）可以直接复用别人的成果

**缺点**：
- 学习曲线（YAML + Ansible 概念）
- Docker 构建时间会增加（需要安装 Ansible 本身）
- Docker 镜像体积略增

---

### 工具 3：Dev Containers（devcontainer.json）

**能替代你什么**：整个 `project_handover/clientside/ubuntu/` 目录的用途——让开发者一键启动标准化开发环境

**是什么**：VSCode / GitHub Codespaces 的开放标准，一个 `devcontainer.json` 文件描述开发环境（基础镜像、挂载、端口转发、VSCode 扩展）

**集成方案**：
```
.devcontainer/
├── devcontainer.json          # 描述开发环境（引用你的 Dockerfile）
└── docker-compose.yaml        # 可选：引用你的 compose 文件
```
```json
{
  "name": "RK3588S Dev Env",
  "dockerComposeFile": "../project_handover/clientside/ubuntu/docker-compose.yaml",
  "service": "dev-env",
  "workspaceFolder": "/development",
  "forwardPorts": [2109, 2345],
  "extensions": ["ms-vscode.cpptools", "ms-python.python"]
}
```

**优点**：
- VSCode 原生支持，用户体验极好（一键打开容器）
- 与你现有的 Dockerfile + Compose 完全兼容，改动极小
- 让你的工具对 AI 代码助手（GitHub Copilot、Cursor）友好——这些工具原生理解 devcontainer.json

**缺点**：
- 绑定 VSCode 生态（虽然规范是开放的）
- 不解决 Dockerfile 本身的跨平台问题

---

### 工具 4：`envsubst`（立即可用，替代当前模板渲染）

**能替代你什么**：Stage 3/4/5 里那个重复了三次的 `env | cut | sed` 模板渲染逻辑

**现状**：
```bash
# 当前：70+ 行的复杂 sed 替换循环
env | cut -d= -f1 > /tmp/env_vars.txt
while read var_name; do
    sed -i "s|\${$var_name}|$var_value_escaped|g" "$output_file.tmp"
done < /tmp/env_vars.txt
```

**改造后**：
```bash
# 只需一行，且处理了特殊字符
envsubst < template_file > output_file
```

`envsubst` 已经包含在 `gettext-base` 包里（你已经在 `setup_base.sh` 里安装了），**立刻可用，零成本**。

---

### 工具 5：Nix / NixOS（长期，高难度，颠覆性）

**能替代你什么**：整个构建系统

**是什么**：声明式包管理器，彻底消除"在我机器上能跑"——通过哈希锁定所有依赖，保证完全可复现。

**与你项目的关系**：Nix 可以用 `nix develop` 替代整个 Docker 开发环境，且不需要 Docker。`flake.nix` 就是你的 `.env` + `Dockerfile` + `docker-compose.yaml` 的合体。

**优点**：真正的"任意修改配置就能适应任何构建"，且更轻量
**缺点**：学习曲线陡峭，生态对嵌入式支持不如 Yocto，中文资料少

---

## 四、重构优先级建议

按 **收益/成本比** 排序：

```
优先级 1（立刻做，成本低）：
  ├── 用 envsubst 替换三个 stage 里的 sed 模板渲染逻辑
  │     - 改动：Dockerfile Stage 3/4/5 的 RUN set -a... 代码块
  │     - 收益：消除 70+ 行重复代码，修复特殊字符 bug
  └── docker-compose.yaml 接入 .env 变量
        - 改动：compose 文件里硬编码值改成 ${VAR}
        - 收益：换平台不用手改 compose

优先级 2（中期，值得投入）：
  ├── 添加 .devcontainer/devcontainer.json
  │     - 改动：新增目录和文件，不影响现有代码
  │     - 收益：VSCode 一键开发，AI 友好，现代化项目形象
  └── ~~把 libs/iv_scripts/setup_base.sh 合并到 clientside 版本~~ ✅ 已完成（直接删除，stage_1 版本是唯一源）

优先级 3（长期，架构升级）：
  └── setup_base.sh → Ansible playbook
        - 改动：重写 Stage 1 的包安装逻辑
        - 收益：原生跨发行版，可读性++，复用社区 roles

优先级 4（探索性，根据项目方向决定）：
  └── 不局限 Docker：Vagrant + Ansible
        - 支持 VMware, VirtualBox, KVM
        - 成本高，除非有明确需求
```

---

## 五、让工具成为 AI 可以操作的基础设施

这是最重要的一节。你问：**用户直接用也得能用，但也要让 AI agent 能用**。

### 当前问题
AI agent（比如 Claude Code）要帮用户新建一个 RK3568 Ubuntu 24.04 平台，现在需要：
1. 理解你的三层配置系统
2. 理解哪些字段是必填的
3. 手动写 `.env` 文件
4. 知道要不要修改 compose 文件

这些对 AI 来说都是**隐式知识**，需要读代码才能理解。

### 改进方向：显式化配置 Schema

**方案 A：JSON Schema**
在 `configs/` 目录下加一个 `platform_schema.json`，描述每个字段的含义、类型、是否必填、有效值范围：
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "HarborPilot Platform Config",
  "properties": {
    "PRODUCT_NAME": {
      "type": "string",
      "description": "Platform identifier, used as image name prefix",
      "examples": ["rk3588s", "rk3568"]
    },
    "OS_VERSION": {
      "type": "string",
      "enum": ["20.04", "22.04", "24.04"],
      "description": "Ubuntu version"
    },
    "PORT_SLOT": {
      "type": "integer",
      "minimum": 0,
      "maximum": 99,
      "description": "Port slot for auto-calculating SSH and GDB ports"
    }
  },
  "required": ["PRODUCT_NAME", "OS_VERSION", "PORT_SLOT"]
}
```

AI 看到这个 schema，立刻知道如何生成正确的 `.env` 文件，而不需要阅读所有代码。

**方案 B：Platform Wizard（`create_platform.sh` 升级版）**
你已经有 `scripts/create_platform.sh`——升级它，让它能被 AI 调用：
```bash
# AI 可以这样调用：
./scripts/create_platform.sh \
    --name rk3568-debian12 \
    --os debian \
    --version 12 \
    --port-slot 3 \
    --cuda false
```
而不是交互式的 whiptail 菜单。两种模式共存：人类用菜单，AI 用参数。

### AI 友好的项目特征清单

| 特征 | 当前状态 | 改进方向 |
|------|----------|----------|
| 配置有 schema 文档 | ❌ 只有注释 | ✅ JSON Schema 或 README 表格 |
| 操作可以无交互执行 | ⚠️ create_platform.sh 需要 whiptail | ✅ 加 --non-interactive 参数 |
| 有明确的入口命令 | ✅ build.sh | ✅ 保持 |
| 错误信息清晰 | ⚠️ 部分有 | ✅ 统一错误格式 |
| devcontainer.json | ❌ 无 | ✅ 加上 |
| 配置和实现分离 | ✅ 已做到 | ✅ 继续保持，这是最重要的 |

---

## 六、结语：你应该做什么，不应该做什么

### 应该做
- **继续保持三层配置系统**——这是 HarborPilot 最有价值的部分，也是 AI 可以操作的"意图层"
- **加 JSON Schema**——成本极低，价值极高
- **用 envsubst 替换 sed 模板**——这是当前最容易修的技术债
- **加 devcontainer.json**——让项目现代化

### 不应该做（暂时）
- **全量迁移到 Ansible**——除非你有明确的多发行版需求，当前的 shell 脚本够用
- **支持非 Docker 虚拟化**——Vagrant/KVM 方向，成本高，当前没有具体需求
- **自己实现 Yocto-like 层系统**——你的目标是开发环境，不是系统构建，这是不同问题

### 一句话总结
> **HarborPilot 的核心价值已经成立：配置驱动的嵌入式开发环境。现在需要的不是推倒重来，而是用现有工具填补执行层的缺口（envsubst, devcontainer, JSON Schema），让它成为 AI 可以操作的基础设施。**
