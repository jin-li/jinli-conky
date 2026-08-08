#!/bin/bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "$0")" && pwd -P)"
config_file="$script_dir/jinli-config.lua"
desktop_file="$script_dir/conky-start.desktop"
desktop_exec="$(printf '%q' "$script_dir/start.sh")"

cd "$script_dir"

# Wait for the network and other apps to start.
[[ " $* " =~ " --no-sleep " ]] || sleep 10

# Create a new config if there is none.
[[ -f "$config_file" ]] || cp "$script_dir/jinli-config.example.lua" "$config_file"

# Create a desktop-entry file that can be copied to ~/.config/autostart/.
cat > "$desktop_file" <<EOL
[Desktop Entry]
Type=Application
Name=jinli-conky
Comment=Conky, a system monitor
TryExec=$script_dir/start.sh
Exec=$desktop_exec
Path=$script_dir
Icon=utilities-system-monitor
Terminal=false
StartupNotify=false
Categories=Utility;System;
EOL
echo "Created autostart entry at $desktop_file. Copy it to ~/.config/autostart to autostart conky at login."

if [[ " $@ " =~ " --loop " ]]; then
  while true; do
    conky -c "$config_file" >> /tmp/conky.log 2>&1
    echo "Restarting conky ..." | tee -a /tmp/conky.log
    sleep 1
  done
else
  exec conky -c "$config_file" >> /tmp/conky.log 2>&1
fi
