-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ mini.deps Bootstrap                                                         │
-- │                                                                             │
-- │ This file handles the installation and setup of mini.deps plugin manager.  │
-- │ It's separated from init.lua for better organization.                      │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
    vim.cmd('echo "Installing `mini.nvim`" | redraw')
    local clone_cmd = {
        'git', 'clone', '--filter=blob:none',
        'https://github.com/nvim-mini/mini.nvim', mini_path
    }
    vim.fn.system(clone_cmd)
    vim.cmd('packadd mini.nvim | helptags ALL')
    vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

-- Set up 'mini.deps' (customize to your liking)
require('mini.deps').setup({ path = { package = path_package } })

-- Make mini.deps functions globally available
-- Use 'mini.deps'. `now()` and `later()` are helpers for a safe two-stage
-- startup and are optional.
_G.MiniDeps = {
    add = MiniDeps.add,
    now = MiniDeps.now,
    later = MiniDeps.later,
}
