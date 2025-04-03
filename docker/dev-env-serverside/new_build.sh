#!/bin/bash

#####################################################################################
# 1st group
#####################################################################################
func_1_1_setup_environment() {
    echo "Setting up environment..."

    set -ex

    BUILD_SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
    cd ${BUILD_SCRIPT_DIR}

    echo "BUILD_SCRIPT_DIR=${BUILD_SCRIPT_DIR}"
    echo "current_dir=$(pwd -P)"

    # read -r ${OHNO}
    # Load .env file
    set -a
    source "${BUILD_SCRIPT_DIR}/../../project_handover/.env"
    set +a

    # # ROOT_DIR="$(cd "${BUILD_SCRIPT_DIR}/../../" && pwd)"
    # TEMP_TOOLCHAIN_SRC_GCC="${BUILD_SCRIPT_DIR}/../dev-env-clientside/stage_2_tools/offline_packages/gcc/${TOOLCHAIN_TARBALL_NAME}"
    # TEMP_TOOLCHAIN_SRC_INSTALL_GCC="${BUILD_SCRIPT_DIR}/../dev-env-clientside/stage_2_tools/offline_packages/gcc/install_gcc.sh"
    # TEMP_TOOLCHAIN_SRC_CONFIG_PATH="${BUILD_SCRIPT_DIR}/../dev-env-clientside/stage_2_tools/configs/tool_versions.conf"
    HTTP_REPO_URL="http://192.168.3.67/team_n8/n8_toolchain.git"
    SSH_REPO_URL="git@192.168.3.67:team_n8/n8_toolchain.git"

    GIT_REPO="${SSH_REPO_URL}"

    TEMP_TOOLCHAIN_TARBALLS_DIR="TeMp_toolchains"
    TEMP_TOOLCHAIN_TARGET_DIR="/usr/local/toolchains"
    # TEMP_TOOLCHAIN_TARGET_GCC="${TEMP_TOOLCHAIN_TARBALLS_DIR}/${TOOLCHAIN_TARBALL_NAME}"
    # TEMP_TOOLCHAIN_TARGET_INSTALL_GCC="${TEMP_TOOLCHAIN_TARBALLS_DIR}/install_gcc.sh"
    # TEMP_TOOLCHAIN_TARGET_CONFIG_PATH="${TEMP_TOOLCHAIN_TARBALLS_DIR}/tool_versions.conf"

    TEMP_ENTRYPOINT_SCRIPT_DIR="TeMp_configs"
    TEMP_ENTRYPOINT_SCRIPT_FILE="entrypoint.sh"
    TEMP_START_DISTCCD_SCRIPT_FILE="start_distccd.sh"
    TEMP_DOCKERFILE_NAME="DockerfileOfServerSide"
    TEMP_PULL_TOOLCHAIN_SCRIPT_FILE="pull_toolchain.sh"
    TEMP_VERIFY_SSH_KEY_SCRIPT_FILE="verify_ssh_key.sh"

    TEMP_VERSION_SCRIPT_DIR="TeMp_version"
    TEMP_VERSION_SCRIPT_FILE="version_of_dev_env.sh"
}

func_1_2_utils_read_module() {
    cat "${BUILD_SCRIPT_DIR}/../libs/dockerfile_modules/$1.df" | envsubst
}

func_1_3_cleanup(){
    rm -rf ${BUILD_SCRIPT_DIR}/${TEMP_TOOLCHAIN_TARBALLS_DIR}
    rm -rf ${BUILD_SCRIPT_DIR}/${TEMP_ENTRYPOINT_SCRIPT_DIR}
    rm -rf ${BUILD_SCRIPT_DIR}/${TEMP_VERSION_SCRIPT_DIR}
    rm -f ${BUILD_SCRIPT_DIR}/${TEMP_DOCKERFILE_NAME}
    echo "Done func_1_3_cleanup()"
}

#####################################################################################
#
#####################################################################################
func_2_1_toolchains_preparation() {
    mkdir -p ${TEMP_TOOLCHAIN_TARBALLS_DIR}

    cd ${TEMP_TOOLCHAIN_TARBALLS_DIR}
    # rm -rf *
    # git clone ${GIT_REPO}
    cd -

    ls -lha ${TEMP_TOOLCHAIN_TARBALLS_DIR}

    echo
}

