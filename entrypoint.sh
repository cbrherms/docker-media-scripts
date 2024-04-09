#!/bin/bash

# Usage: docker exec <container_name> runscript <script-name.py>

# Set user and group IDs (defaults if not provided)
PUID=${PUID:-99}
PGID=${PGID:-100}
UMASK=${UMASK:-002}

echo "
---------------------------------------------------------
        PUID:           ${PUID}
        PGID:           ${PGID}
        UMASK:          ${UMASK}
        CONFIG_DIR:     ${CONFIG_DIR}
---------------------------------------------------------
"

# Set umask
umask "$UMASK"

# Modify user and group IDs
groupmod -o -g "$PGID" dockeruser
usermod -o -u "$PUID" dockeruser

# Download/update scripts from Media-Scripts repository
LOCALREPO="$CONFIG_DIR"/.git

echo "Installing/Updating Media-Scripts:"

if [ ! -d "$LOCALREPO" ]; then
    git clone https://github.com/chazlarson/Media-Scripts.git "$CONFIG_DIR"
else
    git config --global --add safe.directory "$CONFIG_DIR"
    git -C "$CONFIG_DIR" pull
fi

# Ensure correct permissions on scripts
chown -R ${PUID}:${PGID} /${CONFIG_DIR} > /dev/null 2>&1
chmod -R 777 /${CONFIG_DIR} > /dev/null 2>&1

# Keep the container running
tail -f /dev/null