# Can tuios replace the herdr or tmux backend of firstmate?

Date: 2026-10-06

## Sources inspected

| Repo | Commit | Notes |
| --- | --- | --- |
| firstmate (github.com/kunchenguid/firstmate) | `5838f105008cb24bc999a819d3c5b50c2fd5675d` | main |
| tuios (github.com/Gaurav-Gosain/tuios, linked from tuios.dev/docs) | `5d627b1eeefbc95eb3b8810dad4381a254e36acb` | `v0.8.5-329-g5d627b1e`, built from source for the E2E checks below |
| herdr (github.com/herdrdev/herdr) | `3d9d2b18dab139ba226ebc5a1c9a9f2c9c3ee4df` | latest tag v0.9.3 |

Paths below are relative to each repo root. `fm:` is firstmate, `tu:` is tuios, `hd:` is herdr.

Locally installed tuios is 0.8.1 (`3832adf`), which has no herdr front (`herdr pane get` answers `unknown command ... for "tuios"`). Everything below needs a tuios built from main.

## Verdict

Feasible with a shim, not as-is. tuios already ships two compatibility layers that cover nearly every firstmate backend operation:

- a herdr front: tuios answers herdr 0.9.3's socket API and CLI (`tu:internal/herdrcli/doc.go:1-29`, `tu:internal/session/herdr_api.go:14-60`);
- a tmux shim: tuios answers tmux's CLI as a tmux 3.4 server (`tu:docs/TMUX_SHIM.md:1-53`).

Neither works unmodified with firstmate:

- herdr path: firstmate appends `--session <name>` to every herdr call (`fm:bin/backends/herdr.sh:387-410`, `fm:docs/herdr-backend.md:518`). herdr strips that flag anywhere before `--` (`hd:src/session.rs:31-95`). tuios's front only knows `--session` as a leading launch option and refuses it (`tu:internal/herdrcli/parse.go:96-102,130`). Trailing, it is a usage error, or worse, gets typed into the pane (verified below).
- tmux path: works through `tuios tmux-shim` with no wrapper when firstmate itself runs in a tuios pane, but caps at 8 concurrent task windows per session (one tmux window = one of 9 fixed tuios workspaces) and loses `#{cursor_y}`.

The best route is the herdr path plus a 5-line `herdr` wrapper that drops `--session`. The tmux route needs no wrapper but hits the 9-workspace cap sooner. Both share the same cap on tabs/windows.

## 1. firstmate backend contract

Backends are shell adapters in `fm:bin/backends/<name>.sh`, sourced through `fm_backend_source` (`fm:bin/fm-backend.sh:624-706`). The known list is hardcoded: `FM_BACKEND_KNOWN="tmux herdr zellij orca cmux"` (`fm:bin/fm-backend.sh:70`). Ops dispatch by `case "$backend"` in `fm:bin/fm-backend.sh:752-1107`. Spawn-time ops dispatch in `fm:bin/fm-spawn.sh:3627-3932`. A new backend name touches `fm-backend.sh` (28 case arms), `fm-spawn.sh` (10), `fm-afk-launch.sh` (10), `fm-control-lib.sh` (4) and others (grep count of `tmux)`/`herdr)` arms).

Auto-detection: `$TMUX` set picks tmux; else `HERDR_ENV=1` picks herdr (`fm:bin/fm-backend.sh:141-172`).

Required tools: tmux needs `tmux treehouse`; herdr needs `herdr jq treehouse` (`fm:bin/fm-backend.sh:308-317`).