func_2_2_file_entrypoint_preparation() {
    # 首先设置日志相关的环境变量
    local log_dir="/development/docker_volumes/log/distccd"
    local log_level="${DISTCC_LOG_LEVEL:-debug}"

    mkdir -p ${TEMP_ENTRYPOINT_SCRIPT_DIR}
    touch ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_ENTRYPOINT_SCRIPT_FILE}

    cat > ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_ENTRYPOINT_SCRIPT_FILE} << EOF
#!/bin/bash

#-------------------------------------------------
# 1st. enable exit on error
set -e

echo -e "\nStarting entrypoint.sh..."

#-------------------------------------------------
# 2nd. set PATH
current_path=\$(cat /etc/environment | grep "^PATH=" | cut -d'=' -f2- | tr -d '"')
export PATH=\${current_path}
echo "PATH=\${PATH}"
echo "current_path=\${current_path}"

#-------------------------------------------------
# 3rd. start distccd
# /usr/local/bin/${TEMP_START_DISTCCD_SCRIPT_FILE} &

#-------------------------------------------------
# 4th. start ssh server
if [ "${ENABLE_SSH}" == "true" ]; then
    service ssh start
fi

echo -e "The end of entrypoint.sh\n"
tail -f /dev/null

EOF
    chmod +x ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_ENTRYPOINT_SCRIPT_FILE}
}

func_2_3_file_start_distccd_preparation(){
    ####################################################################
    # start distccd script
    ####################################################################
    touch ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_START_DISTCCD_SCRIPT_FILE}
    cat > ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_START_DISTCCD_SCRIPT_FILE} << DELIM
#!/bin/bash

#-------------------------------------------------
# 1st. enable exit on error
set -e

#-------------------------------------------------
# 2nd. add debug output
echo -e "\nStarting distcc server..."
echo "PATH=\${PATH}"

#-------------------------------------------------
# 3rd. create log directory
if ! mkdir -p /development/docker_volumes/log/distccd; then
    echo "ERROR: Failed to create log directory"
    exit 1
fi

#-------------------------------------------------
# 4th. get cpu info and verify
AVAILABLE_CORES=\$(nproc)
if [ -z "\${AVAILABLE_CORES}" ] || [ "\${AVAILABLE_CORES}" -eq 0 ]; then
    echo "ERROR: Failed to get CPU cores, using default value 1"
    AVAILABLE_CORES=1
fi
echo "Available cores: \${AVAILABLE_CORES}"

# #-------------------------------------------------
# # 5th. calculate jobs and verify
# DISTCC_JOBS=\$(( \${AVAILABLE_CORES} * 8/10 ))
# if [ "\${DISTCC_JOBS}" -lt 1 ]; then
#     echo "WARNING: Calculated jobs too low, using default value 1"
#     DISTCC_JOBS=1
# fi
# echo "Setting jobs to: \${DISTCC_JOBS}"

#-------------------------------------------------
# 6th. start service
# --daemon: running in background
# --no-detach: do not detach from the terminal
# --no-avahi: do not use avahi
# --allow: allow connections from the specified IP address
# --jobs: set the number of jobs
# --log-stderr: log to stderr
# --log-level: set the log level
# --log-file: set the log file
# --stats: enable stats
# --stats-port: set the stats port
# --enable-tcp-insecure: enable tcp insecure
# --verbose: enable verbose
# --nice: set the priority of the process;
#          nice is from -20 to 19,
#          lower number means higher priority.
#          so 10 means lower priority.

distccd \
        --daemon \
        --no-detach \
        --allow 0.0.0.0/0 \
        --listen 0.0.0.0 \
        --port ${DISTCC_GCC_11_MAIN_PORT} \
        --jobs \${AVAILABLE_CORES} \
        --log-stderr \
        --log-level debug \
        --log-file /development/docker_volumes/log/distccd/distcc-gcc-11.log \
        --stats \
        --stats-port ${DISTCC_GCC_11_STATS_PORT} \
        --enable-tcp-insecure \
        --verbose \
        --nice 10 &

