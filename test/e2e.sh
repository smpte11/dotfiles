#!/usr/bin/env bash
groups=(local-files idempotent services secrets theme history smoke tools proton media identity tuios switch picker teardown)
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
    if has_module ssh-agent; then
        [ -s "$HOME/.config/systemd/user/dev.mise.proton-pass-ssh-agent.service" ] || fail "the proton ssh agent unit is missing"
        [ -x "$HOME/.local/bin/proton-pass-ssh-agent" ] || fail "the proton ssh agent wrapper is not executable"
    fi
    if has_module base; then
        [ -s "$HOME/.config/systemd/user/protonvpn-connect.service" ] || fail "the protonvpn connect unit is missing"
        grep -q "com.protonvpn.www" "$HOME/.config/systemd/user/protonvpn-connect.service" || fail "the protonvpn connect unit does not run the flatpak cli"
        grep -q 'Status: Connected' "$HOME/.config/systemd/user/protonvpn-connect.service" || fail "the protonvpn connect unit does not skip connect when already connected"
        grep -q "X-GNOME-Autostart-enabled=false" "$HOME/.config/autostart/proton.desktop" || fail "the protonvpn gui autostart is not disabled"
    else
        [ ! -e "$HOME/.config/systemd/user/protonvpn-connect.service" ] || fail "the protonvpn connect unit is deployed without the base module"
    fi
}

