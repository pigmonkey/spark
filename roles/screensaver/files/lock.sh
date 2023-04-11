#!/bin/sh

hash brightnessctl 2> /dev/null
if [ $? -eq 0 ]; then
    BRIGHTNESS=true
fi

if ! pidof i3lock > /dev/null; then
    if [ "$BRIGHTNESS" = true ]; then
        brightnessctl --quiet --save
        brightnessctl --quiet set 10%
    fi
    /usr/bin/i3lock --color=1d2021 --ignore-empty-password
    if [ "$BRIGHTNESS" = true ]; then
        brightnessctl --quiet --restore
    fi
fi
