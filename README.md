# Dotfiles

Managed with [mise bootstrap](https://mise.jdx.dev/bootstrap.html) and
[mise dotfiles](https://mise.jdx.dev/dotfiles.html). The checkout lives at
`~/.dotfiles`, and `~/.config/mise` links to `home/.config/mise` in it.

## Fresh machine

```sh
curl -fsSL https://raw.githubusercontent.com/smpte11/dotfiles/main/install.sh | sh
```

The script installs mise, clones the repository to `~/.dotfiles` and runs
`dotfiles-setup`. On an interactive terminal `dotfiles-setup` opens the gum
picker `home/.local/bin/dotfiles-choose`, which lists the modules declared in
`modules.toml` with a one-line description of what each adds. Modules combine
freely on one host. The modules already recorded in
`home/.config/mise/miserc.local.toml` are pre-selected, so re-running the
installer or `mise run dotfiles:update` lets you add or remove modules, and
picking the same set again changes nothing. On an interactive run the setup
first offers to edit the raw profile file in your editor instead of using the
picker (`dotfiles-choose --edit` does the same standalone). The choice is
written to
`home/.config/mise/miserc.local.toml` (not committed) and `mise bootstrap`
runs. Set `DOTFILES_ENV=base,dev` to skip the questions. To add a module,
add a `config.<name>.toml` and a `[module.<name>]` entry in `modules.toml`. The
`work` module is no longer offered by the picker but still works through
`DOTFILES_ENV=work`. `dotfiles-setup` adds `ssh` to every machine that has an
identity module. The `proton-pass` module installs the `pass-cli` binary under
`~/.local/share/proton-pass-cli/` and deploys a `~/.local/bin/pass-cli`
wrapper that picks a key provider that actually works on this machine (D-Bus
Secret Service when available, kernel keyring, filesystem fallback in
headless environments), so `pass-cli login` works everywhere; the `base`
module includes it. A failed `pass-cli login` no longer aborts the install:
setup prints a warning, and you finish with `pass-cli login` followed by
`mise run dotfiles:update`. The `ssh-agent` module is optional
and adds the Proton Pass SSH agent. On a `dev` machine the Codestral key is
passed to `mise bootstrap` as the `CODESTRAL_API_KEY` bootstrap secret. To
change the key, remove `~/.config/codestral/env` and run
`mise run dotfiles:update`. On a `base` machine the base module deploys
`~/.vibe/config.toml` and renders `~/.vibe/.env` (0600) with `MISTRAL_API_KEY`
read from `pass://Personal/Vibe/API Key`, so one run of the installer or
`mise run dotfiles:update` configures Vibe on a fresh machine; to change the
key, remove `~/.vibe/.env` and run `mise run dotfiles:update`. On a `media` or
`gaming` machine it reads the `pass://Media/Netfelix/*` items
from Proton Pass and gives them to `mise bootstrap` as the matching bootstrap
secrets (`SONARR_API_KEY`, `RADARR_API_KEY`, `PROWLARR_API_KEY`,
`QUESTARR_API_KEY`, `QBIT_USERNAME`, `QBIT_PASSWORD`, `YTS_API_URL`), falling
back to the API keys already deployed in the `config.xml` files. The WebUI
logins of the media stack (qBittorrent, Radarr, Sonarr, Prowlarr, Jellyfin)
live as their own login entries in the Media vault, e.g.
`pass://Media/qbittorrent`; `QBIT_PASSWORD` is read from there. Each app's API
key is also collocated as an `apiKey` extra field on its login entry (e.g.
`pass://Media/sonarr`); the standalone `pass://Media/Netfelix/*_API_KEY`
entries remain as the bootstrap source.

## Layout

| Path | Deployed | Holds |
| --- | --- | --- |
| `home/` | always | Shared files, linked file by file into `~` |
| `ssh/` | `ssh` | `~/.ssh/config`; the module also builds the tuios fork |
| `base/` | `base` | Personal signing key, Vibe config and key |
| `dev/` | `dev` | Codestral key |
| `proton-pass/` | `proton-pass` | `pass-cli` wrapper that picks a working key provider |
| `ssh-agent/` | `ssh-agent` | Proton Pass SSH agent wrapper and `~/.ssh/config.d/agent` |
| `work/` | `work` | 1Password agent, work identity, k9s skin, Claude keybindings |
| `desktop/` | `desktop` | Journal reminder and check-ins, OpenDeck journal and pixel clock and timer plugins, OpenDeck profiles |
| `media/` | `media` | netfelix quadlets, Configarr config, *arr seed configs, media drive guard for agents |
| `gaming/` | `gaming` | Questarr quadlets, config and timer for the games library |
| `home/.config/mise/config.toml` | always | Tools, groups, templates, repos |
| `home/.config/mise/config.<module>.toml` | per module | The module's vars, env, groups, services and hooks |
| `modules.toml` | no | Module catalog shown by the setup picker |
| `home/.config/mise/themes.toml` | | Theme palettes for the `*.tera` templates |

Files ending in `.tera` are templates. They read `vars` from the config and the
palette of `mise vars theme` from `themes.toml`. `switch-theme` runs `mise run theme:switch [theme]`
and changes the theme for this machine by writing `home/.config/mise/conf.d/theme.toml` (git-ignored,
tracked by mise history). Without a name it opens a picker. `mise dot rollback` of that file restores the
previous theme and renders the templates again.

## Media server (`media` and `gaming` modules)

The `media` module targets the media player. It deploys the netfelix quadlets
to `~/.config/containers/systemd/netfelix/`, the Configarr config to
`~/.config/media/configarr/config.yml`, and seed `config.xml` files (only when
missing, so existing installs keep their keys) that pin each *arr API key. A
oneshot `configarr.container` plus a daily `configarr.timer` apply the
declarative settings through the *arr APIs. The module also deploys a headless
qbittorrent quadlet on host networking (WebUI on port 8081, config migrated from
`~/.config/qBittorrent`, downloads under `/run/media/system/media/torrents`), so
the host qBittorrent must be stopped before the container takes over port 8081.
A `qbit-vpn-guard.service` user unit runs qbittorrent only while the Proton VPN
interface is up (`vars.vpn_interface`, `proton0`) and pins qBittorrent's
`NetworkInterface` to that interface, so the client stays inactive and cannot
leak traffic when the VPN is down; the post-dotfiles hook enables the guard
alongside the timers. The `gaming` module deploys Questarr
the same way (a oneshot `questarr-config.container` plus a daily
`questarr-config.timer` apply `gaming/questarr/config.json` through Questarr's
admin-scope API) but with `Network=host` instead of joining the netfelix pod, so
it works with or without `media` on the same host. One-time setup: create an
`admin` API key in Questarr (Settings -> API keys) and store it as
`pass://Media/Netfelix/QUESTARR_API_KEY`. Secrets reach the containers as
podman secrets injected as environment variables that `config.yml` reads with
`!env`: a single post-dotfiles hook in `home/.config/mise/config.toml` creates
each podman secret once from its environment variable when set, so modules that
share a dependency (qbit for both `media` and `gaming`) use the same secret.
Each module only declares the `[bootstrap.secrets.*]` entries its containers
consume, and the hook enables whichever timer units are deployed. The `media`
module also deploys
`~/.agents/machine/protect-media-drives.md`, which forbids agents from touching
the mounted media pool; `~/.agents/machine/` files are read before anything else
on machines that have them.

## Everyday commands

- `mise run dotfiles:update` pulls the checkout and bootstraps again.
- `dotfiles-teardown [--yes]` removes the checkout, mise and everything deployed (asks for confirmation without `--yes`).
- `mise dot status` lists what is deployed. `mise dot apply` deploys new files.
- `mise dot status --missing` exits with 1 when a file differs from the config.
  `mise dot diff` shows what `mise dot apply` would change.
- `mise dot edit <target>` opens the source of a deployed file, such as the
  `.tera` template of a rendered file.
- `mise run dotfiles:history [path]` browses the saved checkpoints of the tracked files.
  It previews each change, restores a checkpoint and undoes an operation.
- `mise run deck:import` converts the Elgato Stream Deck profiles of this Mac into the
  OpenDeck profiles of the `desktop` module, with one set for macOS and one for Linux.
  OpenDeck writes profile changes through the symlinks into the checkout. Key images are
  copied, so `mise dot add --changed` brings a changed image back.
- `mise run test:fresh` installs the repository in Linux containers with docker
  or podman and checks it. Each install is saved as a checkpoint image and is
  reused until a file outside the checks changes; `--fresh` installs again.
  Each check group runs in its own container from the checkpoint, so
  `mise run test:fresh base --only theme,secrets` runs only those groups.
  `mise run test:clean` removes the images, checkpoints and caches. Run it
  locally before pushing a change.
