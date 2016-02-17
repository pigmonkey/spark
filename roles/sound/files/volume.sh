#!/bin/sh

STEP="2%"

if [ $1 == "up" ]; then
    amixer set Master "$STEP"+ unmute
    amixer set Speaker "$STEP"+ unmute
    amixer set Headphone "$STEP"+ unmute
elif [ $1 == "down" ]; then
    amixer set Master "$STEP"- unmute
    amixer set Speaker "$STEP"- unmute
    amixer set Headphone "$STEP"- unmute
elif [ $1 == "toggle" ]; then
    amixer set Master toggle
    amixer set Speaker toggle
    amixer set Headphone toggle
elif [ $1 == "mic" ]; then
    amixer set Capture toggle
    amixer set Mic toggle
fi
