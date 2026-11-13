-- Language servers for the minimal config: notes (zk) and config languages.
-- Servers must be installed separately: `zk`, `taplo`, `yaml-language-server`,
-- `vscode-json-language-server`.

Config.now_if_args(function()
  vim.pack.add({ 'https://github.com/neovim/nvim-lspconfig' })
  vim.lsp.enable({ 'zk', 'taplo', 'yamlls', 'jsonls' })
end)
