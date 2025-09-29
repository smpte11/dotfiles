# doftiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Declarative Package Management

Packages are declared in `.chezmoidata/packages.toml` and automatically installed when the declarations change.

### Package Categories

- `packages.brews.packages` - Homebrew packages (macOS and Linux)
- `packages.casks.packages` - Homebrew casks (macOS only)
- `packages.flatpaks.packages` - Flatpak packages (Bazzite/Bluefin only)
- `packages.npm.packages` - npm packages (cross-platform)

### Usage

1. Edit `.chezmoidata/packages.toml`
2. Run `chezmoi apply`
3. Packages install automatically
