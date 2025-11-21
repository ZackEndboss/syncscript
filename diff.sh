#!/bin/bash

# ==============================================================================
# Sync Library
#
# Enthält wiederverwendbare Funktionen für den Verzeichnisvergleich mit rsync.
# Diese Datei soll nicht direkt ausgeführt, sondern von anderen Skripten
# via `source sync_lib.sh` eingebunden werden.
# ==============================================================================

# Usage:
# Import
# source "diff.sh"
#
# Führe den Vergleich aus. Quelle ist SOURCE_DIR, Ziel ist DESTINATION_DIR.
# rsync_output=$(run_rsync_comparison "$SOURCE_DIR" "$DESTINATION_DIR" "$IGNORE_FILE_PATH" "$SSH_PORT")
#
# Werte die Ausgabe aus, um die Größe der fehlenden Daten zu erhalten.
# bytes_to_sync=$(parse_missing_size_bytes "$rsync_output")
#
# Ausgabe der Berechnungen
# echo "$(format_bytes_human_readable $bytes_to_sync)"
# echo "$(print_result_human_readable $bytes_to_sync)"
# echo "$rsync_output"

source config_lib.sh
max_mb_s=${INTERNET_SPEED_MB_S:-12}
#set -x
# Führt den rsync-Vergleich im Trockenlauf-Modus aus.
# Gibt die komplette Ausgabe (stdout & stderr) von rsync zurück.
#
# @param $1: string - Quellverzeichnis (source)
# @param $2: string - Zielverzeichnis (destination)
# @param $3: string - Pfad zur Ignore-Datei
# @param $4: int    - SSH-Port (optional, Standard ist 22)
# @return: string - Die rohe Ausgabe von rsync
run_rsync_comparison() {
    local source_dir="$1"
    local destination_dir="$2"
    local ignore_file="$3"
    local ssh_port=${4:-22} # Nutzt den übergebenen Port oder 22 als Standard

    local rsh_option="--rsh=ssh -p ${ssh_port}"

    # Führe rsync aus und leite stdout sowie stderr um, um alles zu erfassen.
    rsync -an --stats --exclude-from="$ignore_file" "$rsh_option" "$source_dir" "$destination_dir" 2>&1
}

# Extrahiert die Gesamtgröße der fehlenden Dateien in Bytes aus der rsync-Ausgabe.
#
# @param $1: string - Die rohe rsync-Ausgabe von run_rsync_comparison
# @return: int - Die Anzahl der Bytes oder eine leere Zeichenkette
parse_missing_size_bytes() {
    local rsync_output="$1"
    echo "$rsync_output" | grep 'Total transferred file size:' | awk '{print $5}' | tr -d ','
}

# Formatiert eine Byte-Anzahl in ein für Menschen lesbares Format (KiB, MiB etc.).
#
# @param $1: int - Die Anzahl der Bytes
# @return: string - Der formatierte String (z.B. "1.23 MiB")
format_bytes_human_readable() {
    local bytes="$1"

    # Führe keine Berechnung durch, wenn die Eingabe leer oder 0 ist.
    if [ -z "$bytes" ] || [ "$bytes" -eq 0 ]; then
        echo "0 B"
        return
    fi

    awk -v bytes="$bytes" '
        function human(x) {
            s=" B  KiB MiB GiB TiB"
            while (x >= 1024 && length(s) > 1) {
                x /= 1024
                s = substr(s, 5)
            }
            return sprintf("%.2f%s", x, substr(s, 1, 4))
        }
        BEGIN { print human(bytes) }
    '
}

print_result_human_readable() {
    local bytes="$1"
    local title="$2"
    local mb_sec=${3:-$max_mb_s}
    local size_human_readable=$(numfmt --to=iec --suffix=B --format="%.1f" "$bytes")
    size_human_readable="$(printf "%8s" "$size_human_readable")"
    #local speed_progress=$(printf "%.0f" "$(($(($bytes/$(($mb_sec*1024*1024))))/60))")
    local speed_progress=$(awk -v b="$bytes" -v m="$mb_sec" 'BEGIN { result = (b / (m * 1024 * 1024)) / 60; printf "%.0f\n", result }')

    # --- Schritt 4: Ergebnis anzeigen ---
    if [ -z "$bytes" ] || [ "$bytes" -eq 0 ]; then
        printf "✅ %8s%s $title"
    else
        human_readable_size=$(format_bytes_human_readable "$bytes")
        #echo "⚠️ $size_human_readable $title - dauer: $speed_progress min"
        printf "⚠️  %8s %s - dauer: %s min\n" "$size_human_readable" "$title" "$speed_progress"
        # Hier könnten Sie z.B. eine E-Mail senden oder eine andere Aktion auslösen.
    fi
}

total_bytes=0
print_config_diff_result() {
#    source config.sh
    # Loop through each configuration entry
    for entry in "${SYNC_ENTRIES[@]}"; do
        IFS=';' read -ra ADDR <<< "$entry"  # split entry into an array using semicolon
        UNIQUE_NAME="${ADDR[0]}"
        SRC_PATH="${ADDR[1]}"
        DEST_PATH="${ADDR[2]}"
        TITLE="${SRC_PATH##*:}"

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

        # Analyse
        rsync_output=$(run_rsync_comparison "$SRC_PATH/" "$DEST_PATH" "$EXCLUDE_FILE" "$REMOTE_PORT")
        bytes=$(parse_missing_size_bytes "$rsync_output")
        total_bytes=$((bytes + total_bytes))
        result=$(print_result_human_readable "$bytes" "$TITLE")
        echo "$result"
#        break
    done
}

print_total_bytes_gesamt_diff() {
  echo "$(print_result_human_readable $total_bytes Gesamt)"
}

#print_config_diff_result
#echo
#print_total_bytes_gesamt_diff
