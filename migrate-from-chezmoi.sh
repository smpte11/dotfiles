#!/usr/bin/env bash
set -euo pipefail

old="$HOME/.local/share/chezmoi"
dotfiles="$HOME/.dotfiles"
chezmoi_config="$HOME/.config/chezmoi"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

fail() { echo "migrate: $*" >&2; exit 1; }
note() { echo "migrate: $*"; }
chezmoi() { mise exec chezmoi@latest -- chezmoi "$@"; }

chezmoi_data() { sed -n "s/^ *$1 = \"\{0,1\}\([^\"]*\)\"\{0,1\}$/\1/p" "$chezmoi_config/chezmoi.toml" | head -n 1; }

modules_from_chezmoi() {
    [ "$(chezmoi_data configured)" = true ] || return 0
    if [ "$(chezmoi_data password_manager)" = none ]; then
        chezmoi_data profile
    else
        echo "$(chezmoi_data profile),desktop"
    fi
}

written_by_chezmoi() {
    jq -r --arg type "$1" '.entryState | to_entries[] | select(.value.type == $type) | .key' "$work/state.json"
}

chezmoi_hash() {
    jq -r --arg path "$1" '.entryState[$path].contentsSHA256 // empty' "$work/state.json"
}

sha256() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1
}

mise_targets() {
    mise dot status --json | jq -r '(.files[] | .target), (.edits[] | .path)' | sed "s|^~|$HOME|"
}

owned_by_mise() {
    case "$(readlink "$1" 2>/dev/null)" in "$dotfiles"/*) return 0 ;; esac
    case "$(realpath "$1" 2>/dev/null)" in "$dotfiles"/*) return 0 ;; esac
    grep -qxF "$1" "$work/mise-targets"
}

unload_old_services() {
    if [ "$(uname -s)" = Darwin ]; then
        for label in com.felbro.journal com.felbro.proton-pass-ssh-agent; do
            launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
        done
    elif [ -d /run/systemd/system ]; then
        systemctl --user disable --now journal-reminder.timer proton-pass-ssh-agent.service 2>/dev/null || true
    fi
}

retire_mise_config() {
    local config="$HOME/.config/mise" file hash
    [ -L "$config" ] && return 0
    [ -d "$config" ] || return 0
    while IFS= read -r -d '' file; do
        hash=$(chezmoi_hash "$file")
        if [ -z "$hash" ] || [ "$hash" != "$(sha256 "$file")" ]; then
            mv "$config" "$config.pre-migration"
            note "kept your own files in $config.pre-migration; merge them into $dotfiles/home/.config/mise and delete it"
            return 0
        fi
    done < <(find "$config" -type f -print0)
    rm -rf "$config"
}

repair_worktrees() {
    local git_file
    while IFS= read -r -d '' git_file; do
        git -C "$(dirname "$git_file")" worktree repair >/dev/null 2>&1 ||
            note "could not repair the git worktree in $(dirname "$git_file")"
    done < <(find "$1" -name .git -type f -print0)
}

remove_chezmoi_symlinks() {
    local path target
    while IFS= read -r path; do
        [ -L "$path" ] || continue
        target=$(realpath "$path" 2>/dev/null || true)
        case "$target" in "$dotfiles"/* | "$old"/*) rm "$path"; continue ;; esac
        rm "$path"
        if [ -d "$target" ]; then
            mv "$target" "$path"
            repair_worktrees "$path"
            note "moved $target to $path"
        fi
    done < <(written_by_chezmoi symlink)
}

remove_chezmoi_files() {
    local path hash
    while IFS= read -r path; do
        [ "$path" = "$HOME/.local/bin/mise" ] && continue
        { [ -e "$path" ] || [ -L "$path" ]; } || continue
        owned_by_mise "$path" && continue
        hash=$(chezmoi_hash "$path")
        if [ -f "$path" ] && [ ! -L "$path" ] && [ "$hash" = "$(sha256 "$path")" ]; then
            rm "$path"
        else
            note "kept $path: it changed after chezmoi wrote it"
        fi
    done < <(written_by_chezmoi file)
    while IFS= read -r path; do
        rmdir "$path" 2>/dev/null || true
    done < <(written_by_chezmoi dir | sort -r)
}

[ -d "$chezmoi_config" ] || fail "no chezmoi configuration in $chezmoi_config; nothing to migrate"
[ -d "$old/home/.config/mise" ] || [ -d "$dotfiles/home/.config/mise" ] ||
    fail "update $old to the mise layout first (jj git fetch && jj rebase -d 'trunk()')"
command -v jq >/dev/null 2>&1 || jq() { mise exec jq@latest -- jq "$@"; }

modules="${DOTFILES_ENV-$(modules_from_chezmoi)}"
: >"$work/chezmoi.toml"
chezmoi --config "$work/chezmoi.toml" --persistent-state "$chezmoi_config/chezmoistate.boltdb" state dump >"$work/state.json"

unload_old_services
if [ -f "$HOME/.config/mise/conf.d/dotfiles.toml" ]; then
    mise dot unapply --yes --force
fi
remove_chezmoi_symlinks
if [ -d "$old" ] && [ ! -e "$dotfiles" ]; then
    mv "$old" "$dotfiles"
fi
retire_mise_config

DOTFILES_ENV="$modules" "$dotfiles/home/.local/bin/dotfiles-setup" --force-dotfiles "$@"

mise_targets >"$work/mise-targets"
remove_chezmoi_files
if [ "$(uname -s)" != Darwin ] && [ -d /run/systemd/system ]; then
    systemctl --user daemon-reload
fi

rm -rf "$chezmoi_config" "$HOME/.cache/chezmoi"
mise uninstall --all chezmoi >/dev/null 2>&1 || true
note "done; modules: ${modules:-none}"
