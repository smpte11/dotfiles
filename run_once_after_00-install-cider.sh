#!/bin/bash

set -eou pipefail

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

if detect_container; then
    echo "Running in a container! No need for this..."
else
    if [[ "$(uname)" = "Darwin" ]]; then
        echo "No need for Cider on MacOS"
    else
        if ! command -v jq >/dev/null; then
            echo "JQ should be installed. Aborting..."
            exit 1
        fi

        if [[ "$(bw status --raw | jq -r .status)" == "unauthenticated" ]]; then
            bw login
        fi

        if [[ -z "${BW_SESSION:-}" ]]; then
            BW_SESSION="$(bw unlock --raw)"
            export BW_SESSION
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
