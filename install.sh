#!/bin/sh
set -e

GITHUB_USER="smpte11"
REPO="dotfiles"

is_container() {
    [ -n "${CODESPACES:-}" ] || [ -n "${REMOTE_CONTAINERS:-}" ] || [ -n "${container:-}" ] || [ -f /.dockerenv ] || [ -f /run/.containerenv ]
}

# Install mise if needed
if ! type mise >/dev/null 2>&1; then
    echo "Installing mise..."
    curl https://mise.run | sh
fi

# Ensure mise binary and shims are on PATH for this script and chezmoi apply
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# Borrow chezmoi via mise to run the initial apply; the apply writes the global
# mise config (which lists chezmoi in mise_tools) and the after-install hook
# makes it permanent.
if is_container; then
    mise exec chezmoi@latest -- chezmoi init --apply "https://github.com/${GITHUB_USER}/${REPO}.git"
else
    mise exec chezmoi@latest -- chezmoi init --apply "git@github.com:${GITHUB_USER}/${REPO}.git"
fi
