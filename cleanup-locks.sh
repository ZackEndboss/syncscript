#!/bin/bash

echo "$(date +%F) $0 started"
for file in .*.lock; do
    # Prüfen, ob Dateien mit dem Muster existieren
    if [ ! -f "$file" ]; then
        echo "Keine treffer: \"$file\""
        continue
    fi

    # PID auslesen und auf numerischen Wert prüfen
    pid=$(cat "$file")
    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "Fehler: Ungültige PID ($pid) in Datei $file"
        echo "Datei gelöscht:  $file"
        continue
    fi

    # Prüfen, ob der Prozess läuft
    if ps -p "$pid" > /dev/null; then
        echo "Details für zu beendenden Prozess (PID: $pid, Datei: $file):"
        # Detaillierte Ausgabe (User, PID, PPID, C, STIME, TTY, TIME, CMD)
        ps -f -p "$pid" | grep -v "^UID" | sed 's/^/  /'

        # Prozess beenden (zunächst regulär, bei Bedarf erzwungen)
        kill -15 "$pid" 2>/dev/null
        sleep 0.5
        if ps -p "$pid" > /dev/null; then
            kill -9 "$pid" 2>/dev/null
            echo "  -> Prozess wurde mit SIGKILL (kill -9) erzwungen beendet."
        else
            echo "  -> Prozess wurde mit SIGTERM (kill -15) beendet."
        fi
    else
        echo "Prozess (PID: $pid, Datei: $file) läuft nicht mehr."
    fi

    # Lock-Datei löschen
    rm "$file"
    echo "Datei gelöscht: $file"
    echo "---------------------------------------------------"
done
echo "$(date +%F) $0 done."


