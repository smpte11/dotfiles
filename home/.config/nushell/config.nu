# config.nu
#
# Nushell configuration. Previously split between `env.nu` and `config.nu`;
# `env.nu` is deprecated upstream so everything now lives here.
# See https://www.nushell.sh/book/configuration.html

# ─── environment variables ───────────────────────────────────────────

$env.EDITOR = 'nvim'
$env.VISUAL = 'nvim'

$env.K9S_CONFIG_DIR = $"($env.HOME)/.config/k9s"

$env.RIPGREP_CONFIG_PATH = $"($env.HOME)/.config/ripgrep/.ripgreprc"

# Canonical firstmate operational home. Without it, firstmate scripts fall
# back to the repo root as the home and create a second one there.
$env.FM_HOME = $"($env.HOME)/.local/state/firstmate"

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
path add $"($env.HOME)/.nix-profile/bin"
path add '/nix/var/nix/profiles/default/bin'

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

mkdir ($nu.data-dir | path join "vendor/autoload")
tv init nu | save -f ($nu.data-dir | path join "vendor/autoload/tv.nu")
^mise activate nu | save -f ($nu.data-dir | path join "vendor/autoload/mise.nu")
zoxide init nushell --cmd cd | save -f ($nu.data-dir | path join "vendor/autoload/zoxide.nu")

oh-my-posh init nu --config ~/.config/ohmyposh/.minischeme.omp.toml

# ─── aliases ─────────────────────────────────────────────────────────

alias ll = ls -l

alias jj = jj --color=always
alias jjui = env -u NO_COLOR TERM=xterm-256color jjui
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
            if $is_stderr {
                ^gum style --border normal --border-foreground $color --bold $message | print -e
            } else {
                ^gum style --border normal --border-foreground $color --bold $message | print
            }
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

def --wrapped switch-theme [...args: string] {
    ^mise run theme:switch ...$args
}

const ocaml_module = ($nu.config-path | path dirname | path join "ocaml.nu")
use $ocaml_module *

const firstmate_module = ($nu.config-path | path dirname | path join "firstmate.nu")
use $firstmate_module *

# ─── sources ─────────────────────────────────────────────────────────

source $"($nu.cache-dir)/carapace.nu"
