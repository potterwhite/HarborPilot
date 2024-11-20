#!/bin/bash
set -e

# Backup original sources.list
cp /etc/apt/sources.list /etc/apt/sources.list.backup

# Configure apt to use aliyun mirror for Ubuntu 22.04 (jammy)
cat > /etc/apt/sources.list << EOF
deb http://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
EOF

# Update system with retry mechanism
for i in {1..3}; do
    if apt-get update; then
        break
    fi
    echo "Retry $i: Update failed, retrying in 5 seconds..."
    sleep 5
done

# Install essential packages first
apt-get install -y --no-install-recommends \
    build-essential \
    git \
    vim \
    wget \
    curl \
    python3 \
    python3-pip \
    cmake \
    ninja-build \
    gdb \
    file \
    locales \
    tzdata \
    sudo \
    openssh-client

# Install development tools
apt-get install -y --no-install-recommends \
    libncurses5-dev \
    flex \
    bison \
    gperf \
    device-tree-compiler \
    libssl-dev \
    u-boot-tools

# Install SDK from mounted volume
SDK_DIR="${SDK_INSTALL_DIR}"
SDK_PKG="${CONTAINER_VOLUME_ROOT}/sdk/${SDK_PKG_NAME}"

echo "Installing SDK to ${SDK_DIR}..."
if [ -f "${SDK_PKG}" ]; then
    mkdir -p ${SDK_DIR}
    if tar xf ${SDK_PKG} -C ${SDK_DIR}; then
        echo "SDK installation completed"
    else
        echo "Error: Failed to extract SDK"
        exit 1
    fi
else
    echo "Error: SDK package not found at ${SDK_PKG}"
    exit 1
fi

# Clean APT cache
apt-get clean
rm -rf /var/lib/apt/lists/*

# Set timezone
ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime