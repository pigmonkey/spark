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

# If the executable does not exist, run tor-browser-en once to extract the
# files.
if [ ! -f "$BROWSER" ]; then
    echo 'extracting files'
    $FIREJAIL $TBB
fi

# Check the PAX flags on the browser, setting them if necessary.
echo 'checking PAX flags'
getfattr -n user.pax.flags "$BROWSER" | grep -q '^user.pax.flags=".*m.*"'
if [ $? -ne 0 ]; then
    echo 'setting PAX flags'
    setfattr -n user.pax.flags -v "m" "$BROWSER"
fi

# Launch the browser
$FIREJAIL $TBB "$@"
