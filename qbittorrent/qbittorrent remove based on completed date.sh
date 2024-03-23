#!/bin/bash

# qBittorrent credentials and URL
QB_USERNAME="USER"
QB_PASSWORD="<PASSWORD>"
QB_URL="http://localhost:8080"

# Login and save cookie
COOKIE=$(curl -s -c - --data "username=$QB_USERNAME&password=$QB_PASSWORD" "$QB_URL/api/v2/auth/login" | grep SID | cut -f7)

if [ -z "$COOKIE" ]; then
    echo "Login failed."
    exit 1
fi

# Get list of all torrents
TORRENTS=$(curl -s --cookie "SID=$COOKIE" "$QB_URL/api/v2/torrents/info?filter=completed")

# Current date in seconds since the epoch
CURRENT_DATE=$(date +%s)

# Loop through each torrent
echo "$TORRENTS" | jq -c '.[]' | while read -r torrent; do
    HASH=$(echo "$torrent" | jq -r '.hash')
    COMPLETION_DATE=$(echo "$torrent" | jq -r '.completion_on')

    # Calculate age in weeks
    let "AGE_WEEKS=($CURRENT_DATE - $COMPLETION_DATE) / 604800"

    if [ "$AGE_WEEKS" -ge 2 ]; then
        # Delete torrent and its files
        curl -s --cookie "SID=$COOKIE" --data "hashes=$HASH&deleteFiles=true" "$QB_URL/api/v2/torrents/delete"
        echo "Deleted torrent $HASH and its files."
    fi
done