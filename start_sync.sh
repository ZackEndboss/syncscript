#!/bin/bash


# Exit on any error
set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Make scripts executable if they aren't already
chmod +x "$SCRIPT_DIR/sync-directory.sh"

# Loading config
source config.sh

logger "Sync-Skript started: $(basename "$0")"

# Function to check if a process is running
is_process_running() {
    local pid=$1
    ps -p "$pid" > /dev/null 2>&1
}

# Loop through each configuration entry
for entry in "${SYNC_ENTRIES[@]}"; do
    IFS=';' read -ra ADDR <<< "$entry"  # split entry into an array using semicolon
    UNIQUE_NAME="${ADDR[0]}"
    SRC_PATH="${ADDR[1]}"
    DEST_PATH="${ADDR[2]}"
    EXCLUDE_FILE="$SCRIPT_DIR/.exclude_${UNIQUE_NAME}.txt"  # specific exclude file for each entry
    LOCK_FILE="$SCRIPT_DIR/.${UNIQUE_NAME}.lock"  # Lock file for each unique name


    # Check if lock file exists
    if [ -f "$LOCK_FILE" ]; then
        LOCK_PID=$(cat "$LOCK_FILE")
        if is_process_running "$LOCK_PID"; then
            echo "Sync process is already running for $UNIQUE_NAME (PID $LOCK_PID). Skipping..."
            logger "Sync-Skript ${UNIQUE_NAME}-sync already running: ${UNIQUE_NAME}[$LOCK_PID]"
            continue
        else
            echo "Stale lock file detected for $UNIQUE_NAME. Removing stale lock file..."
            rm -f "$LOCK_FILE"
        fi
    fi


    # Start sync and capture the PID
    echo "Syncing $UNIQUE_NAME..."
    "$SCRIPT_DIR/sync-directory.sh" "$SRC_PATH" "$DEST_PATH" "$REMOTE_PORT" "$EXCLUDE_FILE" &
    SYNC_PID=$!
    echo "$SYNC_PID" > "$LOCK_FILE"

    # Wait for sync process to complete
    wait "$SYNC_PID"
    if [ $? -eq 0 ]; then
        echo "Sync completed for $UNIQUE_NAME."
    else
        echo "Sync failed for $UNIQUE_NAME. See logs for details."
        logger "Sync-Skript ${UNIQUE_NAME}-sync failed: {UNIQUE_NAME}[$SYNC_PID]"
    fi
    rm -f "$LOCK_FILE"

done

echo "All syncs completed successfully."
logger "Sync-Script done."
