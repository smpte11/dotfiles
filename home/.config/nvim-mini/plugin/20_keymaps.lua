-- Custom mappings, trimmed for a writing-focused setup.

local nmap = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { desc = desc })
end

nmap('<Esc>', '<cmd>noh<cr>', 'Clear Search')

-- Prose helpers
nmap('<Leader>pw', '<cmd>setlocal wrap!<cr>', 'Toggle Wrap')
nmap('<Leader>ps', '<cmd>setlocal spell!<cr>', 'Toggle Spell')

-- Leader group clues for 'mini.clue'
Config.leader_group_clues = {
  { mode = 'n', keys = '<Leader>b', desc = '+Buffer' },
  { mode = 'n', keys = '<Leader>e', desc = '+Explore/Edit' },
  { mode = 'n', keys = '<Leader>f', desc = '+Find' },
  { mode = 'n', keys = '<Leader>p', desc = '+Prose' },
  { mode = 'n', keys = '<Leader>s', desc = '+Session' },
  { mode = 'n', keys = '<Leader>q', desc = '+Quit' },
}

local nmap_leader = function(suffix, rhs, desc, opts)
  opts = vim.tbl_extend('force', { desc = desc }, opts or {})
  vim.keymap.set('n', '<Leader>' .. suffix, rhs, opts)
end

-- Buffer
nmap_leader('bd', '<cmd>lua MiniBufremove.delete()<cr>', 'Delete buffer')

-- Explore/Edit
nmap_leader('ed', '<cmd>lua MiniFiles.open()<cr>', 'Open explorer')
nmap_leader('ef', '<cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<cr>', 'Explore file directory')

-- Find
nmap_leader('ff', '<cmd>Pick files<cr>', 'Find files')
nmap_leader('fg', '<cmd>Pick grep_live<cr>', 'Grep live')
nmap_leader('fb', '<cmd>Pick buffers<cr>', 'Find buffers')
nmap_leader('fh', '<cmd>Pick help<cr>', 'Find helptags')
nmap_leader('fr', '<cmd>Pick resume<cr>', 'Resume last picker')

-- Session
nmap_leader('sl', '<cmd>lua MiniSessions.read()<cr>', 'Read session')
nmap_leader('sw', function() MiniSessions.write(vim.fn.getcwd(), {}) end, 'Write session')

-- Quit
nmap_leader('qq', '<cmd>qa<cr>', 'Quit all')
nmap_leader('qw', '<cmd>wqa<cr>', 'Write and quit all')
