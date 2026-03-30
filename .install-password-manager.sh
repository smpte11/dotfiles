#!/bin/sh

ONEPASSWORD_HOST="Felixs-MacBook-Pro"

if [ "$(hostname -s 2>/dev/null || hostname)" = "$ONEPASSWORD_HOST" ]; then
    # 1Password CLI
    type op >/dev/null 2>&1 && exit 0

    case "$(uname -s)" in
    Darwin)
        brew install --cask 1password-cli
        ;;
    *)
        echo "unsupported OS for 1password on this host" >&2
        exit 1
        ;;
    esac
else
    # Proton Pass CLI
    type pass-cli >/dev/null 2>&1 && exit 0
    curl -fsSL https://proton.me/download/pass-cli/install.sh | bash
fi
