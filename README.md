# Syncscript

## Before Running
Bevor du das Skript ausführst, stelle sicher, dass du folgende Schritte durchgeführt hast:

### 1. SSH-Key Setup
- Stelle sicher, dass dein lokaler öffentlicher SSH-Schlüssel im `$HOME/.ssh/authorized_keys` auf dem Remote-Host hinterlegt ist:
  ```
  cat ~/.ssh/*.pub | ssh user@remote_host -p 22 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
  ```

### 2. Bekannte Hosts hinzufügen
- Füge den Remote-Host zu deinen bekannten Hosts hinzu, um Verbindungsprobleme zu vermeiden:
  ```
  ssh-keyscan -H "remote_host" >> ~/.ssh/known_hosts
  ```

### 3. Vorbereitung für Unraid: UserScripts
- Wenn du Unraid verwendest, richte die erforderlichen UserScripts ein.
  ```
  cd PATH/TO/SCRIPTS
  ./start_sync.sh
  ```

## Test
Teste das Skript, indem du in das Verzeichnis des Skripts wechselst und die folgenden Befehle ausführst:

```
cd path/to/script
./sync-directory.sh "/mnt/user/source_path/Filme" "user@host:/home/user/dest_path/Filme" "SSH_PORT" "local/path/to/EXCLUDE_FILE.txt"
./sync-directory.sh "user@host:/path/to/source" "/path/to/destination" "SSH_PORT" "local/path/to/EXCLUDE_FILE.txt"
```

### Finale Einrichtung
## Final Setup
Bearbeite `config.sh` gemäß deinen spezifischen Anforderungen:

```
# Remote-Host (kann Quelle oder Ziel sein)
REMOTE_HOST=example.com

# SSH-Port
REMOTE_PORT=22

# Ordner synchronisieren
# Syntax: "Titel;Quelle;Ziel"
SYNC_ENTRIES=(
    "ebooks;/local/source/path/to/ebooks;$REMOTE_HOST:/remote/destination/path/to/ebooks"
    "filme;$REMOTE_HOST:/remote/source/to/filme;/local/destination/to/filme"
)
```

### Hinweise
- Ersetze `"remote_host"` und andere Platzhalter mit den tatsächlichen Werten, die für deine Konfiguration spezifisch sind.
- Stelle sicher, dass du den korrekten SSH-Port angibst, falls du einen anderen als den Standardport (22) verwendest.
