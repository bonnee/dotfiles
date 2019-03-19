#!/usr/bin/env bash

save="/tmp/bkl"

idle_backlight=5
fade_time=500
fade_steps=20

save(){
  xbacklight -get > "$save"
}

resume(){
  val=$(cat "$save")
  set_backlight "$val"
}

set_backlight(){
  xbacklight -time "$fade_time" -steps "$fade_steps" -set "$1"
}


while getopts "drs0" opt; do
    case $opt in
      d)
	set_backlight "$idle_backlight"
	;;
      r)
	resume
	;;
      s)
        save
	;;
      0)
	set_backlight 0
	;;
      *)
	exit 1
	;;
    esac
done
