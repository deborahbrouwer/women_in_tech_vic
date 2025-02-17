#!/bin/bash

set -eu

info() {
    # green color
    echo -e "\033[32m$1\033[0m" >&2
}

BINARY="/wit_shared/bin/women_in_tech_vic"
SCRIPT="${BASH_SOURCE[0]}"

# Health check: wait for the build.sh to finish
while true; do
    if [ ! -f "$BINARY" ]; then
        info "Binary file does not exist yet. Sleeping..."
        sleep 3
        continue
    fi

    CURRENT_TIME=$(date +%s)

    BINARY_TIME=$(stat -c %Y "$BINARY")
    BINARY_AGE=$((CURRENT_TIME - BINARY_TIME))

    info "The binary is $BINARY_AGE seconds old."

    SCRIPT_TIME=$(stat -c %Y "$SCRIPT")
    SCRIPT_AGE=$((CURRENT_TIME - SCRIPT_TIME))

    info "This script is $SCRIPT_AGE seconds ago."

    if [ "$BINARY_AGE" -lt "$SCRIPT_AGE" ]; then
        info "The binary is newer than the script."
        echo ${CURRENT_TIME} > health_check
        break;
    else
        sleep 3
    fi
done




sleep infinity

