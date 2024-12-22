# syncscript

# BEFORE RUNNING:
 - be sure, your local public ssh key is in the $HOME/.ssh/authorized_keys on the remote-host
   cat ~/.ssh/*.pub # put this key into the remote $HOME/.ssh/authorized_keys

 - add known_hosts
   ssh-keyscan -H "remote_host" >> ~/.ssh/known_hosts

 - Unraid: UserScripts

# TEST:
 cd path/to/script
 ./sync-directories.sh "/mnt/user/source_path/Filme" "user@host:/home/user/dest_path/Filme" "SSH_PORT" "local/path/to/EXCLUDE_FILE.txt"
 ./sync-directories.sh "user@host:/path/to/source" "/path/to/destination" "SSH_PORT" "local/path/to/EXCLUDE_FILE.txt"

# Final:
 Edit your config.sh

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
 
 
