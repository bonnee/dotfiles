#!/bin/sh

#[ "${FLOCKER}" != "$0" ] && exec env FLOCKER="$0" flock -en "$0" "$0" "$@" || :
. "$HOME/.cache/wal/colors.sh"

#tmpbg='/tmp/screen.png'

trans="#00000000"
alpha="D9"

#grim "$tmpbg"
#convert "$tmpbg" -scale 50% -scale 10% -scale 1000% -scale 200% "$tmpbg"
#"$HOME/.local/bin/blur_screen.sh" "$tmpbg"

swaylock -f \
--screenshot \
--effect-blur 6x7 \
--effect-vignette 0.6:0.5 \
--clock \
--timestr "%H:%M" \
--datestr "%A %d %B" \
--ignore-empty-password \
--grace 5 \
\
--hide-keyboard-layout \
--indicator-idle-visible \
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
#--time-effects \