check_secrets() {
    local codestral=$HOME/.config/codestral/env vibe=$HOME/.vibe/.env status_output
    if has_module base; then
        check_vibe_secret
    else
        [ ! -e "$vibe" ] || fail "$vibe is deployed without the base module"
    fi
    if ! has_module dev-private; then
        [ ! -e "$codestral" ] || fail "$codestral is deployed without the dev-private module"
        [ "$(mise env --json | jq -r '.NVIM_AI_PROVIDER // empty')" != codestral ] || fail "NVIM_AI_PROVIDER is codestral without the dev-private module"
        return 0
    fi
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

check_vibe_secret() {
    local vibe=$HOME/.vibe/.env status_output
    [ -f "$vibe" ] && [ ! -s "$vibe" ] || fail "$vibe is not an empty file without a key"
    rm "$vibe"
    status_output=$(MISTRAL_API_KEY=e2e-secret-vibe mise dot status --verbose 2>&1)
    if grep -q e2e-secret-vibe <<<"$status_output"; then fail "mise dot status prints the vibe key"; fi
    MISTRAL_API_KEY=e2e-secret-vibe mise dot apply --yes >/dev/null
    [ "$(cat "$vibe")" = MISTRAL_API_KEY=e2e-secret-vibe ] || fail "$vibe does not hold the key"
    [ "$(stat -c %a "$vibe")" = 600 ] || fail "$vibe is not 0600"
    [ "$(mise env --json | jq -r .MISTRAL_API_KEY)" = e2e-secret-vibe ] || fail "mise env does not load the vibe key"
    mise bootstrap --yes "${bootstrap_args[@]}" >/dev/null || fail "bootstrap fails without the vibe key in the environment"
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
    if has_module base; then
        pi --version >/dev/null 2>&1 || fail "pi is not runnable through its mise shim"
        opencode --version >/dev/null 2>&1 || fail "opencode is not runnable through its mise shim"
    fi
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
    local expected_email=felix@brouss.eu expected_harness=null signing_key plugin_js
    if has_module work; then
        expected_email=felix.brousseau-tremblay@kivra.com
    fi
    if has_module dev-private; then
        expected_harness=pi
    fi
    if has_module dev-work; then
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
    else
        [ ! -e "$HOME/.ssh/config" ] || fail "an ssh config was deployed without the ssh module"
    fi
    if mise ls --current --json | jq -e 'has("github:Gaurav-Gosain/tuios")' >/dev/null; then
        fail "upstream tuios is installed as a mise tool and would shadow the fork"
    fi
    if has_module base; then
        signing_key=$(jj config get signing.key)
        [ "${signing_key#\~/}" = .ssh/personal.pub ] || fail "jj does not sign with the personal key"
        if ssh -G workgit | grep -qx 'hostname github.com'; then fail "workgit is configured on a base machine"; fi
    fi
    if has_module ssh-agent; then
        ssh -G personalgit | grep -qx "identityagent $HOME/.ssh/proton-pass-agent.sock" || fail "personal ssh agent is not proton"
    fi
    if has_module work; then
        ssh -G workgit | grep -qx 'hostname github.com' || fail "ssh does not know workgit"
        ssh -G workgit | grep -qx "identityagent $HOME/.1password/agent.sock" || fail "work ssh agent is not 1password"
        [ "$(jj config get signing.backends.ssh.program)" = /opt/1Password/op-ssh-sign ] || fail "jj does not sign with op-ssh-sign"
    fi
    if has_module dev-work; then
        [ -L "$HOME/.claude/keybindings.json" ] || fail "claude keybindings are missing"
    else
        [ ! -e "$HOME/.claude/keybindings.json" ] || fail "claude keybindings are deployed without the dev-work module"
    fi
    if has_module desktop; then
        grep -qx 'Exec=flatpak run me.amankhanna.opendeck --hide' "$HOME/.config/autostart/opendeck.desktop" || fail "opendeck does not start at login"
        if mise dot status 2>&1 | grep -q 'ignoring group'; then fail "mise ignores a dotfile group: $(mise dot status 2>&1 | grep 'ignoring group')"; fi
    else
        [ ! -e "$HOME/.config/autostart/opendeck.desktop" ] || fail "opendeck autostart is deployed without the desktop module"
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
    has_module dev || return $skip
    mise bootstrap --dry-run --only task 2>&1 | grep -q 'fork-sync build' || fail "the bootstrap task does not build the tuios fork"
    (
        make_forks
        mise bootstrap --only task --yes >"$work/task.log" 2>&1 || fail "the bootstrap task fails: $(cat "$work/task.log")"
    )
    "$HOME/.local/bin/tuios" | grep -q '^fork-' || fail "the bootstrap task did not build the tuios fork"
    jj -R "$HOME/src/tuios" git remote list | grep -qx 'origin personalgit:smpte11/tuios.git' || fail "the tuios fork does not push over ssh"
}

check_switch() {
    [ "$scenario" = fresh ] && has_module base || return $skip
    (
        stub_systemd
        DOTFILES_ENV=work script -qec "'$HOME/.local/bin/dotfiles-setup' ${bootstrap_args[*]}" /dev/null >"$work/switch.log" 2>&1
    ) || fail "the switch to work failed: $(tail -5 "$work/switch.log")"
    if ! uses_pass && grep -qE 'pass-cli (login|is not logged in)' "$work/switch.log"; then fail "the switch to work asks for a pass-cli login: $(grep pass-cli "$work/switch.log")"; fi
    ssh -G workgit | grep -qx "identityagent $HOME/.1password/agent.sock" || fail "the ssh agent is not 1password after the switch"
    grep -q 1password "$HOME/.ssh/config.d/agent" || fail "config.d/agent does not point to 1password"
    [ ! -e "$HOME/.config/systemd/user/dev.mise.proton-pass-ssh-agent.service" ] || fail "the proton unit remains after the switch"
    [ ! -e "$HOME/.local/bin/proton-pass-ssh-agent" ] || fail "the proton wrapper remains after the switch"
    [ ! -e "$HOME/.local/bin/pass-cli" ] || fail "the pass-cli wrapper remains after the switch"
    [ ! -e "$HOME/.config/codestral/env" ] || fail "the codestral key remains after the switch"
    if has_module gaming; then
        [ ! -e "$HOME/.config/containers/systemd/netfelix/questarr.container" ] || fail "the questarr quadlet remains after the switch"
        [ ! -e "$HOME/.config/media/questarr" ] || fail "the questarr config remains after the switch"
    fi
    if has_module torrent; then
        [ ! -e "$HOME/.config/containers/systemd/netfelix/netfelix.pod" ] || fail "the netfelix pod remains after the switch"
        [ ! -e "$HOME/.config/containers/systemd/netfelix/qbittorrent.container" ] || fail "the qbittorrent quadlet remains after the switch"
        [ ! -e "$HOME/.config/systemd/user/qbit-vpn-guard.service" ] || fail "the qbit-vpn-guard service remains after the switch"
    fi
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
    if has_module dev; then
        [ -s "$HOME/.config/k9s/skins/active-theme.yaml" ] || fail "k9s skin is missing"
        expect_tool devcontainer-cli present
        expect_tool github:kunchenguid/no-mistakes present
    else
        expect_tool devcontainer-cli absent
        expect_tool github:kunchenguid/no-mistakes absent
    fi
    if has_module base; then
        [ -s "$HOME/.pi/agent/AGENTS.md" ] || fail "the pi agent instructions are missing"
        [ -s "$HOME/.config/opencode/opencode.json" ] || fail "the opencode config is missing"
        expect_tool pi present
        expect_tool npm:@opencode/cli present
    else
        [ ! -e "$HOME/.pi/agent/AGENTS.md" ] || fail "the pi agent instructions are deployed without the base module"
        [ ! -e "$HOME/.config/opencode/opencode.json" ] || fail "the opencode config is deployed without the base module"
        expect_tool pi absent
        expect_tool npm:@opencode/cli absent
    fi
    if has_module dev-private; then
        [ -s "$HOME/.config/crib/config.toml" ] || fail "the crib config is missing"
        expect_tool ollama present
        expect_tool github:fgrehm/crib present
    else
        [ ! -e "$HOME/.config/crib/config.toml" ] || fail "the crib config is deployed without the dev-private module"
        expect_tool ollama absent
        expect_tool github:fgrehm/crib absent
    fi
    expect_tool npm:@agentclientprotocol/claude-agent-acp absent
}

uses_pass() {
    has_module proton-pass || has_module torrent
}

check_proton() {
    local real=$HOME/.local/share/proton-pass-cli/pass-cli out link
    if has_module proton-pass; then
        grep -qx 'PROTON_PASS_LINUX_KEYRING=dbus' "$HOME/.config/environment.d/proton-pass.conf" || fail "the proton-pass session env is missing"
    else
        [ ! -e "$HOME/.config/environment.d/proton-pass.conf" ] || fail "the proton-pass session env is deployed without the proton-pass module"
    fi
    if ! uses_pass; then
        [ ! -e "$real" ] || fail "the pass-cli binary is installed without a proton module"
        [ ! -e "$HOME/.local/bin/pass-cli" ] || fail "$HOME/.local/bin/pass-cli exists without the proton-pass module"
        [ "$scenario" = fresh ] || return 0
        script -qec "DOTFILES_ENV=$modules '$HOME/.local/bin/dotfiles-setup' update ${bootstrap_args[*]}" /dev/null >"$work/proton-tty.log" 2>&1 || fail "setup without proton-pass failed: $(tail -5 "$work/proton-tty.log")"
        if grep -qE 'pass-cli (login|is not logged in)' "$work/proton-tty.log"; then fail "setup without proton-pass asks for pass-cli: $(grep pass-cli "$work/proton-tty.log")"; fi
        [ ! -e "$real" ] || fail "setup without proton-pass installed the pass-cli binary"
        return 0
    fi
    [ -x "$real" ] || fail "the pass-cli binary is not installed at $real"
    if has_module proton-pass; then
        [ -L "$HOME/.local/bin/pass-cli" ] || fail "$HOME/.local/bin/pass-cli is not the deployed wrapper"
        link="$(readlink "$HOME/.local/bin/pass-cli")"
        case "$link" in
        *"proton-pass/.local/bin/pass-cli") ;;
        *) fail "the pass-cli wrapper does not point into the checkout: $link" ;;
        esac
        out=$(env -u PROTON_PASS_KEY_PROVIDER -u PROTON_PASS_LINUX_KEYRING "$HOME/.local/bin/pass-cli" info 2>&1 || true)
        if printf '%s\n' "$out" | grep -qiE 'keyring|encryption key|secret service'; then
            fail "the wrapper still hits a keyring error without a system keyring: $out"
        fi
        printf '%s\n' "$out" | grep -q 'authenticated client' || fail "pass-cli info does not report the missing session: $out"
        out=$(timeout 10 env -u PROTON_PASS_KEY_PROVIDER -u PROTON_PASS_LINUX_KEYRING "$HOME/.local/bin/pass-cli" login 2>&1 || true)
        printf '%s\n' "$out" | grep -q 'account.proton.me' || fail "pass-cli login does not reach the web flow through the wrapper: $out"
    else
        [ ! -e "$HOME/.local/bin/pass-cli" ] || fail "$HOME/.local/bin/pass-cli exists without the proton-pass module"
    fi
    if [ "$scenario" = fresh ] && has_module proton-pass; then
        mv "$real" "$real.stub"
        printf '#!/bin/sh\nexit 1\n' >"$real"
        chmod +x "$real"
        if ! script -qec "DOTFILES_ENV=$modules '$HOME/.local/bin/dotfiles-setup' update ${bootstrap_args[*]}" /dev/null >"$work/proton-tty.log" 2>&1; then
            mv -f "$real.stub" "$real"
            fail "setup on a terminal aborted when pass-cli login failed: $(tail -5 "$work/proton-tty.log")"
        fi
        grep -q 'pass-cli login did not complete' "$work/proton-tty.log" || fail "setup did not warn about the failed login"
        mv -f "$real.stub" "$real"
    fi
}

