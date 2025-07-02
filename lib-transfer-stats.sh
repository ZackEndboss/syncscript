#!/bin/bash

# ==============================================================================
# ===== GLOBALE KONFIGURATION =====
# ==============================================================================
TMP_FOLDER="/tmp"
TMP_POSTFIX="_monitor_data.json"

# ==============================================================================
# ===== INTERNE HELFER-FUNKTIONEN =====
# ==============================================================================
_get_tmp_file_path() {
  local target_folder=$(realpath "${1}")
  local prefix=$(basename "$target_folder")
  local target_folder_hash=$(echo -n "$target_folder" | md5sum | cut -d ' ' -f 1)
  echo "${TMP_FOLDER}/${prefix}_${target_folder_hash}${TMP_POSTFIX}"
}

# ==============================================================================
# NEU: Methode nur für Formatierung und Ausgabe. Kann von überall genutzt werden.
#
# @param $1: header_text - Eine Überschrift für den Status-Block
# @param $2: duration_s - Dauer in Sekunden (kann Fließkommazahl sein)
# @param $3: size_b - Größe in Bytes
# @param $4: speed_b_s - Geschwindigkeit in Bytes/Sekunde
# ==============================================================================
_print_formatted_status() {
    local header_text="$1"
    local duration_s="$2"
    local size_b="$3"
    local speed_b_s=0
    if (( duration_s > 0 && size_b > 0 )); then
      speed_b_s=$((size_b / duration_s))
    fi

    local human_readable_size=$(numfmt --to=iec-i --suffix=B --format="%.1f" "$size_b")
    local human_readable_speed=$(numfmt --to=iec-i --suffix=B/s --format="%.2f" "$speed_b_s")
    local duration_int=${duration_s%.*}
    local human_readable_duration=$(date -u -d @"$duration_int" +'%H:%M:%S')

    echo "--- $header_text ---"
    echo "Vergangene Zeit:   $human_readable_duration"
    echo "Datenänderung:     $human_readable_size"
    echo "Durchschn. Gesch.: $human_readable_speed"
    echo "------------------------------------------------"
}

# ==============================================================================
# ===== ÖFFENTLICHE FUNKTIONEN (API) =====
# ==============================================================================

# Unverändert, da die Logik solide ist.
start_monitoring() {
  local target_folder="$1"
  local tmp_file=$(_get_tmp_file_path "$target_folder")
  local start_bytes=$(du -sb "$target_folder" | cut -f1)
  local start_seconds=$(date +%s)
  printf '{\n' > "$tmp_file"
  printf '  "target_folder": "%s",\n' "$(realpath "$target_folder")" >> "$tmp_file"
  printf '  "start_bytes": %s,\n' "$start_bytes" >> "$tmp_file"
  printf '  "start_seconds": %s\n' "$start_seconds" >> "$tmp_file"
  printf '}\n' >> "$tmp_file"
}

# Unverändert, gibt weiterhin die Rohdaten zurück.
get_status() {
  local target_folder="$1"
  local tmp_file=$(_get_tmp_file_path "$target_folder")
  if [[ ! -f "$tmp_file" ]]; then
    echo "Fehler: Temporäre Datei für '$target_folder' nicht gefunden." >&2
    return 1
  fi
  local real_target_folder=$(grep '"target_folder"' "$tmp_file" | cut -d '"' -f 4)
  local start_bytes=$(grep '"start_bytes"' "$tmp_file" | cut -d ':' -f 2 | tr -d ' ,')
  #local start_seconds=$(grep '"start_seconds"' "$tmp_file" | cut -d '"' -f 4)
  local start_seconds=$(grep '"start_seconds"' "$tmp_file" | cut -d ':' -f 2 | tr -d ' ,')
  local end_bytes=$(du -sb "$real_target_folder" | cut -f1)
  local end_seconds=$(date +%s)
  local duration_s=$((end_seconds - start_seconds))
  local size_b=$((end_bytes - start_bytes))
  local speed_b_s=0
  if (( $duration_s > 0 && $size_b > 0 )); then
    speed_b_s=$((size_b / duration_s))
  fi
  echo "${duration_s};${size_b};${speed_b_s}"
}

# ANGEPASST: Ruft jetzt die neue Helfer-Funktion zur Ausgabe auf.
display_status() {
  local target_folder="$1"
  local status_data
  status_data=$(get_status "$target_folder")
  if [[ $? -ne 0 ]]; then
    echo "$status_data"
    return 1
  fi
  IFS=';' read -r duration_s size_b speed_b_s <<< "$status_data"
  _print_formatted_status "Status für: $target_folder" "$duration_s" "$size_b" "$speed_b_s"
}

