#!/bin/sh

hash light 2> /dev/null
if [ $? -eq 0 ]; then
    BRIGHTNESS=true
fi

if ! pidof physlock > /dev/null; then
    if [ "$BRIGHTNESS" = true ]; then
        light -O
        light -S 10
    fi
    /usr/sbin/physlock -md
    if [ "$BRIGHTNESS" = true ]; then
        light -I
    fi
fi
