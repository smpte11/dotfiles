-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ Neovim Options Configuration                                                │
-- │                                                                             │
-- │ All vim.opt, vim.o, and vim.g settings centralized in one place.           │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- ═══════════════════════════════════════════════════════════════════════════════
-- LEADER KEYS (Must be set before plugins load)
-- ═══════════════════════════════════════════════════════════════════════════════

vim.g.mapleader = " "      -- Space as leader key
vim.g.maplocalleader = "," -- Comma as local leader (for filetype-specific mappings)

-- ═══════════════════════════════════════════════════════════════════════════════
-- GENERAL SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════════

vim.g.have_nerd_font = true -- Enable if you have a Nerd Font installed

-- ═══════════════════════════════════════════════════════════════════════════════
-- UI OPTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

vim.opt.termguicolors = true  -- Enable 24-bit RGB colors
vim.opt.number = true         -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.signcolumn = "yes"    -- Always show sign column (prevents text shift)
vim.opt.cursorline = true     -- Highlight current line
vim.opt.showmode = false      -- Don't show mode (it's in statusline)
vim.opt.laststatus = 3        -- Global statusline

-- Popup menu (completion menu) appearance
vim.opt.pumblend = 0 -- No transparency for popup menu (fully opaque)
-- NOTE: 'pumborder' is not available in nvim 0.11.x, only in nightly/0.12+
-- if vim.fn.has("nvim-0.12") == 1 then
--     vim.opt.pumborder = Utils.border_style -- Use centralized border style (requires nvim 0.12+)
-- end

-- Whitespace visualization
vim.opt.list = true
vim.opt.listchars = {
    tab = "» ",
    trail = "·",
    nbsp = "␣",
    extends = "…",
    precedes = "…"
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- EDITING OPTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

vim.opt.mouse = "a"        -- Enable mouse support
vim.opt.breakindent = true -- Wrapped lines continue visually indented
vim.opt.autoindent = true  -- Copy indent from current line
vim.opt.expandtab = true   -- Use spaces instead of tabs
vim.opt.tabstop = 4        -- Number of spaces for a tab
vim.opt.shiftwidth = 4     -- Number of spaces for indentation
vim.opt.scrolloff = 10     -- Minimal lines to keep above/below cursor

-- Word boundaries (treat snake_case and kebab-case as separate words)
vim.opt.iskeyword:remove("_")
vim.opt.iskeyword:remove("-")

-- ═══════════════════════════════════════════════════════════════════════════════
-- SEARCH OPTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

vim.opt.ignorecase = true    -- Case-insensitive searching
vim.opt.smartcase = true     -- Case-sensitive if uppercase present
vim.opt.inccommand = "split" -- Live preview of substitutions

-- ═══════════════════════════════════════════════════════════════════════════════
-- FILE HANDLING
-- ═══════════════════════════════════════════════════════════════════════════════

vim.opt.undofile = true            -- Persistent undo history
vim.opt.swapfile = false           -- Disable swap files
vim.opt.path = vim.opt.path + "**" -- Search down into subfolders

-- ═══════════════════════════════════════════════════════════════════════════════
-- PERFORMANCE
-- ═══════════════════════════════════════════════════════════════════════════════

vim.opt.updatetime = 100 -- Faster completion (default is 4000ms)
vim.opt.timeoutlen = 300 -- Time to wait for mapped sequence

-- ═══════════════════════════════════════════════════════════════════════════════
-- SPLITS & WINDOWS
-- ═══════════════════════════════════════════════════════════════════════════════

vim.opt.splitright = true -- Vertical splits open to the right
vim.opt.splitbelow = true -- Horizontal splits open below

-- ═══════════════════════════════════════════════════════════════════════════════
-- SESSIONS
-- ═══════════════════════════════════════════════════════════════════════════════

vim.opt.sessionoptions:remove("blank") -- Don't save empty windows in sessions

-- ═══════════════════════════════════════════════════════════════════════════════
-- SPELLING
-- ═══════════════════════════════════════════════════════════════════════════════

vim.opt.spelllang = "en"          -- English spelling
vim.opt.spelloptions = "camel"    -- Treat CamelCase as separate words
vim.opt.complete:append("kspell") -- Use spell dictionary for completion

-- ═══════════════════════════════════════════════════════════════════════════════
-- CLIPBOARD
-- ═══════════════════════════════════════════════════════════════════════════════

-- Sync clipboard between OS and Neovim
-- Scheduled after UiEnter to avoid startup delay
vim.schedule(function()
    vim.opt.clipboard = "unnamedplus"
end)
