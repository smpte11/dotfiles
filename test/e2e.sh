#!/usr/bin/env bash
set -euo pipefail
umask 022

chezmoi() { mise exec chezmoi@latest -- chezmoi "$@"; }
fail() { echo "FAIL: $*" >&2; exit 1; }
step() { echo "--- $*"; }

chezmoi_targets() { chezmoi managed -p absolute | sort; }
mise_targets() { mise dot status --json | jq -r '(.files[], .edits[]) | .target // empty' | sed "s|^~|$HOME|" | sort; }

owned_by_mise() {
    local path=$1 target
    while read -r target; do
        [ -n "$target" ] || continue
        case "$path" in "$target" | "$target"/*) return 0 ;; esac
    done <<<"$mise_owned"
    return 1
}

source_dir=$HOME/.local/share/chezmoi

checkout() {
    mkdir -p "$source_dir"
    find "$source_dir" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
    tar -C "$1" --exclude=./.git --exclude=./.jj -cf - . | tar -C "$source_dir" -xf -
    git -C "$source_dir" init --quiet
}

if [ -d /base ]; then
    step "apply base revision"
    checkout /base
    chezmoi init --apply
    chezmoi_targets >/tmp/base-managed
else
    : >/tmp/base-managed
fi

step "upgrade to working copy"
checkout /src
chezmoi init --apply

step "chezmoi verify"
chezmoi verify || fail "chezmoi target state differs"

step "mise dot status"
mise dot status --missing >/dev/null || fail "mise dotfiles not applied: $(mise dot status)"

step "single owner"
mise_owned=$(mise_targets)
both=$(comm -12 <(chezmoi_targets) <(echo "$mise_owned" | sed '/^$/d'))
[ -z "$both" ] || fail "managed by chezmoi and mise: $both"

step "no orphans"
orphans=""
while read -r path; do
    owned_by_mise "$path" && continue
    if [ -e "$path" ] || [ -L "$path" ]; then
        orphans+="$path"$'\n'
    fi
done < <(comm -23 /tmp/base-managed <(chezmoi_targets))
[ -z "$orphans" ] || fail "left behind by chezmoi: $orphans"

step "idempotent"
[ -z "$(chezmoi diff)" ] || fail "second chezmoi apply would change: $(chezmoi diff)"
chezmoi apply
mise dot status --missing >/dev/null || fail "mise dotfiles drifted after a second apply"

step "smoke"
zsh -i -c exit || fail "zsh does not start"
expected=$(chezmoi execute-template '{{ (index .identities .profile).email }}')
[ "$(jj config get user.email)" = "$expected" ] || fail "jj user.email is not $expected"
tv list-channels | grep -qx alias || fail "television does not load the cable channels"

echo "PASS: $DOTFILES_PROFILE"
