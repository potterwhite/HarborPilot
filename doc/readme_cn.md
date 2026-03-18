# HarborPilot

<div align="center">

![版本](https://img.shields.io/badge/版本-1.5.0-blue?style=flat-square)
![许可证](https://img.shields.io/badge/许可证-MIT-green?style=flat-square)
![平台](https://img.shields.io/badge/宿主机-Ubuntu-orange?style=flat-square)
![Docker](https://img.shields.io/badge/Docker-必须-2496ED?style=flat-square&logo=docker&logoColor=white)
![Shell](https://img.shields.io/badge/shell-bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![目标](https://img.shields.io/badge/目标-嵌入式Linux-lightgrey?style=flat-square)

**一条命令搞定嵌入式 Linux Docker 开发环境 — 多平台、可复现、对接 Harbor 私有镜像仓库。**

[快速上手](quick_start.md) · [English](../README.md) · [更新日志](../CHANGELOG.md)

</div>

---

## 这是什么？

HarborPilot 是一套完全脚本化的工具链，用于为嵌入式 Linux 目标平台构建、管理和分发**容器化交叉编译开发环境**。

与其让每个开发者手动安装工具链、配置系统并祈祷一致性，HarborPilot 让你：

1. **一条命令构建** — `./harbor` 即可完成镜像构建 → 打 tag → 推送到 Harbor
2. **自动推送** — 构建完成后自动推送到私有 Harbor registry，带 manifest 校验
3. **秒级启动** — 任意 Ubuntu 宿主机上运行 `ubuntu_only_entrance.sh start`，容器即刻就绪

主要目标平台为 Rockchip 系列 SoC（RK3588s、RK3568、RV1126、RV1126bp），但三层配置系统使添加新平台变得非常简单。

---

## 核心特性

| 特性 | 说明 |
|---|---|
| **一命令构建** | `./harbor` — 选平台，构建，打 tag，推送，完成 |
| **多平台支持** | RK3588s、RK3568（20.04 / 22.04）、RV1126、RV1126bp |
| **三层配置** | `defaults/` → `common.env` → `platform.env`，新增全局开关只改一处 |
| **Harbor 对接** | 构建后自动推送 + manifest 验证 |
| **预检查** | 构建前检测 registry 登录状态，未登录则提示，避免构建完才报错 |
| **NVIDIA GPU 支持** | 按平台可选，rk3588s 默认开启 |
| **SSH + GDB 端口** | 每个平台配置唯一的 SSH 和 GDB 端口，互不冲突 |
| **Samba 支持** | 可选的宿主机 ↔ 容器文件共享（CIFS） |

---

## 架构概览

```
HarborPilot/
│
├── harbor                          ← 入口脚本：构建 + 打 tag + 推送
│
├── configs/
│   ├── defaults/                   ← Layer 1：全局默认值（所有平台继承）
│   │   ├── base.env                   基础：OS 版本、用户、时区
│   │   ├── tools.env                  工具安装开关 & 版本号
│   │   ├── workspace.env              工作区路径 & 行为
│   │   ├── registry.env               Registry 地址
│   │   ├── runtime.env                SSH/GDB/syslog 开关
│   │   ├── proxy.env                  代理配置
│   │   └── ...
│   ├── platform-independent/
│   │   └── common.env              ← Layer 2：项目版本、维护者信息
│   └── platforms/
│       ├── rk3588s.env             ← Layer 3：平台特有覆盖（只写差异部分）
│       ├── rk3568.env
│       ├── rk3568-ubuntu22.env
│       ├── rv1126.env
│       ├── rv1126bp.env
│       └── offline.env             ← 新平台模板
│
├── docker/
│   ├── dev-env-clientside/         ← 五阶段 Dockerfile
│   │   ├── build.sh
│   │   └── Dockerfile
│   ├── dev-env-serverside/         ← ⚠ 已废弃
│   └── libs/                       ← 可复用的 Dockerfile 片段和脚本
│
└── project_handover/
    ├── clientside/ubuntu/
    │   ├── ubuntu_only_entrance.sh ← 容器生命周期管理（start/stop/recreate…）
    │   └── harbor.crt              ← Harbor CA 证书（每台宿主机安装一次）
    └── serverside/                 ← ⚠ 已废弃
```

### 三层配置加载顺序

```
Layer 1  configs/defaults/*.env              全局默认值，所有平台继承
   ↓
Layer 2  configs/platform-independent/common.env   项目版本与常量
   ↓
Layer 3  configs/platforms/<platform>.env          平台特有覆盖
```

后加载的层覆盖先加载的。平台文件里只需写**与默认值不同的内容**。
新增一个全局开关？只改 `configs/defaults/tools.env`，所有平台自动继承。

---

## 支持的平台

| 平台 | Ubuntu 版本 | SSH 端口 | GDB 端口 | 备注 |
|---|---|---|---|---|
| `rk3588s` | 22.04 | 2109 | 2345 | 默认启用 NVIDIA GPU |
| `rv1126bp` | 22.04 | 2119 | 2355 | |
| `rk3568` | 20.04 | 2129 | 2365 | |
| `rv1126` | 22.04 | 2139 | 2375 | |
| `rk3568-ubuntu22` | 22.04 | 2149 | 2385 | |
| `offline` | 22.04 | — | — | 新平台模板 |

---

## 快速上手

→ **[完整快速上手指南](quick_start.md)**

```bash
# 1. 安装 Docker，信任 Harbor CA 证书（每台宿主机执行一次）
#    详见 quick_start.md 步骤 1–2

# 2. 登录 Harbor registry
docker login <registry-ip>:<registry-port>

# 3. 构建 — 交互式选择目标平台
./harbor

# 4. 启动容器
./project_handover/clientside/ubuntu/ubuntu_only_entrance.sh start
```

---

## 废弃说明

| 组件 | 状态 |
|---|---|
| `project_handover/serverside/` | ⚠️ **已废弃** — distcc 分布式编译 serverside 不再维护。脚本保留供参考，不会再更新。 |
| Windows 宿主机支持 | ❌ **已移除** — 仅支持 Ubuntu 宿主机。 |

---

## 许可证

[MIT](../LICENSE) © 2024 PotterWhite