| Op | tmux adapter | herdr adapter |
| --- | --- | --- |
| container ensure | `$TMUX` set: `tmux display-message -p '#S'`; else `tmux has-session -t firstmate \|\| tmux new-session -d -s firstmate` (`fm:bin/backends/tmux.sh:73-81`) | start named server if `status --json` says `.server.running != true`: `herdr server --session S` (`fm:bin/backends/herdr.sh:1656-1672`); find/create home workspace via `workspace list`/`workspace create` (`fm:bin/backends/herdr.sh:2023`) |
| create task | `tmux list-windows -t S -F '#{window_name}'`, `tmux new-window -dP -F '#{window_id}' -t "S:" -n NAME -c DIR`, `set-window-option automatic-rename off`, `allow-rename off` (`fm:bin/backends/tmux.sh:97-108`) | `tab list --workspace W`, `tab create --workspace W --cwd DIR --label L --no-focus` (`fm:bin/backends/herdr.sh:2494-2530`) |
| current path | `display-message -p -t T '#{pane_current_path}'` (`fm:bin/backends/tmux.sh:112-114`) | `pane get P` -> `.result.pane.foreground_cwd` (`fm:bin/backends/herdr.sh:3055-3059`) |
| send line + Enter | `send-keys -t T TEXT Enter` (`fm:bin/backends/tmux.sh:120-122`) | `pane run P TEXT` (`fm:bin/backends/herdr.sh:3065-3068`) |
| send literal | `send-keys -t T -l TEXT` (`fm:bin/backends/tmux.sh:128-130`) | `pane send-text P TEXT` (`fm:bin/backends/herdr.sh:3077-3083`) |
| send key | `display-message -p -t T '#{pane_id}'`, `send-keys -t T KEY` (`fm:bin/backends/tmux.sh:56-59`) | `pane send-keys P enter\|escape\|ctrl+c\|ctrl+u` (`fm:bin/backends/herdr.sh:3086-3109`) |
| capture (scrollback tail) | `capture-pane -p -t T -S -N` (`fm:bin/backends/tmux.sh:41-43`) | `pane read P --source recent --lines >=200`, tail locally (`fm:bin/backends/herdr.sh:3126-3135`) |
| visible capture | `capture-pane -p -t T -S -0` (`fm:bin/backends/tmux.sh:49-51`) | `pane read P --source visible [--format ansi]` (`fm:bin/backends/herdr.sh:3140-3148`) |
| composer read | `capture-pane -e -p -t T -S 0 -E -` and `#{cursor_y}` (`fm:bin/fm-tmux-lib.sh:76-84`), fed to shared `fm_composer_classify_screen` (`fm:bin/fm-composer-lib.sh:1743-1790`) | visible ansi read plus `agent get` identity (`fm:bin/backends/herdr.sh:3145-3148`, `:1888-1889`) |
| submit with verify | `fm_tmux_submit_core` (`fm:bin/backends/tmux.sh:65-67`) | send-text, then Enter retries confirmed by `agent get` status polls (`fm:bin/backends/herdr.sh:3682-3720`) |
| busy state | none, `unknown` (`fm:bin/fm-backend.sh:907-917`) | `agent get` `.result.agent.agent_status` plus `pane process-info` shell check (`fm:bin/backends/herdr.sh:3682-3692`) |
| agent liveness | `list-windows -t =S`, `#{pane_tty}`, `ps -t TTY` (`fm:bin/backends/tmux.sh:146-160,215-330`) | `pane process-info --pane P` (`.shell_pid`, `.foreground_processes[].argv`) (`fm:bin/backends/herdr.sh:1414`, `:2399`) |
| target exists | `display-message -p -t T '#{pane_id}'` (`fm:bin/fm-backend.sh:955-1000`) | `pane get P` (`fm:bin/fm-backend.sh:965-979`) |
| kill | `kill-window -t "=S:=W"`, re-read inventory on failure, parse `can't find session:` (`fm:bin/backends/tmux.sh:146-210`) | `pane close` / `tab close` (`fm:bin/backends/herdr.sh:3592`) |
| push events | none (`fm:bin/fm-backend.sh:1048-1053`) | gate: client protocol plus `events.subscribe` in `herdr api schema` (`fm:bin/backends/herdr.sh:3857`); raw AF_UNIX `events.subscribe` for `pane.agent_status_changed` (`fm:bin/backends/herdr-eventwait.py:1-35`); socket from `session list --json` `.socket_path` (`fm:bin/backends/herdr.sh:3837-3846`) |
| version gate | n/a | `herdr status --json` `.client.protocol >= MIN` (`fm:bin/backends/herdr.sh:520-540`) |
| session routing | `$TMUX` | `HERDR_SESSION` (default `default`) plus trailing `--session S` on every call (`fm:bin/backends/herdr.sh:387-410,545-547`) |

