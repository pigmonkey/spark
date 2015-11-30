#!/bin/sh

FIREJAIL=""

hash firejail 2> /dev/null

if [ $? -eq 0 ]; then
    FIREJAIL=firejail
fi

$FIREJAIL /usr/bin/rtorrent "$@"
