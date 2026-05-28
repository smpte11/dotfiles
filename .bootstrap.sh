#!/bin/sh
set -e

GITHUB_USER="smpte11"
REPO="dotfiles"

# Install mise if needed
if ! type mise >/dev/null 2>&1; then
    echo "Installing mise..."
    curl https://mise.run | sh
fi

# Ensure mise binary and shims are on PATH for this script and chezmoi apply
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# Borrow gh via mise just for this bootstrap; chezmoi apply will install it
# permanently via mise_tools.
gh() { mise exec gh@latest -- gh "$@"; }

# Authenticate with GitHub (browser-based OAuth, no SSH needed)
if ! gh auth status >/dev/null 2>&1; then
    echo "Authenticating with GitHub..."
    gh auth login
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

# Borrow chezmoi via mise to run the initial apply; the apply itself will write
# the global mise config (which lists chezmoi in mise_tools) and the
# after-install hook will make it permanent.
echo "Initializing chezmoi..."
mise exec chezmoi@latest -- chezmoi init --apply "git@github.com:${GITHUB_USER}/${REPO}.git"