distccd \
        --daemon \
        --no-detach \
        --allow 0.0.0.0/0 \
        --listen 0.0.0.0 \
        --port ${DISTCC_GCC_10_MAIN_PORT} \
        --jobs \${AVAILABLE_CORES} \
        --log-stderr \
        --log-level debug \
        --log-file /development/docker_volumes/log/distccd/distcc-gcc-10.log \
        --stats \
        --stats-port ${DISTCC_GCC_10_STATS_PORT} \
        --enable-tcp-insecure \
        --verbose \
        --nice 10 &

# distccd \
#         --daemon \
#         --no-detach \
#         --allow 192.168.0.0/16 \
#         --port ${DISTCC_GCC_11_MAIN_PORT} \
#         --jobs \${AVAILABLE_CORES} \
#         --log-stderr \
#         --log-level debug \
#         --log-file /development/docker_volumes/log/distccd/distcc-gcc-11.log \
#         --stats \
#         --stats-port ${DISTCC_GCC_11_STATS_PORT} \
#         --enable-tcp-insecure \
#         --verbose \
#         --nice 10 &

# distccd \
#         --daemon \
#         --no-detach \
#         --allow 192.168.0.0/16 \
#         --port ${DISTCC_GCC_10_MAIN_PORT} \
#         --jobs \${AVAILABLE_CORES} \
#         --log-stderr \
#         --log-level debug \
#         --log-file /development/docker_volumes/log/distccd/distcc-gcc-10.log \
#         --stats \
#         --stats-port ${DISTCC_GCC_10_STATS_PORT} \
#         --enable-tcp-insecure \
#         --verbose \
#         --nice 10 &
DELIM

    chmod +x ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_START_DISTCCD_SCRIPT_FILE}
    cat ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_START_DISTCCD_SCRIPT_FILE}
}

func_2_4_file_version_script_preparation() {
    mkdir -p ${TEMP_VERSION_SCRIPT_DIR}
    touch ${TEMP_VERSION_SCRIPT_DIR}/${TEMP_VERSION_SCRIPT_FILE}

    cat > ${TEMP_VERSION_SCRIPT_DIR}/${TEMP_VERSION_SCRIPT_FILE} << EOF
#!/bin/bash

# This script is auto-generated during docker build
# DO NOT EDIT MANUALLY

PROJECT_VERSION="${PROJECT_VERSION}"
PROJECT_RELEASE_DATE="${PROJECT_RELEASE_DATE}"

echo "Current Version of Distcc Server Environment is: \${PROJECT_VERSION}"
echo "Current Release Date of Distcc Server Environment is: \${PROJECT_RELEASE_DATE}"
EOF
    chmod +x ${TEMP_VERSION_SCRIPT_DIR}/${TEMP_VERSION_SCRIPT_FILE}
}

