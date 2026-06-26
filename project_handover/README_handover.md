# 开发环境使用指南

## 前置条件

- Docker 已安装并运行
- 能访问 Harbor 镜像仓库（网络可达）

## 快速开始

```bash
# 1. 解压
tar xzf project_handover_*.tar.gz
cd project_handover

# 2. 启动（首次运行会自动引导配置）
./clientside/ubuntu/ubuntu_only_entrance.sh start
```

首次运行时，脚本会自动创建主机配置文件。按 **Enter** 使用默认值，或输入自定义值。

## 常用命令

| 命令 | 说明 |
|------|------|
| `start` | 创建并启动容器 |
| `stop` | 停止容器 |
| `restart` | 重启容器 |
| `recreate` | 删除并重建容器 |
| `remove` | 停止并删除容器 |

```bash
./clientside/ubuntu/ubuntu_only_entrance.sh <命令>
```

## 修改配置

主机配置文件位于 `configs/3_hosts/<你的主机名>.env`，可直接编辑：

```bash
nano configs/3_hosts/$(hostname).env
```

修改后运行 `recreate` 使配置生效。

## 目录结构

```
project_handover/
├── clientside/ubuntu/       # 容器管理脚本
├── configs/
│   ├── 1_defaults/          # 默认配置（勿改）
│   ├── 2_platforms/         # 平台配置（勿改）
│   └── 3_hosts/             # 主机配置（你的配置在这里）
├── scripts/                 # 共享脚本
└── README_handover.md       # 本文件
```
