-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ Plugin System Bootstrap                                                     │
-- │                                                                             │
-- │ This file sets up mini.deps and makes its functions globally available.    │
-- │ It loads FIRST (00- prefix) before all other plugin files.                 │
-- │                                                                             │
-- │ All other plugin files in /plugin/ are auto-loaded alphabetically by       │
-- │ Neovim and can use the global add, now, later functions.                   │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- Bootstrap mini.deps (sets up _G.MiniDeps globally)
require("config.bootstrap")

-- Make mini.deps functions globally available for all plugin files
-- This allows any plugin/*.lua file to use add(), now(), later() directly
_G.add = MiniDeps.add
_G.now = MiniDeps.now
_G.later = MiniDeps.later

-- Set up spec function with explicit dependencies
local spec_module = require("config.spec")
_G.spec = spec_module.setup({
	add = _G.add,
	now = _G.now,
	later = _G.later,
})
