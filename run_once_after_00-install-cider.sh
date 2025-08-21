#!/bin/bash

set -eou pipefail

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

if detect_container; then
    echo "Running in a container! No need for this..."
else
    if [[ "$(uname)" = "Darwin" ]]; then
        echo "No need for Cider on MacOS"
    else
        bw login >/dev/null 2>&1 || echo "Already logged in to BW"

        if [[ -z "${BW_SESSION:-}" ]]; then
            BW_SESSION="$(bw unlock --raw)"
            export BW_SESSION
        fi

        if ! command -v jq >/dev/null; then
            echo "JQ should be installed. Aborting..."
            exit 1
        fi

        FILENAME="cider-v3.0.2-linux-x64.AppImage"

        echo "Fetching from Bitwarden Filen credentials..."
        FILEN_USERNAME="$(bw get item Filen | jq -r ".login.username")"
        FILEN_PASSWORD="$(bw get item Filen | jq -r ".login.password")"

        if [[ -z $FILEN_USERNAME || -z $FILEN_PASSWORD ]]; then
            echo "Could not retrieve username or password"
            exit 1
        fi

        echo "Downloading from Filen..."
        filen --email "$FILEN_USERNAME" --password "$FILEN_PASSWORD" --two-factor-code "$(bw get totp Filen)" download "$FILENAME" /tmp/

        echo "Integrate with Gear Lever..."
        flatpak run it.mijorus.gearlever --integrate /tmp/$FILENAME

        echo "Done"
    fi
fi
