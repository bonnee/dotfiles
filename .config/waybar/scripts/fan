#!/usr/bin/env bash

rpm="$(grep speed /proc/acpi/ibm/fan | awk '{print $2}')"

if [ "$rpm" -ne 0 ]; then
  class="low"
  (( $(echo "${rpm}>3490"|bc -l) )) && class="medium"
  (( $(echo "${rpm}>3990"|bc -l) )) && class="high"

  echo "󰈐"
  echo "$rpm RPM"
  echo "$class"
fi
