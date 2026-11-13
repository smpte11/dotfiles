-- Built-in Neovim behavior
-- Trimmed from the main config, tuned for prose and small screens.

-- stylua: ignore start
-- General ====================================================================
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

vim.o.mouse       = 'a'
vim.o.mousescroll = 'ver:25,hor:6'
vim.o.undofile    = true
vim.o.clipboard   = 'unnamedplus'
vim.o.swapfile    = false

-- UI =========================================================================
vim.o.breakindent    = true
vim.o.breakindentopt = 'list:-1'
vim.o.cursorline     = true
vim.o.cursorlineopt   = 'screenline,number'
vim.o.linebreak      = true
vim.o.list           = true
vim.o.number         = true
vim.o.pumheight      = 10
vim.o.ruler          = false
vim.o.shortmess      = 'CFOSWaco'
vim.o.showmode       = false
vim.o.signcolumn     = 'yes'
vim.o.splitbelow     = true
vim.o.splitkeep      = 'screen'
vim.o.splitright     = true
vim.o.winborder      = 'single'
vim.o.wrap           = true -- Prose first: wrap by default (toggle with <Leader>pw)
vim.o.scrolloff      = 8

vim.o.fillchars = 'eob: ,fold:┄'
vim.o.listchars = 'extends:…,nbsp:␣,precedes:…,tab:> '

-- Editing ====================================================================
vim.o.autoindent    = true
vim.o.expandtab     = true
vim.o.formatoptions = 'rqnl1j'
vim.o.ignorecase    = true
vim.o.incsearch     = true
vim.o.infercase     = true
vim.o.shiftwidth    = 2
vim.o.smartcase     = true
vim.o.smartindent   = true
vim.o.spelloptions  = 'camel'
vim.o.tabstop       = 2

vim.o.iskeyword = '@,48-57,_,192-255,-'

vim.o.formatlistpat = [[^\s*[0-9\-\+\*]\+[\.\\)]*\s\+]]

-- Built-in completion
vim.o.complete         = '.,w,b,kspell'
vim.o.completeopt      = 'menuone,noselect,fuzzy,nosort'
vim.o.completetimeout  = 100

-- Autocommands ================================================================
local f = function() vim.cmd('setlocal formatoptions-=c formatoptions-=o') end
Config.new_autocmd('FileType', nil, f, "Proper 'formatoptions'")

-- Diagnostics ================================================================
local diagnostic_opts = {
  signs = { priority = 9999, severity = { min = 'WARN', max = 'ERROR' } },
  underline = { severity = { min = 'HINT', max = 'ERROR' } },
  virtual_text = { current_line = true, severity = { min = 'ERROR', max = 'ERROR' } },
  update_in_insert = false,
}
Config.later(function() vim.diagnostic.config(diagnostic_opts) end)
-- stylua: ignore end
