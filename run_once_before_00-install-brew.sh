#!/bin/bash

set -ex

if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "Running on MacOS"
    HOMEBREW_PREFIX="/opt/homebrew"
else
    echo "Running on Linux"
    HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
fi

if command -v brew >/dev/null; then
    echo "brew is already installed"
else
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    (
        echo
        echo "eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)""
    ) >>"$HOME"/.bashrc
    eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
fi
