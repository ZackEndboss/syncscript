#!/bin/bash

# TEST:
# cd path/to/script
# ./sync-directory.sh "/mnt/user/source_path/Filme" "user@host:/home/user/dest_path/Filme" "SSH_PORT" "local/path/to/EXCLUDE_FILE.txt"
# ./sync-directory.sh "user@host:/path/to/source" "/path/to/destination" "SSH_PORT" "local/path/to/EXCLUDE_FILE.txt"

# Exit on any error
set -e

# Function for error handling
error_exit() {
    echo "Error: $1" >&2
    exit 1
}
# Funktion zur Überprüfung, ob es sich um einen Remote-Pfad handelt
is_remote_path() {
    [[ "$1" =~ ^[^@]+@[^:]+: ]]
}

# Check if required arguments are provided
if [ "$#" -lt 4 ]; then
    error_exit "Usage: $0 <src_path> <remote_path> <ssh_port> <exclude_file>"
fi

SRC_PATH="$1"
DEST_PATH="$2"
SSH_PORT="$3"
EXCLUDE_FILE="$4"
RSYNC_OPTS="-av --partial-dir=.rsync-partials --info=progress2" # -av --partial

echo
echo "source:      $SRC_PATH"
echo "destination: $DEST_PATH"
echo "ssh-port:    $SSH_PORT"
echo "exclude-file: $EXCLUDE_FILE"


# Verify local path exists and is writable
if ! is_remote_path "$SRC_PATH"; then
    if [ ! -d "$SRC_PATH" ]; then
        error_exit "SRC_PATH $SRC_PATH does not exist or is not a directory"
    fi
fi
if ! is_remote_path "$DEST_PATH"; then
    if [ ! -d "$DEST_PATH" ]; then
        error_exit "DEST_PATH $DEST_PATH does not exist or is not a directory"
    fi
    if [ ! -w "$DEST_PATH" ]; then
        error_exit "DEST_PATH $DEST_PATH is not writable"
    fi

fi

# Check if exclude file exists, if not create it
if [ ! -f "$EXCLUDE_FILE" ]; then
    touch "$EXCLUDE_FILE" || error_exit "Failed to create $EXCLUDE_FILE"
fi

# Get list of all files and directories from remote, handling spaces correctly
if is_remote_path "$SRC_PATH"; then
    # Remote-Pfad
    user_host="${SRC_PATH%%:*}"  # Extrahiere "user@host"
    remote_path="${SRC_PATH#*:}" # Extrahiere den eigentlichen Pfad
    echo "user_host: $user_host - remote_path: $remote_path"
    #ITEMS=$(ssh -p "$SSH_PORT" "$user_host" "ls -A \"$remote_path\"") || error_exit "Failed to get remote directory listing for $path"
    ITEMS=$(ssh -p "$SSH_PORT" "$user_host" "find \"$remote_path\" -type f") || error_exit "Failed to get remote directory listing for $path"

else
    # Lokaler Pfad
    #ITEMS=$(ls -A "$SRC_PATH") || error_exit "Failed to get local directory listing"
    ITEMS=$(find "$SRC_PATH" -type f) || error_exit "Failed to get local directory listing"
fi

#echo "items:"
#echo "$ITEMS"

# Retry loop for rsync
SUCCESS=0
MAX_ATTEMPTS=10

# rsync -av --partial --partial-dir=.rsync-partials --info=progress2 \

for (( ATTEMPT=1; ATTEMPT<=MAX_ATTEMPTS; ATTEMPT++ ))
do
    echo "Attempt $ATTEMPT of $MAX_ATTEMPTS..."
    rsync $RSYNC_OPTS \
        --rsh="ssh -p $SSH_PORT" \
        --exclude-from="$EXCLUDE_FILE" \
        "$SRC_PATH/" \
        "$DEST_PATH"

    if [ $? -eq 0 ]; then
        SUCCESS=1
        break
    else
        echo "Rsync failed, retrying in 2 minutes..."
        sleep 120
    fi
done

# Check if rsync was successful for the final actions
if [ $SUCCESS -eq 1 ]; then
    echo "$ITEMS" > "$EXCLUDE_FILE" || error_exit "Failed to update Exclude_File"
    echo "Sync completed. Updated directory listing saved to $EXCLUDE_FILE"
else
    error_exit "Rsync failed after $MAX_ATTEMPTS attempts."
fi