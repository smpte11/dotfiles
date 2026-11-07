#!/usr/bin/env bash
set -euo pipefail
umask 022

scenario=$1
modules=${2:-}
bootstrap_args=(--skip services --skip task)

dotfiles=$HOME/.dotfiles
origin=/tmp/origin
work=/tmp/e2e
mkdir -p "$work"
local_files=(
    .config/nvim/plugin/42_local.lua
    .config/zk/templates/local-journal.md
)

fail() { echo "FAIL: $*" >&2; exit 1; }
step() { echo "--- $*"; }
has_module() { case ",$modules," in *",$1,"*) return 0 ;; esac; return 1; }
has_identity() { has_module ssh || has_module base || has_module work; }

snapshot() {
    mkdir -p "$2"
    rsync -a --exclude=/.git --exclude=/.jj "$1/" "$2/"
}

stub_systemd() {
    mkdir -p "$work/stubs" "$work/runtime/systemd"
    cat >"$work/stubs/systemctl" <<'STUB'
#!/bin/sh
case " $* " in
*" is-enabled "*) echo enabled ;;
*" is-active "*) echo active ;;
esac
exit 0
STUB
    chmod +x "$work/stubs/systemctl"
    : >"$work/runtime/bus"
    export PATH="$work/stubs:$PATH" XDG_RUNTIME_DIR="$work/runtime"
}