## 2. tuios programmatic control

Native (`tu:docs/CLI_REFERENCE.md`):

- Daemon with detachable sessions: `tuios new NAME --detach`, `attach`, `ls`, `kill-session`, `daemon` (`:290-330`, `:894-915`).
- Remote control with no client attached: `new-window [--workspace N] [--cwd] [--no-focus] [--print-id]` (`:1057-1095`), `send-keys -w` (`:943-1024`), `send-text -w` (`:1026-1055`), `capture-pane -w [-S] [--lines N] [--ansi]` (`:3053-3112`), `list-windows --json` incl. `agent_state` (`:2758-2800`), `close-window` (`:1292-1313`), `subscribe` event stream with `agent-state` events (`:1697-1752`), `wait-for` (`:1563`).
- Native agent-state detection for Claude Code, Codex, Pi, etc. via hooks/screen rules (`tu:docs/AGENT_STATE.md:89-116`).
- Pane grants gate every call from inside a pane (`tu:docs/CONFIGURATION.md:1048-1060`).

herdr front:

- Every pane gets `HERDR_ENV=1`, `HERDR_SOCKET_PATH=<daemon socket>.herdr`, `HERDR_PANE_ID`, `HERDR_TAB_ID`, `HERDR_WORKSPACE_ID`, `HERDR_BIN_PATH` (`tu:docs/AGENT_STATE.md:337-346`).
- `HERDR_BIN_PATH` is a link named `herdr` to tuios at `$XDG_RUNTIME_DIR/tuios/herdr/bin/herdr`, deliberately not on `PATH` (`tu:docs/AGENT_STATE.md:451-456`).
- Mapping: herdr workspace = tuios session, herdr tab = tuios workspace slot, herdr pane = tuios window (`tu:docs/AGENT_STATE.md:545-560`).
- Methods answered include workspace/tab/pane list/get/create/close, `pane.read`, `pane.send_text/keys/input`, `pane.process_info`, `agent.get`, `events.subscribe` (`tu:internal/session/herdr_api.go:253-318`, `tu:internal/session/herdr_events.go:14-37`). Reports version `0.9.3+tuios`, protocol 22 (`tu:docs/AGENT_STATE.md:537-540`).
- `status --json` pings the socket and prints herdr's `client`/`server` shape (`tu:internal/herdrcli/run.go:249-300`). `session list --json` lists one session `default` with `socket_path` (`tu:internal/herdrcli/run.go:320-331`).
- Unsupported: `api schema` (`tu:internal/herdrcli/groups.go:559-568`), `server stop` and server launch (`:572-583`, `parse.go:96-102`), `session attach/stop/delete` (`groups.go:676-689`).
- Differences: `pane.send_text` is a bracketed paste with control chars stripped (`tu:docs/AGENT_STATE.md:715-727`); `tab.create` uses the first free workspace slot and fails `tab_create_failed` when all are taken (`tu:internal/session/herdr_api.go:667-684`); slot count defaults to 9 (`tu:internal/session/session_ops.go:19`).

tmux shim:

