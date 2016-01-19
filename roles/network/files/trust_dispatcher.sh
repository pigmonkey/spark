#!/bin/sh

action="$2"

case $action in
    up)
        /usr/local/bin/toggle_units
        ;;
    down)
        /usr/local/bin/toggle_units
        ;;
esac

exit $?
