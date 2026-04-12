#!/bin/bash

# Remote-Host (can be source or destination)
REMOTE_HOST=example.com

# SSH-Port
REMOTE_PORT=22

# Default UserID & GroupID of Files/Folder created by rsync
UID=99
GID=100

# Additional SSH Options for rsync. Like: -J user@my_ssh_jumpserver to use ssh-tunnel
SSH_OPTS=""

# Folder to Sync
# Syntax: "title;source;destination"
SYNC_ENTRIES=(
    "ebooks;/local/source/path/to/ebooks;$REMOTE_HOST:/remote/destination/path/to/ebooks"
    "filme;$REMOTE_HOST:/remote/source/to/filme;/local/destination/to/filme"
)
