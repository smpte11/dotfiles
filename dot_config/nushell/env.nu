# env.nu
#
# Installed by:
# version = "0.110.0"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

$env.EDITOR = 'nvim'
$env.VISUAL = 'nvim'

$env.KUBECONFIG = $"($env.HOME)/.kube/kivra-app-01-vbg.yaml"

$env.RIPGREP_CONFIG_PATH = $"($env.HOME)/.config/ripgrep/.ripgreprc"

$env.SSH_AUTH_SOCK = $"($env.HOME)/.ssh/proton-pass-agent.sock"

use std/util "path add"

# linux
path add '/home/linuxbrew/.linuxbrew/bin'
path add '/home/linuxbrew/.linuxbrew/sbin'

# macos
path add '/opt/homebrew/bin'
path add '/opt/homebrew/sbin'

# kuberntes
path add $"($env.HOME)/.krew/bin"

# common
path add '/usr/local/bin'

## ${UserConfigDir}/nushell/env.nu
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"

zoxide init nushell --cmd cd | save -f ~/.zoxide.nu
