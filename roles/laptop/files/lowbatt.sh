#!/bin/sh

BATTERY="BAT0"

low() {
    # Warn if the battery is low.
    message="Battery $BATTERY is at $CAPACITY. We need more power, Scotty!"
    systemd-cat -t 'lowbatt' -p warning echo "$message"
    notify-send --urgency=critical "Low Battery" "$message"
    wall "Battery is low. $message"
}

critical() {
    # Suspend if the battery is critical.
    systemd-cat -t 'lowbatt' -p warning echo "Battery $BATTERY is critical. Suspending."
    /usr/bin/systemctl suspend
}

# Allow the user to specify a different battery.
if [ -n "$1" ]; then
    BATTERY="$1"
fi

# Only continue if we can get the capacity of the battery.
if [ -f /sys/class/power_supply/"$BATTERY"/capacity ]; then
    # Get the remaining capacity of the battery.
    CAPACITY=`cat /sys/class/power_supply/"$BATTERY"/capacity`
else
    echo "Could not get capacity for battery $BATTERY."
    exit 1
fi

# If the capacity is between 5 and 10, it is low.
if [ "$CAPACITY" -gt 5 -a "$CAPACITY" -le 10 ]; then
    low
# If the capacity is 5 or less, it is critical.
elif [ "$CAPACITY" -le 5 ]; then
    critical
fi
