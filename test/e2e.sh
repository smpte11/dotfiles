#!/usr/bin/env bash
set -euo pipefail
umask 022

scenario=$1
modules=${2:-}
bootstrap_args=(--skip services --skip final-hook)

dotfiles=$HOME/.dotfiles
origin=/tmp/origin
work=/tmp/e2e
mkdir -p "$work"
local_files=(
    .config/nvim/plugin/42_local.lua
    .config/zk/templates/local-journal.md
)
parity_targets=(
    .config/ghostty/themes/active-theme
    .config/helix/languages.toml
    .config/helix/themes/active-theme.toml
    .config/television/themes/active-theme.toml
    .config/tuios/config.toml
    .config/k9s/skins/active-theme.yaml
    .local/share/claude-lsp/.claude-plugin/marketplace.json
    .local/share/claude-lsp/plugins/elixir-lsp/.claude-plugin/plugin.json
)

fail() { echo "FAIL: $*" >&2; exit 1; }
step() { echo "--- $*"; }
has_module() { case ",$modules," in *",$1,"*) return 0 ;; esac; return 1; }

snapshot() {
    mkdir -p "$2"
    rsync -a --exclude=/.git --exclude=/.jj "$1/" "$2/"
}

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

mise_targets() {
    mise dot status --json | jq -r '(.files[] | .target), (.edits[] | .path)' | sed "s|^~|$HOME|"
}

owned_by_mise() {
    case "$(readlink "$1" 2>/dev/null)" in "$dotfiles"/*) return 0 ;; esac
    case "$(realpath "$1" 2>/dev/null)" in "$dotfiles"/*) return 0 ;; esac
    grep -qxF "$1" "$work/mise-targets"
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
mise_targets >"$work/mise-targets"

step "local files kept"
for f in "${local_files[@]}"; do
    [ "$(cat "$HOME/$f" 2>/dev/null)" = "-- local $f" ] || fail "$HOME/$f was changed or removed"
done

if [ "$scenario" = migrate ]; then
    step "no chezmoi leftovers"
    leftovers=""
    while IFS= read -r path; do
        [ "$path" = "$HOME/.local/bin/mise" ] && continue
        [ -f "$path" ] || [ -L "$path" ] || continue
        owned_by_mise "$path" || leftovers+="$path"$'\n'
    done < <(jq -r '.entryState | to_entries[] | select(.value.type == "file") | .key' "$work/chezmoi-state.json")
    while IFS= read -r path; do
        [ -L "$path" ] || continue
        owned_by_mise "$path" || leftovers+="$path"$'\n'
    done < <(jq -r '.entryState | to_entries[] | select(.value.type == "symlink") | .key' "$work/chezmoi-state.json")
    [ -z "$leftovers" ] || fail "left behind by chezmoi: $leftovers"

    step "templates render like chezmoi did"
    for f in "${parity_targets[@]}"; do
        [ -f "$work/parity/$f" ] || continue
        cmp -s "$work/parity/$f" "$HOME/$f" || fail "$f differs from the chezmoi render: $(diff "$work/parity/$f" "$HOME/$f")"
    done
fi

step "idempotent"
git -C "$dotfiles" status --porcelain >"$work/checkout-before"
if [ "$scenario" = fresh ] && [ -s "$work/checkout-before" ]; then
    fail "install wrote into the checkout: $(cat "$work/checkout-before")"
fi
mise bootstrap --yes "${bootstrap_args[@]}" >/dev/null
mise dot status --missing >/dev/null || fail "dotfiles drifted after a second bootstrap"
git -C "$dotfiles" status --porcelain >"$work/checkout-after"
cmp -s "$work/checkout-before" "$work/checkout-after" || fail "bootstrap wrote into the checkout: $(diff "$work/checkout-before" "$work/checkout-after")"

step "services"
(
    stub_systemd
    mise bootstrap services apply --yes >/dev/null
    mise bootstrap --only linux-systemd-units --yes >/dev/null
)
if [ -d "$HOME/.config/systemd/user" ] && grep -rnE '\{\{|~/' "$HOME/.config/systemd/user"; then
    fail "unexpanded syntax in the systemd user units"
fi
if has_module personal; then
    [ -s "$HOME/.config/systemd/user/dev.mise.proton-pass-ssh-agent.service" ] || fail "the proton ssh agent unit is missing"
    [ -x "$HOME/.local/bin/proton-pass-ssh-agent" ] || fail "the proton ssh agent wrapper is not executable"
fi

step "theme switch"
before=$(cat "$HOME/.config/ghostty/themes/active-theme")
mise run theme:switch tokyonight >/dev/null
[ "$(cat "$HOME/.config/ghostty/themes/active-theme")" != "$before" ] || fail "ghostty theme did not change"
grep -q 'colorscheme tokyonight' "$HOME/.config/nvim/plugin/25_theme.lua" || fail "nvim theme did not change"
theme_file=$dotfiles/home/.config/mise/conf.d/theme.toml
grep -qx 'theme = "tokyonight"' "$theme_file" || fail "the theme choice was not written to $theme_file"
[ "$(mise dot history --path "$theme_file" --json | jq length)" -ge 1 ] || fail "no checkpoint saved for $theme_file"
mise dot rollback "$theme_file" --yes >/dev/null
[ "$(cat "$HOME/.config/ghostty/themes/active-theme")" = "$before" ] || fail "ghostty theme did not switch back after the rollback"

step "history"
tracked=$(mise dot paths --json | jq -r '.entries[] | select(.mode == "track") | .path | ltrimstr("~/.dotfiles/")')
for p in \
    home/.zshrc \
    home/.bashrc \
    home/.zshenv \
    home/.config/mise/themes.toml \
    home/.config/mise/conf.d/theme.toml \
    home/.config/ghostty/themes/active-theme.tera; do
    grep -qxF -- "$p" <<<"$tracked" || fail "$p is not tracked"
done
if has_module work; then
    grep -qxF "work/.config/k9s/skins/active-theme.yaml.tera" <<<"$tracked" || fail "the k9s skin template is not tracked"
fi
history_file=$dotfiles/home/.zshrc
history_before=$(cat "$history_file")
mise dot save >/dev/null
echo "# e2e history edit" >>"$history_file"
mise dot save >/dev/null
[ "$(mise dot history --path "$history_file" --json | jq length)" -ge 1 ] || fail "no checkpoint saved for $history_file"
mise dot rollback "$history_file" --yes >/dev/null
[ "$(cat "$history_file")" = "$history_before" ] || fail "rollback did not restore $history_file"

step "smoke"
zsh -i -c exit || fail "zsh does not start"
reshim_err=$(mise reshim 2>&1 >/dev/null) || true
[ -z "$reshim_err" ] || fail "mise reshim warns about unusable tool executables: $reshim_err"
pi --version >/dev/null 2>&1 || fail "pi is not runnable through its mise shim"
tv list-channels | grep -qx alias || fail "television does not load the cable channels"
hx --health 2>&1 | grep -q "Config file: $HOME/.config/helix/config.toml" || fail "helix does not find its config"
nvim --headless +qa >/dev/null 2>&1 || fail "nvim fails to install its plugins"
nvim_errors=$(nvim --headless +qa 2>&1 >/dev/null) || fail "nvim exits with an error: $nvim_errors"
[ -z "$nvim_errors" ] || fail "nvim reports errors: $nvim_errors"
if grep -rlE '\{\{|\{%' "$HOME/.config/ghostty/themes" "$HOME/.config/nvim/plugin/25_theme.lua" "$HOME/.config/tuios/config.toml"; then
    fail "unrendered template syntax"
fi

expected_email=felix@brouss.eu
expected_harness=pi
if has_module work; then
    expected_email=felix.brousseau-tremblay@kivra.com
    expected_harness=claude
fi
[ "$(jj config get user.email)" = "$expected_email" ] || fail "jj user.email is not $expected_email"
[ "$(mise env --json | jq -r .FM_HARNESS)" = "$expected_harness" ] || fail "FM_HARNESS is not $expected_harness"

if has_module ssh || has_module personal || has_module work; then
    [ -L "$HOME/.ssh/config" ] || fail "the ssh config is not deployed"
    ssh -G personalgit | grep -qx 'hostname github.com' || fail "ssh does not know personalgit"
    [ -s "$HOME/.ssh/personal.pub" ] || fail "personal.pub is missing"
    [ "$(stat -c %a "$HOME/.ssh")" = 700 ] || fail "$HOME/.ssh is not 0700"
else
    [ ! -e "$HOME/.ssh/config" ] || fail "an ssh config was deployed without the ssh module"
fi
if mise ls --current --json | jq -e 'has("github:Gaurav-Gosain/tuios")' >/dev/null; then
    fail "upstream tuios is installed as a mise tool and would shadow the fork"
fi
if has_module personal; then
    ssh -G personalgit | grep -qx "identityagent $HOME/.ssh/proton-pass-agent.sock" || fail "personal ssh agent is not proton"
    signing_key=$(jj config get signing.key)
    [ "${signing_key#\~/}" = .ssh/personal.pub ] || fail "jj does not sign with the personal key"
    if ssh -G workgit | grep -qx 'hostname github.com'; then fail "workgit is configured on a personal machine"; fi
fi
if has_module work; then
    ssh -G workgit | grep -qx 'hostname github.com' || fail "ssh does not know workgit"
    ssh -G workgit | grep -qx "identityagent $HOME/.1password/agent.sock" || fail "work ssh agent is not 1password"
    [ "$(jj config get signing.backends.ssh.program)" = /opt/1Password/op-ssh-sign ] || fail "jj does not sign with op-ssh-sign"
    [ -s "$HOME/.config/k9s/skins/active-theme.yaml" ] || fail "k9s skin is missing"
    [ -L "$HOME/.claude/keybindings.json" ] || fail "claude keybindings are missing"
fi

if [ "$scenario" = fresh ] && has_module personal; then
    step "switch from personal to work"
    (
        stub_systemd
        DOTFILES_ENV=work "$HOME/.local/bin/dotfiles-setup" "${bootstrap_args[@]}" >/dev/null
    )
    ssh -G workgit | grep -qx "identityagent $HOME/.1password/agent.sock" || fail "the ssh agent is not 1password after the switch"
    grep -q 1password "$HOME/.ssh/config.d/agent" || fail "config.d/agent does not point to 1password"
    [ ! -e "$HOME/.config/systemd/user/dev.mise.proton-pass-ssh-agent.service" ] || fail "the proton unit remains after the switch"
    [ ! -e "$HOME/.local/bin/proton-pass-ssh-agent" ] || fail "the proton wrapper remains after the switch"
    [ -L "$HOME/.ssh/config" ] || fail "the ssh config was pruned by the switch"
    [ "$(stat -c %a "$HOME/.ssh")" = 700 ] || fail "$HOME/.ssh is not 0700 after the switch"
    grep -qx 'env = \["work","ssh"\]' "$dotfiles/home/.config/mise/miserc.local.toml" || fail "the modules are not work and ssh after the switch"
fi

echo "PASS: $scenario ${modules:-none}"
