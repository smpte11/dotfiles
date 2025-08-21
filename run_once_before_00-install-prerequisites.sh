#!/bin/bash

set -ex

detect_container() {
    # Docker (rootful)
    if [ -f /.dockerenv ]; then
        return 0
    fi
    # Docker or LXC via cgroup
    if grep -qaE 'docker|lxc' /proc/1/cgroup 2>/dev/null; then
        return 0
    fi
    # Podman (rootful or rootless)
    if [ -f /run/.containerenv ]; then
        return 0
    fi
    # Podman environment variable
    if [ "${container:-}" = "podman" ]; then
        return 0
    fi
    # User namespace (rootless container hint)
    if [ -f /proc/1/uid_map ] && ! grep -qE '^0:0:' /proc/1/uid_map; then
        return 0
    fi
    return 1
}

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
