# What would a native, EXPERIMENTAL `tuios` backend for firstmate take?

Date: 2026-10-06

Builds on [2026-10-06-tuios-firstmate-backend.md](2026-10-06-tuios-firstmate-backend.md) (the herdr-front route, its wrapper, slot leak, 9-slot cap). That doc is not repeated here.

## Sources inspected

| Repo | Commit | Notes |
| --- | --- | --- |
| firstmate | `5838f105008cb24bc999a819d3c5b50c2fd5675d` | local checkout `~/.local/share/firstmate`, read-only |
| tuios | `0291286b22c14a234409a41204788157bf4b42b2` | main, 2026-10-06; 337 commits after `v0.8.5` (`0f70da9d`, 2026-10-02) |
| tuios binary | built from main via mise (`tuios --version` prints `dev`) | `tuios --skill <topic>`, `tuios list-verbs --json` |

`fm:` is firstmate, `tu:` is tuios. "E2E" means checked against an isolated tuios daemon (fresh `XDG_RUNTIME_DIR`/`XDG_STATE_HOME`/`XDG_CONFIG_HOME`), since deleted. The live daemon was only read.

## Verdict

| Question | Answer |
| --- | --- |
| Feasible? | Yes. Every firstmate operation has a native tuios verb, and the verbs firstmate needs already exist in released tuios 0.8.5 (`tu:internal/session/verb_protocol.go` same verbs/params at `v0.8.5`). The herdr-front route needs tuios main. |
| Better than the herdr front? | Yes on structure: no tab/slot object, so no slot leak and no 9-task cap; real `needs_input` state; JSON events; per-task sessions. No on cwd: the native `cwd` misses the treehouse subshell (E2E), same as zellij/cmux, so it needs their marker probe. |
| Size | Similar to zellij/cmux: about 2.0k to 2.5k added lines for parity, plus 0.6k to 0.9k for native agent state and push events. About 27 required case arms outside the adapter, plus 10 for the native extras. |
| Recommendation | Keep the herdr-front route for now and land the small tuios fixes (section 6). Open a firstmate issue proposing an explicit-only EXPERIMENTAL `tuios` backend. Build it only once the maintainer agrees. A private fork of a 5.5k-line `fm-spawn.sh` that changes every day is the main risk. |

## 1. firstmate backend contract

### 1a. Selection, detection, validation

