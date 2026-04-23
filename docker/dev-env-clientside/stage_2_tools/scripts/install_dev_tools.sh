#!/bin/bash
################################################################################
# File: docker/stage_2_tools/scripts/install_dev_tools.sh
#
# Description: Main script for installing development tools
#              Installs compilers, debuggers, and development utilities
#
# Author: PotterWhite
# Created: 2024-11-21
# Last Modified: 2025-07-14
#
# Copyright (c) 2024
# License: MIT
################################################################################
set -e

###############################################################################
# First: Install core build tools and compilers
# Description: Essential compilation and build system tools installation
###############################################################################
first_install_core_tools() {
    apt-get update && apt-get install -y \
        build-essential \
        ninja-build \
        make \
        autoconf \
        automake \
        libtool \
        meson \
        pkg-config \
        ccache \
        tree

    if [ "${INSTALL_HOST_CMAKE}" = "true" ]; then
        apt-get install -y \
            cmake
    fi
}

###############################################################################
# Second: Install development and debug tools
# Description: Tools for debugging, code analysis and development
###############################################################################
second_install_dev_tools() {
    apt-get install -y \
        gdb \
        valgrind \
        clang \
        clang-format \
        clang-tidy \
        lldb \
        cppcheck \
        minicom

    if [[ "${PRODUCT_NAME}" == "rv1126bp" ]]; then
        # required by rv1126bp platform-kernel 6.1
        apt-get install -y \
            libmpc-dev \
            libgmp-dev
    fi

    echo "OS_VERSION = ${OS_VERSION}"
    if [ "${OS_VERSION}" != "20.04" ]; then
        apt-get install -y repo 
    else
        # -----------------------------------------
        # add libicu for rk3568 build process of the sdk
        # date: nov27.2025
        # author: James
        # -----------------------------------------
        apt-get install -y libicu-dev
    fi
    echo "install repo"
}

###############################################################################
# Third: Configure minicom settings
# Description: Setup minicom configurations for different serial devices
###############################################################################
third_config_minicom() {
    # Create minicom config directory
    mkdir -p /etc/minicom

    # Default configuration (ttyUSB0)
    tee /etc/minicom/minirc.dfl > /dev/null << 'EOF'
        # Machine-generated file - use "minicom -s" to change parameters.
        pu port             /dev/ttyUSB0
        pu baudrate         115200
        pu bits             8
        pu parity           N
        pu stopbits         1
        pu rtscts           No
        pu histlines        5000
        # pu timestamp        Yes
        # # Add color scheme
        # pu color_bg0        BLACK
        # pu color_fg0        GREEN
        # pu color_bg1        BLACK
        # pu color_fg1        YELLOW
        # pu color_bg2        BLACK
        # pu color_fg2        WHITE
EOF
    # Remove leading spaces from the config file
    sed -i 's/^[[:space:]]*//' /etc/minicom/minirc.dfl

    # USB serial configuration
    tee /etc/minicom/minirc.usb > /dev/null << 'EOF'
        # Configuration for USB serial devices
        pu port             /dev/ttyUSB0
        pu baudrate         115200
        pu bits             8
        pu parity           N
        pu stopbits         1
        pu rtscts           No
        pu histlines        5000
        # pu timestamp        Yes
        # Add color scheme
        # pu color_bg0        BLACK
        # pu color_fg0        CYAN
        # pu color_bg1        BLACK
        # pu color_fg1        YELLOW
        # pu color_bg2        BLACK
        # pu color_fg2        WHITE
EOF
    sed -i 's/^[[:space:]]*//' /etc/minicom/minirc.usb

    # ACM serial configuration
    tee /etc/minicom/minirc.acm > /dev/null << 'EOF'
        # Configuration for ACM serial devices
        pu port             /dev/ttyACM0
        pu baudrate         115200
        pu bits             8
        pu parity           N
        pu stopbits         1
        pu rtscts           No
        pu histlines        5000
        # pu timestamp        Yes
        # # Add color scheme
        # pu color_bg0        BLACK
        # pu color_fg0        MAGENTA
        # pu color_bg1        BLACK
        # pu color_fg1        YELLOW
        # pu color_bg2        BLACK
        # pu color_fg2        WHITE
EOF
    sed -i 's/^[[:space:]]*//' /etc/minicom/minirc.acm

    # Set proper permissions
    chmod 644 /etc/minicom/minirc.*

    # Add usage information to motd
    tee -a /etc/motd > /dev/null << 'EOF'

        Minicom Serial Configurations Available:
        ---------------------------------------
        minicom         -> Default configuration (ttyUSB0)
        minicom usb     -> USB serial device configuration
        minicom acm     -> ACM serial device configuration

        All configurations use 115200 8N1 without flow control
EOF
    sed -i 's/^[[:space:]]*//' /etc/motd
}

