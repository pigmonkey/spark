#!/bin/sh

IMG_VIEWER="feh -x --auto-zoom --title showme"

location="$(mapbox geocoding "$1" | jq -c .features[0])"
lon=$(echo $location | jq .center[0])
lat=$(echo $location | jq .center[1])
tmp=$(mktemp $TMPDIR/$(uuidgen).png.XXX)
mapbox staticmap --lat $lat --lon $lon --zoom ${2:-13} --size 1279 1279 \
mapbox.satellite $tmp
eval $IMG_VIEWER $tmp
