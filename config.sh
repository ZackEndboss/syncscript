#!/bin/bash

# Remote-Host (can be source or destination)
REMOTE_HOST=example.com

# SSH-Port
REMOTE_PORT=22

# Folder to Sync
# Syntax: "title;source;destination"
SYNC_ENTRIES=(
    "ebooks;/local/source/path/to/ebooks;$REMOTE_HOST:/remote/destination/path/to/ebooks"
    "filme;$REMOTE_HOST:/remote/source/to/filme;/local/destination/to/filme"
)
