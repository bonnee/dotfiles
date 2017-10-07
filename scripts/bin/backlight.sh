#!/bin/bash
#
#  i3-backlight
#
#  Backlight control and notifications for i3wm.
#
#  Requires:
#    notify-osd
#    xbacklight
#    awk
#
#  Copyright (c) 2017 Matteo Bonora. All rights reserved.
#  License: GNU Lesser General Public License v3
#
#  Author: Matteo Bonora <bonora.matteo@gmail.com>
#  URL: https://github.com/Bonnee/dotfiles/blob/master/scripts/bin/backlight.sh

get_default_device() {
    xbacklight -list | head -n1
}

get_backlight() {
    xbacklight -get
}

get_brightness() {
    xrandr --verbose | grep -i brightness | cut -f2 -d ' ' | head -n1
}

# Raises the backlight or brightness.
#
# Arguments:
#   device  (string) The device to modify.
#   amount    (int) The % of brightness to add.
raise_backlight() {
    if (( $(get_backlight) == 100 )) && (( $(bc <<< "$(get_brightness) <= 1.0") )); then
        # If backlight is already topped out, then increase brightness to make text more readable
	     set_brightness "1.2"
    else if (( $(get_backlight) == 1 )); then
            # Assures that final backlight value is a multiple of amount
            set_backlight "$1" "$2"
        else
            xbacklight -ctrl $1 -inc $2
        fi
    fi
}

# Lowers the backlight or brightness.
#
# Arguments:
#   device  (string) The device to modify.
#   amount    (int) The % of brightness to subtract.
lower_backlight() {
    # make the same controls of raise_backlight, but reversed.
    if (( $(get_backlight) == 100 )) && (( $(bc <<< "$(get_brightness) > 1.0") )); then
	     set_brightness "1"
    else if (( $(get_backlight) - "$2" < 1 )); then
            set_backlight "$1" "1"
        else
            xbacklight -ctrl $1 -dec $2
        fi
    fi
}

set_backlight() {
    xbacklight -ctrl $1 -set $2
}

set_brightness() {
    xrandr --output $(xrandr -q | grep ' connected' | head -n 1 | cut -d ' ' -f1) --brightness $1
}

get_backlight_icon() {
    local bl="$1"
    local icon

    if [ "${bl}" -eq "100" ]; then
        icon="stock_backlight-max"
    elif [ "${bl}" -ge "70" ]; then
        icon="stock_backlight-high"
    elif [ "${bl}" -ge "40" ]; then
        icon="stock_backlight-med"
    elif [ "${bl}" -gt "0" ]; then
        icon="stock_backlight-min"
    else
        icon="stock_backlight-0"
    fi

    echo "${icon}"
}

notify_backlight() {
    local device="$1"
    bl=$(get_backlight "$device")
    #icon=$(get_backlight_icon "$bl")
    notify-send -u low -t 1 -i "${icon}" -h int:value:"${bl}" -h string:synchronous:backlight "Backlight"
}

# Updates the status line.
#
# Arguments:
#   signal  (string) The signal used to update the status line.
#   proc    (string) The name of the status line process.
update_statusline() {
    local signal="$1"
    local proc="$2"
    pkill "-${signal}" "${proc}"
}

usage() {
    echo "Usage: $0 [options]
Control backlight and related notifications.

Options:
  -i <amount>       increase backlight
  -d <amount>       decrease backlight
  -n                show notification
  -p <device name>  name of device
  -t <procname>     name of status line process. must be used with -u
  -u <signal>       update status line using signal. must be used with -t
  -v <value>        set backlight
  -h                display this help and exit
" 1>&2
    exit 1
}


opt_decrease_backlight=false
opt_increase_backlight=false
opt_notification=false
opt_set_backlight=false
device="$(get_default_device)"
signal=""
statusline=""
backlight_amount="5"

while getopts ":d:hi:mns:t:u:v:" o; do
    case "${o}" in
        d)
            opt_decrease_backlight=true
            backlight_amount="${OPTARG}"
            ;;
        i)
            opt_increase_backlight=true
            backlight_amount="${OPTARG}"
            ;;
        n)
            opt_notification=true
            ;;
        p)
            device="${OPTARG}"
            ;;
        t)
            statusline="${OPTARG}"
            ;;
        u)
            signal="${OPTARG}"
            ;;
        v)
            opt_set_backlight=true
            backlight_amount="${OPTARG}"
            ;;
        h | *)
            usage
            ;;
    esac
done
shift $((OPTIND-1)) # Shift off options and optional --

if ${opt_increase_backlight}; then
    raise_backlight "${device}" "${backlight_amount}"
fi

if ${opt_decrease_backlight}; then
    lower_backlight "${device}" "${backlight_amount}"
fi

if ${opt_set_backlight}; then
    set_backlight "${device}" "${backlight_amount}"
fi

# The options below this line must be last
if ${opt_notification}; then
    notify_backlight "${device}"
fi

if [ -n "${signal}" ]; then
    if [ -z "${statusline}" ]; then
        usage
    fi
    update_statusline "${signal}" "${statusline}"
else
    if [ -n "${statusline}" ]; then
        usage
    fi
fi

