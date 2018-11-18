#!/bin/bash

/usr/bin/reflector --latest 20 \
                   --sort rate \
                   --protocol https \
                   --save /etc/pacman.d/mirrorlist
                   
if [[ -f /etc/pacman.d/mirrorlist.pacnew ]]; then
    rm /etc/pacman.d/mirrorlist.pacnew
fi
