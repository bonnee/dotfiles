#!/bin/env bash
# Taken from: https://www.reddit.com/r/i3wm/comments/kt6uvw/a_script_allowing_you_to_refer_to_multiple/gikj8wz?utm_source=share&utm_medium=web2x&context=3
grim -g "$( slurp )" - | feh -x --class custom-float-no-border -- -
