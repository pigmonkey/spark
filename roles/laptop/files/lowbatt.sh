#!/bin/sh

BATTERY="BAT0"

low() {
    # Warn if the battery is low.
    message="Battery $BATTERY is at $CAPACITY%. We need more power, Scotty!"
    systemd-cat -t 'lowbatt' -p warning echo "$message"
    notify-send --urgency=critical "Low Battery" "$message"
    wall "Battery is low. $message"
}

critical() {
    # Suspend if the battery is critical.
    systemd-cat -t 'lowbatt' -p warning echo "Battery $BATTERY is critical. Suspending."
    /usr/bin/systemctl suspend
}

get_status() {
    # Get the status of the battery.
    if [ -f /sys/class/power_supply/"$BATTERY"/status ]; then
        # Get the remaining capacity of the battery.
        STATUS=`cat /sys/class/power_supply/"$BATTERY"/status`
    else
        echo "Could not get status for battery $BATTERY."
        exit 1
    fi
    # If the battery is not discharging, exit silently.
    if [ "$STATUS" != "Discharging" ]; then
        exit
    fi
}

get_capacity() {
    # Only continue if we can get the capacity of the battery.
    if [ -f /sys/class/power_supply/"$BATTERY"/capacity ]; then
        # Get the remaining capacity of the battery.
        CAPACITY=`cat /sys/class/power_supply/"$BATTERY"/capacity`
    else
        echo "Could not get capacity for battery $BATTERY."
        exit 1
    fi
}

check_capacity() {
    # If the capacity is between 5 and 10, it is low.
    if [ "$CAPACITY" -gt 5 -a "$CAPACITY" -le 10 ]; then
        low
    # If the capacity is 5 or less, it is critical.
    elif [ "$CAPACITY" -le 5 ]; then
        critical
    fi
}

# Allow the user to specify a different battery.
if [ -n "$1" ]; then
    BATTERY="$1"
fi

get_status
get_capacity
check_capacity
