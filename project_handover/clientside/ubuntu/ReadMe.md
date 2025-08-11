# 项目移交文件包 (Project Handover Package)

## 概述 (Overview)
本文件包包含项目移交的基本信息和使用指南。所有核心文件都已存储在服务器上，本文件包作为快速入门指南。

## 1.0 文件结构 (File Structure)
```
project_handover/
├── ReadMe.md          # 本使用指南
└── ubuntu_only_entrance.sh # 仅ubuntu系统使用的入口脚本
└── .env 配置文件，包含docker image和container的重要环境变量
```

## 2.0 快速开始 (Quick Start)
### 2.1 安装docker
```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 2.2 调整仓库配置
#### 2.2.1 允许http协议的docker镜像仓库(本条废弃,请使用2.2.2)
```bash
sudo mkdir -p /etc/docker
sudo vim /etc/docker/daemon.json
```
在文件中添加以下内容（替换server-ip为实际IP）
```bash
{
  "insecure-registries": ["192.168.3.67:9000"]
}
```

#### 2.2.2 复制https证书
```bash
sudo mkdir -p /etc/docker/certs.d/192.168.3.67:9000
sudo cp ./harbor.crt /etc/docker/certs.d/192.168.3.67:9000/ca.crt
sudo systemctl restart docker
```

### 2.3 下载docker镜像
- 2.3.1 [Host下]联络管理员获得为您预备的Harbor系统的帐号密码（以下载docker镜像）

- 2.3.2 [Host下]
    ```bash
    docker login 192.168.3.67:9000
    ```
    登陆期间会提示输入账户，请输入2.3.1得到的帐号和密码

- 2.3.3 [Host下]创建&进入您的容器Container
    ```bash
    ./ubuntu_only_entrance.sh
    ```

## 2.4 配置ssh
```bash
vim ~/.ssh/config
```

添加到文件末尾
```bash
Host container_n8
        Hostname 127.0.0.1
        Port 2109
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null
        User developer
```

### 2.5 上传您的ssh key到您的gitlab帐号

- 2.5.1 [Host下]联络管理员获得sdk 在内部服务器上的具有对git仓库访问权限的帐号和密码
- 2.5.2 [Host下]您需要使用步骤2.2.1得到的账户和密码登陆内部gitlab服务器（参步骤2.2），上传您的ssh key（gitlab已完全禁止密码方式操作git仓库）
```bash
    http://192.168.3.67
```

### 2.6 拉取sdk的代码
#### a-使用git管理的代码库
```bash
pull_sdk.sh
```

#### b-使用repo(python)管理的代码库

**复制下面这段代码到container中执行:**
```bash
sudo bash -c "
#------------------------------------------------------------------------------
# --- CONFIGURATION ---
# All user-configurable variables are defined here for easy modification.
#------------------------------------------------------------------------------

# 1. The manifest URL for your project's source code.
REPO_MANIFEST_URL='ssh://git@192.168.3.67/team_rk3568/rk356x-manifests.git'

# 2. The download URL for the 'repo' tool itself. Using a mirror is recommended.
REPO_TOOL_URL='https://mirrors.tuna.tsinghua.edu.cn/git/git-repo'

# 3. The local directory path where the SDK will be downloaded.
SDK_ROOT_PATH='/development/sdk'

# 4. The non-root user who will own the files and run repo commands.
TARGET_USER='developer'

# 5. The number of parallel jobs for 'repo sync'.
SYNC_JOBS=4

#------------------------------------------------------------------------------
# --- EXECUTION LOGIC ---
# Do not modify below this line unless you know what you are doing.
#------------------------------------------------------------------------------

  SCRIPT_PATH=\"/tmp/setup_sdk.sh\"

  tee \"\${SCRIPT_PATH}\" <<'EOF'
#!/bin/bash
set -e

# These variables are passed in as arguments from the parent script.
ARG_REPO_MANIFEST_URL=\"\$1\"
ARG_REPO_TOOL_URL=\"\$2\"
ARG_SDK_ROOT_PATH=\"\$3\"
ARG_TARGET_USER=\"\$4\"
ARG_SYNC_JOBS=\"\$5\"

