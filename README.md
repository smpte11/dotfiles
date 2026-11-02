# Dotfiles

Managed with [mise bootstrap](https://mise.jdx.dev/bootstrap.html) and
[mise dotfiles](https://mise.jdx.dev/dotfiles.html). The checkout lives at
`~/.dotfiles`, and `~/.config/mise` links to `home/.config/mise` in it.

## Fresh machine

```sh
curl -fsSL https://raw.githubusercontent.com/smpte11/dotfiles/main/install.sh | sh
```

The script installs mise, clones the repository to `~/.dotfiles` and runs
`dotfiles-setup`. `dotfiles-setup` asks for the machine's modules, writes them
to `home/.config/mise/miserc.local.toml` (not committed) and runs
`mise bootstrap`. Set `DOTFILES_ENV=work,desktop` to skip the questions.
`dotfiles-setup` adds `ssh` to every machine that has an identity module.
On a `personal` machine it also logs in to Proton Pass and gives the Codestral
key to `mise bootstrap` as the `CODESTRAL_API_KEY` bootstrap secret. To change
the key, remove `~/.config/codestral/env` and run `mise run dotfiles:update`.

## Layout

| Path | Deployed | Holds |
| --- | --- | --- |
| `home/` | always | Shared files, linked file by file into `~` |
| `ssh/` | `ssh` | `~/.ssh/config`; the module also builds the tuios fork |
| `personal/` | `personal` | Proton Pass agent, personal signing key, Codestral key |
| `work/` | `work` | 1Password agent, work identity, k9s skin, Claude keybindings |
| `desktop/` | `desktop` | Journal reminder and Stream Deck plugin |
| `home/.config/mise/config.toml` | always | Tools, groups, templates, repos |
| `home/.config/mise/config.<module>.toml` | per module | The module's vars, env, groups, services and hooks |
| `home/.config/mise/themes.toml` | | Theme palettes for the `*.tera` templates |

Files ending in `.tera` are templates. They read `vars` from the config and the
palette of `mise vars theme` from `themes.toml`. `switch-theme` runs `mise run theme:switch [theme]`
and changes the theme for this machine by writing `home/.config/mise/conf.d/theme.toml` (git-ignored,
tracked by mise history). Without a name it opens a picker. `mise dot rollback` of that file restores the
previous theme and renders the templates again.

## Everyday commands

- `mise run dotfiles:update` pulls the checkout and bootstraps again.
- `mise dot status` lists what is deployed. `mise dot apply` deploys new files.
- `mise run dotfiles:history [path]` browses the saved checkpoints of the tracked files.
  It previews each change, restores a checkpoint and undoes an operation.
- `mise run test:fresh` installs the repository in Linux containers with docker
  or podman and checks it. Each install is saved as a checkpoint image and is
  reused until a file outside the checks changes; `--fresh` installs again.
  Each check group runs in its own container from the checkpoint, so
  `mise run test:fresh personal --only theme,secrets` runs only those groups.
  `mise run test:clean` removes the images, checkpoints and caches.

## Migrating a chezmoi machine

Update the chezmoi checkout to this layout, then run
`~/.local/share/chezmoi/migrate-from-chezmoi.sh`. It moves the checkout to
`~/.dotfiles`, keeps the machine's profile, bootstraps with mise and removes
what chezmoi left behind. `mise run test:migrate <chezmoi-revision>` tests it
in a container.
