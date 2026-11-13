-- Minimal mini.nvim config for editing, writing and tweaking configuration.
-- Started with `NVIM_APPNAME=nvim-mini nvim` (alias it to `mnvim`).
--
-- Structure:
-- - init.lua          This file: plugin manager and loading helpers
-- - plugin/           Sourced during startup
-- --- 10_options.lua  Built-in Neovim behavior
-- --- 20_keymaps.lua  Custom mappings
-- --- 30_mini.lua     MINI configuration
-- --- 40_lsp.lua      Language servers (zk, taplo, yamlls, jsonls)
-- - after/            Overrides for filetypes and servers
-- - snippets/         Snippets for markdown and config languages

-- Config table to pass data between scripts
_G.Config = {}

-- Autocommand helper
local gr = vim.api.nvim_create_augroup('mini-config', {})
Config.new_autocmd = function(event, pattern, callback, desc)
  local opts = { group = gr, pattern = pattern, callback = callback, desc = desc }
  vim.api.nvim_create_autocmd(event, opts)
end

-- 'mini.nvim' powers all of this config
vim.pack.add({ 'https://github.com/nvim-mini/mini.nvim' })

-- Loading helpers (see `:h MiniMisc.safely()`)
local misc = require('mini.misc')
Config.now = function(f) misc.safely('now', f) end
Config.later = function(f) misc.safely('later', f) end
Config.now_if_args = vim.fn.argc(-1) > 0 and Config.now or Config.later
Config.on_filetype = function(ft, f) misc.safely('filetype:' .. ft, f) end
