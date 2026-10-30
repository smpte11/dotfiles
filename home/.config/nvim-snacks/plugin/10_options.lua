-- stylua: ignore start
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

vim.o.mouse       = 'a'
vim.o.mousescroll = 'ver:25,hor:6'
vim.o.switchbuf   = 'usetab'
vim.o.undofile    = true
vim.o.clipboard   = 'unnamedplus'
vim.o.swapfile    = false

vim.o.shada = "'100,<50,s10,:1000,/100,@100,h"

vim.o.breakindent    = true
vim.o.breakindentopt = 'list:-1'
vim.o.colorcolumn    = '+1'
vim.o.cursorline     = true
vim.o.linebreak      = true
vim.o.list           = true
vim.o.number         = true
vim.o.pumborder      = 'single'
vim.o.pumheight      = 10
vim.o.pummaxwidth    = 100
vim.o.ruler          = false
vim.o.shortmess      = 'CFOSWaco'
vim.o.showmode       = false
vim.o.signcolumn     = 'yes'
vim.o.splitbelow     = true
vim.o.splitkeep      = 'screen'
vim.o.splitright     = true
vim.o.winborder      = 'single'
vim.o.wrap           = false

vim.o.cursorlineopt  = 'screenline,number'

vim.o.laststatus = 3
vim.o.statusline = "%!v:lua.require'statusline'.render()"

vim.o.fillchars = 'eob: ,fold:╌'
vim.o.listchars = 'extends:…,nbsp:␣,precedes:…,tab:> '

vim.o.foldlevel   = 10
vim.o.foldmethod  = 'indent'
vim.o.foldnestmax = 10
vim.o.foldtext    = ''

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
vim.o.virtualedit   = 'block'

vim.o.iskeyword = '@,48-57,_,192-255,-'

vim.o.formatlistpat = [[^\s*[0-9\-\+\*]\+[\.\)]*\s\+]]

vim.o.autocomplete    = true
vim.o.complete        = 'o,.,w,b,kspell'
vim.o.completeopt     = 'menuone,noselect,fuzzy,nosort,popup'
vim.o.completetimeout = 100

vim.o.wildmode    = 'noselect:lastused,full'
vim.o.wildoptions = 'pum,fuzzy'

local f = function() vim.cmd('setlocal formatoptions-=c formatoptions-=o') end
Config.new_autocmd('FileType', nil, f, "Proper 'formatoptions'")

Config.new_autocmd('CmdlineChanged', { ':', '/', '?' }, function() vim.fn.wildtrigger() end, 'Cmdline autocompletion')

local diagnostic_opts = {
  signs = { priority = 9999, severity = { min = 'WARN', max = 'ERROR' } },
  underline = { severity = { min = 'HINT', max = 'ERROR' } },
  virtual_lines = false,
  virtual_text = {
    current_line = true,
    severity = { min = 'ERROR', max = 'ERROR' },
  },
  update_in_insert = false,
}

Config.later(function() vim.diagnostic.config(diagnostic_opts) end)
-- stylua: ignore end
