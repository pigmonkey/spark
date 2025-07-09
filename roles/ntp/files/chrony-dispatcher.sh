#!/bin/bash
# Stolen from: https://aur.archlinux.org/packages/networkmanager-dispatcher-chrony#comment-1024845

case $2 in
    connectivity-change)
        case $CONNECTIVITY_STATE in
            FULL)
                chronyc online
                echo "chronyd taken online"
            ;;
            UNKNOWN|NONE|PORTAL|LIMITED)
                chronyc offline
                echo "chronyd taken offline"
            ;;
        esac
    ;;
    vpn-up|vpn-down)
        chronyc offline
        chronyc online
        echo "chronyd taken online"
    ;;

esac
