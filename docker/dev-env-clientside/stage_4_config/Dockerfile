ARG IMAGE_NAME=embedded-dev
FROM ${IMAGE_NAME}:stage3

# Copy configuration scripts and templates
COPY scripts/configure_env.sh /tmp/
COPY configs/env_config.conf /tmp/

# Configure environment
RUN chmod +x /tmp/configure_env.sh && \
    /tmp/configure_env.sh && \
    rm -f /tmp/configure_env.sh /tmp/env_config.conf.template && \
    # Update PATH in /etc/environment
    sed -i 's/^session    required     pam_env.so$/session    required     pam_env.so readenv=1/g' /etc/pam.d/login && \
    echo "source /etc/environment" >> /etc/bash.bashrc && \
    chmod 644 /etc/environment
