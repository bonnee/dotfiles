#!/bin/sh

#. "$HOME/.cache/wal/colors.sh"
source "$HOME/.cache/wal/colors.sh"

wallpaper=$(cat "$HOME/.cache/wal/wal")
tmpbg="/tmp/bg.png"
#cp $wallpaper $tmpbg

trans="#00000000"
alpha="D9"

#magick "$wallpaper" -scale 50% -scale 10% -scale 1000% -scale 200% "$tmpbg"
#"$HOME/.local/bin/blur_screen.sh" "$tmpbg"

swaylock -f \
--image $wallpaper \
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
\
--text-ver-color="$foreground" \
--text-wrong-color="$foreground"

