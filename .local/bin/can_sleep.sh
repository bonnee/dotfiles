#!/bin/sh
if ! command -v playerctl &> /dev/null; then
    echo "Error: playerctl is not installed. Please install it."
    exit 2
fi

if playerctl status 2> /dev/null | grep -q "Playing"; then
  exit 0
fi
exit 1
