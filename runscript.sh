#!/bin/bash

# Usage: docker exec <container_name> runscript <script-name.py>

# Set the script name from the argument
SCRIPT_NAME="$1"

# Set UMASK (defaults if not provided)
UMASK=${UMASK:-002}

# Search for the script in subdirectories of CONFIG_DIR
SCRIPT_PATH=$(find "$CONFIG_DIR" -type f -name "$SCRIPT_NAME" | head -n 1)

if [ -z "$SCRIPT_PATH" ]; then
    echo "Error: Script '$SCRIPT_NAME' not found in $CONFIG_DIR or its subdirectories." > >(tee -a /proc/1/fd/1) 2> >(tee -a /proc/1/fd/2 >&2)
    exit 1
fi

# Set the working directory to the directory containing the script
WORKING_DIR=$(dirname "$SCRIPT_PATH")

# Debugging: Print script path and working directory
echo ""
echo "---------------------------------------"
echo "Script path: $SCRIPT_PATH"
echo "Working directory: $WORKING_DIR"
echo "---------------------------------------"
echo ""

# Run the script as dockeruser and redirect output to PID1 (docker logs)
echo "" > >(tee -a /proc/1/fd/1)
su -s /bin/bash -c "umask $UMASK && cd $WORKING_DIR && exec ./$SCRIPT_NAME" dockeruser > >(tee -a /proc/1/fd/1) 2> >(tee -a /proc/1/fd/2 >&2)
echo "" > >(tee -a /proc/1/fd/1)