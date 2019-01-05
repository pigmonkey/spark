#!/bin/bash

# Get the location from ip-api.com if the user didn't specify.
location="$1"
if [ -z "$1" ]; then
    location_data=$(curl -s http://ip-api.com/json)
    location=$(echo "$location_data" | jq -r 'if (.zip | length) != 0 then .zip else .city end')
    lat=$(echo "$location_data" | jq '.lat')
    lon=$(echo "$location_data" | jq '.lon')
    country=$(echo "$location_data" | jq -r '.country')
fi

# Request the narrow version when appropriate.
columns=$(tput cols)
opts='?'
if [ "$columns" -lt 125 ]; then
    opts+='n'
fi

# If we fetched coordinates and are in the US, provide a URL to the detailed forecast.
if [ "$country" == "United States" ] && [ -n "$lat" ] && [ -n "$lon" ]; then
    details="https://forecast.weather.gov/MapClick.php?lat=$lat&lon=$lon&FcstType=graphical&menu=1"
fi

weather=$(curl -s -H "Accept-Language: ${LANG%_*}" --compressed wttr.in/"$location$opts")

echo "$weather"$'\n\n'"$details" | LESS="-F -w -R -X -z-4" less
