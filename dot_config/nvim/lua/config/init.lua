-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ Main Configuration Entry Point                                              │
-- │                                                                             │
-- │ This module loads all core configuration:                                  │
-- │   - Options (vim settings)                                                 │
-- │   - Keymaps (global keybindings)                                           │
-- │   - Autocmds (autocommands)                                                │
-- │   - Commands (user commands)                                               │
-- │   - Utils (global utilities)                                               │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- Load global utilities first (provides Utils namespace)
require("config.utils")

-- Load core configuration
require("config.options")  -- vim.opt, vim.g settings
require("config.keymaps")  -- Global keymaps
require("config.autocmd")  -- Autocommands
require("config.cmd")      -- User commands