check_media() {
    local f app pod=$HOME/.config/containers/systemd/netfelix torrents=$HOME/.local/share/torrents
    has_module media && torrents=/run/media/system/media/torrents
    if has_module gaming; then
        for f in questarr.container questarr-config.container; do
            [ -f "$pod/$f" ] || fail "quadlet $f is not deployed"
            if grep -qE '\{\{|\{%' "$pod/$f"; then
                fail "$f has unrendered template syntax"
            fi
        done
        [ -f "$HOME/.config/systemd/user/questarr-config.timer" ] || fail "the questarr-config timer is not deployed"
        [ -f "$HOME/.config/media/questarr/config.json" ] || fail "the questarr config is not deployed"
        [ "$(stat -c %a "$HOME/.config/media/questarr/config.json")" = 600 ] || fail "the questarr config is not 0600"
        [ -f "$HOME/.config/media/questarr/apply.py" ] || fail "the questarr apply script is not deployed"
        grep -qx "Volume=$HOME/.local/share/questarr/games:/data:z" "$pod/questarr.container" || fail "questarr does not mount the games dir in home"
        grep -qx "ExecStartPre=/bin/mkdir -p $HOME/.local/share/questarr/games" "$pod/questarr.container" || fail "the questarr quadlet does not create the games dir"
        grep -qx "Volume=$torrents:$torrents:z" "$pod/questarr.container" || fail "questarr does not mount the torrents dir at the qbittorrent path"
        grep -q "TORRENTS_DIR=$torrents\$" "$pod/questarr-config.container" || fail "the questarr-config quadlet does not pass the torrents dir"
        [ "$(jq -r '.downloaders[] | select(.name == "qBittorrent") | .downloadPath' "$HOME/.config/media/questarr/config.json")" = "\$TORRENTS_DIR/questarr" ] || fail "the questarr config does not save downloads under the torrents dir"
        [ ! -L "$HOME/.local/share/questarr/games" ] || fail "the questarr games dir is a symlink"
    else
        [ ! -e "$pod/questarr.container" ] || fail "a questarr quadlet is deployed without the gaming module"
        [ ! -e "$HOME/.config/media/questarr" ] || fail "the questarr config is deployed without the gaming module"
    fi
    if ! has_module torrent; then
        for f in netfelix.pod prowlarr.container byparr.container prowlarr-config.container qbittorrent.container; do
            [ ! -e "$pod/$f" ] || fail "quadlet $f is deployed without the torrent module"
        done
        [ ! -e "$HOME/.config/systemd/user/qbit-vpn-guard.service" ] || fail "the qbit-vpn-guard service is deployed without the torrent module"
        [ ! -e "$HOME/.config/media/qbit-vpn-guard.sh" ] || fail "the qbit-vpn-guard script is deployed without the torrent module"
        [ ! -e "$HOME/.config/systemd/user/prowlarr-config.timer" ] || fail "the prowlarr-config timer is deployed without the torrent module"
    else
        for f in netfelix.pod prowlarr.container byparr.container prowlarr-config.container qbittorrent.container; do
            [ -f "$pod/$f" ] || fail "quadlet $f is not deployed"
            if grep -qE '\{\{|\{%' "$pod/$f"; then
                fail "$f has unrendered template syntax"
            fi
        done
        grep -qx 'PublishPort=9696:9696/tcp' "$pod/netfelix.pod" || fail "the pod does not publish the prowlarr port"
        grep -qx 'PublishPort=8191:8191/tcp' "$pod/netfelix.pod" || fail "the pod does not publish the byparr port"
        if grep -q 'PublishPort=8989' "$pod/netfelix.pod"; then fail "the base pod publishes a media port"; fi
        grep -qx 'Pod=netfelix.pod' "$pod/prowlarr.container" || fail "prowlarr does not join the netfelix pod"
        grep -qx 'Pod=netfelix.pod' "$pod/byparr.container" || fail "byparr does not join the netfelix pod"
        grep -q "ghcr.io/thephaseless/byparr" "$pod/byparr.container" || fail "the byparr quadlet does not use the byparr image"
        [ ! -e "$pod/flaresolverr.container" ] || fail "the flaresolverr quadlet is still deployed"
        grep -q "Network=host" "$pod/qbittorrent.container" || fail "the qbittorrent quadlet does not use host networking"
        grep -qx "Volume=$torrents:$torrents:z" "$pod/qbittorrent.container" || fail "the qbittorrent torrents mount is not $torrents with the shared :z label"
        if has_module media; then
            if grep -q 'mkdir' "$pod/qbittorrent.container"; then fail "qbittorrent creates a torrents dir on the media pool"; fi
        else
            grep -qx "ExecStartPre=/bin/mkdir -p $torrents" "$pod/qbittorrent.container" || fail "the qbittorrent quadlet does not create the torrents dir"
        fi
        [ -f "$HOME/.config/systemd/user/qbit-vpn-guard.service" ] || fail "the qbit-vpn-guard service is not deployed"
        [ -x "$HOME/.config/media/qbit-vpn-guard.sh" ] || fail "the qbit-vpn-guard script is not executable"
        if grep -qE "\{{|\{%" "$HOME/.config/systemd/user/qbit-vpn-guard.service" "$HOME/.config/media/qbit-vpn-guard.sh"; then
            fail "the qbit-vpn-guard files have unrendered template syntax"
        fi
        grep -q "proton0" "$HOME/.config/media/qbit-vpn-guard.sh" || fail "the qbit-vpn-guard script does not render the vpn interface"
        grep -q "qbittorrent.service" "$HOME/.config/media/qbit-vpn-guard.sh" || fail "the qbit-vpn-guard script does not manage the qbittorrent unit"
        grep -q 'Unit=prowlarr-config.service' "$HOME/.config/systemd/user/prowlarr-config.timer" || fail "the prowlarr-config timer does not target the prowlarr-config quadlet service"
        [ "$(stat -c %a "$HOME/.config/media/prowlarr-config/config.yml")" = 600 ] || fail "the prowlarr configarr config is not 0600"
        grep -q 'definition: Knaben' "$HOME/.config/media/prowlarr-config/config.yml" || fail "the prowlarr configarr config does not hold the indexers"
        if grep -q 'applications:' "$HOME/.config/media/prowlarr-config/config.yml"; then fail "the prowlarr configarr config syncs the media applications"; fi
        grep -q 'Secret=yts_api_url,type=env,target=YTS_API_URL' "$pod/prowlarr-config.container" || fail "the prowlarr-config quadlet does not inject the yts secret"
        [ "$(stat -c %a "$HOME/.config/prowlarr/config.xml")" = 600 ] || fail "the prowlarr seed config is not 0600"
        if grep -qE '\{\{|\{%' "$HOME/.config/prowlarr/config.xml"; then fail "the prowlarr seed config has unrendered template syntax"; fi
    fi
    if ! has_module media; then
        for f in netfelix.pod.d/media.conf sonarr.container radarr-kids.container seerr-kids.container configarr.container; do
            [ ! -e "$pod/$f" ] || fail "$f is deployed without the media module"
        done
        [ ! -e "$HOME/.config/media/sync-seerr-api-keys.sh" ] || fail "the seerr api key sync script is deployed without the media module"
        [ ! -e "$HOME/.agents/machine/protect-media-drives.md" ] || fail "the media drive guard is deployed without the media module"
        has_module torrent && return 0
        return $skip
    fi
    for f in sonarr.container radarr.container radarr-kids.container jellyfin.container seerr.container seerr-kids.container configarr.container; do
        [ -f "$pod/$f" ] || fail "quadlet $f is not deployed"
        if grep -qE '\{\{|\{%' "$pod/$f"; then
            fail "$f has unrendered template syntax"
        fi
    done
    grep -qx 'PublishPort=8989:8989/tcp' "$pod/netfelix.pod.d/media.conf" || fail "the media drop-in does not publish the sonarr port"
    grep -qx 'PublishPort=7879:7879/tcp' "$pod/netfelix.pod.d/media.conf" || fail "the media drop-in does not publish the radarr-kids port"
    grep -qx 'PublishPort=5056:5056/tcp' "$pod/netfelix.pod.d/media.conf" || fail "the media drop-in does not publish the seerr-kids port"
    [ -f "$HOME/.config/systemd/user/configarr.timer" ] || fail "the configarr timer is not deployed"
    grep -q 'Unit=configarr.service' "$HOME/.config/systemd/user/configarr.timer" || fail "the configarr timer does not target the configarr quadlet service"
    [ -f "$HOME/.config/media/configarr/config.yml" ] || fail "the configarr config is not deployed"
    [ "$(stat -c %a "$HOME/.config/media/configarr/config.yml")" = 600 ] || fail "the configarr config is not 0600"
    grep -q 'api_key: !env SONARR_API_KEY' "$HOME/.config/media/configarr/config.yml" || fail "the configarr config does not read the sonarr key from the environment"
    if grep -qx '    indexers:' "$HOME/.config/media/configarr/config.yml"; then fail "the media configarr config still manages the prowlarr indexers"; fi
    grep -q 'Secret=sonarr_api_key,type=env,target=SONARR_API_KEY' "$pod/configarr.container" || fail "the configarr quadlet does not inject the sonarr key secret"
    grep -q 'Secret=radarr_kids_api_key,type=env,target=RADARR_KIDS_API_KEY' "$pod/configarr.container" || fail "the configarr quadlet does not inject the radarr-kids key secret"
    grep -q 'movie_category: radarr-kids' "$HOME/.config/media/configarr/config.yml" || fail "the configarr config does not route radarr-kids downloads to their own qbit category"
    [ "$(grep -cF "remote_path: $torrents" "$HOME/.config/media/configarr/config.yml")" = 3 ] || fail "the configarr config does not map the qbit remote path for sonarr, radarr and radarr-kids"
    grep -q 'host: host.containers.internal' "$HOME/.config/media/configarr/config.yml" || fail "the configarr remote path mapping does not match the host-network qbit download client"
    grep -q 'baseUrl: http://localhost:7879' "$HOME/.config/media/configarr/config.yml" || fail "the configarr config does not sync prowlarr to radarr-kids"
    [ -x "$HOME/.config/media/sync-seerr-api-keys.sh" ] || fail "the seerr api key sync script is not deployed executable"
    if grep -qE '\{\{|\{%' "$HOME/.config/media/sync-seerr-api-keys.sh"; then fail "the seerr api key sync script has unrendered template syntax"; fi
    grep -q 'seerr-kids.service' "$HOME/.config/media/sync-seerr-api-keys.sh" || fail "the seerr api key sync script does not restart seerr-kids"
    grep -q 'sync-seerr-api-keys.sh' "$dotfiles/home/.config/mise/config.media.toml" || fail "the media bootstrap does not run the seerr api key sync script"
    grep -q '"~/.config/media/sync-seerr-api-keys.sh"' "$dotfiles/home/.config/mise/config.media.toml" || fail "the media dotfile group does not deploy the seerr api key sync script"
    for app in sonarr radarr radarr-kids; do
        [ -f "$HOME/.config/$app/config.xml" ] || fail "the $app seed config is not deployed"
        [ "$(stat -c %a "$HOME/.config/$app/config.xml")" = 600 ] || fail "the $app seed config is not 0600"
        if grep -qE '\{\{|\{%' "$HOME/.config/$app/config.xml"; then
            fail "the $app seed config has unrendered template syntax"
        fi
    done
    [ -e "$HOME/.agents/machine/protect-media-drives.md" ] || fail "the media drive guard is not deployed"
    grep -q '/run/media/system/media' "$HOME/.agents/machine/protect-media-drives.md" || fail "the media drive guard does not name the media mount"
}

