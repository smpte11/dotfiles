# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Fresh Machine Setup

Run a single command to bootstrap everything:

```sh
curl -fsSL https://raw.githubusercontent.com/smpte11/dotfiles/main/.bootstrap.sh | bash
```

This will:

1. Install Homebrew
2. Install and authenticate GitHub CLI (`gh auth login` via browser)
3. Generate an SSH key and upload it to GitHub
4. Install chezmoi
5. Clone this repo and apply all dotfiles and packages

## Adding Packages

Edit `.chezmoidata.toml` and add the package name to the appropriate list:

- `packages.common_brews` — installed on all platforms via Homebrew
- `packages.darwin.brews` / `.casks` / `.taps` — macOS only
- `packages.linux.brews` — Linux only

Then run:

```sh
chezmoi apply
```

## Password Manager

Installed automatically via the `hooks.read-source-state.pre` hook on `chezmoi init`:

- **Work Mac** (`Felixs-MacBook-Pro`) — 1Password CLI (`op`)
- **All other hosts** — Proton Pass CLI (`pass-cli`)
