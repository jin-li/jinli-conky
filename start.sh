#!/bin/bash

cd $(dirname $0)

# wait for the network and other apps to start
[[ " $@ " =~ " --no-sleep " ]] || sleep 10;

# create a new config if there is none
[[ -f jinli-config.lua ]] || cp jinli-config.example.lua jinli-config.lua

# clear the old autostart entry (if any) and create a new one
[[ -f conky-start.desktop ]] && rm conky-start.desktop
cat > conky-start.desktop <<EOL
[Desktop Entry]
Type=Application
Name=jinli-conky
Comment=Conky, a system monitor
Exec=$(pwd)/start.sh
Icon=utilities-system-monitor
Terminal=false
Categories=Utility;System;
EOL
echo "Created autostart entry at $(pwd)/conky-start.desktop. Copy it to ~/.config/autostart to autostart conky at login."

if [[ " $@ " =~ " --loop " ]]; then
  while true; do
    conky -c jinli-config.lua >> /tmp/conky.log 2>&1
    echo "Restarting conky ..." | tee -a /tmp/conky.log
    sleep 1
  done
else
  exec conky -c jinli-config.lua >> /tmp/conky.log 2>&1
fi