###############################################################################
# Fourth: Install documentation tools
# Description: Documentation and visualization tools installation
###############################################################################
fourth_install_doc_tools() {
    echo "Installing documentation tools..."
    # Install documentation generation tools
    apt-get install -y \
        doxygen \
        graphviz

    if [ "${INSTALL_MAN_DOC}" = "true" ]; then
        echo -e "\tInstalling man documentation system..."
        # Install man documentation system
        apt-get install -y \
            man-db \
            manpages \
            manpages-dev \
            manpages-posix \
            manpages-posix-dev \
            gcc-doc \
            cpp-doc \
            glibc-doc \
            python3-doc \
            bash-doc
        # Rebuild man database
        mandb

        # Add man page search path configuration if not exists
        if ! grep -q "MANPATH_MAP /usr/local/bin" /etc/manpath.config; then
            echo 'MANPATH_MAP /usr/local/bin /usr/local/man' >> /etc/manpath.config
            echo 'MANPATH_MAP /usr/bin /usr/share/man' >> /etc/manpath.config
        fi
        echo -e "\tMan documentation system installed successfully"
    fi

    # required by rv1126bp - i18n
    apt-get install -y gettext

    echo "Documentation tools installation completed"
}

###############################################################################
# Fifth: Install version control and utilities
# Description: Version control and development utilities installation
###############################################################################
fifth_install_vcs_tools() {
    apt-get install -y \
        git \
        git-lfs \
        bash-completion

    # Configure git completion for both root and dev user
    for user_home in "/root" "/home/${DEV_USERNAME}"; do
        tee -a "${user_home}/.bashrc" > /dev/null << EOF
# Enable git completion
source /usr/share/bash-completion/completions/git

# Enable bash completion
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
EOF
    done
}

###############################################################################
# Sixth: Install kernel development tools
# Description: Tools required for kernel development
###############################################################################
sixth_install_kernel_tools() {
    apt-get install -y \
        device-tree-compiler \
        liblz4-tool \
        liblz4-dev \
        libssl-dev \
        expect \
        bison \
        flex \
        texinfo \
        exuberant-ctags \
        cscope

    # libncurses5-dev was renamed to libncurses-dev in Ubuntu 22.04+
    local os_major
    os_major=$(echo "${OS_VERSION}" | cut -d'.' -f1)
    if [ "${os_major}" -ge 22 ]; then
        apt-get install -y libncurses-dev
    else
        apt-get install -y libncurses5-dev
    fi
}

###############################################################################
# Seventh: Install Node.js development environment
# Description: Setup Node.js using nvm or direct install based on region
###############################################################################

seventh_install_nodejs() {
    # Choose installation method based on NPM_USE_CHINA_MIRROR
    if [ "${NPM_USE_CHINA_MIRROR}" = "true" ]; then
        echo "Using China mirror for Node.js installation..."
        seventh_install_nodejs_china
    else
        echo "Using overseas mirror for Node.js installation..."
        seventh_install_nodejs_overseas
    fi
}

# Overseas installation method (original)
seventh_install_nodejs_overseas() {
    echo "Installing nvm and Node.js from original source..."
    # Install nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # Add nvm to current shell session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install and use Node.js LTS version
    if ! nvm install --lts || ! nvm use --lts; then
        echo "Failed to setup Node.js"
        return 1
    fi

    # Add nvm setup to user profile
    cat >> /home/$DEV_USERNAME/.bashrc << EOF
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF

    return 0
}

