#!/bin/sh

curl wttr.in/"${1:-$(curl http://ip-api.com/json | jq 'if (.zip | length) != 0 then .zip else .city end')}"
