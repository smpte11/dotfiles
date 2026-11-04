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
*)
    fail "unknown scenario $scenario"
    ;;
esac

step "layout"
[ "$(readlink "$HOME/.config/mise")" = "$dotfiles/home/.config/mise" ] || fail "$HOME/.config/mise is not linked to the checkout"

step "mise dot status"
mise dot status --missing >/dev/null || fail "dotfiles not applied: $(mise dot status)"

git -C "$dotfiles" status --porcelain >"$work/checkout-before"
if [ "$scenario" = fresh ] && [ -s "$work/checkout-before" ]; then
    fail "install wrote into the checkout: $(cat "$work/checkout-before")"
fi
