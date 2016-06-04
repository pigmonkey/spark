#!/bin/sh
#
# Launch the Tor Browser in a Firejail sandbox, verifying that PaX flags are
# properly set for a grsec kernel.
#
###############################################################################

BROWSER=~/.tor-browser-en/INSTALL/Browser/firefox
TBB=/usr/bin/tor-browser-en

# Check if Firejail is available.
FIREJAIL=""
hash firejail 2> /dev/null
if [ $? -eq 0 ]; then
    FIREJAIL=firejail
fi

# Attempt to run tor-browser-en.
$FIREJAIL $TBB "$@"

# If it failed with exit code 139, set the PaX flags and run again.
if [ $? -eq 139 ]; then
    echo 'setting PAX flags'
    setfattr -n user.pax.flags -v "m" "$BROWSER"
    $FIREJAIL $TBB "$@"
fi
