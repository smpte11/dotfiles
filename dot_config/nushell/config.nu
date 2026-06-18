# config.nu
#
# Nushell configuration. Previously split between `env.nu` and `config.nu`;
# `env.nu` is deprecated upstream so everything now lives here.
# See https://www.nushell.sh/book/configuration.html

# ─── environment variables ───────────────────────────────────────────

$env.EDITOR = 'nvim'
$env.VISUAL = 'nvim'

$env.KUBECONFIG = $"($env.HOME)/.kube/kivra-app-01-vbg.yaml"
$env.K9S_CONFIG_DIR = $"($env.HOME)/.config/k9s"

$env.RIPGREP_CONFIG_PATH = $"($env.HOME)/.config/ripgrep/.ripgreprc"

$env.SSH_AUTH_SOCK = if $nu.os-info.name == "macos" {
    $"($env.HOME)/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
} else {
    $"($env.HOME)/.ssh/proton-pass-agent.sock"
}

# ─── PATH ────────────────────────────────────────────────────────────

use std/util "path add"

path add $'($env.HOME)/.local/bin'
path add '/usr/local/bin'

if $nu.os-info.name == "macos" {
    path add '/opt/homebrew/bin'
    path add '/opt/homebrew/sbin'
} else if $nu.os-info.name == "linux" {
    path add '/home/linuxbrew/.linuxbrew/bin'
    path add '/home/linuxbrew/.linuxbrew/sbin'
}

path add $"($env.HOME)/.krew/bin"

# mise shims — placed last so they take precedence over system tools.
# Required so mise-managed tools are available immediately in this shell;
# the autoload-written mise.nu (below) only takes effect on the next launch.
path add $"($env.HOME)/.local/share/mise/shims"

# ─── nushell display ─────────────────────────────────────────────────

$env.config.show_banner = false
$env.config.buffer_editor = "nvim"
$env.config.edit_mode = "vi"

# ─── vendor integrations ─────────────────────────────────────────────

$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'

mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"

zoxide init nushell --cmd cd | save -f ~/.zoxide.nu

mkdir ($nu.data-dir | path join "vendor/autoload")
tv init nu | save -f ($nu.data-dir | path join "vendor/autoload/tv.nu")
^mise activate nu | save -f ($nu.data-dir | path join "vendor/autoload/mise.nu")

oh-my-posh init nu --config ~/.config/ohmyposh/.minischeme.omp.toml

# ─── aliases ─────────────────────────────────────────────────────────

alias ll = ls -l

# ─── custom commands ─────────────────────────────────────────────────

# Helper to fetch external commands for completion
def "nu-complete commands" [] {
    $env.PATH
    | split row (char esep)
    | each { |dir|
        if ($dir | path exists) {
            ls $dir | get name | path basename
        }
    }
    | flatten
    | uniq
}

# Run a command multiple times, stopping on first failure
def --wrapped repeat [
    ...args: string@"nu-complete commands"
] {
    if ($args | length) < 2 {
        print -e "Usage: repeat COUNT [-q] COMMAND [ARGS...]"
        return 1
    }

    # FIX: 'skip 1' removes from the beginning, 'drop 1' removes from the end!
    let count = ($args | first | into int)
    let rest = ($args | skip 1)
    let quiet = ($rest | any {|it| $it == "-q" or $it == "--quiet"})
    let command_parts = ($rest | where {|it| $it != "-q" and $it != "--quiet"})

    if $count <= 0 {
        error make {msg: "COUNT must be a positive integer"}
    }

    let print_block = {|color, message, is_stderr|
        if not $quiet {
            let width = (term size).columns
            let sep = ("" | fill -c "━" -w $width)
            let style = (ansi $"($color)_bold")
            let reset = (ansi reset)
            let output = $"($style)($sep)\n ($message)\n($sep)($reset)"
            if $is_stderr { print -e $output } else { print $output }
        }
    }

    for i in 1..$count {
        let cmd_name = ($command_parts | first)
        let cmd_args = ($command_parts | skip 1) # Skip the command name to get just the args
        let cmd_pretty = ($command_parts | str join ' ')

        do $print_block "blue" $"▶ Run ($i)/($count): ($cmd_pretty)" false

        # Execute the external command
        # The ^ ensures we don't accidentally call a Nushell alias/built-in
        ^$cmd_name ...$cmd_args

        if $env.LAST_EXIT_CODE != 0 {
            do $print_block "red" $"✖ Failed with code ($env.LAST_EXIT_CODE) on run ($i)/($count)" true
            return $env.LAST_EXIT_CODE
        }
    }

    do $print_block "green" $"✓ Successfully completed all ($count) runs" false
}

# Switch the chezmoi theme via an fzf picker that renders color swatches inline.
def switch-theme [] {
    let data_path = (chezmoi source-path | str trim | path join ".chezmoidata.toml")
    let data = (open $data_path)
    let active = $data.active_theme
    let names = ($data.themes | columns | sort)

    let swatch_for = {|hex|
        if ($hex | is-empty) {
            ""
        } else {
            let h = ($hex | str replace -r '^#' '')
            let r = ($h | str substring 0..<2 | into int --radix 16)
            let g = ($h | str substring 2..<4 | into int --radix 16)
            let b = ($h | str substring 4..<6 | into int --radix 16)
            let code = $"48;2;($r);($g);($b)m"
            $"(ansi -e $code)  (ansi reset)"
        }
    }

    let name_width = (($names | each {|n| $n | str length } | math max) + 2)

    let items = ($names | each {|name|
        let theme = ($data.themes | get $name)
        let marker = if $name == $active { "● " } else { "  " }
        let padded = ($name | fill -a left -c ' ' -w $name_width)
        let colors = [
            $theme.background
            $theme.foreground
            $theme.cursor
            $theme.palette.red
            $theme.palette.green
            $theme.palette.yellow
            $theme.palette.blue
            $theme.palette.magenta
            $theme.palette.cyan
        ]
        let swatches = ($colors | where {|c| $c | is-not-empty } | each {|c| do $swatch_for $c } | str join '')
        $"($marker)($padded) ($swatches)"
    })

    let selected = ($items
        | str join "\n"
        | ^fzf --ansi --no-sort --reverse --header "Theme Switcher" --height $"(($names | length) + 4)" --prompt "› "
        | str trim)

    if ($selected | is-empty) { return }

    let theme_name = ($selected | ansi strip | str trim | str replace -r '^●\s+' '' | split row ' ' | first)

    if $theme_name == $active {
        print $"'($theme_name)' is already the active theme"
        return
    }

    let content = (open $data_path --raw)
    let updated = ($content | str replace -r 'active_theme\s*=\s*"[^"]*"' $'active_theme = "($theme_name)"')
    $updated | save -f $data_path

    print $"Applying '($theme_name)'..."
    chezmoi apply

    print $"Switched to '($theme_name)'!"
    print ""
    print "Reload notes:"
    print "  Ghostty: auto-reloads on config change"
    print "  Zellij:  open a new tab/session to pick up the new theme"
    print "  Neovim:  restart to pick up the new theme"
}

const goose_completions = ($nu.config-path | path dirname | path join "goose-completions.nu")
use $goose_completions

# ─── sources ─────────────────────────────────────────────────────────

source $"($nu.cache-dir)/carapace.nu"
source ~/.zoxide.nu
