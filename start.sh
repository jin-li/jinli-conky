#!/bin/bash

cd $(dirname $0)

# wait for the network and other apps to start
[[ " $@ " =~ " --no-sleep " ]] || sleep 10;

# create a new config if there is none
[[ -f jinli-config.lua ]] || cp jinli-config.example.lua jinli-config.lua


if [[ " $@ " =~ " --loop " ]]; then
  while true; do
    conky -c jinli-config.lua >> /tmp/conky.log 2>&1
    echo "Restarting conky ..." | tee -a /tmp/conky.log
    sleep 1
  done
else
  exec conky -c jinli-config.lua >> /tmp/conky.log 2>&1
fi
