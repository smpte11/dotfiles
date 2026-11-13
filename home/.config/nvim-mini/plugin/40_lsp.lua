-- Language servers for the minimal config: notes (zk) and config languages.
-- `zk`, `taplo`, `yaml-language-server` and `vscode-json-language-server` are
-- installed via mise; `efm-langserver` formats markdown with prettier.

Config.now_if_args(function()
  vim.pack.add({ 'https://github.com/neovim/nvim-lspconfig' })
  vim.lsp.enable({ 'zk', 'taplo', 'yamlls', 'jsonls', 'efm' })
end)
