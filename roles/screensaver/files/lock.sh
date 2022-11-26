#!/bin/sh

hash light 2> /dev/null
if [ $? -eq 0 ]; then
    BRIGHTNESS=true
fi

if ! pidof i3lock > /dev/null; then
    if [ "$BRIGHTNESS" = true ]; then
        light -O
        light -S 10
    fi
    /usr/bin/i3lock --color=1d2021 --ignore-empty-password
    if [ "$BRIGHTNESS" = true ]; then
        light -I
    fi
fi
