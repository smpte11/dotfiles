#!/usr/bin/env bash
set -euo pipefail
umask 022

chezmoi() { mise exec chezmoi@latest -- chezmoi "$@"; }
fail() { echo "FAIL: $*" >&2; exit 1; }
step() { echo "--- $*"; }

source_dir=$HOME/.local/share/chezmoi
mise_home=$source_dir/home
local_files=(
    .config/nvim/plugin/42_local.lua
    .config/zk/templates/local-journal.md
)

chezmoi_files() { chezmoi managed -i files,symlinks -p absolute | sort; }
owned_by_mise() { [ -e "$mise_home/${1#"$HOME"/}" ] || [ -L "$mise_home/${1#"$HOME"/}" ]; }

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
    chezmoi_files >/tmp/base-managed
else
    : >/tmp/base-managed
fi

for f in "${local_files[@]}"; do
    mkdir -p "$HOME/$(dirname "$f")"
    echo "-- local $f" >"$HOME/$f"
done

step "upgrade to working copy"
checkout /src
chezmoi init --apply

step "chezmoi verify"
chezmoi verify || fail "chezmoi target state differs"

step "mise dot status"
mise dot status --missing >/dev/null || fail "mise dotfiles not applied: $(mise dot status)"

step "every file in home/ is deployed"
while read -r f; do
    rel=${f#"$mise_home"/}
    [ "$(readlink -f "$HOME/$rel")" = "$(readlink -f "$f")" ] || fail "$HOME/$rel does not link to $f"
    if [ -L "$HOME/$rel" ] && [ "$(readlink "$HOME/$rel")" != "$f" ]; then
        fail "$HOME/$rel is a symlink to $(readlink "$HOME/$rel"), not to $f"
    fi
done < <(find "$mise_home" \( -type f -o -type l \))

step "single owner"
both=""
while read -r path; do
    if owned_by_mise "$path"; then both+="$path"$'\n'; fi
done < <(chezmoi_files)
[ -z "$both" ] || fail "managed by chezmoi and mise: $both"

step "no orphans"
orphans=""
while read -r path; do
    owned_by_mise "$path" && continue
    if [ -e "$path" ] || [ -L "$path" ]; then orphans+="$path"$'\n'; fi
done < <(comm -23 /tmp/base-managed <(chezmoi_files))
[ -z "$orphans" ] || fail "left behind by chezmoi: $orphans"

step "local files kept"
for f in "${local_files[@]}"; do
    [ "$(cat "$HOME/$f" 2>/dev/null)" = "-- local $f" ] || fail "$HOME/$f was changed or removed"
done

step "idempotent"
[ -z "$(chezmoi diff)" ] || fail "second chezmoi apply would change: $(chezmoi diff)"
chezmoi apply
mise dot status --missing >/dev/null || fail "mise dotfiles drifted after a second apply"

step "smoke"
zsh -i -c exit || fail "zsh does not start"
expected=$(chezmoi execute-template '{{ (index .identities .profile).email }}')
[ "$(jj config get user.email)" = "$expected" ] || fail "jj user.email is not $expected"
tv list-channels | grep -qx alias || fail "television does not load the cable channels"
hx --health 2>&1 | grep -q "Config file: $HOME/.config/helix/config.toml" || fail "helix does not find its config"
[ -x "$HOME/.local/bin/fork-sync" ] || fail "fork-sync is not executable"
nvim --headless +qa >/dev/null 2>&1 || fail "nvim fails to install its plugins"
nvim_errors=$(nvim --headless +qa 2>&1 >/dev/null) || fail "nvim exits with an error: $nvim_errors"
[ -z "$nvim_errors" ] || fail "nvim reports errors: $nvim_errors"

echo "PASS: $DOTFILES_PROFILE"
