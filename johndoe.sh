#!/bin/bash

# This is a proof of concept login script to be placed on the SWG.

output=$(curl http://192.168.10.168:8999/johndoe.txt)
while read -r line; do
	    echo "$line"
		curl --header "X-Forwarded-For: $line" -d "USERNAME=johndoe&PASSWORD=calvary&submit=Login" http://127.0.0.1ilogin
	done <<< "$output"


# Don't forget to add a crontab entry on the SWG to run this script.
# This example will run every 5 minutes.

# */5 * * * * /root/login_scripts/johndoe.sh >/dev/null 2>&1