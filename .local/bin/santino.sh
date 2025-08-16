#!/bin/sh
# Taken from: https://www.reddit.com/r/i3wm/comments/kt6uvw/a_script_allowing_you_to_refer_to_multiple/gikj8wz?utm_source=share&utm_medium=web2x&context=3

border_size=2

coords=$(slurp -f "%x %y %X %Y %w %h")

screen_coords=$(echo $coords | awk -v border="$border_size" '{print $1","$2,$5"x"$6}')
window_pos=$(echo $coords | awk -v border="$border_size" '{print $3-border*2","$4-border*2}')

grim -g "$screen_coords" - | swayimg -s real -p "$window_pos" -w "image" -c general.app_id=santino -c info.show=no -

