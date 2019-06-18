#!/usr/bin/env bash

save="/tmp/bkl"

idle_backlight=5
fade_down_time=1000
fade_up_time=500
fade_down_steps=60
fade_up_steps=30

save(){
  tmp_backlight=$(get_backlight)

  if [ "$tmp_backlight" -gt $idle_backlight ]; then
    echo "$tmp_backlight" > "$save"
  fi
}

get_backlight()
{
  xbacklight -get
}

resume(){
  if [[ -r "$save" ]]; then
    val=$(cat "$save")
  else
    val=50
  fi
  set_backlight "$val" "$fade_up_time" "$fade_up_steps"
}

set_backlight(){
  xbacklight -set "$1" -time "$2" -steps "$3"
}


while getopts "drs0" opt; do
    case $opt in
      d)
	set_backlight "$idle_backlight" "$fade_down_time" "$fade_down_steps"
	;;
      r)
	resume
	;;
      s)
        save
	;;
      0)
	set_backlight 0 "$fade_down_time" "$fade_down_steps"
	;;
      *)
	exit 1
	;;
    esac
done
