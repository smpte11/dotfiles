#!/bin/sh
set -eu

repo="${DOTFILES_REPO:-https://github.com/smpte11/dotfiles.git}"
dotfiles="$HOME/.dotfiles"

if ! command -v mise >/dev/null 2>&1; then
    curl -fsSL https://mise.run | sh
fi
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

if [ ! -d "$dotfiles" ]; then
    git clone "$repo" "$dotfiles"
fi

exec "$dotfiles/home/.local/bin/dotfiles-setup" --force-dotfiles "$@"
