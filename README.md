# Dotfiles

This repository holds my dotfiles. [mise bootstrap](https://mise.jdx.dev/bootstrap.html)
and [mise dotfiles](https://mise.jdx.dev/dotfiles.html) manage them. The
checkout lives at `~/.dotfiles`. The directory `~/.config/mise` links to
`home/.config/mise` in the checkout.

## Install on a fresh machine

1. Run the installer:

   ```sh
   curl -fsSL https://raw.githubusercontent.com/smpte11/dotfiles/main/install.sh | sh
   ```

2. The installer installs mise, clones this repository to `~/.dotfiles` and
   runs `dotfiles-setup`.
3. On an interactive terminal, `dotfiles-setup` opens the gum picker
   `home/.local/bin/dotfiles-choose`. The picker lists the modules from
   `modules.toml` with a one-line description each.
4. Pick the modules for this machine. Modules combine freely.

Example: pick `dev` and `dev-private` to get the common dev setup plus your
private tooling. `dev-private` pulls in `dev` on its own, so you can also pick
only `dev-private`.

The picker pre-selects the modules recorded in
`home/.config/mise/miserc.local.toml`. Because of this, you can re-run the
installer or `mise run dotfiles:update` to add or remove modules. Pick the same
set again and nothing changes.

On an interactive run, setup first offers to edit the raw profile file in your
editor instead of using the picker. `dotfiles-choose --edit` does the same
standalone.

The setup writes your choice to `home/.config/mise/miserc.local.toml`. This
file is not committed. Then `mise bootstrap` runs.

Set `DOTFILES_ENV=base,dev-private` to skip the questions.

## Modules

A module is one feature set. Each module has a `config.<name>.toml` file and a
`[module.<name>]` entry in `modules.toml`. To add a module, add both.

Module groups:

- `dev` holds the common dev setup.
- `dev-private` and `dev-work` each hold the tooling for one setup. Both pull
  in `dev`.
- `torrent` holds the download stack. `media` and `gaming` both pull it in.

The `machine:` entries at the top of `modules.toml` pick a full set for one
machine: `work-mac`, `home-desktop`, `media-server` or `tablet`. Pick one of
these on a new machine.

Example: `media-server` gives you `base`, `torrent`, `media`, `proton-pass`
and `ssh-agent`.

`dotfiles-setup` adds the `ssh` module to every machine that has an identity
module.

## Secrets

### Proton Pass (`proton-pass`)

The `proton-pass` module installs the `pass-cli` binary under
`~/.local/share/proton-pass-cli/`. It also deploys a `~/.local/bin/pass-cli`
wrapper. The wrapper picks a key provider that works on this machine: D-Bus
Secret Service when available, else the kernel keyring, else a filesystem
fallback in headless environments. `pass-cli login` therefore works everywhere.

The module is opt-in. Without it, setup does not install `pass-cli` and does
not ask for a login. Exception: `torrent` machines (`media` or `gaming`) read
their keys from Proton Pass.

A failed `pass-cli login` does not abort the install. Setup prints a warning.
Finish the login later:

1. Run `pass-cli login`.
2. Run `mise run dotfiles:update`.

The `ssh-agent` module is optional. It adds the Proton Pass SSH agent.

### Agent keys

With the `dev-private` module, setup passes the Codestral key to
`mise bootstrap` as the `CODESTRAL_API_KEY` bootstrap secret. To change the key,
remove `~/.config/codestral/env` and run `mise run dotfiles:update`.

The `base` module installs Vibe, pi and opencode. It deploys
`~/.vibe/config.toml` and `~/.config/opencode/opencode.json`, and renders
`~/.vibe/.env` (mode 0600) with `MISTRAL_API_KEY`. With the `proton-pass`
module, setup reads the key from `pass://Personal/Vibe/API Key`. Without it,
setup reads the key from the environment. One run of the installer or
`mise run dotfiles:update` thus configures the three agents on a fresh
machine.

mise loads `~/.vibe/.env` with `redact = true`, so mise never prints the key.
pi reads the key from the environment as its Mistral provider key. opencode
reads it through the `mistral` provider in its config, which names
`MISTRAL_API_KEY` as the credential. To change the key, remove `~/.vibe/.env`
and run `mise run dotfiles:update`.

On a `torrent` machine, setup reads the `pass://Media/Netfelix/*` items from
Proton Pass. It passes them to `mise bootstrap` as the matching bootstrap
secrets: `SONARR_API_KEY`, `RADARR_API_KEY`, `PROWLARR_API_KEY`,
`QUESTARR_API_KEY`, `QBIT_USERNAME`, `QBIT_PASSWORD` and `YTS_API_URL`. When
an item is missing, setup falls back to the API keys already deployed in the
`config.xml` files.

The WebUI logins of the media stack (qBittorrent, Radarr, Sonarr, Prowlarr,
Jellyfin) live as their own login entries in the Media vault, for example
`pass://Media/qbittorrent`. `QBIT_PASSWORD` is read from there. Each app's
API key sits as an `apiKey` extra field on its login entry, for example
`pass://Media/sonarr`. The standalone `pass://Media/Netfelix/*_API_KEY` entries
remain the bootstrap source.

## Layout

| Path | Deployed | Holds |
| --- | --- | --- |
| `home/` | always | Shared files, linked file by file into `~` |
| `ssh/` | `ssh` | `~/.ssh/config`; the module also builds the tuios fork |
| `base/` | `base` | Personal signing key, Vibe, pi and opencode with the Mistral key, Proton VPN flatpak and CLI autostart on Linux |
| `dev/` | `dev` | k9s skin, tuios config |
| `dev-private/` | `dev-private` | pi firstmate extension, Codestral key, crib config |
| `dev-work/` | `dev-work` | Claude keybindings |
| `proton-pass/` | `proton-pass` | `pass-cli` wrapper that picks a working key provider |
| `ssh-agent/` | `ssh-agent` | Proton Pass SSH agent wrapper and `~/.ssh/config.d/agent` |
| `work/` | `work` | 1Password agent, work identity |
| `desktop/` | `desktop` | Journal reminder and check-ins, OpenDeck journal and pixel clock and timer plugins, OpenDeck profiles |
| `torrent/` | `torrent` | netfelix pod, prowlarr, byparr, VPN-gated qbittorrent, prowlarr Configarr config and seed config |
| `media/` | `media` | netfelix pod ports drop-in, *arr quadlets, Configarr config, *arr seed configs, media drive guard for agents |
| `gaming/` | `gaming` | Questarr quadlets, config and timer for the games library |
| `home/.config/mise/config.toml` | always | Tools, groups, templates, repos |
| `home/.config/mise/config.<module>.toml` | per module | The module's vars, env, groups, services and hooks |
| `modules.toml` | no | Module catalog shown by the setup picker |
| `home/.config/mise/themes.toml` | | Theme palettes for the `*.tera` templates |

## Templates and themes

Files ending in `.tera` are templates. A template reads `vars` from the
config. It also reads the palette of `mise vars theme` from `themes.toml`.

`switch-theme` runs `mise run theme:switch [theme]`. The command changes the
theme for this machine by writing `home/.config/mise/conf.d/theme.toml`. This
file is git-ignored and tracked by mise history. Without a name, the command
opens a picker. `mise dot rollback` of that file restores the previous theme
and renders the templates again.

Example: `switch-theme` opens the picker. `mise run theme:switch nord` applies
the `nord` palette at once.

## Media server (`torrent`, `media` and `gaming` modules)

### `torrent`: the download stack

The `torrent` module is the download stack that `media` and `gaming` share. It
deploys `netfelix.pod` to `~/.config/containers/systemd/netfelix/` with the
prowlarr and byparr quadlets in it. It also deploys a headless qbittorrent
quadlet on host networking. The WebUI listens on port 8081, and the config
migrates from `~/.config/qBittorrent`.

qbittorrent mounts `vars.torrents_dir` at the same path inside the container.
The `media` module sets it to `/run/media/system/media/torrents`. Without
`media`, it is `~/.local/share/torrents`.

Stop the host qBittorrent before the container takes over port 8081.

A `qbit-vpn-guard.service` user unit runs qbittorrent only while the Proton VPN
interface is up (`vars.vpn_interface`, `proton0`). The unit also pins
qBittorrent's `NetworkInterface` to that interface. The client stays inactive
and cannot leak traffic when the VPN is down.

A oneshot `prowlarr-config.container` and a daily `prowlarr-config.timer` apply
the prowlarr tags, sync profile, byparr proxy and indexers from
`torrent/configarr/config.yml` through Configarr.

On every non-work machine, the `base` module installs the Proton VPN flatpak.
It deploys `protonvpn-connect.service`, which connects the Proton VPN CLI at
startup and re-connects within a minute when the tunnel drops. It also deploys
a disabled `proton.desktop` autostart entry, so the GUI never fights the CLI.

### `media`: the media player

The `media` module targets the media player. It adds the *arr, Jellyfin and
Seerr quadlets to the same pod. The drop-in `netfelix.pod.d/media.conf`
publishes their ports. Quadlet merges it into `netfelix.pod`.

The module deploys the Configarr config to
`~/.config/media/configarr/config.yml`. It also deploys seed `config.xml`
files, only when missing, so existing installs keep their keys. Each seed file
pins one *arr API key.

A oneshot `configarr.container` and a daily `configarr.timer` apply the
declarative settings through the *arr APIs. This includes the prowlarr
applications that sync the indexers to Sonarr and Radarr.

### `gaming`: the games library

The `gaming` module deploys Questarr the same way. A oneshot
`questarr-config.container` and a daily `questarr-config.timer` apply
`gaming/questarr/config.json` through Questarr's admin-scope API. Questarr uses
`Network=host` instead of joining the netfelix pod.

Games live in `~/.local/share/questarr/games`. Questarr mounts
`vars.torrents_dir` at the same path as qbittorrent and saves its downloads to
`torrents/questarr`. Imports therefore need no path mapping.

One-time setup:

1. Create an `admin` API key in Questarr (Settings -> API keys).
2. Store it as `pass://Media/Netfelix/QUESTARR_API_KEY`.

### Shared plumbing

Secrets reach the containers as podman secrets. The containers inject them as
environment variables, which `config.yml` reads with `!env`. A single
post-dotfiles hook in `home/.config/mise/config.toml` creates each podman
secret once from its environment variable when set. Modules that share a
dependency therefore use the same secret. Example: qbit serves both `media`
and `gaming`.

Each module declares only the `[bootstrap.secrets.*]` entries its containers
consume. The hook enables whichever timer and guard units are deployed.

The `media` module also deploys `~/.agents/machine/protect-media-drives.md`.
This file forbids agents from touching the mounted media pool. Machines read
every file in `~/.agents/machine/` before anything else.

## Everyday commands

- `mise run dotfiles:update` pulls the checkout and bootstraps again.
- `dotfiles-teardown [--yes]` removes the checkout, mise and everything
  deployed. Without `--yes`, it asks for confirmation.
- `mise dot status` lists what is deployed. `mise dot apply` deploys new files.
- `mise dot status --missing` exits with 1 when a file differs from the
  config. `mise dot diff` shows what `mise dot apply` would change.
- `mise dot edit <target>` opens the source of a deployed file, such as the
  `.tera` template of a rendered file.
- `mise run dotfiles:history [path]` browses the saved checkpoints of the
  tracked files. It previews each change, restores a checkpoint and undoes an
  operation.
- `mise run deck:import` converts the Elgato Stream Deck profiles of this Mac
  into the OpenDeck profiles of the `desktop` module, with one set for macOS
  and one for Linux. OpenDeck writes profile changes through the symlinks into
  the checkout. Key images are copied, so `mise dot add --changed` brings a
  changed image back.
- `mise run test:fresh` installs the repository in Linux containers with docker
  or podman and checks it. Each install is saved as a checkpoint image and is
  reused until a file outside the checks changes; `--fresh` installs again.
  Each check group runs in its own container from the checkpoint. Example:
  `mise run test:fresh base --only theme,secrets` runs only those groups.
  `mise run test:clean` removes the images, checkpoints and caches. Run
  `test:fresh` locally before you push a change.
