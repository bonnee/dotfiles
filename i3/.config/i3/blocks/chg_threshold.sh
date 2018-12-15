#!/usr/bin/env bash

charge_delta=3
steps=10
bat="BAT1"
current_threshold=$(echo "$(cat "/sys/class/power_supply/$bat/charge_stop_threshold")"|bc -l)

if [ "$BLOCK_BUTTON" == 1 ]; then
  if [ "$current_threshold" -ge 100 ]; then
    new_threshold=50;
  else
    new_threshold=$(echo "$current_threshold+$steps"|bc -l);
  fi
  
  sudo tlp setcharge "$new_threshold" "$new_threshold" > /dev/null
  current_threshold=$new_threshold
fi

echo "$(echo "$current_threshold+$charge_delta"|bc -l)%"