func_2_5_file_dockerfile_preparation() {

    cat > "${BUILD_SCRIPT_DIR}/${TEMP_DOCKERFILE_NAME}" << DELIM
FROM ubuntu:22.04

########################
# apt source
########################
$(func_1_2_utils_read_module apt_source)

########################
# base packages
########################
$(func_1_2_utils_read_module base_packages)

########################
# network packages
########################
$(func_1_2_utils_read_module network_packages)

########################
# distcc
########################
RUN apt-get update && apt-get install -y \
    distcc \
    && rm -rf /var/lib/apt/lists/*

########################
# distccd user
########################
# RUN groupadd -r distccd && \
#     useradd -r -g distccd -d /home/distccd -s /usr/sbin/nologin -c "distcc daemon" distccd && \

RUN mkdir -p /home/distccd && \
    chown distccd: /home/distccd

#####################################################
# Set root password
#####################################################
RUN echo "root:${DEV_USER_ROOT_PASSWORD}" | chpasswd

#####################################################
#  Copy git cloned toolchains unto ${TEMP_TOOLCHAIN_TARGET_DIR}
#####################################################
RUN mkdir -p ${TEMP_TOOLCHAIN_TARGET_DIR} && \
    cd ${TEMP_TOOLCHAIN_TARGET_DIR} && \
    git config --global init.defaultBranch main && \
    git config --global --add safe.directory ${TEMP_TOOLCHAIN_TARGET_DIR} && \
    git init && \
    git remote add origin ${GIT_REPO}

####################################################################
#  Handle PATH problem(where distccd could find all chains)
####################################################################
# ENV toolchain_11_3="${TEMP_TOOLCHAIN_TARGET_DIR}/format_bins/arm-gnu-toolchain-11.3.rel1-x86_64-aarch64-none-linux-gnu"
# ENV toolchain_10_3="${TEMP_TOOLCHAIN_TARGET_DIR}/format_bins/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu"
# ENV original_path=$(cat /etc/environment | grep "^PATH=" | cut -d'=' -f2- | tr -d '"')
RUN echo "original_path=${original_path}" && \
    echo "toolchain_11_3=${toolchain_11_3}" && \
    echo "toolchain_10_3=${toolchain_10_3}" && \
    echo "before:" && \
    cat /etc/environment && \
    echo "PATH=${TEMP_TOOLCHAIN_TARGET_DIR}/format_bins/arm-gnu-toolchain-11.3.rel1-x86_64-aarch64-none-linux-gnu/bin:${TEMP_TOOLCHAIN_TARGET_DIR}/format_bins/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin:$(cat /etc/environment | grep "^PATH=" | cut -d'=' -f2- | tr -d '"')" > /etc/environment && \
    echo "after:" && \
    cat /etc/environment && \
    chmod 644 /etc/environment

####################################################################
# Auto load envs from /etc/environment every time when bash start
####################################################################
RUN echo "source /etc/environment" >> /etc/bash.bashrc && \
    chmod 644 /etc/bash.bashrc

# COPY ${TEMP_TOOLCHAIN_TARGET_GCC} /tmp/offline_packages/gcc/
# COPY ${TEMP_TOOLCHAIN_TARGET_INSTALL_GCC} /tmp/offline_packages/gcc/
# COPY ${TEMP_TOOLCHAIN_TARGET_CONFIG_PATH} /tmp

# RUN ls -lha /tmp/  && \
#     ls -lha /tmp/offline_packages/ && \
#     ls -lha /tmp/offline_packages/gcc/ && \
#     chmod +x /tmp/offline_packages/gcc/install_gcc.sh && \
#     /tmp/offline_packages/gcc/install_gcc.sh && \
#     echo "source /etc/environment" >> /etc/bash.bashrc && \
#     chmod 644 /etc/environment

#############################################
#  entrypoint init
#############################################
COPY ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_ENTRYPOINT_SCRIPT_FILE} /usr/local/bin/${TEMP_ENTRYPOINT_SCRIPT_FILE}
COPY ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_START_DISTCCD_SCRIPT_FILE} /usr/local/bin/${TEMP_START_DISTCCD_SCRIPT_FILE}
COPY ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_PULL_TOOLCHAIN_SCRIPT_FILE} /usr/local/bin/${TEMP_PULL_TOOLCHAIN_SCRIPT_FILE}
COPY ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_VERIFY_SSH_KEY_SCRIPT_FILE} /usr/local/bin/${TEMP_VERIFY_SSH_KEY_SCRIPT_FILE}

#############################################
#  version script init
#############################################
COPY ${TEMP_VERSION_SCRIPT_DIR}/${TEMP_VERSION_SCRIPT_FILE} /usr/local/bin/${TEMP_VERSION_SCRIPT_FILE}

ENTRYPOINT ["/usr/local/bin/${TEMP_ENTRYPOINT_SCRIPT_FILE}"]

DELIM
}

func_2_6_pull_toolchains_prepration(){
    cat > ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_PULL_TOOLCHAIN_SCRIPT_FILE} << DELIM
#!/bin/bash
################################################################################
# Script Name: ${TEMP_PULL_TOOLCHAIN_SCRIPT_FILE}
# Description: Pull Toolchains from git repository with safety checks
# Author: @MrJamesLZAZ
# Date: 2025-02-14
# Usage: ${TEMP_PULL_TOOLCHAIN_SCRIPT_FILE} [-h|--help] [branch_name]
# Note: This script is generated from template with environment variables
################################################################################

set -e
trap 'echo "Error occurred. Exiting..."; exit 1' ERR
REPO_INSTALL_PATH="${TEMP_TOOLCHAIN_TARGET_DIR}"
GIT_REPO="${GIT_REPO}"

################################################################################
# Print help message
################################################################################
print_help() {
    cat << EOF
Usage: \$(basename "\$0") [-h|--help] [branch_name]

Pull changes from remote git repository.

Arguments:
    branch_name     Target branch name to pull (default: all remote branches)

Options:
    -h, --help     Show this help message

Examples:
    \$(basename "\$0")                     # Pull main remote branches defaultly
    \$(basename "\$0") develop             # Pull only develop branch(if exists)
    \$(basename "\$0") all                 # Pull all remote branches
EOF
    # \$(basename "\$0") feature/xyz         # Pull only feature branch

    exit 0
}

################################################################################
# Main function to orchestrate the Repo pulling process
################################################################################
main() {
    # Parse command line arguments
    local branch=""  # empty means pull all branches

    if [ "\$#" -gt 1 ]; then
        # a. if we have more than 1 argument, then it's an error
        echo "Error: Too many arguments"
        return 1
    elif [ "\$#" -eq 1 ]; then
        # b.if we have 1 argument, then it's a branch name
        # Check for help flag
        if [[ "\$1" == "-h" ]] || [[ "\$1" == "--help" ]]; then
            print_help
        fi

        # Parse branch name if provided
        if [[ ! "\$1" =~ ^- ]]; then
            branch="\$1"
        else
            echo "Error: Invalid branch name format, should not start with '-'"
            return 1
        fi
    elif [ "\$#" -eq 0 ]; then
        # c. if we have no argument, then it's a default pull main branch
        branch="main"
    else
        # d. if we have invalid arguments, then it's an error
        echo "Error: Invalid arguments number: \$#"
        return 1
    fi

    echo "=== Starting ToolChains Pull Process ==="
    [ -n "\$branch" ] && echo "Target branch: \$branch" || echo "Target: All remote branches"

    1_check_git_user || exit 1
    2_verify_ssh_access || exit 1
    3_validate_repository || exit 1
    4_pull_changes "\$branch" || exit 1

    echo "=== ToolChains Pull Process Completed Successfully ==="
}

################################################################################
# 1. Check and configure Git user information if needed
################################################################################
1_check_git_user() {
    echo "Checking Git user configuration..."

    # Check global git config first
    local git_name=\$(git config --global user.name)
    local git_email=\$(git config --global user.email)

    # If still not set, prompt user for input
    if [ -z "\$git_name" ]; then
        echo "Git user name is not configured."
        read -p "Please enter your name: " input_name
        if [ -z "\$input_name" ]; then
            echo "Error: Name cannot be empty"
            return 1
        fi
        git config --global user.name "\$input_name"
        echo "Git user name set to: \$input_name"
    fi

    if [ -z "\$git_email" ]; then
        echo "Git user email is not configured."
        read -p "Please enter your email: " input_email
        if [ -z "\$input_email" ] || ! echo "\$input_email" | grep -qE '^[^@]+@[^@]+\.[^@]+\$'; then
            echo "Error: Invalid email format"
            return 1
        fi
        git config --global user.email "\$input_email"
        echo "Git user email set to: \$input_email"
    fi

    return 0
}

################################################################################
# 2. Verify SSH access using verify_ssh_key.sh
################################################################################
2_verify_ssh_access() {
    echo "Verifying SSH access..."
    if ! /usr/local/bin/verify_ssh_key.sh; then
        echo "Error: SSH key verification failed"
        return 1
    fi
    return 0
}

################################################################################
# 3. Validate repository exists and has correct remote
################################################################################
3_validate_repository() {
    cd "${TEMP_TOOLCHAIN_TARGET_DIR}"

    # For fresh repository (only .git exists), remove and clone again
    if [ -d ".git" ] && [ \$(ls -A | grep -v '^.git\$' | wc -l) -eq 0 ]; then
        echo "Fresh repository detected, performing clean clone..."
        cd ..
        rm -rf "\${REPO_INSTALL_PATH}"
        git clone "\${GIT_REPO}" "\${REPO_INSTALL_PATH}" || return 1
        cd "\${REPO_INSTALL_PATH}"
        return 0
    fi

    # Normal validation for existing repository
    if [ ! -d ".git" ]; then
        echo "Error: Not a git repository. Please initialize first"
        return 1
    fi

    local current_remote=\$(git remote get-url origin 2>/dev/null || echo "")
    if [ "\$current_remote" != "\${GIT_REPO}" ]; then
        echo "Error: Repository remote URL mismatch"
        echo "Current: \$current_remote"
        echo "Expected: \${GIT_REPO}"
        return 1
    fi

    return 0
}

################################################################################
# 4. Pull latest changes from remote repository
################################################################################
4_pull_changes() {
    local target_branch="\$1"
    echo "Fetching remote information..."
    git fetch origin || return 1

    if [ "\$target_branch" = "all" ]; then
        # Pull all remote branches
        _pull_all_branches
        return \$?
    else
        # Pull specific branch
        _pull_single_branch "\$target_branch"
        return \$?
    fi
}

################################################################################
# Helper function to pull a single branch
################################################################################
_pull_single_branch() {
    local branch="\$1"
    echo "Pulling branch: \$branch"

    # Check if working directory is clean
    if git rev-parse --verify HEAD >/dev/null 2>&1; then
        if ! git diff --quiet HEAD 2>/dev/null; then
            echo "Error: Working directory is not clean"
            return 1
        fi
    fi

    # Check if branch exists remotely
    if ! git ls-remote --heads origin "\$branch" | grep -q "\$branch"; then
        echo "Error: Branch '\$branch' doesn't exist in remote repository"
        return 1
    fi

    # Checkout and pull
    if git rev-parse --verify "origin/\$branch" >/dev/null 2>&1; then
        git checkout -B "\$branch" "origin/\$branch"
    else
        echo "Error: Remote branch not found"
        return 1
    fi

    git pull --recurse-submodules origin "\$branch" || return 1
    return 0
}

################################################################################
# Helper function to pull all remote branches
################################################################################
_pull_all_branches() {
    echo "Pulling all remote branches..."
    local error_occurred=false

    # Get list of remote branches
    local remote_branches=\$(git ls-remote --heads origin | grep -oP "refs/heads/\K.*")

    # Pull each branch
    for branch in \$remote_branches; do
        echo -e "\nProcessing branch: \$branch"
        if ! _pull_single_branch "\$branch"; then
            echo "Warning: Failed to pull branch '\$branch'"
            error_occurred=true
            continue
        fi
    done

    # Always return to main branch if it exists
    if echo "\$remote_branches" | grep -q "^main\$"; then
        echo -e "\nReturning to main branch"
        git checkout main
    fi

    [ "\$error_occurred" = true ] && return 1
    return 0
}

# Execute main function with all arguments
main "\$@"
DELIM

chmod +x ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_PULL_TOOLCHAIN_SCRIPT_FILE}
}

func_2_7_verify_sshkey_script_preparation() {
    cat > ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_VERIFY_SSH_KEY_SCRIPT_FILE} << DELIM
#!/bin/bash
################################################################################
# Script Name: ${TEMP_VERIFY_SSH_KEY_SCRIPT_FILE}
# Description: Verify and initialize SSH keys for repository access
# Author: @MrJamesLZAZ
# Date: 2025-02-14
# Usage: source ${TEMP_VERIFY_SSH_KEY_SCRIPT_FILE}
# Returns: 0 on success, 1 on failure
################################################################################

################################################################################
# Constants
################################################################################
SSH_KEY_NAME="\${DEFAULT_SSH_KEY_NAME:-SSHKEY_Default_ED25519}"
SSH_DIR="\$HOME/.ssh"
SSH_KEY_PATH="\$SSH_DIR/\$SSH_KEY_NAME"
SSH_CONFIG="\$SSH_DIR/config"
GIT_REPO=${GIT_REPO}

################################################################################
# Main function to orchestrate SSH key verification process
################################################################################
main() {
    echo "=== Starting SSH Key Verification ==="

    1_verify_ssh_directory || exit 1
    2_check_and_initialize_key || exit 1
    3_update_ssh_config || exit 1
    4_test_connection || exit 1

    echo "=== SSH Key Verification Completed Successfully ==="
}

################################################################################
# 1. Verify SSH directory exists with correct permissions
# Returns:
#   0 on success, 1 on failure
################################################################################
1_verify_ssh_directory() {
    echo "Verifying SSH directory..."
    mkdir -p "\$SSH_DIR"
    chmod 700 "\$SSH_DIR"
    return 0
}

################################################################################
# 2. Check if SSH key exists and is valid, initialize if needed
# Returns:
#   0 on success, 1 on failure
################################################################################
2_check_and_initialize_key() {
    echo "Checking SSH key..."

    # Check if key files exist
    if [ ! -f "\${SSH_KEY_PATH}" ] || [ ! -f "\${SSH_KEY_PATH}.pub" ]; then
        echo "SSH key not found. Initializing new key..."
        _initialize_new_key
        return \$?
    fi

    # Verify permissions
    if [ "\$(stat -c %a \${SSH_KEY_PATH})" != "600" ]; then
        echo "Fixing private key permissions..."
        chmod 600 "\${SSH_KEY_PATH}"
    fi

    if [ "\$(stat -c %a \${SSH_KEY_PATH}.pub)" != "644" ]; then
        echo "Fixing public key permissions..."
        chmod 644 "\${SSH_KEY_PATH}.pub"
    fi

    # Validate key format
    if ! ssh-keygen -l -f "\${SSH_KEY_PATH}" >/dev/null 2>&1; then
        echo "Invalid key format. Initializing new key..."
        _initialize_new_key    # 直接调用函数
        return \$?             # 返回函数的退出状态
    fi

    return 0
}

################################################################################
# Helper function to initialize new SSH key
# Returns:
#   0 on success, 1 on failure
################################################################################
_initialize_new_key() {
    echo "Please paste your SSH private key (Press Enter, then Ctrl+D):"
    # Read private key content
    private_key=\$(cat) || return 1

    echo "Please paste your SSH public key:"
    read -r public_key || return 1

    # Validate and clean up private key
    if [ -z "\$private_key" ]; then
        echo "Error: Private key cannot be empty"
        return 1
    fi

    # Validate and clean up public key
    if [ -z "\$public_key" ]; then
        echo "Error: Public key cannot be empty"
        return 1
    fi

    # Clean up public key (only remove leading/trailing spaces)
    public_key=\$(echo "\$public_key" | sed 's/^\s*//;s/\s*\$//')

    # Define supported SSH key types
    local KEY_TYPES_BASIC="ssh-rsa|ssh-ed25519|ssh-dss"
    local KEY_TYPES_ECDSA="ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521"
    local KEY_TYPES_RSA_SHA2="rsa-sha2-256|rsa-sha2-512"
    local KEY_TYPES_SECURITY_KEY="sk-ecdsa-sha2-nistp256@openssh.com|sk-ssh-ed25519@openssh.com"

    # Combine all supported types
    local SUPPORTED_KEY_TYPES="\${KEY_TYPES_BASIC}|\${KEY_TYPES_ECDSA}|\${KEY_TYPES_RSA_SHA2}|\${KEY_TYPES_SECURITY_KEY}"

    # Validate public key format with common SSH key types
    if ! echo "\$public_key" | grep -qE "^(\${SUPPORTED_KEY_TYPES})"; then
        echo "Warning: Unrecognized SSH key type."
        echo "Detected format: \$(echo "\$public_key" | awk '{print \$1}')"
        echo "Do you want to proceed anyway? (y/N)"
        read -r answer
        if [[ ! "\$answer" =~ ^[Yy]\$ ]]; then
            echo "Operation cancelled by user"
            return 1
        fi
        echo "Proceeding with provided key..."
    fi

    # Create .ssh directory if it doesn't exist
    mkdir -p "\$SSH_DIR"
    chmod 700 "\$SSH_DIR"

    # Save private key
    echo "\$private_key" > "\${SSH_KEY_PATH}"
    chmod 600 "\${SSH_KEY_PATH}"

    # Save public key
    echo "\$public_key" > "\${SSH_KEY_PATH}.pub"
    chmod 644 "\${SSH_KEY_PATH}.pub"

    echo "SSH keys have been saved successfully"
    return 0
}

