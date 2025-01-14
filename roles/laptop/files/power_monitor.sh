#! /bin/bash
# Original stolen from Kobus van Schoor:
# https://kobusvs.co.za/blog/power-profile-switching/

BAT=$(echo /sys/class/power_supply/BAT*)
BAT_STATUS="$BAT/status"
BAT_CAP="$BAT/capacity"
AC_STATUS=/sys/class/power_supply/ACAD/online
LOW_BAT_PERCENT=50

AC_PROFILE="desktop"
BAT_PROFILE="balanced"
LOW_BAT_PROFILE="laptop-battery-powersave"

# wait a while if needed
[[ -z $STARTUP_WAIT ]] || sleep "$STARTUP_WAIT"

# start the monitor loop
prev=0

while true; do
    # read the current state
    if [[ $(cat "$AC_STATUS") == "0" ]]; then
        if [[ $(cat "$BAT_CAP") -gt $LOW_BAT_PERCENT ]]; then
            profile=$BAT_PROFILE
        else
            profile=$LOW_BAT_PROFILE
        fi
    else
        profile=$AC_PROFILE
    fi

    # set the new profile
    if [[ $prev != "$profile" ]]; then
        echo setting power profile to $profile
        # powerprofilesctl set $profile
        tuned-adm profile $profile
    fi

    prev=$profile

    # wait for the next power change event
    inotifywait -qq "$AC_STATUS" "$BAT_CAP"
done
