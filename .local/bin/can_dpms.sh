#!/bin/sh

# Function to check if the sink is an external display
is_external_display() {
    local sink_description
    sink_description=$(pactl info | grep 'Default Sink' | awk '{print $3}')

    if echo "$sink_description" | grep -q 'hdmi\|dp'; then
        return 0  # External display detected
    else
        return 1  # External display not detected
    fi
}

# Check if playerctl is installed
command -v playerctl > /dev/null 2>&1 || {
    echo "Error: playerctl is not installed. Please install it."
    exit 1
}

# Check if music is playing on an external display
if playerctl status --format "{{ uc(status) }}" 2> /dev/null | grep -q "PLAYING" && is_external_display; then
    exit 0  # Music playing on an external display
else
    exit 1  # No music playing or not on an external display
fi

