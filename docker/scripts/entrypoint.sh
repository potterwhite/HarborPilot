#!/bin/bash
set -e

# If root user, create development user
if [ "$(id -u)" = "0" ]; then
    if [ -n "$DEV_USER" ] && [ -n "$DEV_UID" ]; then
        # Create user
        useradd -m -u $DEV_UID -s /bin/bash $DEV_USER
        # Add sudo privileges
        echo "$DEV_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$DEV_USER
        # Switch to development user
        exec sudo -u $DEV_USER "$@"
    fi
fi

exec "$@" 
