#!/bin/bash

# harbor_setup.sh

gen_environment_variables() {
    # 设置 Harbor 目录
    HARBOR_PATH="/development/hdd1_4tb/harbor/harbor"
    HARBOR_VERSION="v2.8.3"
    HARBOR_INSTALLER="harbor-offline-installer-${HARBOR_VERSION}.tgz"
    HARBOR_DOWNLOAD_URL="https://github.com/goharbor/harbor/releases/download/${HARBOR_VERSION}/${HARBOR_INSTALLER}"

    # 颜色定义
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
}

# 打印消息函数
print_msg() {
    echo -e "${2:-$GREEN}$1${NC}"
}

check_prerequisites() {
    # 检查是否为 root
    if [ "$EUID" -ne 0 ]; then
        print_msg "Please run as root" "${RED}"
        exit 1
    fi

    # 检查 Docker 是否安装
    if ! command -v docker &> /dev/null; then
        print_msg "Docker not found. Installing Docker..." "${YELLOW}"
        curl -fsSL https://get.docker.com | sh
    fi

    # 检查 docker compose 是否安装
    if ! command -v docker-compose &> /dev/null; then
        print_msg "Docker Compose not found. Installing Docker Compose..." "${YELLOW}"
        apt-get update && apt-get install -y docker-compose-plugin
    fi
}

# download_harbor() {
#     # 创建目录
#     mkdir -p "$(dirname ${HARBOR_PATH})"
#     cd "$(dirname ${HARBOR_PATH})"

#     # 下载 Harbor
#     if [ ! -f "${HARBOR_INSTALLER}" ]; then
#         print_msg "Downloading Harbor..."
#         wget -c ${HARBOR_DOWNLOAD_URL}
#     fi

#     # 解压 Harbor
#     if [ ! -d "${HARBOR_PATH}" ]; then
#         print_msg "Extracting Harbor..."
#         tar xzvf ${HARBOR_INSTALLER}
#     fi
# }

# configure_harbor() {
#     cd "${HARBOR_PATH}"

#     # 如果配置文件不存在，从模板创建
#     if [ ! -f "harbor.yml" ]; then
#         cp harbor.yml.tmpl harbor.yml

#         # 修改配置
#         sed -i "s/hostname: reg.mydomain.com/hostname: 192.168.3.67/" harbor.yml
#         sed -i "s/port: 80/port: 9000/" harbor.yml
#         sed -i "s/harbor_admin_password: Harbor12345/harbor_admin_password: Harbor12345/" harbor.yml
#     fi

#     # 运行安装脚本
#     ./install.sh
# }

setup_systemd() {
    # 创建系统服务文件
    cat > /etc/systemd/system/harbor.service << EOF
[Unit]
Description=Harbor Container Registry
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${HARBOR_PATH}
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载 systemd
    systemctl daemon-reload

    # 启用服务
    systemctl enable harbor.service

    # 启动服务
    systemctl start harbor.service
}

check_status() {
    # 等待服务启动
    print_msg "Waiting for Harbor to start..."
    sleep 20

    # 检查状态
    if docker ps | grep -q "goharbor/nginx-photon"; then
        print_msg "Harbor started successfully!"
        print_msg "You can access Harbor at: http://192.168.3.67:9000"
        print_msg "Username: admin"
        print_msg "Password: Harbor12345"
    else
        print_msg "Harbor may have failed to start. Please check logs." "${RED}"
        print_msg "Use 'docker compose logs' to view logs." "${YELLOW}"
        exit 1
    fi
}

main() {
    gen_environment_variables
    check_prerequisites
    download_harbor
    configure_harbor
    setup_systemd
    check_status
}

main "$@"