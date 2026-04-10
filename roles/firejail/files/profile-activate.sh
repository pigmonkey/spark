#!/bin/bash

PROFILEDIR=~/.config/firejail
SYSDIR=/usr/local/etc/firejail
COUNT=0

# If the profile directory does not exist, create it.
if [ ! -d "$PROFILEDIR" ]; then
    mkdir -p "$PROFILEDIR"
fi

# For every system profile, create a user profile if one does not already
# exist.
for path in "$SYSDIR"/*.profile; do
    file=`basename $path`
    destination=$PROFILEDIR/$file
    if [ ! -e $destination ]; then
        echo "include $SYSDIR/$file" > $destination
        COUNT=$((COUNT + 1))
    fi
done

echo "$COUNT profiles activated"
