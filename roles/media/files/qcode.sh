#!/bin/sh
#
# Generate a QR Code and display the resulting image.
#
# Data to encode may be provided either through standard input or as an
# argument. If no data is provided, the clipboard content will be used.
#
###############################################################################

IMG_VIEWER="feh -x --title qcode -"

read -t 0 stdin

if [ -n "$stdin" ]; then
    source="$stdin"
elif [ -n "$1" ]; then
    source="$1"
else
    source=$(xclip -o -selection clipboard)
fi

echo "$source" | qrencode --size=10 -o - | $IMG_VIEWER -
