#!/usr/bin/env bash

[ "${FLOCKER}" != "$0" ] && exec env FLOCKER="$0" flock -en "$0" "$0" "$@" || :
. "$HOME/.cache/wal/colors.sh"

tmpbg='/tmp/screen.png'

trans="#00000000"
alpha="D9"

grim "$tmpbg"
convert "$tmpbg" -scale 50% -scale 10% -scale 1000% -scale 200% "$tmpbg"

swaylock -f \
--ignore-empty-password \
\
--indicator-radius=150 \
--inside-ver-color="$background$alpha" \
--ring-ver-color="$color2" \
\
--text-clear-color="$background" \
--inside-clear-color="$foreground" \
--line-clear-color="$foreground" \
--ring-clear-color="$foreground" \
\
--inside-wrong-color="$background$alpha" \
--ring-wrong-color="$color6" \
\
--inside-color="$background$alpha" \
--ring-color="$trans" \
--line-uses-ring \
--separator-color="$trans" \
--key-hl-color="$color1" \
--bs-hl-color="$color6" \
\
--text-ver-color="$foreground" \
--text-wrong-color="$foreground" \
\
-i "$tmpbg"
