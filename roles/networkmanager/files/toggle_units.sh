#!/bin/sh

start() {
    echo "starting all the things"
    systemctl start $(cat /usr/local/etc/trusted_units)
    exit $?
}

stop() {
    echo "stopping all the things"
    systemctl stop $(cat /usr/local/etc/trusted_units)
    exit $?
}

# Get all active connections.
connections=($(nmcli --terse -f uuid conn show --active))

# If there are no active connections, the trusted units should be stopped.
if [ ${#connections[@]} -eq 0 ]; then
    echo "there are no active connections"
    stop
# If there are active connections, and any of them are untrusted, the
# trusted units should be stopped.
else
    for uuid in "${connections[@]}"; do
        grep -q \^"$uuid"\$ /usr/local/etc/trusted_networks
        if [ "$?" -ne 0 ]; then
            echo "$uuid is untrusted"
            stop
        fi
    done
fi
# If we're still here, the trusted units should be started
start
