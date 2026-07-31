<div align="center">
  <h1>HarborPilot</h1>
  <p><i>一条命令搞定嵌入式 Linux Docker 开发环境 — 多平台、可复现、对接 Harbor 私有镜像仓库</i></p>
</div>

<p align="center">
  <img src="docs/zh/assets/light-background.png" alt="HarborPilot Banner" width="100%"/>
</p>

<p align="center">
  <a href="https://github.com/potterwhite/HarborPilot/releases">
    <img src="https://img.shields.io/github/v/release/potterwhite/HarborPilot?color=blue&label=version">
  </a>
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License"/>
  <img src="https://img.shields.io/badge/host-Ubuntu-orange?style=flat-square" alt="Host Platform"/>
  <img src="https://img.shields.io/badge/Docker-required-2496ED?style=flat-square&logo=docker&logoColor=white" alt="Docker"/>
  <img src="https://img.shields.io/badge/shell-bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white" alt="Shell"/>
  <img src="https://img.shields.io/badge/target-Rockchip%20%7C%20ARM%20SoC-lightgrey?style=flat-square" alt="Target"/>
</p>

<p align="center">
  <strong>简体中文</strong>
</p>

---

## HarborPilot 解决什么问题？

**你正在为嵌入式 Linux 开发板（RK3588、RK3588S、RK3568、RV1126 或其他 ARM SoC，运行 Ubuntu 或 Debian）构建 Docker 开发环境吗？**

常见痛点：
- 每个开发者装的工具链略有不同 → 不同机器上构建结果不一致
- 支持多芯片家族意味着维护多份分叉的 Dockerfile
- 加上 Ubuntu 24.04 支持就破坏 20.04 上的工作流（apt 格式、UID 冲突、pip PEP 668）
- 同时跑多个平台的容器时端口冲突
- 把镜像推送到私有 Harbor Registry 靠一堆没人记得住的胶水脚本

**HarborPilot 一并解决**：单命令构建管线、三层配置系统（新增平台只需 20 行以内配置）、自动端口分配（保证零冲突）。

---

## HarborPilot 是什么？

HarborPilot 是一套完全脚本化的工具链，用于为嵌入式 Linux 目标平台**构建、管理和分发容器化交叉编译开发环境**。

- **一条命令构建** — `./harbor` 选择平台、构建 5 阶段 Docker 镜像、打 tag、推送到私有 Harbor Registry
- **一条命令启动** — 抽出 handover tarball 后 `./entrance.sh start` 即可在任意 Ubuntu 宿主机上拉起完整配置的开发容器
- **三层配置系统** — 改一处全局默认值，所有平台自动继承；新增平台只需不到 20 行
- **PORT_SLOT 自动端口分配** — 一个整数自动推导 SSH 和 GDB 端口，彻底告别手动管理

主要目标平台：Rockchip 系列 SoC（RK3588S、RK3568、RV1126、RV1126bp），覆盖 Ubuntu 20.04 / 22.04 / 24.04。
架构本身与平台无关——新增 Debian 平台或其他芯片家族只需几分钟。

---

## 核心特性

| 特性 | 说明 |
|---|---|
| **一命令构建** | `./harbor` — 选 host → 构建 → 打 tag → 推送 → 校验 manifest |
| **一命令启动** | `./entrance.sh start` — 抽出 tarball 后秒级拉起完整容器 |
| **Host 为核心** | host 配置是用户操作对象；platform 与 defaults 是不可见支撑层 |
| **端口零冲突** | `PORT_SLOT` 公式 — SSH 与 GDB 端口自动推导，绝不冲突 |
| **Registry 全流程** | 自动推送 + manifest SHA256 校验 — 不是「上传完听天由命」 |
| **芯片家族分组** | `CHIP_FAMILY` 驱动 Harbor project、SDK 仓库、SSH key；RK3588 多个变体共享一个 team |
| **AI 可读配置** | `.env` 文件就是意图层 — AI agent 可直接读、修改、然后调用 `./harbor` 构建 |
| **嵌入式默认项** | GDB server、串口透传、OpenCV、可选 CUDA — 全都预接好 |
| **跨发行版支持** | Ubuntu 20.04 / 22.04 / 24.04 全部正确处理（DEB822、UID 1000、PEP 668） |
| **envsubst 模板** | 所有阶段配置经 `envsubst` 渲染 — 不再依赖脆弱的 sed 管道 |

---

## 三层配置怎么工作？

```
Layer 1:  configs/1_defaults/*.env        ← 全局默认值（自动、不可见）
Layer 2:  configs/2_platforms/<name>.env  ← 平台身份（自动、不可见）
Layer 3:  configs/3_hosts/<hostname>.env   ← 主机配置（用户操作对象）
```

**Host 才是核心对象。** 每个 host 配置通过 `BASE_PLATFORM` 声明自己使用的平台，包含所有该机器特定的覆盖项。用户只与 host 配置交互——platform 与 defaults 是内部支撑层。

一个 host 配置最少需要：
- `BASE_PLATFORM` — 使用哪个平台（如 `rk3588-rk3588s_ubuntu-24.04`）
- `HOST_VOLUME_DIR` — 在本机存储 Docker volume 的目录

**PORT_SLOT** 是端口的单一真源：
- `CLIENT_SSH_PORT = 2109 + PORT_SLOT × 10`
- `GDB_PORT = 2345 + PORT_SLOT × 10`

新增一个 host：运行 `./harbor` → 「Create new host config」，或手动复制 `TEMPLATE.env.example`。

→ 深入了解：[docs/zh/3-highlights/config_layers.md](docs/zh/3-highlights/config_layers.md)

---

## 仓库结构

