#!/bin/sh
set -eu

install_1password() {
    type op >/dev/null 2>&1 && return 0

    case "$(uname -s)" in
    Darwin)
        brew install --cask 1password-cli
        ;;
    *)
        echo "unsupported OS for 1password on this machine" >&2
        exit 1
        ;;
    esac
}

install_proton() {
    PATH="$HOME/.local/bin:$PATH"

    if ! type pass-cli >/dev/null 2>&1; then
        if type jq >/dev/null 2>&1; then
            curl -fsSL https://proton.me/download/pass-cli/install.sh | bash
        else
            curl -fsSL https://proton.me/download/pass-cli/install.sh | mise exec jq@latest -- bash
        fi
    fi

    pass-cli info >/dev/null 2>&1 && return 0

    if [ -t 0 ]; then
        pass-cli login
    else
        echo "pass-cli is not logged in; run 'pass-cli login'" >&2
        exit 1
    fi
}

case "${1:-}" in
1password) install_1password ;;
proton) install_proton ;;
*)
    echo "usage: $0 1password|proton (stale chezmoi config? run 'chezmoi init')" >&2
    exit 1
    ;;
esac
