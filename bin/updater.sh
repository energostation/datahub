#!/usr/bin/env bash

WATCH_DIR="/srv/datahub"
LOCK_NAME=".core-update.lock"
LOCK_FILE="$WATCH_DIR/$LOCK_NAME"

echo "Starting monitor for: $WATCH_DIR"
echo "Monitoring file: $LOCK_FILE"

function update_action() {
    delay=$1
    sleep $delay
    systemctl stop datahub-core.service
    systemctl start datahub-core.service
    rm -f "$LOCK_FILE"
}

if [ -f "$LOCK_FILE" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Lock file found at startup, processing..."
    update_action 0
fi

inotifywait -m -e create,moved_to "$WATCH_DIR" |
while read path action file; do
    if [ "$file" = "$LOCK_NAME" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Lock file detected (event: $action)"

        # Small delay to ensure file is fully written
        sleep 0.5

        # Check if file still exists (in case it was quickly deleted)
        if [ -f "$LOCK_FILE" ]; then
            delay=10
            echo "Scheduling core update in $delay seconds ..."
            update_action $delay
            echo "Core update done."
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Lock file disappeared before processing"
        fi
    fi
done