- `tuios tmux-shim -- CMD` puts a `tmux` link first on `PATH` and sets `TMUX`/`TMUX_PANE` for CMD (`tu:docs/TMUX_SHIM.md:34-53`). Outside a pane, use the link with `-S $XDG_RUNTIME_DIR/tuios/tmux/socket` (`:57-80`).
- tmux window = tuios workspace, tmux pane = tuios window (`:95-102`). `new-window` takes the lowest empty workspace, else `create window failed: every tuios workspace already holds panes` (`tu:internal/tmuxcompat/shim.go:597-606`).
- Commands: `new-window -dP -F`, `send-keys [-l]`, `capture-pane -p -S -E -e`, `display-message -p`, `list-windows`, `has-session`, `new-session -d`, `kill-window` (`tu:docs/TMUX_SHIM.md:181-200`). `set-window-option` succeeds as a no-op (`:213-216`). `=` exact-match targets accepted (`tu:internal/tmuxcompat/view.go:463`).
- Format variables include `pane_tty`, `pane_current_command`, `pane_current_path`, `pane_id`, `window_id`; `cursor_y` is not listed and expands to nothing (`tu:docs/TMUX_SHIM.md:136-152`).
- In a pane, `new-session` is refused and other sessions are unreachable (`:107-109`, `:191`).

## 3. Mapping

Legend: S supported, P partial, M missing. "E2E" means checked against a tuios built at the commit above, in an isolated daemon.

### Via the herdr front

| firstmate op | tuios | Status | Evidence |
| --- | --- | --- | --- |
| trailing `--session S` on every call | refused or mis-parsed | M | E2E: `workspace list --session default` -> `usage: herdr workspace list` exit 2; `tab create ... --session default` -> `unknown option: --session`; `status --json --session default` -> usage exit 2; `pane send-keys P enter --session default` -> `invalid_key ... --session`; `pane send-text P "echo hi" --session default` exit 0 and typed `echo hi --session default` into the pane. Cause: `tu:internal/herdrcli/pane.go:26-30,95-109`, `parse.go:96-102` |
| version gate `status --json .client.protocol` | protocol 22 | S | `tu:internal/herdrcli/run.go:259-262` |
| server ensure | `.server.running` true while daemon up; `herdr server` refused | P | `run.go:269-272`; firstmate never needs to launch it if tuios is running |
| workspace list/create | sessions | S | E2E `workspace list` |
| tab create `--workspace --cwd --label --no-focus` | workspace slot | P | E2E OK for tabs 2-9, tab 10 -> `tab_create_failed ... 9 workspaces` |
| pane get `.foreground_cwd` | yes | S | E2E |
| pane run | `pane.send_input` (paste + Enter) | S | E2E |
| pane send-text | paste, ctrl chars stripped | P | `tu:docs/AGENT_STATE.md:715-727` |
| pane send-keys enter/escape/ctrl+c/ctrl+u | yes | S | E2E (without trailing flag) |
| pane read recent/visible/ansi | 80 default, 1000 max lines | S | E2E; `tu:docs/AGENT_STATE.md:636` |
| pane process-info --pane | shell_pid, pgid, argv, cmdline | S | E2E; argv needs `write`/`admin` grant (`tu:docs/AGENT_STATE.md:648`) |
| agent get `.agent.agent_status` | mapped from tuios state | S | `tu:internal/session/herdr_api.go:1164-1209`; `agent_not_found` for a plain shell (E2E) |
| pane/tab close | yes | S | `herdr_api.go:267,280` |
| push events gate (`api schema`) | unsupported | P | `groups.go:566-567`; firstmate falls back to polling (`fm:bin/fm-backend.sh:1040-1047`). `events.subscribe` itself exists (`tu:internal/session/herdr_events.go:381`), so `FM_BACKEND_HERDR_EVENTS_FORCE=1` could enable it (untested) |
| socket path from `session list --json` | `default` at `<sock>.herdr` | S | `run.go:320-331`; matches firstmate default session (`fm:bin/backends/herdr.sh:545-547`) |
| `terminal title` | `client.window_title.set` | S | `groups.go:620-635` |
| typing into a pane blocked on a prompt | needs `respond` grant | P | `tu:internal/session/pane_grants.go:929-930`; default `open` mode gives `admin` without `respond` (`tu:docs/CONFIGURATION.md:1053-1060`) |