# China mirror installation method
# _with_CVE_2024_29415
seventh_install_nodejs_china() {

    echo "Installing Node.js using China mirrors..."

    # Install Node.js directly from China mirror
    # curl -fsSL https://npmmirror.com/mirrors/node/v18.18.2/node-v18.18.2-linux-x64.tar.gz -o /tmp/node.tar.gz
    curl -fsSL https://registry.npmmirror.com/-/binary/node/v22.16.0/node-v22.16.0-linux-x64.tar.gz -o /tmp/node.tar.gz

    # Create installation directory
    mkdir -p /usr/local/lib/nodejs

    # Extract and install
    tar -xzf /tmp/node.tar.gz -C /usr/local/lib/nodejs

    # Get versioned directory name
    NODE_VERSION=$(ls /usr/local/lib/nodejs | grep "node-v")

    # Create environment variable config
    cat > /etc/profile.d/nodejs.sh << EOF
export PATH=/usr/local/lib/nodejs/${NODE_VERSION}/bin:\$PATH
EOF

    # Also add to system PATH via symlinks
    ln -sf /usr/local/lib/nodejs/${NODE_VERSION}/bin/node /usr/local/bin/
    ln -sf /usr/local/lib/nodejs/${NODE_VERSION}/bin/npm /usr/local/bin/
    ln -sf /usr/local/lib/nodejs/${NODE_VERSION}/bin/npx /usr/local/bin/

    # Configure npm to use China mirror
    npm config set registry https://registry.npmmirror.com

    # Verify installation
    if ! node -v; then
        echo "Failed to setup Node.js"
        return 1
    fi

    # Add to user profile
    cat >> /home/$DEV_USERNAME/.bashrc << EOF
# Node.js configuration
export PATH=/usr/local/lib/nodejs/${NODE_VERSION}/bin:\$PATH
# NPM China mirror configuration
npm config set registry https://registry.npmmirror.com
EOF

    # Cleanup
    rm -f /tmp/node.tar.gz

    return 0
}

###############################################################################
# Eighth: Install Python packages
# Description: Install specific versions of Python packages
###############################################################################
eighth_install_python_packages() {
    # -------------------------------------------------------------------------
    # Python 2.7: removed from Ubuntu 22.04+ official repositories.
    # Only install on Ubuntu 20.04 where it is still available.
    # -------------------------------------------------------------------------
    local os_major
    os_major=$(echo "${OS_VERSION}" | cut -d'.' -f1)

    if [ "${os_major}" -le 20 ]; then
        echo "Ubuntu <= 20.04: installing python2.7..."
        apt-get update && apt-get install -y \
            python2.7 \
            python2.7-dev \
            libpython2.7 \
            libpython2.7-dev

        # Setup Python symlinks
        ln -sf /usr/bin/python2.7 /usr/bin/python
        ln -sf /usr/bin/python2.7 /usr/bin/python2
    else
        echo "Ubuntu >= 22.04: python2.7 not available, skipping python2 installation"
    fi

    #----------------------------------------------
    # Python 3.x Installation
    python3 --version
    apt-get update && apt-get install -y python3-pip python3-dev
    pip3 --version

    # Install Python package manager
    local max_retries=3

    # --break-system-packages was introduced in pip 23; Ubuntu 20.04 ships pip 20
    # which does not recognise the flag. Detect the major version at runtime.
    local _pip_major
    _pip_major=$(pip3 --version 2>/dev/null | grep -oP '(?<=pip )\d+' || echo "0")
    local _pip_break_flag=""
    if [ "${_pip_major}" -ge 23 ] 2>/dev/null; then
        _pip_break_flag="--break-system-packages"
    fi

    install_package() {
        local package=$1
        local version=$2
        local retry=0

        while [ $retry -lt $max_retries ]; do
            # shellcheck disable=SC2086
            if pip3 install --no-cache-dir \
               ${_pip_break_flag} \
               -i https://mirrors.aliyun.com/pypi/simple/ \
               --trusted-host mirrors.aliyun.com \
               --timeout 30 \
               "${package}==${version}"; then
                return 0
            fi
            echo "Retry installing ${package} (${retry}/${max_retries})"
            retry=$((retry + 1))
            sleep 5
        done
        echo "Warning: Failed to install ${package}, continuing anyway..."
        return 0
    }

    [ -n "${CMAKE_FORMAT_VERSION}" ] && install_package "cmake-format" "${CMAKE_FORMAT_VERSION}"
    [ -n "${PRE_COMMIT_VERSION}" ] && install_package "pre-commit" "${PRE_COMMIT_VERSION}"
}

###############################################################################
# Tenth: Cleanup
# Description: Clean up package manager cache
###############################################################################
nintyninth_cleanup() {
    apt-get clean && rm -rf /var/lib/apt/lists/*
}


###############################################################################
# Main function
# Description: Execute all installation steps in order
###############################################################################
main() {
    first_install_core_tools
    second_install_dev_tools
    third_config_minicom
    fourth_install_doc_tools
    fifth_install_vcs_tools
    sixth_install_kernel_tools

    if ! seventh_install_nodejs; then
        echo "Critical: Node.js environment setup failed. Exiting..."
        exit 1
    fi

    eighth_install_python_packages

    #------------------------------
    nintyninth_cleanup
}

# Execute main function
main
