#!/bin/sh
set -e

GITHUB_USER="smpte11"
REPO="dotfiles"

is_container() {
    [ -n "${CODESPACES:-}" ] || [ -n "${REMOTE_CONTAINERS:-}" ] || [ -n "${container:-}" ] || [ -f /.dockerenv ] || [ -f /run/.containerenv ]
}

# Install Homebrew if needed
if ! type brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null)"
fi

# Install chezmoi if needed
if ! type chezmoi >/dev/null 2>&1; then
    echo "Installing chezmoi..."
    brew install chezmoi
fi

if ! type go >/dev/null 2>&1; then
    echo "Installing go..."
    brew intall go
fi

if is_container; then
    # In containers: no SSH key, clone over HTTPS
    chezmoi init --apply "https://github.com/${GITHUB_USER}/${REPO}.git"
else
    # On bare metal: authenticate with GitHub and set up SSH
    if ! type gh >/dev/null 2>&1; then
        echo "Installing GitHub CLI..."
        brew install gh
    fi

    if ! gh auth status >/dev/null 2>&1; then
        echo "Authenticating with GitHub..."
        gh auth login -w -p ssh
    fi

    chezmoi init --apply "git@github.com:${GITHUB_USER}/${REPO}.git"
fi