### Via the tmux shim

| firstmate op | Status | Evidence |
| --- | --- | --- |
| container ensure (in pane, `$TMUX` set) | S | shim sets `TMUX` (`tu:docs/TMUX_SHIM.md:39-40`) |
| container ensure (outside pane) | P | E2E `has-session`/`new-session -d -s firstmate` OK, but only with `-S <socket>`, which firstmate never passes (`TMUX_SHIM.md:57-71`) |
| new-window -dP -F '#{window_id}' -t S: -n -c | P | E2E prints `@380958002`; 9th and 10th window fail (`every tuios workspace already holds panes`) |
| set-window-option automatic-rename off | S (no-op) | E2E exit 0 |
| list-windows -t =S -F '#{window_name}' | S | E2E |
| display-message pane_id/pane_tty/pane_current_command/pane_current_path | S | E2E `%304377061\|/dev/ttys017\|zsh\|/private/tmp` |
| `#{cursor_y}` | M | E2E empty. firstmate then falls back to cursorless classification (`fm:bin/fm-composer-lib.sh:1757-1762`), same as herdr |
| send-keys -l / Enter | S | E2E |
| capture-pane -p -S -N / -S -0 / -e -S 0 -E - | S | E2E |
| kill-window -t =S:=W, `can't find session:` on missing | S | E2E |
| `ps -t pane_tty` liveness | S | real tty given (E2E) |

## 4. Shim sketch (herdr route)

Put this first on `PATH` as `herdr` for firstmate, running inside a tuios pane (so `HERDR_SOCKET_PATH` and `HERDR_BIN_PATH` are set):

```sh
#!/bin/sh
n=$#
i=0
drop=
while [ "$i" -lt "$n" ]; do
  a=$1; shift; i=$((i + 1))
  if [ -n "$drop" ]; then drop=; continue; fi
  case "$a" in
    --)
      set -- "$@" "$a"
      while [ "$i" -lt "$n" ]; do set -- "$@" "$1"; shift; i=$((i + 1)); done
      break ;;
    --session) drop=1; continue ;;
    --session=*) continue ;;
  esac
  set -- "$@" "$a"
done
exec "$HERDR_BIN_PATH" "$@"
```

It drops `--session` before `--`, as herdr does (`hd:src/session.rs:59-80`). E2E against the isolated daemon: `status --json --session default` -> protocol 22, running true; `session list --json --session default` -> `default`, running; `pane send-text P "echo wrapped ok" --session default` then `pane send-keys P enter --session=default` typed and ran exactly `echo wrapped ok`.

Plus:

- run firstmate under tuios with `[agents.permissions] grants = ["admin", "respond"]` (`tu:docs/CONFIGURATION.md:706-707`) so it can send Escape/C-c to a crew blocked on a prompt;
- keep `FM_BACKEND_HERDR_SESSION` at `default`;
- accept at most 8 concurrent task tabs per home workspace, or raise the session's workspace count (`NumWorkspaces`, `tu:internal/session/session.go:506-511`; no documented config key found);
- optionally `FM_BACKEND_HERDR_EVENTS_FORCE=1` to use tuios's `events.subscribe` instead of polling.

Hazard: inside any tuios pane `HERDR_ENV=1` is set, so firstmate auto-detects herdr (`fm:bin/fm-backend.sh:153-158`). Without the wrapper, `command -v herdr` finds a real herdr if installed, and herdr's explicit `--session` wins over the inherited `HERDR_SOCKET_PATH` (`hd:src/session.rs:82-84`), so firstmate silently drives the real herdr server instead of tuios.

## 5. Upstream changes that would remove the shim

tuios:

1. herdrcli: strip `--session NAME` / `--session=NAME` anywhere before `--`, as herdr does (`hd:src/session.rs:55-80`), and accept `default` (or any name) as the one session. Fixes the text-injection hazard too.
2. Per-session workspace count above 9 for agent fleets, or `tab.create` / tmux `new-window` that can add slots.
3. tmux shim: `cursor_y`/`cursor_x` format variables (data exists in tuios session state, `tu:internal/session/session.go`).
4. `api schema`: ship a schema or a minimal one listing implemented methods, so capability gates like firstmate's pass.
5. Drop a workspace (herdr tab) when its last pane closes, as herdr does, so slots are not leaked (section 6).
6. Report a pane at a harness prompt (e.g. Claude's folder-trust dialog) as blocked/needs_input rather than working.

firstmate:

1. Herdr adapter: pass `--session` only when the session is not `default`, or detect `+tuios` in `status --json .client.version` and drop it.
2. Optional first-class `tuios` backend using the native CLI (`new-window --print-id`, `send-text -w`, `send-keys -w`, `capture-pane -w --ansi`, `list-windows --json` agent_state, `subscribe --types agent-state`), registered in `FM_BACKEND_KNOWN` and the ~50 dispatch arms listed in section 1. More work than the herdr-front route for little gain.

## 6. Applied setup and E2E results (2026-10-06)

Setup in this repo:

- tuios from main via mise: `"go:github.com/Gaurav-Gosain/tuios/cmd/tuios" = "main"` (`dot_config/mise/config.toml`). Release 0.8.5 is not enough: its herdr front refuses `status --json` and `session list --json`, which firstmate's version check needs (`fm:bin/backends/herdr.sh:523`). Both landed on main after 0.8.5 (`tu:6103c96`, `tu:655ac1a`).
- The section 4 wrapper as `~/.local/share/firstmate-tuios/bin/herdr`, prepended to `PATH` only inside `_fm-launch` (zsh, bash, nushell). It falls back to `$(dirname "$HERDR_SOCKET_PATH")/herdr/bin/herdr` when `HERDR_BIN_PATH` is unset.
- `[agents.permissions] mode = 'strict'`, `grants = ['admin', 'respond']`. `grants` only applies under `strict`; it is the default for every pane, not only firstmate's.
- `[hooks] after-close-window` runs `~/.config/tuios/hooks/close-empty-tabs` (see the slot leak below).

Real herdr hazard, confirmed: with a real `herdr server --session default` running, the real herdr client with `--session default` reaches that server and ignores `HERDR_SOCKET_PATH`. The wrapper is required, not optional.

E2E through firstmate's own backend functions (`fm_backend_herdr_container_ensure`, `fm_backend_herdr_create_task`, `fm_backend_*` dispatch), scratch `FM_HOME`, tuios daemon on main:

| Step | Result |
| --- | --- |
| `version_check` | ok (`0.9.3+tuios`, protocol 22) |
| `container_ensure`, `create_task` | ok, target `default:<pane_id>` |
| `send_text_submit`, `capture` | ok, command ran and output read back |
| `send_key C-c`, `has_push` | ok, push available |
| `kill`, `target_exists` after | pane gone |
| Claude at its folder-trust prompt | `agent_state` alive, `busy_state` **busy** (not blocked); `Escape` answered the prompt |

Slot leak: tuios keeps a herdr tab (tuios workspace) with zero panes and its label after its last pane closes, and `tab create` does not reuse it. firstmate closes tasks by closing or killing the pane and expects herdr to drop the emptied tab, so each finished task held one of the 9 slots for good. `herdr tab close` on the empty tab frees it. Workaround: the `after-close-window` hook closes every zero-pane tab that is not its session's last. Verified for a direct `pane close` and for `fm_backend_kill`.

Open: blocked prompts read as `busy`, so firstmate cannot tell a stuck crew from a working one; at most 8 concurrent tasks per firstmate workspace.
