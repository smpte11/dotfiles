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
picker `home/.local/bin/dotfiles-choose`, which lists the profiles declared in
`profiles.toml` with a one-line description of what each adds. The modules
already recorded in `home/.config/mise/miserc.local.toml` are pre-selected, so
re-running the installer or `mise run dotfiles:update` lets you add or remove
profiles, and picking the same set again changes nothing. The choice is
written to `home/.config/mise/miserc.local.toml` (not committed) and
`mise bootstrap` runs. Set `DOTFILES_ENV=work,desktop` to skip the questions.
To add a profile, add a `config.<name>.toml` module and a `[profile.<name>]`
entry in `profiles.toml`. `dotfiles-setup` adds `ssh` to every machine that has
an identity module. The `proton-pass` profile installs `pass-cli` and logs in
on any machine. On a `personal` machine it also gives the Codestral key to
`mise bootstrap` as the `CODESTRAL_API_KEY` bootstrap secret. To change
the key, remove `~/.config/codestral/env` and run `mise run dotfiles:update`.
On a `media` machine it reads the `pass://Media/Netfelix/*` items from Proton
Pass and gives them to `mise bootstrap` as the matching bootstrap secrets
(`SONARR_API_KEY`, `RADARR_API_KEY`, `PROWLARR_API_KEY`, `QBIT_USERNAME`,
`QBIT_PASSWORD`, `YTS_API_URL`), falling back to the API keys already deployed
in the `config.xml` files.

## Layout

| Path | Deployed | Holds |
| --- | --- | --- |
| `home/` | always | Shared files, linked file by file into `~` |
| `ssh/` | `ssh` | `~/.ssh/config`; the module also builds the tuios fork |
| `personal/` | `personal` | Proton Pass agent, personal signing key, Codestral key |
| `work/` | `work` | 1Password agent, work identity, k9s skin, Claude keybindings |
| `desktop/` | `desktop` | Journal reminder and check-ins, OpenDeck journal and pixel clock and timer plugins, OpenDeck profiles |
| `media/` | `media` | netfelix quadlets, Configarr config, *arr seed configs, media drive guard for agents |
| `home/.config/mise/config.toml` | always | Tools, groups, templates, repos |
| `home/.config/mise/config.<module>.toml` | per module | The module's vars, env, groups, services and hooks |
| `profiles.toml` | no | Profile catalog shown by the setup picker |
| `home/.config/mise/themes.toml` | | Theme palettes for the `*.tera` templates |

Files ending in `.tera` are templates. They read `vars` from the config and the
palette of `mise vars theme` from `themes.toml`. `switch-theme` runs `mise run theme:switch [theme]`
and changes the theme for this machine by writing `home/.config/mise/conf.d/theme.toml` (git-ignored,
tracked by mise history). Without a name it opens a picker. `mise dot rollback` of that file restores the
previous theme and renders the templates again.

## Media server (`media` module)

The `media` module targets the media player. It deploys the netfelix quadlets
to `~/.config/containers/systemd/netfelix/`, the Configarr config to
`~/.config/media/configarr/config.yml`, and seed `config.xml` files (only when
missing, so existing installs keep their keys) that pin each *arr API key. A
oneshot `configarr.container` plus a daily `configarr.timer` apply the
declarative settings through the *arr APIs. Questarr is configured the same
way: a oneshot `questarr-config.container` plus a daily `questarr-config.timer`
apply `media/questarr/config.json` through Questarr's admin-scope API. One-time
setup: create an `admin` API key in Questarr (Settings -> API keys) and store it
as `pass://Media/Netfelix/QUESTARR_API_KEY`; the post-dotfiles hook turns it into
the `questarr_api_key` podman secret. Secrets reach the container as
podman secrets (created by a post-dotfiles hook) injected as environment
variables that `config.yml` reads with `!env`. The module also deploys
`~/.agents/machine/protect-media-drives.md`, which forbids agents from touching
the mounted media pool; `~/.agents/machine/` files are read before anything else
on machines that have them.

## Everyday commands

- `mise run dotfiles:update` pulls the checkout and bootstraps again.
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
  `mise run test:fresh personal --only theme,secrets` runs only those groups.
  `mise run test:clean` removes the images, checkpoints and caches. Run it
  locally before pushing a change.
