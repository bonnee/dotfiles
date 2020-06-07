#!/bin/sh

if [ -z "$1" ]; then
  >&2 echo "Error: No output path specified"
  exit 1
fi
out_img="$1"

# Blocky instead of blur. faster
#filters='noise=alls=10,scale=iw*.05:-1,scale=iw*20:-1:flags=neighbor'
filters='boxblur=8:8'

if [ "$XDG_SESSION_TYPE" != "wayland" ]; then

  res="$(xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/')"

  ffmpeg -y -loglevel 0 -s "$res" -f x11grab -i $DISPLAY -vframes 1 -vf "$filters" "$out_img"

  echo $out_img
else
  in_img="$(mktemp).png"
  grim "$in_img"

  ffmpeg -y -loglevel 0 -i "$in_img" -vf "$filters" "$out_img"

  rm "$in_img"
fi

