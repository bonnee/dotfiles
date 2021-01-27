#!/bin/sh

# Sends a graphical notification when a device's battery gets low

lowbat=15

upower -m > >(while read -r line ; do
  case $line in
    *"device changed"*)
      device="$(echo $line | awk '{print $4}')"

      model="$(upower -i $device | grep model | awk '{ for (i=3; i<=NF; i++) printf("%s ", $i) }')"
      state="$(upower -i $device | grep battery-level | awk '{print $2}')"
      bat="$(upower -i $device | grep percentage | awk '{print $2}' | sed 's/.$//')"
  
      echo "$device" "$bat%"
      if [ "$bat" -le $lowbat ]; then
        notify-send -u "critical" "$model battery is at $bat%"
      fi

      ;;
  esac

done)
