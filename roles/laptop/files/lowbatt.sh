#!/bin/bash

CRITICAL=5
LOW=12
VERBOSE=false

usage() {
    echo "Usage: lowbatt [OPTION...]

Options:
    -u      the user who should be notified if the battery is low
    -v      be verbose"
}

log() {
    if [ "$VERBOSE" = true ]; then
        echo "$1"
    fi
}

# Warn if the capacity is low.
low() {
    message="Total capacity is at $capacity. We need more power, Scotty!"
    systemd-cat -t 'lowbatt' -p warning echo "$message"
    if [ -n "$NOTIFYUSER" ]; then
        su "$NOTIFYUSER" -c "notify-send --urgency=critical \"Low Battery\" \"$message\""
    else
        notify-send --urgency=critical "Low Battery" "$message"
    fi
    wall "Battery is low. $message"
}

# Suspend if the capacity is critical.
critical() {
    systemd-cat -t 'lowbatt' -p warning echo "Capacity is critical. Suspending."
    /usr/bin/systemctl suspend
}

# Determine if the system is on battery or AC power.
get_status() {
    if [ "$(cat "/sys/class/power_supply/AC/online")" = "1" ]; then
        log "System is on AC power"
        # If the AC is online, exit.
        exit
    fi
    log "System is on battery power"
}

# Find all batteries.
find_batteries() {
    batteries=($(find /sys/class/power_supply -name 'BAT*'))
    num_batteries=${#batteries[@]}
    if [ ${#batteries[@]} -eq 0 ]; then
        echo 'Failed to find any batteries'
        exit 1
    fi
    log "Found $num_batteries batteries"
}

# Adjust the low and critical levels by the number of batteries.
adjust_levels() {
    CRITICAL=$(( CRITICAL * num_batteries ))
    LOW=$(( LOW * num_batteries ))
    log "Adjusted critical is <= $CRITICAL"
    log "Adjusted low is <= $LOW"
}

# Get the total capacity of all batteries.
get_capacity() {
    capacity=0
    for i in "${batteries[@]}"; do
        capacity=$(( capacity + $(cat "$i"/capacity) ))
    done
    log "Total capacity is $capacity"
}

# Determine if the capacity is low or critical.
check_capacity() {
    if [ $capacity -gt "$CRITICAL" ] &&  [ "$capacity" -le "$LOW" ]; then
        low
    elif [ "$capacity" -le "$CRITICAL" ]; then
        critical
    else
        log "Capacity is within acceptable limits"
    fi
}

while getopts "u:vh" opt; do
    case $opt in
        u)
            NOTIFYUSER=$OPTARG
            ;;
        v)
            VERBOSE=true
            ;;
        h)
            usage
            exit
            ;;
    esac
done

get_status
find_batteries
adjust_levels
get_capacity
check_capacity
