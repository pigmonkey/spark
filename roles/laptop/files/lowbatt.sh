#!/bin/sh

capacity='low'

# Try to get an actual percentage.
if [ -f /sys/class/power_supply/BAT0/capacity ]; then
    capacity="at `cat /sys/class/power_supply/BAT0/capacity`%"
fi

# Build the message body.
message="Battery is $capacity. We need more power, Scotty!"

# Make some noise.
notify-send --urgency=critical "Low Battery" "$message"
wall "Battery is low. $message"
