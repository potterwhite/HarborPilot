# 开发环境使用指南

## 🚀 快速开始（首次部署）

## 前置条件

- Docker 已安装并运行
- 能访问 Harbor 镜像仓库（网络可达）

## 启动

```bash
./entrance.sh start
```

首次运行会自动引导创建配置，**一路 Enter 用默认值即可**。

## 📚 进阶内容（首次部署不需要查看）

## 附录A：常用命令

```bash
./entrance.sh start      # 启动
./entrance.sh stop       # 停止
./entrance.sh restart    # 重启
./entrance.sh recreate   # 重建（配置改了用这个）
./entrance.sh remove     # 删除容器
```

## 附录B：修改配置

配置文件位于 `clientside/ubuntu/configs/3_hosts/<主机名>.env`：

```bash
nano clientside/ubuntu/configs/3_hosts/$(hostname).env
```

改完后运行 `recreate` 生效。

## 附录C：目录结构

```
project_handover_*/
├── README_handover.md                 # 本文件
├── entrance.sh            # 入口脚本（symlink）
└── clientside/
    └── ubuntu/
        ├── entrance.sh    # 实际入口
        ├── scripts/                   # 管理脚本
        ├── configs/
        │   ├── 1_defaults/            # 默认配置（勿改）
        │   ├── 2_platforms/           # 平台配置（勿改）
        │   └── 3_hosts/               # 你的配置在这里
        └── volume/                    # 容器工作目录（自动创建）
```

## 附录D：自定义 Volume 路径

默认情况下，容器数据存储在 `clientside/ubuntu/volume/`，首次启动自动创建，**无需任何配置**。

如果需要使用其他路径（如大容量磁盘），首次运行时输入自定义路径即可，脚本会自动创建 symlink。
