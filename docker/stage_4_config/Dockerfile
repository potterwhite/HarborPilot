FROM embedded-dev:stage3

# Copy configuration scripts and templates
COPY scripts/configure_env.sh /tmp/
COPY configs/env_config.conf /tmp/

# Configure environment
RUN chmod +x /tmp/configure_env.sh && \
    /tmp/configure_env.sh && \
    rm -f /tmp/configure_env.sh /tmp/env_config.conf.template