################################################################################
# 3. Update SSH config with server details
# Returns:
#   0 on success, 1 on failure
################################################################################
3_update_ssh_config() {
    echo "Updating SSH configuration..."

    # Extract server IP from git repo URL
    local server_ip=\$(_extract_server_ip)
    if [ \$? -ne 0 ]; then
        return 1
    fi

    # Create/update config file
    touch "\$SSH_CONFIG"
    chmod 600 "\$SSH_CONFIG"

    if grep -q "Host \$server_ip" "\$SSH_CONFIG"; then
        sed -i "/Host \$server_ip/,/IdentityFile/c\Host \$server_ip\n    IdentityFile \$SSH_KEY_PATH" "\$SSH_CONFIG"
    else
        echo -e "\nHost \$server_ip\n    IdentityFile \$SSH_KEY_PATH" >> "\$SSH_CONFIG"
    fi

    echo "SSH config updated for host \$server_ip"
    return 0
}

################################################################################
# Helper function to extract server IP from git repo URL
# Returns:
#   Server IP on success, exits with 1 on failure
################################################################################
_extract_server_ip() {
    local ip=\$(echo "\${GIT_REPO}" | grep -oP '(?<=@)[^:]+')
    if [ -z "\$ip" ]; then
        echo "Error: Could not extract server IP from \${GIT_REPO}" >&2
        return 1
    fi
    echo "\$ip"
}

