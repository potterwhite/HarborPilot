# 快速上手指南

> **Related:** [English Version →](../../en/4-for-beginner/quick_start.md)

本指南带你从零开始，在一台全新的 Ubuntu 宿主机上完成 HarborPilot 的配置，直到开发容器成功运行。

> **平台支持说明**
> - ✅ **Ubuntu 宿主机** — 完整支持
> - ❌ **Windows 宿主机** — 已放弃支持

---

## 前置条件

| 要求 | 说明 |
|---|---|
| Ubuntu 20.04 / 22.04 宿主机 | 其他 Debian 系发行版可能也可以工作 |
| 网络或局域网连通 | 用于拉取 Docker 基础镜像 |
| Harbor Registry 访问权限 | 向管理员申请账号密码 |
| Harbor CA 证书 | 仓库内已包含：`project_handover/clientside/ubuntu/harbor.crt` |

---

## Step 1 — 安装 Docker

```bash
# 添加 Docker 官方 GPG key
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 添加 Docker apt 源
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# 将当前用户加入 docker 组（避免每条命令都需要 sudo）
sudo usermod -aG docker "$USER"
newgrp docker
```

---

## Step 2 — 信任 Harbor Registry 证书

Harbor 使用自签名 TLS 证书。Docker 必须信任它，否则所有 `docker pull` / `docker push` 操作都会报证书错误。

```bash
# 将 <registry-ip> 和 <registry-port> 替换为你平台 .env 文件中的
# HARBOR_SERVER_IP 和 HARBOR_SERVER_PORT 的值
REGISTRY_HOST="<registry-ip>:<registry-port>"

sudo mkdir -p "/etc/docker/certs.d/${REGISTRY_HOST}"
sudo cp ./project_handover/clientside/ubuntu/harbor.crt \
        "/etc/docker/certs.d/${REGISTRY_HOST}/ca.crt"

sudo systemctl restart docker
```

> **示例**（rk3588s 平台）：
> ```bash
> sudo mkdir -p /etc/docker/certs.d/192.168.0.19:8443
> sudo cp ./project_handover/clientside/ubuntu/harbor.crt \
>         /etc/docker/certs.d/192.168.0.19:8443/ca.crt
> sudo systemctl restart docker
> ```

---

## Step 3 — 登录 Harbor Registry

```bash
docker login <registry-ip>:<registry-port>
# 示例：
docker login 192.168.0.19:8443
```

输入管理员提供的账号和密码。Docker 会缓存凭证，每台宿主机只需执行一次。

> **提示：** `./harbor` 脚本在检测到未登录时会主动提示你执行此命令，不会在构建完 30 分钟后才报推送错误。

---

## Step 4 — 克隆仓库

```bash
git clone <repo-url>
cd HarborPilot
```

---

## Step 5 — 构建 Docker 镜像

从仓库根目录运行 `harbor` 脚本。它会：

1. 让你选择目标平台（如 `rk3588s`、`rk3568` …）
2. 自动建立配置 symlink
3. 构建多阶段 Docker 镜像
4. 打 tag 并推送到 Harbor Registry

```bash
./harbor
```

在运行过程中，脚本会自动检测是否已登录 Registry，如未登录会提示你先登录再继续。

> **操作提示：** 每个交互提示都支持按 `n` 跳过（可选步骤），或等待 10 秒倒计时自动执行默认操作（继续）。

---

## Step 6 — 启动开发容器

构建完成后，脚本会打印 **Next Steps** 操作提示，按提示操作：

```bash
./project_handover/clientside/ubuntu/ubuntu_only_entrance.sh start
```

支持的命令：

| 命令 | 效果 |
|---|---|
| `start` | 创建并启动容器（本地镜像不存在时自动从 Registry 拉取） |
| `stop` | 停止运行中的容器 |
| `restart` | 重启容器 |
| `recreate` | 删除并以当前配置重建容器 |
| `remove` | 停止并删除容器（镜像保留） |

---

## Step 7 — （可选）配置 SSH 访问

在宿主机的 `~/.ssh/config` 里添加一条配置，方便在宿主机或 IDE 中直接连接容器：

```
Host container_<PRODUCT_NAME>
    Hostname 127.0.0.1
    Port <CLIENT_SSH_PORT>
    User developer
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

将 `<PRODUCT_NAME>` 和 `<CLIENT_SSH_PORT>` 替换为你平台 `.env` 文件中的对应值。以 `rk3588s` 为例：

```
Host container_rk3588s
    Hostname 127.0.0.1
    Port 2109
    User developer
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

连接方式：

```bash
ssh container_rk3588s
```

---

## Step 8 — （可选）在容器内拉取 SDK

根据你的 SDK 仓库管理方式，选择对应方法：

### 方法 A — Git（单仓库）

```bash
# 在容器内执行
pull_sdk.sh
```

### 方法 B — Repo（Android manifest 风格）

向管理员或 SDK 开发者确认 manifest URL，然后参考 `project_handover/clientside/ubuntu/` 目录下的相关文档执行。

---

## 平台端口速查表

| 平台 | OS | CLIENT_SSH_PORT | GDB_PORT |
|---|---|---|---|
| rk3588s | Ubuntu 24.04 | 2109 | 2345 |
| rv1126bp | Ubuntu 22.04 | 2119 | 2355 |
| rk3568 | Ubuntu 20.04 | 2129 | 2365 |
| rv1126 | Ubuntu 22.04 | 2139 | 2375 |
| rk3568-ubuntu22 | Ubuntu 22.04 | 2149 | 2385 |
| rk3588s-ubuntu-24 | Ubuntu 24.04 | 2159 | 2395 |

---

## 常见问题排查

### 拉取镜像时报 `pull access denied`

你未登录或凭证已过期。

```bash
docker login <registry-ip>:<registry-port>
```

### 报 `SSL certificate problem: self-signed certificate`

Harbor CA 证书尚未为 Docker 安装。重新执行 [Step 2](#step-2--信任-harbor-registry-证书)。

### 容器 `start` 后立即退出

检查平台 `.env` 文件中 `HOST_VOLUME_DIR` 指向的目录是否在宿主机上实际存在。

### `HAVE_HARBOR_SERVER` 为空 / 推送步骤意外跳过

确保通过 `./harbor` 入口脚本运行（它会按顺序加载三层配置），而不是直接 source 平台 `.env` 文件。

> 详见：[三层配置系统详解](config_layers_cn.md)