check_teardown() {
    local stub=$work/gum-stub
    cat >"$stub" <<'STUB'
#!/bin/sh
case "$1" in
confirm) exit 1 ;;
esac
STUB
    chmod +x "$stub"
    if DOTFILES_GUM=$stub "$HOME/.local/bin/dotfiles-teardown" >/dev/null 2>&1; then
        fail "teardown must abort when the confirmation is declined"
    fi
    [ -e "$HOME/.zshrc" ] || fail "the aborted teardown removed dotfiles"
    if "$HOME/.local/bin/dotfiles-teardown" </dev/null >/dev/null 2>&1; then
        fail "teardown without --yes must abort without a terminal"
    fi
    [ -e "$HOME/.zshrc" ] || fail "the non-interactive teardown removed dotfiles"
    "$HOME/.local/bin/dotfiles-teardown" --yes >/dev/null 2>&1 || fail "teardown --yes failed"
    [ ! -e "$dotfiles" ] || fail "the checkout remains after teardown"
    [ ! -e "$HOME/.local/bin/mise" ] || fail "mise remains after teardown"
    [ ! -e "$HOME/.local/share/mise" ] || fail "the mise data dir remains after teardown"
    [ ! -L "$HOME/.config/mise" ] || fail "the mise config link remains after teardown"
    [ ! -e "$HOME/.zshrc" ] || fail "$HOME/.zshrc remains after teardown"
    [ ! -e "$HOME/.local/bin/dotfiles-teardown" ] || fail "the teardown script link remains after teardown"
    if has_identity; then
        [ ! -e "$HOME/.ssh/config" ] || fail "$HOME/.ssh/config remains after teardown"
    fi
}

