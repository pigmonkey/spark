#!/bin/sh
#
# Take advantage of mpv's youtube-dl integration to easily watch videos outside
# of the browser. Use sxhkd or xbindkeys to bind this script to a key. When
# you're on a YouTube page, copy the URL to your clipboardand and hit your key
# binding; the video will automatically begin streaming via mpv.
###############################################################################

read -t 0 stdin

if [ -n "$stdin" ]; then
    source="$stdin"
elif [ -n "$1" ]; then
    source="$1"
else
    source=$(xclip -o -selection clipboard)
fi

notify-send "Loading..." "$source"

if ! mpv "$source"; then
    notify-send --urgency=critical "Failed to play" "$source"
fi
