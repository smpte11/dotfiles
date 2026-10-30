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

## Layout

| Path | Deployed | Holds |
| --- | --- | --- |
| `home/` | always | Shared files, linked file by file into `~` |
| `ssh/` | `personal` or `work` | `~/.ssh/config` |
| `personal/` | `personal` | Proton Pass agent, personal signing key, Codestral key |
| `work/` | `work` | 1Password agent, work identity, k9s skin, Claude keybindings |
| `desktop/` | `desktop` | Journal reminder and Stream Deck plugin |
| `home/.config/mise/config.toml` | always | Tools, groups, templates, repos |
| `home/.config/mise/config.<module>.toml` | per module | The module's vars, env, groups, services and hooks |
| `home/.config/mise/themes.toml` | | Theme palettes for the `*.tera` templates |

Files ending in `.tera` are templates. They read `vars` from the config and the
palette of `mise vars theme` from `themes.toml`. `switch-theme` changes the
theme for this machine.

## Everyday commands

- `mise run dotfiles:update` pulls the checkout and bootstraps again.
- `mise dot status` lists what is deployed. `mise dot apply` deploys new files.
- `mise run test:fresh` installs the repository in a Linux container and
  checks it. `mise run test:clean` removes the image and its cache.

## Migrating a chezmoi machine

Update the chezmoi checkout to this layout, then run
`~/.local/share/chezmoi/migrate-from-chezmoi.sh`. It moves the checkout to
`~/.dotfiles`, keeps the machine's profile, bootstraps with mise and removes
what chezmoi left behind. `mise run test:migrate <chezmoi-revision>` tests it
in a container.
