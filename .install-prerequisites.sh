#!/bin/bash

set -ex

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

if command -v filen >/dev/null; then
    echo "Filen is already installed"
else
    curl -sL https://filen.io/cli.sh | bash
fi
