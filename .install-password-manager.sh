#!/bin/sh

CONFIG_FILE="${CHEZMOI_CONFIG_FILE:-$HOME/.config/chezmoi/chezmoi.toml}"

case "$(grep -s '^[[:space:]]*email[[:space:]]*=' "$CONFIG_FILE")" in
*@kivra.com*)
    type op >/dev/null 2>&1 && exit 0

    case "$(uname -s)" in
    Darwin)
        brew install --cask 1password-cli
        ;;
    *)
        echo "unsupported OS for 1password on this machine" >&2
        exit 1
        ;;
    esac
    ;;
*)
    type pass-cli >/dev/null 2>&1 && exit 0
    curl -fsSL https://proton.me/download/pass-cli/install.sh | bash
    ;;
esac
