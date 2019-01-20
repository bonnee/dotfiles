#!/usr/bin/env bash
# Lock wrapper around i3lock-color

tmpbg='/tmp/screen.png'

trans="#00000000"
black="$(xgetres color8)BB"
white="$(xgetres color15)FF"
blue="$(xgetres color4)FF"
red="$(xgetres color1)FF"
green="$(xgetres color10)FF"

scrot "$tmpbg"
convert "$tmpbg" -scale 50% -scale 10% -scale 1000% -scale 200% "$tmpbg"
i3lock --clock --indicator --pass-media-keys \
\
--insidevercolor="$black" \
--ringvercolor="$blue" \
\
--insidewrongcolor="$black" \
--ringwrongcolor="$red" \
\
--insidecolor="$black" \
--ringcolor="$trans" \
--line-uses-ring \
--separatorcolor="$trans" \
--keyhlcolor="$green" \
--bshlcolor="$red" \
\
--verifcolor="$white" \
--wrongcolor="$white" \
--timecolor="$white" \
--datecolor="$white" \
--layoutcolor="$white" \
\
--veriftext="Mhm..." \
--wrongtext="Nope!" \
--timestr="%H:%M" \
--datestr="%a %d %b" \
\
-i "$tmpbg" 
