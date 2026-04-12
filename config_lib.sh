#!/bin/bash

source config.sh

[ -z "$USERID" ] && echo "'USERID' Variable ist leer oder nicht deklariert. SET USERID=$(id -u)"
USERID="${USERID:-$(id -u)}"

[ -z "$GROUPID" ] && echo "'GROUPID' Variable ist leer oder nicht deklariert. SET GROUPID=$(id -g)"
GROUPID="${GROUPID:-$(id -g)}"

# Max length of longest Entrie
get_sync_entries_max_length() {
    local max_len=0
    for entry in "${SYNC_ENTRIES[@]}"; do
        if (( ${#entry} > max_len )); then
            max_len=${#entry}
        fi
    done
    echo $max_len
}

get_sync_entry_by_index_max_length() {
    local index="$1"
    for entry in "${SYNC_ENTRIES[@]}"; do
        local source_path
        source_path=$(echo "$entry" | cut -d';' -f$index)
        if (( ${#source_path} > max_len )); then
            max_len=${#source_path}
        fi
    done
    echo $max_len

}

get_sync_title_max_length() {
    get_sync_entry_by_index_max_length 1
}
get_sync_source_max_length() {
    get_sync_entry_by_index_max_length 2
}
get_sync_destination_max_length() {
    get_sync_entry_by_index_max_length 3
}


