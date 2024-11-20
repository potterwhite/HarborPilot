FROM ubuntu:22.04

# Variable passing chain for build and runtime:
# 1. .env -> defines the initial values
# 2. docker-compose.yml -> passes values via build args
# 3. ARG -> receives values during build time
# 4. ENV -> makes variables available at runtime
ARG DEBIAN_FRONTEND=noninteractive
ARG SDK_INSTALL_DIR  # Receive from docker-compose build args
ARG SDK_PKG_NAME     # Add this
ARG CONTAINER_VOLUME_ROOT     # Add this

# Set as environment variables for scripts
ENV SDK_INSTALL_DIR=${SDK_INSTALL_DIR}
ENV SDK_PKG_NAME=${SDK_PKG_NAME}
ENV CONTAINER_VOLUME_ROOT=${CONTAINER_VOLUME_ROOT}
ENV LANG=C.UTF-8
ENV TZ=Asia/Shanghai

# Working directory
WORKDIR ${CONTAINER_VOLUME_ROOT}

# Copy SDK package and installation script
COPY docker/scripts/install_tools.sh /tmp/
COPY docker/scripts/entrypoint.sh /usr/local/bin/
COPY docker/configs/bashrc /root/.bashrc

# Install tools
RUN chmod +x /tmp/install_tools.sh && \
    /tmp/install_tools.sh && \
    rm -f /tmp/install_tools.sh

##################################################################
# disable GUI support temporarily
# Nov20.2024
# # Setup GUI support
# COPY docker/scripts/setup_gui.sh /tmp/
# RUN chmod +x /tmp/setup_gui.sh && /tmp/setup_gui.sh
##################################################################

# Set entrypoint
ENTRYPOINT ["entrypoint.sh"]
CMD ["/bin/bash"]
