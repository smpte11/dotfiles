#!/bin/sh
set -e

GITHUB_USER="smpte11"
REPO="dotfiles"

# Install Homebrew if needed
if ! type brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null)"
fi

# Install GitHub CLI if needed
if ! type gh >/dev/null 2>&1; then
    echo "Installing GitHub CLI..."
    brew install gh
fi

# Authenticate with GitHub (browser-based OAuth, no SSH needed)
if ! gh auth status >/dev/null 2>&1; then
    echo "Authenticating with GitHub..."
    gh auth login --web --git-protocol ssh
fi

# Generate and upload SSH key if needed
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
    echo "Generating SSH key..."
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N ""
    echo "Uploading SSH key to GitHub..."
    gh ssh-key add "$SSH_KEY.pub" --title "$(hostname) $(date +%Y-%m-%d)"
fi

# Initialize chezmoi
if ! type chezmoi >/dev/null 2>&1; then
    echo "Installing chezmoi..."
    brew install chezmoi
fi

echo "Initializing chezmoi..."
chezmoi init --apply "git@github.com:${GITHUB_USER}/${REPO}.git"