################################################################################
# 4. Test SSH connection to server (Optional)
# Returns:
#   0 on success, 1 on failure
################################################################################
4_test_connection() {
    echo "SSH key setup completed"
    return 0
}

# Execute main function
main
DELIM

    chmod +x ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_VERIFY_SSH_KEY_SCRIPT_FILE}
}

#####################################################################################
# 3rd group
#####################################################################################
build_distcc_image() {
    echo "Building dev-env-serverside image for ${SERVERSIDE_IMAGE_NAME}..."

    # 使用与主开发环境相同的工具链
    docker build \
        --progress=plain \
        --no-cache \
        --network=host \
        -t "${SERVERSIDE_IMAGE_NAME}:${PROJECT_VERSION}" \
        -f "${BUILD_SCRIPT_DIR}/${TEMP_DOCKERFILE_NAME}" \
        ${BUILD_SCRIPT_DIR} 2>&1 | tee "${BUILD_SCRIPT_DIR}/build_log.txt"

    # 检查 docker build 的退出状态
    local exit_status=${PIPESTATUS[0]}
    if [ $exit_status -ne 0 ]; then
        echo "Error: Docker build failed in ${BUILD_SCRIPT_DIR}/build.sh with exit status: $exit_status"
        exit $exit_status
    fi

    return 0
}


#####################################################################################
# 4th group: main entrance
#####################################################################################
main() {
    func_1_1_setup_environment || return 1

    func_2_1_toolchains_preparation || return 1

    func_2_2_file_entrypoint_preparation || return 1

    func_2_3_file_start_distccd_preparation || return 1

    func_2_4_file_version_script_preparation || return 1

    func_2_5_file_dockerfile_preparation || return 1

    func_2_6_pull_toolchains_prepration || return 1

    func_2_7_verify_sshkey_script_preparation || return 1

    if ! build_distcc_image; then
        echo "Error: Failed to build distcc image"
        return 1
    fi

    # func_1_3_cleanup

    echo "Serverside building completed."
    return 0
}


# Ensure func_1_3_cleanup runs even if script fails
# trap func_1_3_cleanup EXIT

main "$@"




###################################

# exec distccd \
#         --no-detach \
#         --allow 192.168.0.0/16 \
#         --jobs 50 \
#         --log-stderr \
#         --log-level debug \
#         --log-file /development/docker_volumes/log/distccd/distcc.log \
#         --stats \
#         --stats-port 3633 \
#         --enable-tcp-insecure \
#         --verbose