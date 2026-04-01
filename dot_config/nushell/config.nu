# config.nu
#
# Installed by:
# version = "0.110.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

$env.config.show_banner = false

$env.config.buffer_editor = "nvim"

$env.config.edit_mode = "vi"

oh-my-posh init nu --config ~/.config/ohmyposh/.minischeme.omp.toml

mkdir ($nu.data-dir | path join "vendor/autoload")
tv init nu | save -f ($nu.data-dir | path join "vendor/autoload/tv.nu")

mkdir ($nu.data-dir | path join "vendor/autoload")
^mise activate nu | save -f ($nu.data-dir | path join "vendor/autoload/mise.nu")

# custom aliases
alias ll = ls -l

# custom command
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

# ${UserConfigDir}/nushell/config.nu
source $"($nu.cache-dir)/carapace.nu"
source ~/.zoxide.nu
