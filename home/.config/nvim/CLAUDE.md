# Neovim config notes

## Tree-sitter highlighting broken after plugin-path change

nvim-treesitter (`main` branch) installs parsers to `~/.local/share/nvim/site/parser/`
and creates per-language query symlinks in `~/.local/share/nvim/site/queries/<lang>`
pointing into the plugin's bundled `runtime/queries/`.

If the plugin directory moves (e.g. `pack/deps/opt/...` → `pack/core/opt/...` when
switching from mini.deps to native `vim.pack`), those query symlinks become dangling.
The highlighter still attaches (parser present) but finds no query, so highlighting
silently disappears for tree-sitter langs (built-ins like lua/markdown still work via
`$VIMRUNTIME`). `:TSUpdate` does not self-heal because it only relinks on a parser
revision change.

Fix: re-point the dangling symlinks to the current plugin path, or
`rm ~/.local/share/nvim/site/queries/<lang>` and `:TSInstall! <lang>`.
