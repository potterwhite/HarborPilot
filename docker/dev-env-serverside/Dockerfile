FROM ubuntu:22.04

# Change apt source to China mirrors

RUN echo "Change apt source to China mirrors" && \
    sed -i 's|http://archive.ubuntu.com/ubuntu/|http://mirrors.aliyun.com/ubuntu/|g' /etc/apt/sources.list && \
    echo -e "Done\n"
# Install base packages

RUN echo "Install base packages" && \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python \
    python3-pip \
    python-dev \
    build-essential \
    cmake \
    pkg-config \
    git \
    wget \
    unzip \
    vim \
    && rm -rf /var/lib/apt/lists/* && \
    echo -e "Done\n"

RUN apt-get update && apt-get install -y     distcc     && rm -rf /var/lib/apt/lists/*

#############################################
#  toolchian init
#############################################
RUN mkdir -p /opt/toolchains
COPY /home/james/Development/docker/DockerDevEnvTemplate/docker/dev-env-serverside../dev-env-clientside/stage_2_tools/offline_packages/gcc/../../configs/tool_version.conf /tmp
COPY /home/james/Development/docker/DockerDevEnvTemplate/docker/dev-env-serverside../dev-env-clientside/stage_2_tools/offline_packages/gcc/install_gcc.sh /tmp
COPY /home/james/Development/docker/DockerDevEnvTemplate/docker/dev-env-serverside../dev-env-clientside/stage_2_tools/offline_packages/gcc/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.gz /tmp

RUN ls -lha /tmp &&     chmod +x /tmp/install_gcc.sh &&     /tmp/install_gcc.sh 

#############################################
#  entrypoint init
#############################################
# COPY /home/james/Development/docker/DockerDevEnvTemplate/docker/dev-env-serverside/configs//home/james/Development/docker/DockerDevEnvTemplate/docker/dev-env-serverside/configs/entrypoint.sh /usr/local/bin//home/james/Development/docker/DockerDevEnvTemplate/docker/dev-env-serverside/configs/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