| Item | Where | tuios impact |
| --- | --- | --- |
| Known/spawn lists | `FM_BACKEND_KNOWN`, `FM_BACKEND_SPAWN` (`fm:bin/fm-backend.sh:70-71`) | add `tuios` to both |
| Selection order | `FM_BACKEND` > `config/backend` > `fm_backend_detect` > `tmux` (`fm:bin/fm-backend.sh:243-273`) | explicit selection works with no detection change |
| Detection | `$TMUX` > `HERDR_ENV=1` > `CMUX_WORKSPACE_ID` > cmux fallbacks (`fm:bin/fm-backend.sh:140-167`) | every tuios pane sets `HERDR_ENV=1` (E2E env dump), so auto-detect picks herdr today. A tuios arm must come before the herdr one |
| Notice | auto-detected EXPERIMENTAL cmux prints a stderr NOTICE (`fm:bin/fm-backend.sh:261-269`) | copy for tuios if it is auto-detected |
| Spawn validation | `fm_backend_validate_spawn` (`fm:bin/fm-backend.sh:286-292`), called at `fm:bin/fm-spawn.sh:1690` and on relaunch `:1748` | list membership only |
| Required tools | `fm_backend_required_tools` (`fm:bin/fm-backend.sh:308-317`); cmux also has its own resolver (`:324-327`) | `tuios jq treehouse` |
| Endpoint validation | `fm_backend_validate_task_endpoint` per-backend arm (`fm:bin/fm-backend.sh:465-547`); requires `endpoint_task_id=` binding, exact single-valued keys, `fm_backend_endpoint_atom_valid` charset `[A-Za-z0-9._@%+-]` (`:382-385`) | uuids and `fm-...` session names pass |
| Adapter sourcing | sibling list per backend (`fm:bin/fm-backend.sh:630-649`) and a source-once guard (`:655-691`) | `fm-backend-hometag-lib.sh fm-composer-lib.sh`, plus `fm-transition-lib.sh fm-agent-process-lib.sh` for the native extras (herdr's list, `:635`) |
| Meta | `backend=` written for non-tmux; backend keys appended (`fm:bin/fm-spawn.sh:4981-5000`) | `tuios_session=`, `tuios_window_id=` |
| Target | `window=` read by `fm_backend_target_of_meta` (`fm:bin/fm-backend.sh:354-363`) | `window=<session>:<window-uuid>` |
| Worktrees | treehouse for every session-provider backend; only orca owns worktrees (`fm:bin/fm-backend.sh:880-898`, `fm:docs/configuration.md:425`) | tuios stays session-provider only. Ignore `tuios worktree` |

### 1b. Functions `bin/backends/tuios.sh` must implement

Required for parity with zellij/cmux (`fm:bin/backends/zellij.sh` has 30 functions, `fm:bin/backends/cmux.sh` 29):

| # | Function | Called from |
| --- | --- | --- |
| 1 | `fm_backend_tuios_tool_check` | version/spawn preflight (pattern `fm:bin/backends/zellij.sh:170`) |
| 2 | `fm_backend_tuios_version_check` | spawn preflight (`fm:bin/backends/zellij.sh:179`) |
| 3 | `fm_backend_tuios_cli` | wrapper that pins the session and parses `--json`/error codes (`fm:bin/backends/zellij.sh:210`) |
| 4 | `fm_backend_tuios_container_ensure` | `fm:bin/fm-spawn.sh` create branch (zellij `:3850-3860`, cmux `:3862-3872`) |
| 5 | `fm_backend_tuios_create_task` | same; prints `<session> <window_id>` |
| 6 | `fm_backend_tuios_parse_target` | every op |
| 7 | `fm_backend_tuios_target_ready` | `fm_backend_target_exists` (`fm:bin/fm-backend.sh:955-992`) |
| 8 | `fm_backend_tuios_current_path` | `spawn_current_path` (`fm:bin/fm-spawn.sh:3921-3928`), used by worktree detection `:4348` and `:3970` |
| 9 | `fm_backend_tuios_send_literal` | `spawn_send_literal` (`fm:bin/fm-spawn.sh:3929-3937`) |
| 10 | `fm_backend_tuios_send_key` | `spawn_send_key` (`:3938-3946`), `fm_backend_send_key` (`fm:bin/fm-backend.sh:797-809`); keys `Escape Enter C-c C-u` (`fm:bin/fm-control-lib.sh:278-290`) |
| 11 | `fm_backend_tuios_send_text_line` | `spawn_send_text_line` (`fm:bin/fm-spawn.sh:3912-3920`) |
| 12 | `fm_backend_tuios_capture` | `fm_backend_capture` (`fm:bin/fm-backend.sh:752-764`) |
| 13 | `fm_backend_tuios_visible_capture` | `fm_backend_visible_capture` (`:785-794`), gated by `FM_BACKEND_VISIBLE_CAPTURE` (`:773`); Kimi spawns refuse without it (`fm:bin/fm-spawn.sh:2753-2755`) |
| 14 | `fm_backend_tuios_composer_state` (+ `_composer_capture`, `_composer_content`, `_composer_observed_append` helpers) | `fm_backend_composer_state` (`fm:bin/fm-backend.sh:929-941`), pre-submit dialog check (`:831-840`) |
| 15 | `fm_backend_tuios_send_text_submit` | `fm_backend_send_text_submit` (`fm:bin/fm-backend.sh:816-851`); zellij shape `fm:bin/backends/zellij.sh:578-590` via `fm_composer_submit_retry_core` |
| 16 | `fm_backend_tuios_kill` | `fm_backend_kill` (`fm:bin/fm-backend.sh:865-878`), spawn rollback `fm:bin/fm-spawn.sh:4215`, teardown `fm:bin/fm-teardown.sh:3622,3718` (children `:3269-3272`) |
| 17 | `fm_backend_tuios_list_live` | recovery/orphan listing; only tests call it today (`fm:tests/fm-backend-cmux-smoke.test.sh:180`) |

Native extras (only tmux/herdr implement these today):

| # | Function | Called from | Effect |
| --- | --- | --- | --- |
| 18 | `fm_backend_tuios_agent_state` (alive/dead/missing/unreadable) | `fm_backend_agent_state` (`fm:bin/fm-backend.sh:1014-1022`); relaunch gate `fm:bin/fm-spawn.sh:1753-1786`; `fm:bin/fm-watch.sh:541,904,1470`; `fm:bin/fm-crew-state.sh:1265`; `fm:bin/fm-teardown.sh:1185` | enables `--relaunch` and confirmed-dead recovery, which zellij/cmux refuse (`fm:bin/fm-control-lib.sh:292-300`) |
| 19 | `fm_backend_tuios_busy_state` | `fm_backend_busy_state` (`fm:bin/fm-backend.sh:907-915`); `fm:bin/fm-busy-lib.sh:1082`, `fm:bin/fm-supervise-daemon.sh:699` | native busy |
| 20 | `fm_backend_tuios_events_capable` | `fm:bin/fm-backend.sh:1059-1068`, `fm:bin/fm-watch.sh:2330` | push gate |
| 21 | `fm_backend_tuios_wait_transition` | `fm:bin/fm-backend.sh:1076-1085`, `fm:bin/fm-watch.sh:2342`; contract rc 0 record / 1 timeout / 2 unusable (`fm:bin/backends/herdr.sh:3958-3965`) | fast `blocked` escalation |
| 22 | `fm_backend_tuios_commit_transition` | `fm:bin/fm-backend.sh:1087-1096` | dedupe marker |
| 23 | `fm_backend_tuios_clear_transition` | `fm:bin/fm-backend.sh:1098-1107` | dedupe marker |

Records go through `fm_transition_record` and the shared policy `blocked->actionable, working->absorb, idle|done->defer` (`fm:bin/fm-transition-lib.sh:39-43,97-102`).

Total: 17 required (+3 composer helpers) and 6 optional native.

### 1c. Case arms outside the adapter

| File | Arms (line) | Required? |
| --- | --- | --- |
| `fm:bin/fm-backend.sh` | KNOWN `70`, SPAWN `71`, required_tools `308-317`, validate_task_endpoint `465-547`, source siblings `630-649`, source guard `655-691`, capture `756-763`, visible-capture list `773`, send_key `801-808`, send_text_submit `841-848`, kill `870-877`, composer_state `933-940`, target_exists `957-991` | 13 required |
| `fm:bin/fm-backend.sh` | busy_state `911-914`, agent_state `1017-1021`, has_push `1049-1052`, events_capable `1064-1067`, wait_transition `1081-1084`, commit `1092-1095`, clear `1103-1106` | 7 native |
| `fm:bin/fm-backend.sh` | detect `140-167`, notice `261-269` | 2 if auto-detected |
| `fm:bin/fm-spawn.sh` | create branch (next to `3850-3872`), send_text_line `3913`, current_path `3922`, send_literal `3930`, send_key `3939`, meta keys `4981-5000` | 6 required |
| `fm:bin/fm-spawn.sh` | `--secondmate` refusal like cmux `1696-1699` | 1 optional |
| `fm:bin/fm-control-lib.sh` | key support `282` | 1 required |
| `fm:bin/fm-control-lib.sh` | state_verified `299`; `fm:bin/fm-crew-state.sh:1265-1270`; `fm:bin/fm-busy-lib.sh:1082` | 3 native |
| `fm:bin/fm-bootstrap.sh` | install hint `802-803` | 1 required |
| `fm:bin/fm-test-run.sh` | family `412-417`, gate-skip `448`, family list `466-467`, timing `697-702`, changed-path map `1451-1456` | 5 required |
| `fm:bin/fm-test-isolation-proof.sh` | `145-149` | 1 required |
| `fm:bin/fm-afk-launch.sh` | record `430-435`, close `447-463`, absent `468-490`, alive `507-516`, create `755-762` (only herdr/tmux today; zellij/cmux skipped it) | 5 optional |

Count: 27 required, 10 native, 8 optional. Peek, send, teardown and watch go through the generic dispatch and need no arm (`fm:bin/fm-teardown.sh:3266` is zellij-only). The supervisor daemon backend (`FM_SUPERVISOR_BACKEND=tmux|herdr`, `fm:docs/configuration.md:530-537`) is a separate axis, out of scope.

## 2. Template: how zellij and cmux were added

| | zellij | cmux |
| --- | --- | --- |
| Initial PR | `e16f1d82` #217, 2026-07-03: 22 files, +1896/-54 | `4a128445` #246, 2026-07-04: 16 files, +2070/-40 |
| Adapter LOC (initial / now) | 521 / 708 | 610 / 653 |
| Follow-up commits on adapter | 11 | 16 |
| Unit test (faked CLI) | `tests/fm-backend-zellij.test.sh` 792 / 1360 lines | `tests/fm-backend-cmux.test.sh` 919 / 1166 |
| Real smoke test | `tests/fm-backend-zellij-smoke.test.sh` 205, unique session, skips without binary (`:19-20`) | `tests/fm-backend-cmux-smoke.test.sh` 188 |
| Safety guard | `tests/zellij-test-safety.sh` 60, refuses session `firstmate` | `tests/cmux-test-safety.sh` 51 |
| Guide | `docs/zellij-backend.md` 114 lines | `docs/cmux-backend.md` 133 lines |
| Evidence | `docs/verification/runtime-backends.md:1855-1910` | `:1911-1981` |
| CI | no lane; family is `optional-binary` (`fm:bin/fm-test-run.sh:448`) | same |
| Auto-detection | never ("explicit-only", `fm:docs/zellij-backend.md:3,19`) | yes, with NOTICE (`fm:docs/cmux-backend.md:42,51-62`) |
| Agent state / push | none (`fm:docs/zellij-backend.md` "Active limits") | none (`fm:docs/cmux-backend.md:120`) |

Contribution rules: backend changes keep setup and limits in the backend guide and evidence in `docs/verification/runtime-backends.md` (`fm:CONTRIBUTING.md:77`). A backend is added only after its own adapter and empirical verification (`fm:bin/fm-backend.sh:57-69`). Experimental backends have "no dedicated real-backend CI lane" (`fm:CONTRIBUTING.md:63`, `fm:docs/configuration.md:420-423`). Doc edits the earlier PRs also made: `README.md` (`:45,53,145,161,225-227`), `docs/configuration.md` (home isolation `:67`, backend table `:420-425`, detection `:435-447`, metadata `:479`, tools `:1264-1273`, env `:2268`), `docs/architecture.md`, `docs/scripts.md`, `docs/documentation-audiences.json` (`:33,98,316`).

## 3. firstmate ops mapped to native tuios

Verb definitions: `tu:internal/session/verb_protocol.go` (line of each verb below). CLI docs: `tu:docs/CLI_REFERENCE.md`.

| firstmate op | Native tuios | Status | Evidence |
| --- | --- | --- | --- |
| container ensure | `new-session` verb: `name`, `window_name`, `cwd`, `width`, `height`, returns `session`, `window_id` in one call | S | `verb_protocol.go:450`; E2E returned `window_id` and a 200x50 window |
| create task | per-task session (above), or `new-window -s S NAME --cwd D --no-focus --print-id` | S | `verb_protocol.go:931`; `CLI_REFERENCE.md:1057`; E2E 13 windows on one workspace (`workspace_windows [13,0,...]`), 12 sessions, no cap |
| duplicate-label check | `list-windows --json` `.custom_name`, `ls --json` session names | S | E2E; name collisions are an error, never a guess (`tuios --skill`, "Addressing things") |
| target exists / gone | `get-window`; socket error codes `window_not_found`, `session_not_found` | S | `verb_protocol.go:920`; E2E codes. The CLI prints prose errors, exit 1, no code |
| current path | `list-windows --json .cwd` | P | `.cwd` is the shell's OSC 7 report, else the shell process cwd, never the foreground child (`tu:internal/session/session.go:2124-2150`). E2E: top-level `cd` tracked; a `zsh -c 'cd X && exec zsh -i'` subshell stayed on the old dir. treehouse enters a subshell, so worktree detection (`fm:bin/fm-spawn.sh:4310-4364`) needs zellij's marker probe (`fm:docs/zellij-backend.md`, "pane_cwd follows a top-level shell cd but not the foreground subshell") |
| send literal | `send-text -w W TEXT` (verbatim) | S | `verb_protocol.go:1166`; E2E |
| send paste / harness submit | `send-text` `paste:true` / `submit:true` (harness Enter from manifest `[input]`) | P | socket only; CLI has no flags (`tuios send-text --help`). E2E paste stripped a BEL. `tu:internal/harness/manifests/claude-code.toml:314-317` |
| send key | `send-keys -w W Enter\|Escape\|ctrl+c\|ctrl+u` | S | `verb_protocol.go:1144`; E2E `ctrl+u` cleared the line |
| capture tail | `capture-pane -w W -S --lines N` (`source:"recent"`) | S | `verb_protocol.go:1207`; E2E |
| visible capture | `capture-pane -w W` (`source:"visible"`) | S | same |
| styled capture for composer | `--ansi` (`styled`) | S | same |
| cursor row | none; `get-window` returns cursor only with a client attached | M | `verb_protocol.go:920` description. Same as zellij (`cursor=0` caps, `fm:bin/backends/zellij.sh:535`) |
| kill | `kill-session S` (per-task session) or `close-window -s S W` | S | `verb_protocol.go:1275,1125`; E2E: `close-window` on a session's last window leaves a 0-window session; `kill-session` removes it |
| process liveness | `list-windows --json .pid .tty .foreground_cmd` | S | E2E fields present. `tty` allows tmux's `ps -t` approach (`fm:bin/backends/tmux.sh:304`) |
| agent state | `get-agent-state --json` `state` (`none working needs_input idle done errored unknown`), `source`, `identity`, `harness_id`, `needs_you`, `blocked_by` | S | `verb_protocol.go:1550`; `tuios --skill state`. E2E below |
| blocked prompt read | `peek-prompt --json`: lines, `actions`, `prompt_id`, `waiting_ms` | S | `verb_protocol.go:1814`; E2E |
| answer prompt | `respond -w W approve\|deny\|choose N` | S | `verb_protocol.go:1843`; needs `respond` grant |
| push events | `subscribe -s S --types agent-state,window-exit,window-closed,session-closed` JSON lines, resumable with `--after-seq --boot-id` | S | `verb_protocol.go:1381`; `tuios --skill events`; E2E `agent-state` event on prompt exit |
| level reconcile | `list-agents --json --select 'session:fm-<hometag>-*'` | S | `verb_protocol.go:1686`; selector keys `wait-for` description in `list-verbs` |
| capability / version gate | `list-verbs --json`: `version` (protocol 1), verb and param presence | S | `verb_protocol.go:350`; replaces herdr's missing `api schema` |

### Native vs herdr front

| Issue (earlier doc) | herdr front | Native |
| --- | --- | --- |
| `--session` refused / typed into pane | needs wrapper | gone: `-s` is a native flag |
| Slot leak (zero-pane tab kept) | `after-close-window` hook workaround | gone: no tab object. Per-task session plus `kill-session` removes all (E2E) |
| 9-task cap | one herdr tab = one of 9 workspace slots (`tu:internal/session/herdr_api.go:667-684`) | gone: unlimited windows per workspace and unlimited sessions (E2E 13 and 12) |
| Blocked prompt | E2E now: tuios reports `needs_input`, the front maps it to `blocked` (`tu:internal/session/herdr_view.go:162-174`). firstmate's `busy_state` folds `blocked` into `idle` (`fm:bin/backends/herdr.sh:3639-3646`); E2E through firstmate: `busy=idle agent=alive raw=blocked composer=pending`. Only the event path would escalate `blocked`, and its gate fails on `api schema` (`fm:bin/backends/herdr.sh:3857-3874`) | `needs_input` read directly; events gated on `list-verbs`, which exists |
| Foreground cwd | `pane get .foreground_cwd` is just `win.Cwd` (`tu:internal/session/herdr_view.go:462`); `pane process-info` has the real foreground cwd (E2E: `foreground_processes[].cwd` = subshell dir) | `list-windows .cwd` has the same gap; no native foreground-cwd field |
| tuios version needed | main (earlier doc, section 6) | 0.8.5 has every verb and param used here (`verb_protocol.go` at `v0.8.5`) |

The earlier doc saw `busy` for the same prompt. On this build, Claude Code 2.1.285's trust prompt ("Quick safety check: Is this a project you created or one you trust?") no longer matches tuios's trust rule (`tu:internal/harness/manifests/claude-code.toml:78-88`, "Do you trust the files in this folder"). The generic form rule (`:126-136`) catches it instead: `needs_input`, `source: screen`, `peek-prompt actions: ["deny"]` only (E2E).

## 4. Design sketch

| Aspect | Proposal | Why |
| --- | --- | --- |
| Container | one tuios session per task, named `fm-<hometag>-<id>` (`fm_backend_hometag`, `fm:bin/fm-backend-hometag-lib.sh:31-52`); first window `fm-<id>` | `kill-session` is atomic teardown; no shared tab bar; `session:fm-<hometag>-*` selector scopes lists and events to one home; `new-session` sets the size of a detached pane (80x24 by default) |
| Alternative | one session per home, tasks as windows | fewer sessions in `tuios ls`, but `close-window` cleanup, nominal 80x24 panes and no per-task size |
| Target / meta | `window=<session>:<window_uuid>`, `tuios_session=`, `tuios_window_id=`, `endpoint_task_id=` | mirrors zellij/cmux; the uuid is stable and wins over names (`tuios --skill`, "Addressing things") |
| Validation | arm in `fm_backend_validate_task_endpoint`: `window == tuios_session:tuios_window_id`, session prefix `fm-<hometag>-` | same refusal discipline as `fm:bin/fm-backend.sh:494-509` |
| Transport | CLI with `--json` for reads; raw socket JSON lines (`python3`, already needed by herdr events) for `new-session`, `send-text paste/submit`, error codes | the CLI lacks those flags and stable codes |
| Detection | phase 1 explicit-only (like zellij). Phase 2: `TUIOS_ENV=1` and `HERDR_SOCKET_PATH == "$TUIOS_SOCKET.herdr"` (tuios is innermost), checked after `$TMUX` and before `HERDR_ENV`, with NOTICE | a real herdr nested in a tuios pane overwrites `HERDR_SOCKET_PATH`, so the equality marks tuios as the innermost layer; auto-detect would silently move current herdr-front users |
| Version gate | `list-verbs --json`: `.version >= 1`, verbs `new-session subscribe get-agent-state peek-prompt`, `capture-pane` params `source styled` | build string is `dev` on main |
| Grants | firstmate pane needs `admin` (other sessions, `kill-session`) plus `respond` (Escape/C-c into a `needs_input` crew) | `tuios --skill grants`; `tu:docs/CONFIGURATION.md:712-725`. Already applied in this repo (`mode='strict'`, `grants=['admin','respond']`) |
| Busy / agent state | `get-agent-state`: `working` busy; `idle\|done` idle; `needs_input` blocked (submit path treats it as busy, like herdr `:3648-3653`); `none` plus no harness process from `ps -t <tty>` dead; `window_not_found` missing | reuses herdr's classifier semantics |
| Events | `wait_transition`: start `tuios subscribe -s <each task session> --types agent-state,window-exit` (or no `-s` plus filter by prefix), wait for `subscribed`, level reconcile via `list-agents --select`, then read lines up to timeout; normalize `needs_input->blocked`, `errored->done`, `none\|unknown->unknown` | same shape as `fm:bin/backends/herdr.sh:3966-4077`; edge events plus a level reconcile avoids the immediate-return loop a level `wait-for agent-state` would cause |
| Composer | `capture-pane --ansi` tail into `fm_composer_classify_screen` with `styled=1 cursor=0 identity=0`; zellij's paste, prove-append, retry-Enter submit | `fm:bin/backends/zellij.sh:532-590` |
| cwd | marker probe (`printf` begin/end around `pwd`) at spawn time, like zellij/cmux | native `.cwd` misses the treehouse subshell (E2E) |
| Test isolation | fresh `XDG_RUNTIME_DIR`, `XDG_STATE_HOME`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME`, unset `TUIOS_SOCKET`; daemon auto-starts on `tuios new --detach`; `tuios kill-server` cleans up | tuios's own E2E harness does this (`tu:e2e/control_plane_test.go:61-72,100-110`); `tuios --skill` ("Am I inside tuios") |
| Isolation caveats | keep `XDG_RUNTIME_DIR` short: the socket path must fit macOS `sun_path` (104 bytes), and the Claude scratchpad path alone is over 100. On macOS the isolated daemon's panes still got the user's grants (`TUIOS_PANE_GRANTS=respond,admin`) despite a fresh `XDG_CONFIG_HOME`, so config is not hermetic there | E2E |
| Safety guard | `tests/tuios-test-safety.sh`: refuse unless `XDG_RUNTIME_DIR` is a test temp dir and the session starts with `fm-test-` | mirrors `fm:tests/zellij-test-safety.sh` |
| CI | possible as a real lane: `go install` plus a headless daemon, unlike GUI cmux | optional; experimental backends have none today |

## 5. Effort and risk

| Work item | Estimate (lines) | Basis |
| --- | --- | --- |
| `bin/backends/tuios.sh`, parity (functions 1-17) | 600-750 | zellij 708, cmux 653 |
| native extras (18-23) plus event reader | 350-500 | herdr's event block `fm:bin/backends/herdr.sh:3857-4077` (~220) plus `herdr-eventwait.py` 157 |
| case arms (27 + 10) | 120-180 | zellij PR touched `fm-backend.sh` +50, `fm-spawn.sh` +30 |
| unit test (faked `tuios`) | 900-1400 | 792-1360 |
| smoke test plus safety guard | 250 | 205 + 60 |
| guide plus evidence section plus config/README edits | 250-300 | 114-133 guide + ~60-70 evidence |
| Total | about 2.5k-3.4k added | zellij +1896, cmux +2070 for parity only |

Time: parity 3-4 focused days; native extras 2-3 days; then upstream review rounds (zellij/cmux each needed 9-16 follow-ups).

| Risk | Level | Note |
| --- | --- | --- |
| Not upstream: carrying a fork of `fm-spawn.sh` (5575 lines, last commit 2026-10-05) | high | every rebase touches the 6 spawn arms and the meta writer |
| tuios churn: 337 commits in 4 days after 0.8.5 | high | use `--json`, socket codes and `list-verbs` feature checks, never prose output |
| cwd via marker probe | medium | proven on zellij/cmux, but it is an active probe at spawn time |
| Screen-rule drift (trust prompt wording) | medium | state still `needs_input` via the generic rule; answers limited |
| Grants misconfig | low | refuses with `forbidden` naming the grant; doctor check in `version_check` via `tuios pane-grants --json` |
| Detection overlap with herdr | low | phase 1 explicit-only |

## 6. Recommendation and upstream proposals

1. Now: keep the herdr-front route (earlier doc, section 6). It works today with a wrapper and a hook.
2. Upstream tuios fixes. They are small, help the herdr route at once, and three of them also remove native-backend work:
   - herdr front: strip `--session NAME`/`--session=NAME` before `--`, as herdr does (earlier doc, section 5.1).
   - herdr front: answer `api schema` with the implemented methods and `pane.agent_status_changed`, so firstmate's events gate (`fm:bin/backends/herdr.sh:3871-3873`) passes and `blocked` escalates.
   - herdr front: close a tab when its last pane closes (removes the hook workaround).
   - herdr front `pane get .foreground_cwd`: use the foreground process cwd that `pane.process_info` already reads, not `win.Cwd` (`tu:internal/session/herdr_view.go:462`). Native: add `foreground_cwd` (and foreground pgid/argv) to `list-windows`/`get-window`, so backends need no `pwd` probe.
   - CLI parity: `send-text --paste/--submit`, `new-window --close-on-exit`, `new --detach --print-id` (window id), stable `error.code` in `--json` errors.
   - Claude Code manifest: add the 2.1.28x trust wording ("Quick safety check", "Yes, I trust this folder") to the trust rule so `respond approve` works (`tu:internal/harness/manifests/claude-code.toml:78-88`).
   - Hermetic config for test daemons on macOS: honour `XDG_CONFIG_HOME` only, or add `TUIOS_CONFIG_DIR`.
3. firstmate: open an issue first, then one PR `feat(backends): add experimental tuios runtime backend`. Scope: explicit-only selection, per-task sessions, functions 1-17, the 27 required arms, unit and smoke tests with a safety guard, `docs/tuios-backend.md`, a `## tuios` evidence section. Second PR: native `agent_state`, `busy_state` and push events (functions 18-23, 10 arms), which unblocks `--relaunch` (`fm:bin/fm-control-lib.sh:296-300`). Optional third: auto-detection with NOTICE.
4. firstmate, independent of tuios: in the herdr adapter, omit `--session` when it is `default` (earlier doc, section 5, firstmate 1). That removes the wrapper even without the tuios fix.

## E2E log (isolated daemon, tuios main `0291286b`)

| Check | Result |
| --- | --- |
| `tuios new --detach fmhome` with fresh XDG dirs | daemon auto-started on `$XDG_RUNTIME_DIR/tuios/tuios.sock` (+ `.herdr`, `.link`) |
| 12 x `new-window --no-focus --print-id` into one session | 13 windows, all workspace 1, no error |
| 11 x `tuios new --detach` | 12 sessions |
| `close-window` on a session's only window | session kept with `window_count: 0` |
| `kill-session` | session gone |
| `new-session` over socket with `width/height` | `session_created`, `window_id`, 200x50 |
| `send-text` (no newline), `send-keys ctrl+u`, `send-keys Enter`, `capture-pane -S --lines 3` | typed, cleared, ran, read back |
| socket `send-text paste:true` with a BEL | BEL stripped |
| top-level `cd`, then `list-windows .cwd` | updated (after ~2s) |
| `zsh -c 'cd X && exec zsh -i'`, then `.cwd` | stayed on the old dir; herdr front `process-info` showed X |
| Claude Code 2.1.285 at its trust prompt | `get-agent-state`: `needs_input`, `blocked_by: approval`, `source: screen`; `peek-prompt` `actions: ["deny"]`; herdr front `agent_status: blocked`; firstmate herdr adapter `busy=idle agent=alive raw=blocked composer=pending` |
| `subscribe -s fmhome --types agent-state,window-exit`, then Escape | `subscribed`, then `agent-state` `state: none` |
| `get-window` on missing window/session over socket | `window_not_found` / `session_not_found` |
| pane env | `TUIOS_ENV=1`, `TUIOS_SESSION`, `TUIOS_SOCKET`, `TUIOS_PANE_ID`, `TUIOS_PANE_GRANTS`, plus `HERDR_ENV=1`, `HERDR_SOCKET_PATH=$TUIOS_SOCKET.herdr` |
