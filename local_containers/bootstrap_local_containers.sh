#!/bin/bash

set -e

# The command `podman compose up -d` provides a thin wrapper around either
# `docker-compose` or `podman-compose` (with docker-compose taking
#  precedence if installed). Suppress the warning about this wrapper.
PODMAN_COMPOSE_WARNING_LOGS=false
export PODMAN_COMPOSE_WARNING_LOGS

info() {
    # green color
    echo -e "\033[32m$1\033[0m" >&2
}

start_podman_containers() {
    # Run a rootless API daemon service
    info "Running a rootless API daemon service..."
    SOCK_PATH="${XDG_RUNTIME_DIR}/podman/podman.sock"
    if [ ! -S "$SOCK_PATH" ]; then
        info "Creating a new podman socket..."
        podman system service --time 0 &
    fi

    info "Building and running containers in rootless environment..."
    podman compose up -d
}

start_podman_containers
