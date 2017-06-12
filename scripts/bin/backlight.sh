get_default_device() {
    xbacklight -list | head -n1
}


get_backlight() {
    xbacklight -get
}

raise_backlight() {
    xbacklight -ctrl $1 -inc $2
}

lower_backlight() {
    xbacklight -ctrl $1 -dec $2
}

set_backlight() {
    xbacklight -ctrl $1 -set $2
}

get_backlight_icon() {
    local vol="$1"
    local icon

    if [ "${vol}" -eq "100" ]; then
        icon="stock_backlight-max"
    elif [ "${vol}" -ge "70" ]; then
        icon="stock_backlight-high"
    elif [ "${vol}" -ge "40" ]; then
        icon="stock_backlight-med"
    elif [ "${vol}" -gt "0" ]; then
        icon="stock_backlight-min"
    else
        icon="stock_backlight-0"
    fi

    echo "${icon}"
}

notify_backlight() {
    local device="$1"
    vol=$(get_backlight "$device")
    icon=$(get_backlight_icon "$vol")
    notify-send -u low -t 1 -i "${icon}" -h int:value:"${vol}" -h string:synchronous:backlight "backlight ${vol}%"
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


