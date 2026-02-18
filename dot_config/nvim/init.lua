-- Enable faster Lua module loading
vim.loader.enable()

-- Load utilities first (provides Utils global namespace)
require("config.utils")

-- Bootstrap mini.deps (must be loaded before config.init because keymaps depend on mini.keymap)
require("config.bootstrap")

-- Load core configuration (options, keymaps, autocmds, commands)
require("config.init")

-- All plugin files in /plugin/ are auto-loaded by Neovim alphabetically.
-- Files are prefixed with numbers to control load order:
--   00-bootstrap.lua - Bootstrap mini.deps (loads first)
--   01-core.lua      - Mini.nvim core UI
--   02-editor.lua    - Editor enhancements
--   (other files load alphabetically after these)
