#!/usr/bin/env bash
. "$(dirname "$0")/lib.sh"

make_origin() {
    snapshot /src "$origin"
    git -C "$origin" init --quiet
    git -C "$origin" add -A
    git -C "$origin" -c user.name=test -c user.email=test@example.com commit --quiet -m snapshot
}

plant_local_files() {
    for f in "${local_files[@]}"; do
        mkdir -p "$HOME/$(dirname "$f")"
        echo "-- local $f" >"$HOME/$f"
    done
}

make_origin

case "$scenario" in
fresh)
    plant_local_files
    step "install with modules: ${modules:-none}"
    DOTFILES_REPO=$origin DOTFILES_ENV=$modules sh /src/install.sh "${bootstrap_args[@]}"
    ;;
migrate)
    step "apply chezmoi base revision as $modules"
    snapshot /base "$HOME/.local/share/chezmoi"
    git -C "$HOME/.local/share/chezmoi" init --quiet
    git -C "$HOME/.local/share/chezmoi" remote add origin "$origin"
    DOTFILES_PROFILE=$modules mise exec chezmoi@latest -- chezmoi init --apply
    : >"$work/empty.toml"
    mise exec chezmoi@latest -- chezmoi --config "$work/empty.toml" state dump >"$work/chezmoi-state.json"
    for f in "${parity_targets[@]}"; do
        if [ -f "$HOME/$f" ]; then
            mkdir -p "$work/parity/$(dirname "$f")"
            sed '/^# k9s skin generated from chezmoi/d' "$HOME/$f" >"$work/parity/$f"
        fi
    done
    plant_local_files
    step "pull the mise layout and migrate"
    find "$HOME/.local/share/chezmoi" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
    snapshot /src "$HOME/.local/share/chezmoi"
    "$HOME/.local/share/chezmoi/migrate-from-chezmoi.sh" "${bootstrap_args[@]}"
    ;;
*)
    fail "unknown scenario $scenario"
    ;;
esac

step "layout"
[ "$(readlink "$HOME/.config/mise")" = "$dotfiles/home/.config/mise" ] || fail "$HOME/.config/mise is not linked to the checkout"
[ ! -e "$HOME/.local/share/chezmoi" ] || fail "the chezmoi checkout is still there"
[ ! -e "$HOME/.config/chezmoi" ] || fail "chezmoi state is still there"

step "mise dot status"
mise dot status --missing >/dev/null || fail "dotfiles not applied: $(mise dot status)"
mise dot status --json | jq -r '(.files[] | .target), (.edits[] | .path)' | sed "s|^~|$HOME|" >"$work/mise-targets"

git -C "$dotfiles" status --porcelain >"$work/checkout-before"
if [ "$scenario" = fresh ] && [ -s "$work/checkout-before" ]; then
    fail "install wrote into the checkout: $(cat "$work/checkout-before")"
fi
