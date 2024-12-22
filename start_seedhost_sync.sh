#!/bin/bash


# Exit on any error
set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Make scripts executable if they aren't already
chmod +x "$SCRIPT_DIR/sync-directories.sh"

# Loading config
source config.sh

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
        echo "Sync process is already running for $UNIQUE_NAME. Skipping..."
        continue
    fi

    # Create lock file
    touch "$LOCK_FILE"

    echo "Syncing $UNIQUE_NAME..."
    # Execute the sync script with configured parameters
    if "$SCRIPT_DIR/sync-directories.sh" "$SRC_PATH" "$DEST_PATH" "$REMOTE_PORT" "$EXCLUDE_FILE"; then
        echo "Sync completed for $UNIQUE_NAME."
    else
        echo "Sync failed for $UNIQUE_NAME. See logs for details."
    fi
    rm "$LOCK_FILE"
done

echo "All syncs completed successfully."
