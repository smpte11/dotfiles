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
runs. Set `DOTFILES_ENV=base,dev-private` to skip the questions. To add a
module, add a `config.<name>.toml` and a `[module.<name>]` entry in
`modules.toml`. `dev` holds the common dev setup; `dev-private` and `dev-work`
hold the tooling for one setup and both pull in `dev`. `torrent` holds the
download stack; `media` and `gaming` both pull it in. The `machine:` entries
at the top of `modules.toml` pick the full set for one machine: `work-mac`,
`home-desktop`, `media-server` and `tablet`. `dotfiles-setup` adds `ssh` to every machine that has an
identity module. The `proton-pass` module installs the `pass-cli` binary under
`~/.local/share/proton-pass-cli/` and deploys a `~/.local/bin/pass-cli`
wrapper that picks a key provider that actually works on this machine (D-Bus
Secret Service when available, kernel keyring, filesystem fallback in
headless environments), so `pass-cli login` works everywhere. The module is
opt-in: without it, setup does not install `pass-cli` and does not ask for a
login, except on `torrent` machines (`media` or `gaming`), which read their keys from
Proton Pass. A failed `pass-cli login` does not abort the install:
setup prints a warning, and you finish with `pass-cli login` followed by
`mise run dotfiles:update`. The `ssh-agent` module is optional
and adds the Proton Pass SSH agent. With the `dev-private` module the Codestral key is
passed to `mise bootstrap` as the `CODESTRAL_API_KEY` bootstrap secret. To
change the key, remove `~/.config/codestral/env` and run
`mise run dotfiles:update`. The `base` module installs Vibe, pi and
opencode, deploys `~/.vibe/config.toml`, `~/.config/opencode/opencode.json` and
renders `~/.vibe/.env` (0600) with `MISTRAL_API_KEY`,
read from `pass://Personal/Vibe/API Key` with the `proton-pass` module and from
the environment without it, so one run of the installer or
`mise run dotfiles:update` configures the three agents on a fresh machine. mise loads
the file into the environment with `redact = true`, so the key is never printed by
mise; pi reads it from the environment as its Mistral provider key, and opencode
reads it through the `mistral` provider in its config, which names `MISTRAL_API_KEY`
as the credential. To change the
key, remove `~/.vibe/.env` and run `mise run dotfiles:update`. On a `torrent`
machine it reads the `pass://Media/Netfelix/*` items
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

Files ending in `.tera` are templates. They read `vars` from the config and the
palette of `mise vars theme` from `themes.toml`. `switch-theme` runs `mise run theme:switch [theme]`
and changes the theme for this machine by writing `home/.config/mise/conf.d/theme.toml` (git-ignored,
tracked by mise history). Without a name it opens a picker. `mise dot rollback` of that file restores the
previous theme and renders the templates again.

## Media server (`torrent`, `media` and `gaming` modules)

The `torrent` module is the download stack that `media` and `gaming` share.
It deploys `netfelix.pod` to `~/.config/containers/systemd/netfelix/` with the
prowlarr and byparr quadlets in it, and a headless qbittorrent quadlet on host
networking (WebUI on port 8081, config migrated from `~/.config/qBittorrent`).
qbittorrent mounts `vars.torrents_dir` at the same path inside the container;
`media` sets it to `/run/media/system/media/torrents`, and without `media` it is
`~/.local/share/torrents`. The host qBittorrent must be stopped before the
container takes over port 8081. A `qbit-vpn-guard.service` user unit runs
qbittorrent only while the Proton VPN interface is up (`vars.vpn_interface`,
`proton0`) and pins qBittorrent's `NetworkInterface` to that interface, so the
client stays inactive and cannot leak traffic when the VPN is down. A oneshot
`prowlarr-config.container` plus a daily `prowlarr-config.timer` apply the
prowlarr tags, sync profile, byparr proxy and indexers from
`torrent/configarr/config.yml` through Configarr. On every non-work machine the
`base` module installs the Proton VPN flatpak and deploys
`protonvpn-connect.service`, which connects the Proton VPN CLI at startup and
re-connects within a minute if the tunnel drops, plus a disabled
`proton.desktop` autostart entry so the GUI never fights the CLI.

The `media` module targets the media player. It adds the *arr, Jellyfin and
Seerr quadlets to the same pod and publishes their ports through the drop-in
`netfelix.pod.d/media.conf`, which Quadlet merges into `netfelix.pod`. It also
deploys the Configarr config to `~/.config/media/configarr/config.yml`, and seed
`config.xml` files (only when missing, so existing installs keep their keys)
that pin each *arr API key. A oneshot `configarr.container` plus a daily
`configarr.timer` apply the declarative settings through the *arr APIs,
including the prowlarr applications that sync the indexers to Sonarr and Radarr.

The `gaming` module deploys Questarr the same way (a oneshot
`questarr-config.container` plus a daily `questarr-config.timer` apply
`gaming/questarr/config.json` through Questarr's admin-scope API) but with
`Network=host` instead of joining the netfelix pod. Games live in
`~/.local/share/questarr/games`. Questarr mounts `vars.torrents_dir` at the same
path as qbittorrent and saves its downloads to `torrents/questarr`, so imports
need no path mapping. One-time setup: create an `admin` API key in Questarr
(Settings -> API keys) and store it as `pass://Media/Netfelix/QUESTARR_API_KEY`.

Secrets reach the containers as podman secrets injected as environment
variables that `config.yml` reads with `!env`: a single post-dotfiles hook in
`home/.config/mise/config.toml` creates each podman secret once from its
environment variable when set, so modules that share a dependency (qbit for
both `media` and `gaming`) use the same secret. Each module only declares the
`[bootstrap.secrets.*]` entries its containers consume, and the hook enables
whichever timer and guard units are deployed. The `media` module also deploys
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
