#!/usr/bin/env bash
# Stolen from Ilija Matoski:
# https://www.matoski.com/article/wifi-ethernet-autoswitch/

name_tag="wifi-wired-exclusive"
syslog_tag="$name_tag"
skip_filename="/etc/NetworkManager/.$name_tag"

if [ -f "$skip_filename" ]; then
  exit 0
fi

interface="$1"
action="$2"

# Bail out if the action is not either up or down.
if [[ "$action" != "up" && "$action" != "down" ]]; then
    exit 0
fi

iface_type=$(nmcli dev | grep "^$interface" | tr -s ' ' | cut -d' ' -f2)
iface_state=$(nmcli dev | grep "^$interface" | tr -s ' ' | cut -d' ' -f3)

echo "$syslog_tag: Interface $interface = $iface_state ($iface_type) is $action"

enable_wifi() {
   echo "$syslog_tag: Interface $interface ($iface_type) is down, enabling wifi."
   nmcli radio wifi on
}

disable_wifi() {
   echo "$syslog_tag: Disabling wifi, ethernet connection detected."
   nmcli radio wifi off
}

if [[ "$iface_type" = "ethernet" || -z "$iface_type" ]] && [ "$action" = "down" ]; then
  enable_wifi
elif [ "$iface_type" = "ethernet" ] && [ "$action" = "up"  ] && [ "$iface_state" = "connected" ]; then
  disable_wifi
fi