check_picker() {
    local stub=$work/gum-stub out before after miserc edstub
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
        grep -E '^(work|dev) - '
    fi
    ;;
esac
STUB
    chmod +x "$stub"
    out=$(DOTFILES_GUM=$stub "$dotfiles/home/.local/bin/dotfiles-choose" "")
    [ "$out" = "dev,work" ] || fail "the picker did not offer and resolve dev and work: $out"
    out=$(DOTFILES_GUM=$stub "$dotfiles/home/.local/bin/dotfiles-choose" "dev-work")
    [ "$out" = "dev,dev-work" ] || fail "the picker did not pull dev in with dev-work: $out"
    out=$(DOTFILES_GUM=$stub "$dotfiles/home/.local/bin/dotfiles-choose" "work-mac")
    [ "$out" = "work,dev,dev-work,desktop" ] || fail "the picker did not expand the work-mac machine: $out"
    out=$("$dotfiles/home/.local/bin/dotfiles-choose" --expand "tablet,ssh,dev-work")
    [ "$out" = "base,tablet,ssh,dev,dev-work" ] || fail "--expand did not expand meta modules and keep plain ones: $out"
    out=$(DOTFILES_GUM=$stub "$dotfiles/home/.local/bin/dotfiles-choose" "gaming,ssh")
    [ "$out" = "torrent,gaming" ] || fail "the picker did not pre-select the deployed modules: $out"
    out=$(DOTFILES_GUM=$stub "$dotfiles/home/.local/bin/dotfiles-choose" "base,proton-pass,ssh")
    [ "$out" = "base,proton-pass" ] || fail "the picker did not keep proton-pass beside base: $out"
    miserc="$dotfiles/home/.config/mise/miserc.local.toml"
    edstub=$work/editor-stub
    cat >"$edstub" <<'STUB'
#!/bin/bash
printf 'env = ["base","media"]\n' >"$1"
STUB
    chmod +x "$edstub"
    cp "$miserc" "$work/miserc.bak"
    out=$(EDITOR=$edstub "$dotfiles/home/.local/bin/dotfiles-choose" --edit)
    [ "$out" = "base,media" ] || fail "profile edit did not read back the env list: $out"
    cp "$work/miserc.bak" "$miserc"
    if has_module dev; then
        grep -q '"dev"' "$dotfiles/home/.config/mise/miserc.local.toml" || fail "miserc.local.toml does not list dev"
    fi
    if uses_pass; then
        [ -x "$HOME/.local/share/proton-pass-cli/pass-cli" ] || fail "the pass-cli binary is not installed although a proton module is active"
    else
        [ ! -e "$HOME/.local/share/proton-pass-cli/pass-cli" ] || fail "the pass-cli binary is installed without a proton module"
    fi
    if has_module proton-pass; then
        grep -q '"proton-pass"' "$dotfiles/home/.config/mise/miserc.local.toml" || fail "miserc.local.toml does not list proton-pass"
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