```
HarborPilot/
│
├── harbor                            ← 入口：构建 → 打 tag → 推送 → 校验
│
├── configs/
│   ├── 1_defaults/                   ← Layer 1 · 6 个阶段对齐的默认文件
│   │   ├── 00_global.env             项目版本、元数据、SDK 版本
│   │   ├── 01_stage_1st_base.env     OS、用户、时区
│   │   ├── 02_stage_2nd_build.env    BuildKit、开发工具、CUDA、OpenCV
│   │   ├── 03_stage_3rd_sdk.env      Registry 地址 + SDK 开关与路径
│   │   ├── 04_stage_4th_proxy.env    代理（默认关闭）
│   │   └── 05_stage_5th_runtime.env  工作区、卷、Samba、SSH/GDB/NVIDIA
│   ├── 2_platforms/                  ← Layer 2 · 仅放各平台的差异覆盖
│   │   ├── rk3588-rk3588s_ubuntu-22.04
│   │   ├── rk3588-rk3588s_ubuntu-24.04
│   │   ├── rk3588-rk3588s_ubuntu-20.04
│   │   ├── rk3568-rk3568_ubuntu-20.04
│   │   ├── rk3568-rk3568_ubuntu-22.04
│   │   ├── rv1126-rv1126_ubuntu-22.04
│   │   ├── rv1126-rv1126bp_ubuntu-22.04
│   │   └── jetson-orin-nx-16g-super_ubuntu-22.04
│   └── 3_hosts/                      ← Layer 3 · 主机配置（用户操作对象）
│
├── docker/
│   └── dev-env-clientside/           ← 5 阶段 Dockerfile
│       ├── Dockerfile                   base → tools → sdk → config → final
│       └── build.sh
│
├── scripts/
│   ├── create_platform.sh            ← 平台向导（交互 + 非交互）
│   ├── port_calc.sh                  ← PORT_SLOT → SSH/GDB 端口推导
│   └── libs/
│       ├── common/                   ← 共享工具（utils.sh, ui.sh）
│       ├── handover/                 ← 客户端脚本（打包进 tarball）
│       ├── config.sh                 ← 三层配置加载器
│       ├── build.sh                  ← Docker build/tag/push
│       └── package.sh                ← Handover 打包
│
└── docs/                             ← 双语文档（EN + ZH）
    ├── en/
    │   ├── 1-for-ai/                 AI agent 参考文件
    │   ├── 2-progress/               阶段跟踪 & 路线图
    │   ├── 3-highlights/             架构决策与分析
    │   └── 4-for-beginner/           快速上手指南
    └── zh/                           中文镜像
```

---

## 支持的平台

| 平台 | Ubuntu | SSH 端口 | GDB 端口 | 备注 |
|---|---|---|---|---|
| `rk3588-rk3588s_ubuntu-22.04` | 22.04 | 2109 | 2345 | 默认启用 NVIDIA GPU |
| `rv1126-rv1126bp_ubuntu-22.04` | 22.04 | 2119 | 2355 | |
| `rk3568-rk3568_ubuntu-20.04` | 20.04 | 2129 | 2365 | |
| `rv1126-rv1126_ubuntu-22.04` | 22.04 | 2139 | 2375 | |
| `rk3568-rk3568_ubuntu-22.04` | 22.04 | 2149 | 2385 | |
| `rk3588-rk3588s_ubuntu-24.04` | 24.04 | 2159 | 2395 | 不带 NVIDIA GPU |
| `rk3588-rk3588s_ubuntu-20.04` | 20.04 | 2169 | 2405 | |
| `jetson-orin-nx-16g-super_ubuntu-22.04` | 22.04 | 2179 | 2415 | Jetson 交叉编译 |

---

## 快速上手

→ **完整指南：[docs/zh/4-for-beginner/quick_start.md](docs/zh/4-for-beginner/quick_start.md)**

```bash
# 1. 安装 Docker 并信任 Harbor CA 证书（每台宿主机一次）
#    → 详见 docs/zh/4-for-beginner/quick_start.md

# 2. 登录 Harbor Registry
docker login <registry-ip>:<registry-port>

# 3. 构建 — 交互式选择目标平台
./harbor

# 4. 启动开发容器
#    （先运行 ./harbor → "Package Handover" 拿到 tarball 并解压）
./entrance.sh start
```

**非交互式（CI / 脚本化）：**
```bash
./scripts/create_platform.sh --non-interactive \
    --name rk3566-debian12 --os debian --os-version 12 \
    --harbor-ip 192.168.3.68 --port-slot 6
```

---

## 常见问题

**Q：芯片家族不在上面列表里能用吗？**
A：可以。运行 `./scripts/create_platform.sh`，几分钟加一个新平台。向导会自动分配 PORT_SLOT 避免冲突，并生成包含所有必填字段的配置文件。

**Q：支持 Ubuntu 24.04 吗？**
A：支持。HarborPilot 自动处理 Ubuntu 24.04 的 DEB822 apt 格式、UID 1000 已被占用、pip 外部管理环境限制等问题。

**Q：能在没有 Harbor Registry 的情况下用吗？**
A：可以。在平台配置里设置 `HAVE_HARBOR_SERVER=FALSE`，镜像就保留在本地。

**Q：Dockerfile 适合 AI 读吗？**
A：`.env` 配置文件就是意图层 — AI agent 可以直接读、修改，然后调用 `./harbor` 构建。`docs/zh/1-for-ai/` 目录里有完整的代码库地图和专为 AI agent 写的工作规则。

---

## 废弃说明

| 组件 | 状态 |
|---|---|
| Windows 宿主机 | ❌ **已移除** — 仅支持 Ubuntu 宿主机 |

---

## 许可证

[MIT](LICENSE) © 2024 PotterWhite
