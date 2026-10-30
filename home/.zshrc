# .zshrc
#
# Interactive-shell setup: vendor integrations, completions, aliases,
# custom commands. Env vars and PATH live in .zshenv instead.
# Mirrors dot_config/nushell/config.nu.

bindkey -v

[[ -t 0 ]] && stty -ixon

# ─── vendor integrations ───────────────────────────────────────────────

autoload -Uz compinit && compinit

zstyle ':completion:*' menu no
zstyle ':fzf-tab:*' query-string prefix first
source "$HOME/.local/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"
source "$HOME/.local/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

if [ -f "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc" ]; then
  source "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc"
fi

eval "$(mise activate zsh)"
eval "$(zoxide init zsh --cmd cd)"
eval "$(tv init zsh)"
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/.minischeme.omp.toml)"

source <(carapace _carapace zsh)

# ─── aliases ────────────────────────────────────────────────────────────

alias ls='eza --group-directories-first --icons=auto --color=auto'
alias l='eza -blF --git --header --group-directories-first --icons=auto --color=auto'
alias ll='eza -la --git --header --octal-permissions --group-directories-first --icons=auto --color=auto'
alias la='eza -la --git --header --group-directories-first --icons=auto --color=auto'
alias lm='eza -l --git --header --sort=modified --reverse --group-directories-first --icons=auto --color=auto'
alias l1='eza --oneline --group-directories-first --icons=auto --color=auto'
alias lt='eza --tree --level=2 --group-directories-first --icons=auto --color=auto'
alias l.='eza -a --oneline --color=never | grep -E "^\."'

# ─── custom commands ────────────────────────────────────────────────────

disable -r repeat 2>/dev/null

repeat() {
  if [ "$#" -lt 2 ]; then
    echo "Usage: repeat COUNT [-q] COMMAND [ARGS...]" >&2
    return 1
  fi

  local count="$1"
  shift

  local quiet=0
  local -a rest
  for a in "$@"; do
    if [ "$a" = "-q" ] || [ "$a" = "--quiet" ]; then
      quiet=1
    else
      rest+=("$a")
    fi
  done
  set -- "${rest[@]}"

  if [ "$count" -le 0 ]; then
    echo "COUNT must be a positive integer" >&2
    return 1
  fi

  local pretty="$*"

  _repeat_banner() {
    [ "$quiet" -eq 1 ] && return
    local color="$1" message="$2" to_stderr="$3"
    if [ "$to_stderr" = 1 ]; then
      gum style --border normal --border-foreground "$color" --bold "$message" >&2
    else
      gum style --border normal --border-foreground "$color" --bold "$message"
    fi
  }

  local i rc
  for ((i = 1; i <= count; i++)); do
    _repeat_banner blue "▶ Run $i/$count: $pretty" 0
    "$@"
    rc=$?
    if [ "$rc" -ne 0 ]; then
      _repeat_banner red "✖ Failed with code $rc on run $i/$count" 1
      return "$rc"
    fi
  done

  _repeat_banner green "✓ Successfully completed all $count runs" 0
}

switch-theme() {
  mise run theme:switch "$@"
}

opam-env() {
  eval "$(opam env)"
}

_fm-launch() {
  local harness="$1"
  local herdr_socket
  if [ -n "$XDG_RUNTIME_DIR" ]; then
    herdr_socket="$XDG_RUNTIME_DIR/tuios/tuios.sock.herdr"
  else
    herdr_socket="/tmp/tuios-$(id -u)/tuios.sock.herdr"
  fi
  (
    cd "$HOME/.local/share/firstmate" || return 1
    export FM_HOME="$HOME/.local/state/firstmate"
    export FM_BACKEND=herdr
    export HERDR_SOCKET_PATH="$herdr_socket"
    export PATH="$(dirname "$herdr_socket")/herdr/bin:$PATH"
    case "$harness" in
      claude) claude ;;
      pi) pi ;;
      *) echo "unknown harness: $harness" >&2; return 1 ;;
    esac
  )
}

fm() {
  local harness
  harness=$(gum choose --selected="${FM_HARNESS:-pi}" claude pi)
  [ -z "$harness" ] && return 1
  _fm-launch "$harness"
}
fm-claude() { _fm-launch claude; }
fm-pi() { _fm-launch pi; }