echo '--- (1/3) Running as root: Installing repo tool ---'
REPO_PATH=\"/usr/local/bin/repo\"
if [ ! -e \${REPO_PATH} ];then
  echo \"Downloading repo tool from \${ARG_REPO_TOOL_URL}...\"
  curl -L \"\${ARG_REPO_TOOL_URL}\" > \${REPO_PATH}
else
  echo \"\${REPO_PATH} already exists.\"
fi
chmod a+x \${REPO_PATH}
echo \"Repo tool is ready at \${REPO_PATH}\"
echo

echo '--- (2/3) Creating SDK directory and setting ownership ---'
mkdir -p \"\${ARG_SDK_ROOT_PATH}\"
chown \"\${ARG_TARGET_USER}:\${ARG_TARGET_USER}\" \"\${ARG_SDK_ROOT_PATH}\" -R
echo \"Directory \${ARG_SDK_ROOT_PATH} is ready for user \${ARG_TARGET_USER}.\"
echo

echo '--- (3/3) Switching to user developer to run repo commands... ---'
sudo -u \"\${ARG_TARGET_USER}\" bash -c \"
  set -e

  echo 'Verifying user git and ssh config...'
  verify_git_config.sh
  verify_ssh_key.sh

  cd \\\"\${ARG_SDK_ROOT_PATH}\\\"

  if [ -d .repo ]; then
    echo 'Directory .repo already exists. Skipping repo init/sync.'
  else
    echo 'Running repo init...'
    # --- HERE IS THE FIX: Added --depth=1 to reduce server load ---
    repo init --depth=1 -u \\\"\${ARG_REPO_MANIFEST_URL}\\\" --repo-url \\\"\${ARG_REPO_TOOL_URL}\\\" --no-repo-verify

    echo \\\"Running repo sync with \${ARG_SYNC_JOBS} jobs...\\\"
    repo sync -j\${ARG_SYNC_JOBS}
  fi
\"
echo
echo '--- SDK setup process completed successfully! ---'

EOF

  chmod +x \"\${SCRIPT_PATH}\"

  echo
  echo \"--- Executing the setup script now... ---\"
  echo \"-------------------------------------------\"

  # Execute the script, passing the configuration variables as arguments.
  \"\${SCRIPT_PATH}\" \"\${REPO_MANIFEST_URL}\" \"\${REPO_TOOL_URL}\" \"\${SDK_ROOT_PATH}\" \"\${TARGET_USER}\" \"\${SYNC_JOBS}\"

  echo \"-------------------------------------------\"
  echo \"--- Script execution finished. Cleaning up... ---\"

  rm \"\${SCRIPT_PATH}\"

  echo \"--- Cleanup complete. Done. ---\"
"
```

**具体使用哪一种方式,请咨询管理员或sdk开发者**


## 3.0 开发方式(Development Method)
### 3.1 建议开发方式
- 透过ssh连接，直接将container内部的代码挂载到host上进行编辑
```bash
mkdir -p ${HOME}/volumes/n8
sshfs container_n8:/development ${HOME}/volumes/n8
cd ${HOME}/volumes/n8
nautilus . &
```

### 3.2 第二种开发方式
- 3.2.1 [Host下]您可以将Qt的项目代码放在该目录下的volumes文件夹里，这个文件夹在容器中被挂载为/development/docker_volumes
- 3.2.2 [Host下]打开Qt Creator，编写代码
- 3.2.3 [`Container下`]用默认的`qmake`来生成Makefile,并`make`编译代码，获得二进制文件
- 3.2.4 [Host下]之后您就可以开始您的开发了

## 4.0 若干信息备注
- 4.1 服务器地址 (Server Address):
    - 公司内部机房
- 4.2 访问方式 (Access Method):
    - `192.168.3.67`

- 4.3 注意事项 (Important Notes)
    - 请不要在docker内做太多改动，因为docker image升级后将覆盖您所作的操作。更推荐的做法是将您的需求提交管理员，管理员进行docker image的更新后，发布新版本开发环境。

- 4.4 技术支持 (Technical Support)
    - 邮箱 (Email): `[baytoo_e_corp@hotmail.com]`

- 4.5 版本信息 (Version Information)
    - 版本号 (Version): `[v0.7.0]`
    - 最后更新 (Last Released): `[2025-02-24]`

