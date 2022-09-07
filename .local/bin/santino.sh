#!/bin/sh
# Taken from: https://www.reddit.com/r/i3wm/comments/kt6uvw/a_script_allowing_you_to_refer_to_multiple/gikj8wz?utm_source=share&utm_medium=web2x&context=3
#grim -g "$( slurp )" - | feh -x --class santino -- -
border_size=2
coords=$(slurp)
swaycoords=$(echo $coords | sed -e "s/ /,/g" -e "s/x/,/g" | awk -v border="$border_size" -F, '{print $1-border*2","$2-border*2","$3","$4}')
grim -g "$coords" - | swayimg -s real -c santino -g $swaycoords -

