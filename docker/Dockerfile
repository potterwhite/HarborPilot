FROM ubuntu:22.04

# Environment variables
ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV TZ=Asia/Shanghai

# Working directory
WORKDIR /work

# Copy configuration files and scripts
COPY docker/scripts/install_tools.sh /tmp/
COPY docker/scripts/entrypoint.sh /usr/local/bin/
COPY docker/configs/bashrc /root/.bashrc

# Setup GUI support
COPY docker/scripts/setup_gui.sh /tmp/

# Install tools
RUN chmod +x /tmp/install_tools.sh && \
    /tmp/install_tools.sh && \
    rm -f /tmp/install_tools.sh

RUN chmod +x /tmp/setup_gui.sh && /tmp/setup_gui.sh

# Set entrypoint
ENTRYPOINT ["entrypoint.sh"]
CMD ["/bin/bash"]