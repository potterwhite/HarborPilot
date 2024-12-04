# 项目移交文件包（Host系统为Windows情况适用） (Project Handover Package)

## 概述 (Overview)
本文件包包含项目移交的基本信息和使用指南。所有核心文件都已存储在服务器上，本文件包作为快速入门指南。

## 1.0 文件结构 (File Structure)
```
project_handover/
├── ReadMe.md          # 本使用指南
└── windows_only_entrance.ps1 # 仅windows系统使用的入口脚本
└── .env 配置文件，包含docker image和container的重要环境变量，供参考
```

## 2.0 访问服务器资源 (Server Access)
- 2.1 服务器地址 (Server Address): 公司内部机房
- 2.2 访问方式 (Access Method): `192.168.3.178`

## 3.0 快速开始 (Quick Start)

### 3.1 下载docker镜像
- 3.1.1 [Host下]联络管理员获得为您预备的docker internal hub的帐号密码（以下载docker镜像）
- 3.1.2 [Host下]下载并安装docker desktop
    (docker desktop下载)[https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe?utm_source=docker&utm_medium=webreferral&utm_campaign=dd-smartbutton&utm_location=module]

    安装全部完成后，请重启您的电脑
- 3.1.3 [Host下]重启后，转移默认wsl2的虚拟硬盘文件
    ```bash
    wsl -l -v
    wsl --shutdown
    wsl --export docker-desktop-data D:\ProgramFiles\Cache\wsl\docker-desktop-data.tar
     wsl --unregister docker-desktop-data
    wsl --import docker-desktop-data D:\ProgramFiles\Cache\wsl\data\ D:\ProgramFiles\Cache\wsl\docker-desktop-data.tar --version 2
    ```

- 3.1.4  [Host下]创建&进入您的容器Container
    双击windows_only_entrance.bat脚本

### 3.2 clone sdk

- 3.2.1 [Host下]联络管理员获得sdk 在内部服务器上的具有对git仓库访问权限的帐号和密码
- 3.2.2 [Host下]您需要使用步骤3.2.1得到的账户和密码登陆内部gitlab服务器（参步骤2.2），上传您的ssh key（gitlab已完全禁止密码方式操作git仓库）
- 3.2.3 [`Container下`]拉取sdk的代码
    ```bash
    pull_sdk.sh
    ```
- 3.2.4 [Host下]您可以将Qt的项目代码放在该目录下的volumes文件夹里，这个文件夹在容器中被挂载为/development/docker_volumes
- 3.2.5 [Host下]打开Qt Creator，编写代码
- 3.2.6 [`Container下`]用默认的`qmake`来生成Makefile,并`make`编译代码，获得二进制文件
- 3.2.7 [Host下]之后您就可以开始您的开发了

## 4.0 注意事项 (Important Notes)
- 请不要在docker内做太多改动，因为docker image升级后将覆盖您所作的操作。更推荐的做法是将您的需求提交管理员，管理员进行docker image的更新后，发布新版本开发环境。

## 5.0 技术支持 (Technical Support)
- 邮箱 (Email): `[baytoo_e_corp@hotmail.com]`

## 版本信息 (Version Information)
- 版本号 (Version): `[v0.5.4]`
- 最后更新 (Last Updated): `[2024-12-04]`

