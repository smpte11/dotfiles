#!/bin/bash

set -ex

detect_container() {
    # Docker (rootful)
    if [ -f /.dockerenv ]; then
        echo ".dockerenv detected"
        return 0
    fi
    # Docker or LXC via cgroup
    if grep -qaE 'docker|lxc' /proc/1/cgroup 2>/dev/null; then
        echo "lxc detected"
        return 0
    fi
    # Podman (rootful or rootless)
    if [ -f /run/.containerenv ]; then
        echo ".containerenv detected"
        return 0
    fi
    # Podman environment variable
    if [ "${container:-}" = "podman" ]; then
        echo "podman env detected"
        return 0
    fi

    # An additional check can be made against /proc/1/cgroup, which often
    # contains "docker" or "kubepods" in a containerized environment.
    # This is another strong indicator.
    if [[ -f /proc/1/cgroup ]] && grep -Eq '/(docker|kubepods)' /proc/1/cgroup; then
        echo "In docker or kubepods"
        return 0 # Success (true)
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
