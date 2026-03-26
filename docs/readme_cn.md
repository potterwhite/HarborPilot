<div align="center">
  <h1>HarborPilot</h1>
  <p><i>一条命令搞定嵌入式 Linux Docker 开发环境 — 多平台、可复现、对接 Harbor 私有镜像仓库</i></p>
</div>

<p align="center">
  <img src="https://github.com/potterwhite/HarborPilot/blob/a997a343a5e883e48cf6771df55a7efbcf3d9933/doc/assets/light-background.png" alt="HarborPilot Banner" width="100%"/>
</p>

<p align="center">
  <a href="https://github.com/potterwhite/HarborPilot/releases">
    <!-- <img src="https://img.shields.io/badge/版本-1.5.0-blue?style=flat-square" alt="version"/> -->
    <img src="https://img.shields.io/github/v/release/potterwhite/HarborPilot?color=blue&label=version">
  </a>
  <img src="https://img.shields.io/badge/许可证-MIT-green?style=flat-square" alt="License"/>
  <img src="https://img.shields.io/badge/宿主机-Ubuntu-orange?style=flat-square" alt="Host Platform"/>
  <img src="https://img.shields.io/badge/Docker-必须-2496ED?style=flat-square&logo=docker&logoColor=white" alt="Docker"/>
  <img src="https://img.shields.io/badge/shell-bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white" alt="Shell"/>
  <img src="https://img.shields.io/badge/目标-Rockchip%20SoC-lightgrey?style=flat-square" alt="Target"/>
</p>

<p align="center">
  <a href="../README.md">English</a> | <strong>简体中文</strong>
</p>

---

## HarborPilot 是什么？

HarborPilot 是一套完全脚本化的工具链，用于为嵌入式 Linux 目标平台**构建、管理和分发容器化交叉编译开发环境**。

它解决的核心问题是：不再让每个开发者手动安装工具链、配置系统、再靠「应该差不多」来保证一致性。HarborPilot 提供：

- **一条命令构建** — `./harbor` 选择平台、构建多阶段 Docker 镜像、打 tag、推送到私有 Harbor Registry
- **一条命令启动** — `ubuntu_only_entrance.sh start` 在任意 Ubuntu 宿主机上秒级拉起完整配置的开发容器
- **分层配置系统** — 修改一处全局默认值，所有平台自动继承；新增一个平台不超过 20 行配置

主要目标平台为 Rockchip 系列 SoC（RK3588s、RK3568、RV1126、RV1126bp），但架构本身与平台无关。

---

## 核心特性

| 特性 | 说明 |
|---|---|
| **一命令构建** | `./harbor` — 选平台 → 构建 → 打 tag → 推送 |
| **多平台支持** | RK3588s · RK3568（Ubuntu 20.04 / 22.04）· RV1126 · RV1126bp |
| **三层配置** | `defaults/` → `common.env` → `platform.env` · [查看详情 →](config_layers_cn.md) |
| **Registry 预检查** | 构建前自动检测 `docker login` 状态，未登录则提示，杜绝 30 分钟构建后才报推送错误 |
| **Harbor 对接** | 构建后自动推送 + manifest 校验 |
| **NVIDIA GPU 支持** | 按平台可选；rk3588s 默认开启 |
| **SSH + GDB 端口** | 每个平台分配唯一端口，互不冲突 |
| **Samba 支持** | 可选的宿主机 ↔ 容器文件共享（CIFS） |

---

## 仓库结构

```
HarborPilot/
│
├── harbor                            ← 入口脚本：构建 → 打 tag → 推送
│
├── configs/
│   ├── defaults/                     ← Layer 1 · 11 个按领域划分的默认配置文件
│   │   ├── 01_base.env               OS、用户、时区
│   │   ├── 02_build.env              Docker BuildKit 开关
│   │   ├── 03_tools.env              开发工具开关 & 版本号
│   │   ├── 04_workspace.env          工作区路径 & 行为
│   │   ├── 05_registry.env           Harbor / GitLab 服务器地址
│   │   ├── 06_sdk.env                SDK 安装开关
│   │   ├── 07_volumes.env            Volume 根路径
│   │   ├── 08_samba.env              Samba 账号密码
│   │   ├── 09_runtime.env            SSH / GDB / syslog 开关
│   │   └── 11_proxy.env              代理（默认关闭）
│   ├── platform-independent/
│   │   └── common.env                ← Layer 2 · 项目版本与常量
│   └── platforms/
│       ├── rk3588s.env               ← Layer 3 · 平台特有覆盖
│       ├── rk3568.env
│       ├── rk3568-ubuntu22.env
│       ├── rv1126.env
│       └── rv1126bp.env
│
├── docker/
│   ├── dev-env-clientside/           五阶段 Dockerfile
│   │   ├── Dockerfile
│   │   └── build.sh
│   └── libs/                         可复用 Dockerfile 片段和脚本
│
├── project_handover/
│   ├── clientside/ubuntu/
│   │   ├── ubuntu_only_entrance.sh   容器生命周期管理脚本
│   │   └── harbor.crt                Harbor CA 证书（每台宿主机安装一次）
│
└── docs/
    ├── architecture/                 AI 文档系统
    │   ├── 00_INDEX.md               导航中心
    │   ├── 1-for-ai/                 AI Agent 参考文件
    │   ├── 2-progress/               进度追踪
    │   └── 3-highlights/             架构决策与分析
    ├── quick_start.md                快速上手指南（英文）
    ├── quick_start_cn.md             快速上手指南（中文）
    ├── config_layers.md              三层配置系统详解（英文）
    └── config_layers_cn.md           三层配置系统详解（中文）
```

> **三层配置系统详解 →** [docs/config_layers_cn.md](config_layers_cn.md)

---

## 支持的平台

| 平台 | Ubuntu 版本 | SSH 端口 | GDB 端口 | 备注 |
|---|---|---|---|---|
| `rk3588s` | 24.04 | 2109 | 2345 | 默认启用 NVIDIA GPU |
| `rv1126bp` | 22.04 | 2119 | 2355 | |
| `rk3568` | 20.04 | 2129 | 2365 | |
| `rv1126` | 22.04 | 2139 | 2375 | |
| `rk3568-ubuntu22` | 22.04 | 2149 | 2385 | |
| `rk3588s-ubuntu-24` | 24.04 | 2159 | 2395 | 无 NVIDIA GPU |

---

## 快速上手

→ **完整指南：[docs/quick_start_cn.md](quick_start_cn.md)**

```bash
# 1. 安装 Docker，信任 Harbor CA 证书（每台宿主机执行一次）
#    → 详见 docs/quick_start_cn.md

# 2. 登录 Harbor Registry
docker login <registry-ip>:<registry-port>

# 3. 构建 — 交互式选择目标平台
./harbor

# 4. 启动开发容器
./project_handover/clientside/ubuntu/ubuntu_only_entrance.sh start
```

---

## 废弃说明

| 组件 | 状态 |
|---|---|
| Windows 宿主机 | ❌ **已移除** — 仅支持 Ubuntu 宿主机 |

---

## 许可证

[MIT](../LICENSE) © 2024 PotterWhite
