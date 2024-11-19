#!/bin/bash
set -e

# Backup original sources.list
cp /etc/apt/sources.list /etc/apt/sources.list.backup

# Configure apt to use aliyun mirror
cat > /etc/apt/sources.list << EOF
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF

# Verify sources.list was written correctly
if [ ! -s /etc/apt/sources.list ]; then
    echo "Error: Failed to write sources.list"
    mv /etc/apt/sources.list.backup /etc/apt/sources.list
    exit 1
fi

# Update system with retry mechanism
for i in {1..3}; do
    if apt-get update && apt-get upgrade -y; then
        break
    fi
    echo "Retry $i: Update failed, retrying in 5 seconds..."
    sleep 5
done

# Install X11 and GUI dependencies
apt-get install -y \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libxrandr2 \
    libxcursor1 \
    libxss1 \
    libasound2 \
    libgtk2.0-0 \
    libgtk-3-0

# Install development tools
apt-get install -y \
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
    openssh-client \
    libncurses5-dev \
    flex \
    bison \
    gperf \
    device-tree-compiler \
    libssl-dev \
    u-boot-tools \
    code

# # Install ARM cross-compilation toolchain
# apt-get install -y \
#     gcc-arm-none-eabi \
#     gcc-aarch64-linux-gnu \
#     g++-aarch64-linux-gnu

# Clean APT cache
apt-get clean
rm -rf /var/lib/apt/lists/*

# Set timezone
ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime