#!/usr/bin/env bash
groups=(local-files idempotent services secrets theme history smoke tools media identity tuios switch picker)
if [ "${1:-}" = groups ]; then
    printf '%s\n' "${groups[@]}"
    exit 0
fi

. "$(dirname "$0")/lib.sh"
group=$3
skip=77

make_forks() {
    local forks=$work/forks
    git init --quiet --bare "$forks/firstmate.git"
    git init --quiet --bare "$forks/tuios.git"
    git init --quiet "$work/tuios-src"
    mkdir -p "$work/tuios-src/cmd/tuios"
    printf 'module example.com/tuios\n\ngo 1.22\n' >"$work/tuios-src/go.mod"
    printf 'package main\n\nimport "fmt"\n\nvar version string\n\nfunc main() { fmt.Println(version) }\n' >"$work/tuios-src/cmd/tuios/main.go"
    git -C "$work/tuios-src" add -A
    git -C "$work/tuios-src" -c user.name=test -c user.email=test@example.com commit --quiet -m fork
    git -C "$work/tuios-src" push --quiet "$forks/tuios.git" HEAD:main HEAD:fm-combined
    git -C "$work/tuios-src" push --quiet "$forks/firstmate.git" HEAD:main
    export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.$forks/.insteadOf" GIT_CONFIG_VALUE_0="https://github.com/smpte11/"
}

check_local_files() {
    for f in "${local_files[@]}"; do
        [ "$(cat "$HOME/$f" 2>/dev/null)" = "-- local $f" ] || fail "$HOME/$f was changed or removed"
    done
}

check_idempotent() {
    mise bootstrap --yes "${bootstrap_args[@]}" >/dev/null
    mise dot status --missing >/dev/null || fail "dotfiles drifted after a second bootstrap"
    git -C "$dotfiles" status --porcelain >"$work/checkout-after"
    cmp -s "$work/checkout-before" "$work/checkout-after" || fail "bootstrap wrote into the checkout: $(diff "$work/checkout-before" "$work/checkout-after")"
}

check_services() {
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
}

check_secrets() {
    has_module personal || return $skip
    local codestral=$HOME/.config/codestral/env status_output
    [ -f "$codestral" ] && [ ! -s "$codestral" ] || fail "$codestral is not an empty file without a key"
    rm "$codestral"
    status_output=$(CODESTRAL_API_KEY=e2e-secret mise dot status --verbose 2>&1)
    if grep -q e2e-secret <<<"$status_output"; then fail "mise dot status prints the codestral key"; fi
    CODESTRAL_API_KEY=e2e-secret mise dot apply --yes >/dev/null
    [ "$(cat "$codestral")" = CODESTRAL_API_KEY=e2e-secret ] || fail "$codestral does not hold the key"
    [ "$(stat -c %a "$codestral")" = 600 ] || fail "$codestral is not 0600"
    [ "$(mise env --json | jq -r .CODESTRAL_API_KEY)" = e2e-secret ] || fail "mise env does not load the codestral key"
    mise bootstrap --yes "${bootstrap_args[@]}" >/dev/null || fail "bootstrap fails without the key in the environment"
}

check_theme() {
    local before theme_file=$dotfiles/home/.config/mise/conf.d/theme.toml
    before=$(cat "$HOME/.config/ghostty/themes/active-theme")
    mise run theme:switch tokyonight >/dev/null
    [ "$(cat "$HOME/.config/ghostty/themes/active-theme")" != "$before" ] || fail "ghostty theme did not change"
    grep -q 'colorscheme tokyonight' "$HOME/.config/nvim/plugin/25_theme.lua" || fail "nvim theme did not change"
    grep -qx 'theme = "tokyonight"' "$theme_file" || fail "the theme choice was not written to $theme_file"
    [ "$(mise dot history --path "$theme_file" --json | jq length)" -ge 1 ] || fail "no checkpoint saved for $theme_file"
    mise dot rollback "$theme_file" --yes >/dev/null
    [ "$(cat "$HOME/.config/ghostty/themes/active-theme")" = "$before" ] || fail "ghostty theme did not switch back after the rollback"
}

check_history() {
    local tracked
    tracked=$(mise dot paths --json | jq -r '.entries[] | select(.mode == "track") | .path | ltrimstr("~/.dotfiles/")')
    [ "$tracked" = home/.config/mise/conf.d/theme.toml ] || fail "history tracks more than the theme choice: $tracked"
}

check_smoke() {
    local reshim_err login_jq nvim_errors
    zsh -i -c exit || fail "zsh does not start"
    reshim_err=$(mise reshim 2>&1 >/dev/null) || true
    [ -z "$reshim_err" ] || fail "mise reshim warns about unusable tool executables: $reshim_err"
    pi --version >/dev/null 2>&1 || fail "pi is not runnable through its mise shim"
    moor --version >/dev/null 2>&1 || fail "moor, the jj pager, is not runnable through its mise shim"
    login_jq=$(env -i HOME="$HOME" PATH=/usr/bin:/bin zsh -l -c 'command -v jq') || fail "a zsh login shell does not find jq"
    [ "$login_jq" = "$HOME/.local/share/mise/shims/jq" ] || fail "a zsh login shell does not use the mise shims: $login_jq"
    tv list-channels | grep -qx alias || fail "television does not load the cable channels"
    if has_module desktop; then
        hx --health 2>&1 | grep -q "Config file: $HOME/.config/helix/config.toml" || fail "helix does not find its config"
    fi
    nvim --headless +qa >/dev/null 2>&1 || fail "nvim fails to install its plugins"
    nvim_errors=$(nvim --headless +qa 2>&1 >/dev/null) || fail "nvim exits with an error: $nvim_errors"
    [ -z "$nvim_errors" ] || fail "nvim reports errors: $nvim_errors"
    if grep -rlE '\{\{|\{%' "$HOME/.config/ghostty/themes" "$HOME/.config/nvim/plugin/25_theme.lua" "$HOME/.config/tuios/config.toml"; then
        fail "unrendered template syntax"
    fi
}

check_identity() {
    local expected_email=felix@brouss.eu expected_harness=pi signing_key plugin_js
    if has_module work; then
        expected_email=felix.brousseau-tremblay@kivra.com
        expected_harness=claude
    fi
    [ "$(jj config get user.email)" = "$expected_email" ] || fail "jj user.email is not $expected_email"
    [ "$(mise env --json | jq -r .FM_HARNESS)" = "$expected_harness" ] || fail "FM_HARNESS is not $expected_harness"

    if has_identity; then
        [ -L "$HOME/.ssh/config" ] || fail "the ssh config is not deployed"
        ssh -G personalgit | grep -qx 'hostname github.com' || fail "ssh does not know personalgit"
        [ -s "$HOME/.ssh/personal.pub" ] || fail "personal.pub is missing"
        [ "$(stat -c %a "$HOME/.ssh")" = 700 ] || fail "$HOME/.ssh is not 0700"
        chmod 755 "$HOME/.ssh"
        if mise bootstrap files status --missing >/dev/null 2>&1; then fail "mise bootstrap files status does not report the mode of $HOME/.ssh"; fi
        mise bootstrap files apply --yes >/dev/null
        [ "$(stat -c %a "$HOME/.ssh")" = 700 ] || fail "mise bootstrap files apply does not restore the mode of $HOME/.ssh"
        mise bootstrap --dry-run --only task 2>&1 | grep -q 'fork-sync build' || fail "the bootstrap task does not build the tuios fork"
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
    if has_module desktop; then
        plugin_js=$HOME/.config/opendeck/plugins/com.felbro.journal.sdPlugin/plugin.js
        [ "$(stat -c %a "$plugin_js")" = 755 ] || fail "$plugin_js is not 0755"
        if grep -qE '\{\{|\{%' "$plugin_js"; then fail "$plugin_js has unrendered template syntax"; fi
        [ -f "$HOME/.config/opendeck/plugins/com.felbro.journal.sdPlugin/manifest.json" ] || fail "the opendeck plugin manifest is missing"
        [ ! -L "$HOME/.config/opendeck/plugins/com.felbro.journal.sdPlugin/imgs/journal.svg" ] || fail "the opendeck plugin icon is a symlink that opendeck refuses to serve"
        deck=$HOME/.config/opendeck/profiles/sd-AB8JA516154CTX
        [ "$(readlink "$deck/Default.json")" = "$dotfiles/desktop/.local/share/opendeck/profiles/linux/sd-AB8JA516154CTX/Default.json" ] || fail "the opendeck default profile is not the linux profile"
        image=$HOME/.config/opendeck/images/sd-AB8JA516154CTX/Default/Keypad.0.0/0-user.png
        [ -f "$image" ] && [ ! -L "$image" ] || fail "the opendeck key images are not copied"
        pixel=$HOME/.config/opendeck/plugins/com.felbro.pixel.sdPlugin
        [ -f "$pixel/plugin.js" ] || fail "the opendeck pixel plugin is missing"
        [ -f "$pixel/pomodoro.html" ] || fail "the focus timer settings page is missing"
        jq -e '.palette.magenta' "$pixel/colors.json" >/dev/null || fail "the pixel plugin colors are not rendered from the theme"
    fi
}

check_tuios() {
    has_identity || return $skip
    (
        make_forks
        mise bootstrap --only task --yes >"$work/task.log" 2>&1 || fail "the bootstrap task fails: $(cat "$work/task.log")"
    )
    "$HOME/.local/bin/tuios" | grep -q '^fork-' || fail "the bootstrap task did not build the tuios fork"
    jj -R "$HOME/src/tuios" git remote list | grep -qx 'origin personalgit:smpte11/tuios.git' || fail "the tuios fork does not push over ssh"
}

check_switch() {
    [ "$scenario" = fresh ] && has_module personal || return $skip
    (
        stub_systemd
        DOTFILES_ENV=work "$HOME/.local/bin/dotfiles-setup" "${bootstrap_args[@]}" >/dev/null
    )
    ssh -G workgit | grep -qx "identityagent $HOME/.1password/agent.sock" || fail "the ssh agent is not 1password after the switch"
    grep -q 1password "$HOME/.ssh/config.d/agent" || fail "config.d/agent does not point to 1password"
    [ ! -e "$HOME/.config/systemd/user/dev.mise.proton-pass-ssh-agent.service" ] || fail "the proton unit remains after the switch"
    [ ! -e "$HOME/.local/bin/proton-pass-ssh-agent" ] || fail "the proton wrapper remains after the switch"
    [ ! -e "$HOME/.config/codestral/env" ] || fail "the codestral key remains after the switch"
    [ -L "$HOME/.ssh/config" ] || fail "the ssh config was pruned by the switch"
    [ "$(stat -c %a "$HOME/.ssh")" = 700 ] || fail "$HOME/.ssh is not 0700 after the switch"
    grep -qx 'env = \["work","ssh"\]' "$dotfiles/home/.config/mise/miserc.local.toml" || fail "the modules are not work and ssh after the switch"
}

check_tools() {
    local j
    j=$(mise ls --current --json)
    expect_tool() {
        local t=$1 want=$2
        if [ "$want" = present ]; then
            jq -e --arg t "$t" 'has($t)' <<<"$j" >/dev/null || fail "$t is not installed"
        else
            jq -e --arg t "$t" 'has($t) | not' <<<"$j" >/dev/null || fail "$t is installed but should not be"
        fi
    }
    if has_module desktop; then
        expect_tool helix present
        expect_tool aqua:nushell/nushell present
    else
        expect_tool helix absent
        expect_tool aqua:nushell/nushell absent
    fi
    if has_module gamebox; then
        expect_tool ollama present
        expect_tool devcontainer-cli present
        expect_tool github:fgrehm/crib present
    else
        expect_tool ollama absent
        expect_tool devcontainer-cli absent
        expect_tool github:fgrehm/crib absent
    fi
    if has_module desktop || has_module work || has_module gamebox; then
        expect_tool github:kunchenguid/no-mistakes present
    else
        expect_tool github:kunchenguid/no-mistakes absent
    fi
    expect_tool npm:@agentclientprotocol/claude-agent-acp absent
}

check_media() {
    local f app
    if ! has_module media; then
        [ ! -e "$HOME/.config/containers/systemd/netfelix" ] || fail "netfelix quadlets deployed without the media module"
        [ ! -e "$HOME/.agents/machine/protect-media-drives.md" ] || fail "the media drive guard is deployed without the media module"
        return $skip
    fi
    for f in netfelix.pod sonarr.container radarr.container prowlarr.container jellyfin.container seerr.container flaresolverr.container configarr.container; do
        [ -f "$HOME/.config/containers/systemd/netfelix/$f" ] || fail "quadlet $f is not deployed"
        if grep -qE '\{\{|\{%' "$HOME/.config/containers/systemd/netfelix/$f"; then
            fail "$f has unrendered template syntax"
        fi
    done
    [ -f "$HOME/.config/systemd/user/configarr.timer" ] || fail "the configarr timer is not deployed"
    grep -q 'Unit=configarr.service' "$HOME/.config/systemd/user/configarr.timer" || fail "the configarr timer does not target the configarr quadlet service"
    [ -f "$HOME/.config/media/configarr/config.yml" ] || fail "the configarr config is not deployed"
    [ "$(stat -c %a "$HOME/.config/media/configarr/config.yml")" = 600 ] || fail "the configarr config is not 0600"
    grep -q 'api_key: !env SONARR_API_KEY' "$HOME/.config/media/configarr/config.yml" || fail "the configarr config does not read the sonarr key from the environment"
    grep -q 'Secret=sonarr_api_key,type=env,target=SONARR_API_KEY' "$HOME/.config/containers/systemd/netfelix/configarr.container" || fail "the configarr quadlet does not inject the sonarr key secret"
    for app in sonarr radarr prowlarr; do
        [ -f "$HOME/.config/$app/config.xml" ] || fail "the $app seed config is not deployed"
        [ "$(stat -c %a "$HOME/.config/$app/config.xml")" = 600 ] || fail "the $app seed config is not 0600"
        if grep -qE '\{\{|\{%' "$HOME/.config/$app/config.xml"; then
            fail "the $app seed config has unrendered template syntax"
        fi
    done
    [ -e "$HOME/.agents/machine/protect-media-drives.md" ] || fail "the media drive guard is not deployed"
    grep -q '/run/media/system/media' "$HOME/.agents/machine/protect-media-drives.md" || fail "the media drive guard does not name the media mount"
}

check_picker() {
    local stub=$work/gum-stub out before after
    cat >"$stub" <<'STUB'
#!/bin/bash
sel=
prev=
for a in "$@"; do
    if [ "$prev" = --selected ]; then sel=$a; fi
    prev=$a
done
case "$1" in
confirm) exit 0 ;;
choose)
    if [ -n "$sel" ]; then
        printf '%s\n' "$sel" | tr ',' '\n'
    else
        printf 'media - pick one\ngamebox - pick two\n'
    fi
    ;;
esac
STUB
    chmod +x "$stub"
    out=$(DOTFILES_GUM=$stub "$dotfiles/home/.local/bin/dotfiles-choose" "")
    [ "$out" = "media,gamebox" ] || fail "the picker did not resolve labels to modules: $out"
    out=$(DOTFILES_GUM=$stub "$dotfiles/home/.local/bin/dotfiles-choose" "gamebox,ssh")
    [ "$out" = "gamebox" ] || fail "the picker did not pre-select the deployed modules: $out"
    if has_module personal || has_module media || has_module proton-pass; then
        [ -x "$HOME/.local/bin/pass-cli" ] || fail "pass-cli is not installed although a proton module is active"
    else
        [ ! -e "$HOME/.local/bin/pass-cli" ] || fail "pass-cli is installed without a proton module"
    fi
    if has_module proton-pass; then
        grep -qx 'env = \["proton-pass"\]' "$dotfiles/home/.config/mise/miserc.local.toml" || fail "miserc.local.toml does not list proton-pass"
    fi
    if [ "$scenario" = fresh ]; then
        before=$(cat "$dotfiles/home/.config/mise/miserc.local.toml")
        DOTFILES_ENV=$modules "$HOME/.local/bin/dotfiles-setup" update "${bootstrap_args[@]}" >/dev/null 2>&1 || fail "re-running setup with the same modules failed"
        after=$(cat "$dotfiles/home/.config/mise/miserc.local.toml")
        [ "$before" = "$after" ] || fail "re-running setup with the same modules rewrote miserc.local.toml"
    fi
}

case " ${groups[*]} " in
*" $group "*) "check_${group//-/_}" ;;
*) fail "unknown group $group; groups: ${groups[*]}" ;;
esac
