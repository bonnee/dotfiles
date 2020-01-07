#!/usr/bin/env bash
#
#  i3-volume
#
#  Volume control and volume notifications for i3wm.
#
#  Requires:
#    notify-osd
#    pulseaudio-utils
#    awk
#
#  Conflicts:
#    dunst -- with notify-osd when invoking notify-send
#
#  Copyright (c) 2016 Beau Hastings. All rights reserved.
#  License: GNU General Public License v2
#
#  Author: Beau Hastings <beausy@gmail.com>
#  URL: https://github.com/hastinbe/i3-volume

# Get default sink name
get_default_out() {
    pacmd stat | awk -F": " '/^Default sink name: /{print $2}'
}

get_default_in() {
    pacmd stat | awk -F": " '/^Default source name: /{print $2}'
}

# Gets the sink volume as a percentage.
#
get_volume() {
  if is_out_muted; then
    echo 0
  else
    pacmd list-sinks |
        awk '/^\s+name: /{indefault = $2 == "<'$out'>"}
            /^\s+volume: / && indefault {print $5; exit}' | sed 's/%$//'
  fi
}

# Set volume of sink.
#
# Arguments:
#   Volume      (integer|linear factor|percentage|decibel)
set_volume() {
    local vol="$1"

    pactl set-sink-volume "${out}" "${vol}" ||
        pactl set-sink-volume "${out}" -- "${vol}"
}

toggle_out_mute() {
    pactl set-sink-mute "$out" toggle
}

toggle_in_mute() {
    pactl set-source-mute "$in" toggle
}

# Check if default sink is muted.
#
# Arguments:
#   Sink name    (string) Symbolic name of sink.
#
# Returns:
#   0 when true, 1 when false.
is_out_muted() {
    local sink="$1"
    muted=$(pacmd list-sinks |
            awk -v 'RS=\r?\n' '/^\s+name: /{indefault = $2 == "<'"$out"'>"}
                /^\s+muted: / && indefault {print $2; exit}')
    [ "${muted}" = "yes" ]
}

# Display program usage.
usage() {
    echo "Usage: $0 [options]
Control volume and related notifications.

Options:
  -g		    get volume
  -s <value>        set volume (can also work with +/- increments)
  -m                toggle mute
  -i		    toggle mic mute
  -h                display this help and exit
" 1>&2
    exit 1
}
###########################################################

opt_mute_out=false
opt_mute_in=false
opt_set_volume=false
opt_get_volume=false
out="$(get_default_out)"
in="$(get_default_in)"

volume_amount=""

while getopts ":gims:" o; do
    case "${o}" in
        m)
            opt_mute_out=true
            ;;
	i)
	    opt_mute_in=true
	    ;;
        t)
            statusline="${OPTARG}"
            ;;
        u)
            signal="${OPTARG}"
            ;;
        s)
            opt_set_volume=true
            volume_amount="${OPTARG}"
            ;;
	g)
	    opt_get_volume=true
	    ;;
        h | *)
            usage
            ;;
    esac
done
shift $((OPTIND-1)) # Shift off options and optional --

if ${opt_set_volume}; then
    set_volume "${volume_amount}"
fi

if ${opt_mute_out}; then
    toggle_out_mute
fi

if ${opt_mute_in}; then
    toggle_in_mute
fi

if ${opt_get_volume}; then
  get_volume
fi
