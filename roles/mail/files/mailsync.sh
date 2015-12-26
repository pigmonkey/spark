#!/bin/sh
# Original source: http://bit.ly/1Ztk5wg
# Run mbsync when full internet connectivity is available.

STATE=`nmcli networking connectivity`

if [ $STATE = 'full' ]
then
    /usr/bin/mbsync -a
    exit $?
fi
echo "No internet connection."
exit 0
