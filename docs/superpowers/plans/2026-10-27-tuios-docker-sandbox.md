# tuios + Docker sandboxed agents - Plan

**Goal:** Run agents in hardened containers, in the style of [agent-sandbox](https://github.com/valentingolchev/agent-sandbox), as tuios panes. tuios must show their state and must be able to `queue`, `ask-agent` and mail them.

**Approach:** Run `docker run -it` (or `docker exec -it`, or `devcontainer exec`) as the pane program. Do not mount the tuios socket. The container reports its state over the pty with OSC 7501. Keep worktrees, `fan verify` and review on the host. Mount the worktree into the container.

## What we know (tested 2026-10-27, OrbStack, tuios fork-f602bb93)

- A container works as a normal tuios pane: `tuios new-window NAME --keep-open -- docker run -it --rm IMAGE CMD`.
- `TUIOS_AGENT=<harness>` is read only when a shell in the pane runs `docker run`. As the pane command itself (`env ...`, `sh -c ...`), tuios does not detect it.
- `start-agent --env TUIOS_AGENT=...` is refused. tuios sets that variable for every pane.
- OSC 7501 from inside the container works without the tuios CLI or the socket:
  `printf '\033]7501;state=working:app=sandbox:msg=<base64>\033\\'`
  States: `working`, `idle`, `done`, `blocked` (with `kind=`), `error`.
- With OSC 7501 state, `tuios queue`, `ask-agent` and the mail wake line work. To read the mail itself, the agent needs the tuios CLI.
- tuios cannot see the container's shell prompt, so `working` does not end by itself. Send `idle` or `done`.
- Closing a pane does NOT stop its container, even with `--rm`.
- agent-sandbox is one bash script, not compose. It does one `docker run -it --rm` per agent, with read-only root, `--cap-drop=ALL`, a non-root user and limits. The network is open, or `--network none`. It has no egress allowlist.

## Open questions

- Does real Claude Code in a container, started from a pane shell with `TUIOS_AGENT=claude-code`, get correct state from the screen rules?
- Can a Claude Code hook in the container write OSC 7501 to `/dev/tty`?
- Which stop method is reliable when a pane closes: a tuios close hook that runs `docker stop`, or `--init` plus a SIGHUP trap?
- Does ACP (`start-agent --protocol acp 'docker run -i --rm IMAGE opencode acp'`) give clean state with no image changes?

## Tasks

- [ ] **1. Real agent test.** Build the agent-sandbox image. Start Claude Code in it from a pane shell with `TUIOS_AGENT=claude-code`. Check `tuios explain-agent-detect` and `tuios explain-agent-screen` through one full turn.
- [ ] **2. Hook test.** In the image, add Claude Code hooks (`UserPromptSubmit`, `Stop`, `Notification`) that write OSC 7501 to `/dev/tty`. Check that the pane goes `working`, then `done`, then `needs_input`.
- [ ] **3. Container lifecycle.** Find a way to stop the container when the pane closes. Test that closing a pane leaves no container in `docker ps`.
- [ ] **4. Launcher.** Write one launcher that does `tuios worktree new`, mounts the worktree, and starts the sandboxed agent in the new session. Then make `tuios fan N --agent <launcher>` work.
- [ ] **5. Network.** Choose an egress policy that allows the LLM API but blocks the rest (proxy or allowlist). agent-sandbox has none today.
- [ ] **6. ACP path.** Test opencode over ACP in a container as the option without a hook.
- [ ] **7. Chezmoi.** Put the launcher, image config and any tuios hook config into this repo.

## Cleanup rules for every test

- `docker ps -a --filter name=<prefix>` must be empty after the test.
- Remove pulled test images and close test panes.
