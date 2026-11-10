#!/usr/bin/env bash

# --- Configuration ---
# Default unit prefix if not provided as an argument
DEFAULT_UNIT_PREFIX="backup"

# Icons (using Nerd Fonts - adjust as needed)
ICON_RUNNING=""    # Example: Spinning gear or similar
ICON_IDLE=""       # Example: Sun or checkmark
ICON_DISABLED=""   # Example: Cross or stop sign
ICON_STOPPED=""    # Example: Cross or stop sign

# --- Script Logic ---
UNIT_PREFIX="${1:-$DEFAULT_UNIT_PREFIX}" # Use first arg as prefix, or default
SERVICE_NAME="${UNIT_PREFIX}.service"
TIMER_NAME="${UNIT_PREFIX}.timer"

# Function to get the status and next run time of the timer
get_timer_status() {
    local timer_status=$(systemctl show "$TIMER_NAME" --property ActiveState --value)
    local timer_enabled=$(systemctl is-enabled "$TIMER_NAME" 2>/dev/null)
    local next_run_raw=$(sudo systemctl list-timers --no-pager --output=json | jq -r --arg timer_name "$TIMER_NAME" '.[] | select(.unit == $timer_name) | .next_elapse_realtime')

    if [[ "$timer_enabled" == "enabled" ]]; then
        if [[ -n "$next_run_raw" ]]; then
            # Convert to a more readable format
            local next_run_date=$(date -d "$next_run_raw" +"%Y-%m-%d %H:%M")
            echo "Timer: Enabled, Next: $next_run_date"
        else
            echo "Timer: Enabled, Next: N/A"
        fi
    else
        echo "Timer: Disabled"
    fi
}

# Handle click events from Waybar
if [[ "$2" == "stop" ]]; then # Now expecting prefix as $1, "stop" as $2
    sudo systemctl stop "$TIMER_NAME"
    sudo systemctl disable "$TIMER_NAME"
    echo "{\"text\": \"${ICON_STOPPED} ${UNIT_PREFIX}: Timer Stopped\", \"tooltip\": \"${UNIT_PREFIX} timer has been stopped and disabled.\", \"class\": \"stopped\"}"
    exit 0
fi

# Check if the backup service is running
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "{\"text\": \"${ICON_RUNNING} ${UNIT_PREFIX}: Running\", \"tooltip\": \"${UNIT_PREFIX} service is currently active.\", \"class\": \"running\"}"
else
    # Service is not running, check timer status
    TIMER_INFO=$(get_timer_status)
    if [[ "$TIMER_INFO" == *"Enabled"* ]]; then
        echo "{\"text\": \"${ICON_IDLE} ${UNIT_PREFIX}: Idle\", \"tooltip\": \"$TIMER_INFO. Click to stop timer.\", \"class\": \"idle\"}"
    else
        echo "{\"text\": \"${ICON_DISABLED} ${UNIT_PREFIX}: Disabled\", \"tooltip\": \"$TIMER_INFO. Timer is disabled.\", \"class\": \"disabled\"}"
    fi
fi