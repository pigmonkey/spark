#!/bin/bash
# {{ ansible_managed }}

if [ "$1" = "post" ]; then
    /usr/local/bin/lock
fi
