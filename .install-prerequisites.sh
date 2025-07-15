#!/bin/bash

set -ex

# Detect if running in a container (rootful or rootless)
detect_container() {
    # Docker (rootful)
    if [ -f /.dockerenv ]; then
        echo "Detected: Docker (rootful) container"
        return 0
    fi
    # Docker or LXC via cgroup
    if grep -qaE 'docker|lxc' /proc/1/cgroup 2>/dev/null; then
        echo "Detected: Docker or LXC container"
        return 0
    fi
    # Podman (rootful or rootless)
    if [ -f /run/.containerenv ]; then
        if [ "$container" = "podman" ]; then
            echo "Detected: Podman (rootful or rootless) container"
        else
            echo "Detected: Generic OCI container"
        fi
        return 0
    fi
    # Podman environment variable
    if [ "$container" = "podman" ]; then
        echo "Detected: Podman container (via env)"
        return 0
    fi
    # User namespace (rootless container hint)
    if [ -f /proc/1/uid_map ] && ! grep -qE '^0:0:' /proc/1/uid_map; then
        echo "Detected: Possibly rootless container (user namespace)"
        return 0
    fi
    echo "No container detected"
    return 1
}

# Call the detection function
detect_container

if command -v brew >/dev/null; then
    echo "brew is already installed"
else
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if command -v bw >/dev/null; then
    echo "bitwarden-cli already installed"
else
    brew install bitwarden-cli
fi

if command -v gh >/dev/null; then
    echo "GitHub CLI is already installed"
else
    brew install gh
fi

if detect_container; then
    echo "In a container! No need for Filen here..."
else
    if command -v filen >/dev/null; then
        echo "Filen is already installed"
    else
        curl -sL https://filen.io/cli.sh | bash
    fi
fi
