#!/usr/bin/env bash

charge_delta=1
display_delta=0
steps=10
bat="BAT1"
current_threshold=$(echo "scale=0; $(cat "/sys/class/power_supply/$bat/charge_stop_threshold")/10*10+10"|bc -l)

if [ "$BLOCK_BUTTON" == 1 ]; then
  if [ "$current_threshold" -ge 100 ]; then
    new_threshold=$(echo "50+$charge_delta"|bc -l);
  else
    new_threshold=$(echo "$current_threshold+$charge_delta+$steps"|bc -l);
  fi
  
  sudo tlp setcharge "$new_threshold" "$new_threshold" > /dev/null
  #current_threshold=$new_threshold
fi
echo "$(echo "$current_threshold+$display_delta"|bc -l)%"

