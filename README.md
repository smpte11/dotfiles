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

## Machine Setup

Run `dotfiles-setup` (also launched by `install.sh` on first install) to pick the machine profile and edit identities in a gum TUI.

Everything identity-specific (email, SSH host alias, password manager, agent harness, SSH public keys) lives in `.chezmoidata/identities.toml`. Switching jobs means editing the `work` identity there, or adding a new profile, then committing that file.

The profile decides the password manager, installed and logged in by the `hooks.read-source-state.pre` hook:

- **1Password** (`op`) or **Proton Pass** (`pass-cli`, logged in with `pass-cli login` when needed), per the identity
- **Containers** (Codespaces, dev containers, Docker, Podman) and unconfigured machines - nothing is installed
