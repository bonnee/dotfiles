#!/usr/bin/env bash
# Lock wrapper around i3lock-color

[ "${FLOCKER}" != "$0" ] && exec env FLOCKER="$0" flock -en "$0" "$0" "$@" || :

tmpbg='/tmp/screen.png'

trans="#00000000"
black="#000000BB"
white="#F6F6F6FF"
blue="#2196F3FF"
red="#F44336FF"
green="#4CAF50FF"

grim "$tmpbg"

convert "$tmpbg" -scale 50% -scale 10% -scale 1000% -scale 200% "$tmpbg"

swaylock -f \
\
--indicator-radius=150 \
--inside-ver-color="$black" \
--ring-ver-color="$blue" \
\
--inside-wrong-color="$black" \
--ring-wrong-color="$red" \
\
--inside-color="$black" \
--ring-color="$trans" \
--line-uses-ring \
--separator-color="$trans" \
--key-hl-color="$green" \
--bs-hl-color="$red" \
\
--text-ver-color="$white" \
--text-wrong-color="$white" \
\
-i "$tmpbg"
#sleep 2