# Unverändert.
stop_monitoring() {
  local target_folder="$1"
  local tmp_file=$(_get_tmp_file_path "$target_folder")
  rm -f "$tmp_file"
}

# ==============================================================================
# ===== "MULTIPLE" METHODEN (jetzt mit neuer Logik) =====
# ==============================================================================

# Unverändert.
start_monitoring_multiple() {
  for folder in "$@"; do
    start_monitoring "$folder"
  done
}

# KOMPLETT NEU: Erzeugt eine aggregierte Zusammenfassung.
display_summary_status() {
  local total_duration="0"
  local total_size=0

  # Schritt 1: Sammle und summiere die Daten aller Ordner
  for folder in "$@"; do
    local status_data
    status_data=$(get_status "$folder")
    if [[ $? -ne 0 ]]; then
      echo "Konnte Status für $folder nicht abrufen, wird übersprungen."
      continue
    fi
    IFS=';' read -r duration_s size_b speed_b_s <<< "$status_data"

    # Addiere zur Gesamtdauer (mit 'bc' für Fließkommazahlen)
    total_duration=$(awk -v total="$total_duration" -v add="$duration_s" 'BEGIN { print total + add }')
    # Addiere zur Gesamtgröße
    total_size=$((total_size + size_b))
  done

  # Schritt 2: Berechne die Gesamt-Geschwindigkeit aus den Gesamt-Werten
  local total_speed=$(awk -v size="$total_size" -v dur="$total_duration" 'BEGIN { if (dur > 0) { printf "%.0f", size / dur } else { print 0 } }')

  # Schritt 3: Rufe die zentrale Ausgabe-Funktion mit den aggregierten Daten auf
  _print_formatted_status "Gesamtstatus (alle Ordner)" "$total_duration" "$total_size" "$total_speed"
}

# Unverändert.
stop_monitoring_multiple() {
  for folder in "$@"; do
    stop_monitoring "$folder"
  done
  echo "Alle Überwachungen beendet und temporäre Dateien gelöscht."
}

# ==============================================================================
# ===== HAUPTPROGRAMM: Zeigt die neue Logik =====
# ==============================================================================
# Test
test() {
  echo ">>> Multi-Ordner-Anwendung startet (finales Design) <<<"
  
  declare -a folder_list=("Serien" "Filme" "Musik/Alben")
  for folder in "${folder_list[@]}"; do mkdir -p "$folder"; done
  echo "Test-Ordner erstellt: ${folder_list[*]}"
  echo ""
  
  echo "Starte Überwachung für alle Ordner..."
  start_monitoring_multiple "${folder_list[@]}"
  echo "Überwachung für ${#folder_list[@]} Ordner gestartet."
  echo ""
  
  echo "Simuliere Arbeit..."
  fallocate -l 100M "Serien/s01e01.mkv"
  fallocate -l 250M "Filme/blockbuster.mp4"
  sleep 2
  fallocate -l 50M "Musik/Alben/album.flac"
  sleep 1
  echo ""
  
  # Zeige den Status für einen einzelnen Ordner an
  display_status "Filme"
  echo ""
  
  # Zeige die neue, aggregierte Zusammenfassung für ALLE Ordner an
  display_summary_status "${folder_list[@]}"
  echo ""
  
  # Aufräumen
  stop_monitoring_multiple "${folder_list[@]}"
  rm "Serien/s01e01.mkv" "Filme/blockbuster.mp4" "Musik/Alben/album.flac"
  rmdir "Serien" "Filme" "Musik/Alben"
  
  echo ">>> Multi-Ordner-Anwendung beendet <<<"
  
  
  
  echo ">>> Wieder-verwendung-test <<<"
  total_duration=0
  total_size=0
  for folder in "${folder_list[@]}"; do
    mkdir "$folder"
    fallocate -l 100M "$folder/s01e01.mkv"
  
    start_monitoring "$folder"
    fallocate -l 250M "$folder/blockbuster.mp4"
  
  #  sleep 2
  
    status_data=$(get_status "$folder")
    IFS=';' read -r local_duration local_size local_speed <<< "$status_data"
  
    ((total_duration += $local_duration ))
    ((total_size += $local_size ))
    rm "$folder/s01e01.mkv"
    rm "$folder/blockbuster.mp4"
    rmdir "$folder"
  done
  
  _print_formatted_status "Total Stats" $total_duration $total_size
}

# ==== Main Guard ====
# Dieser Block wird NUR ausgeführt, wenn das Skript direkt
# aufgerufen wird (z.B. ./script.sh oder bash script.sh),
# aber NICHT, wenn es mit 'source' eingebunden wird.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Führe den Befehl aus, der sich aus den Argumenten zusammensetzt
  if [[ -n "$1" ]]; then
    # An argument was provided, so we call it as a function.
    "$@"
  fi
fi
