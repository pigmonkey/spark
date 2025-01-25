#!/usr/bin/env bash
# Stolen from Ilija Matoski:
# https://www.matoski.com/article/wifi-ethernet-autoswitch/

name_tag="wifi-wired-exclusive"
syslog_tag="$name_tag"
skip_filename="/etc/NetworkManager/.$name_tag"

if [ -f "$skip_filename" ]; then
  exit 0
fi

action="$2"

# Bail out if the action is not either up or down.
if [[ "$action" != "up" && "$action" != "down" ]]; then
    exit 0
fi

active_ethernet=$(nmcli conn show --active | tr -s ' ' | cut -d' ' -f3 | grep ethernet)

enable_wifi() {
   echo "$syslog_tag: No active ethernet connections, enabling wifi."
   nmcli radio wifi on
}

disable_wifi() {
   echo "$syslog_tag: Disabling wifi, ethernet connection detected."
   nmcli radio wifi off
}

if [ -z "$active_ethernet" ]; then
    enable_wifi
else
    disable_wifi
fi
