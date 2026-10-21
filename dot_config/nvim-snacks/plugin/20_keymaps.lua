local nmap = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { desc = desc })
end

nmap('[p', '<Cmd>exe "iput! " . v:register<CR>', 'Paste Above')
nmap(']p', '<Cmd>exe "iput "  . v:register<CR>', 'Paste Below')

nmap('<Esc>', '<cmd>noh<cr>', 'Clear Search')

-- stylua: ignore start
Config.leader_groups = {
  { '<Leader>b', group = 'Buffer' },
  { '<Leader>c', group = 'Config' },
  { '<Leader>e', group = 'Explore/Edit', mode = { 'n', 'x' } },
  { '<Leader>f', group = 'Find' },
  { '<Leader>g', group = 'Git', mode = { 'n', 'x' } },
  { '<Leader>G', group = 'GitHub' },
  { '<Leader>l', group = 'Language', mode = { 'n', 'x' } },
  { '<Leader>o', group = 'Other' },
  { '<Leader>t', group = 'Terminal' },
  { '<Leader>q', group = 'Quit/Session' },
  { '\\', group = 'Toggle' },
  { '<Leader>w', group = 'Window', proxy = '<C-w>' },
}

local nmap_leader = function(suffix, rhs, desc, opts)
  opts = vim.tbl_extend('force', { desc = desc }, opts or {})
  vim.keymap.set('n', '<Leader>' .. suffix, rhs, opts)
end
local xmap_leader = function(suffix, rhs, desc)
  vim.keymap.set('x', '<Leader>' .. suffix, rhs, { desc = desc })
end

nmap_leader('qq', '<cmd>qa<cr>', 'Quit All')
nmap_leader('qw', '<cmd>wqa<cr>', 'Write and Quit All')
nmap_leader('qs', function() require('persistence').load() end, 'Restore session')
nmap_leader('qS', function() require('persistence').select() end, 'Select session')
nmap_leader('ql', function() require('persistence').load({ last = true }) end, 'Restore last session')
nmap_leader('qd', function() require('persistence').stop() end, "Don't save session")

local wipeout = function(force)
  return function() Snacks.bufdelete({ force = force, wipe = true }) end
end

nmap_leader('ba', '<Cmd>b#<CR>', 'Alternate')
nmap_leader('bd', function() Snacks.bufdelete() end, 'Delete')
nmap_leader('bD', function() Snacks.bufdelete({ force = true }) end, 'Delete!')
nmap_leader('bs', function() Snacks.scratch() end, 'Scratch')
nmap_leader('bS', function() Snacks.scratch.select() end, 'Scratch select')
nmap_leader('bw', wipeout(false), 'Wipeout')
nmap_leader('bW', wipeout(true), 'Wipeout!')
nmap('<S-h>', '<cmd>bprevious<cr>', 'Prev Buffer')
nmap('<S-l>', '<cmd>bnext<cr>', 'Next Buffer')

local edit_plugin_file = function(filename)
  return string.format('<Cmd>edit %s/plugin/%s<CR>', vim.fn.stdpath('config'), filename)
end
local explore_quickfix = function()
  vim.cmd(vim.fn.getqflist({ winid = true }).winid ~= 0 and 'cclose' or 'copen')
end
local explore_locations = function()
  vim.cmd(vim.fn.getloclist(0, { winid = true }).winid ~= 0 and 'lclose' or 'lopen')
end

nmap_leader('ci', '<Cmd>edit $MYVIMRC<CR>', 'init.lua')
nmap_leader('ck', edit_plugin_file('20_keymaps.lua'), 'Keymaps config')
nmap_leader('cm', edit_plugin_file('30_mini.lua'), 'MINI config')
nmap_leader('cs', edit_plugin_file('35_snacks.lua'), 'Snacks config')
nmap_leader('co', edit_plugin_file('10_options.lua'), 'Options config')
nmap_leader('cp', edit_plugin_file('40_plugins.lua'), 'Plugins config')
nmap_leader('cu', function () vim.pack.update() end, 'Plugins update')

nmap_leader('ed', function() Snacks.explorer() end, 'Directory')
nmap_leader('ef', function() Snacks.explorer.reveal() end, 'File directory')
nmap_leader('en', function() Snacks.notifier.show_history() end, 'Notifications')
nmap_leader('eq', explore_quickfix, 'Quickfix list')
nmap_leader('eQ', explore_locations, 'Location list')

local pick = function(source, opts)
  return function() Snacks.picker[source](opts) end
end

nmap_leader('<Space>', pick('smart'), 'Smart find')
nmap_leader('f/', pick('search_history'), '"/" history')
nmap_leader('f:', pick('command_history'), '":" history')
nmap_leader('fb', pick('buffers'), 'Buffers')
nmap_leader('fc', pick('git_log'), 'Commits (all)')
nmap_leader('fC', pick('git_log_file'), 'Commits (buf)')
nmap_leader('fd', pick('diagnostics'), 'Diagnostic workspace')
nmap_leader('fD', pick('diagnostics_buffer'), 'Diagnostic buffer')
nmap_leader('ff', pick('files'), 'Files')
nmap_leader('fg', pick('grep'), 'Grep live')
nmap_leader('fG', pick('grep_word'), 'Grep current word')
nmap_leader('fh', pick('help'), 'Help tags')
nmap_leader('fH', pick('highlights'), 'Highlight groups')
nmap_leader('fl', pick('grep_buffers'), 'Lines (all)')
nmap_leader('fL', pick('lines'), 'Lines (buf)')
nmap_leader('fi', pick('lsp_config'), 'LSP servers')
nmap_leader('fj', pick('jumps'), 'Jumps')
nmap_leader('fk', pick('keymaps'), 'Keymaps')
nmap_leader('fm', pick('git_status'), 'Modified files')
nmap_leader('fM', pick('git_diff'), 'Modified hunks')
nmap_leader('fr', pick('resume'), 'Resume')
nmap_leader('fR', pick('lsp_references'), 'References (LSP)')
nmap_leader('fs', pick('lsp_workspace_symbols'), 'Symbols workspace (live)')
nmap_leader('fS', pick('lsp_symbols'), 'Symbols document')
nmap_leader('fu', pick('undo'), 'Undo history')
nmap_leader('fv', pick('recent'), 'Recent paths (all)')
nmap_leader('fV', pick('recent', { filter = { cwd = true } }), 'Recent paths (cwd)')

local codediff_buf = function(args)
  return function()
    local file = vim.api.nvim_buf_get_name(0)
    local root = vim.fs.root(0, '.git') or vim.fn.getcwd()
    vim.cmd('CodeDiff ' .. args .. ' -- ' .. vim.fn.fnameescape(vim.fs.relpath(root, file) or file))
  end
end
local term = function(cmd)
  return function() Snacks.terminal(cmd) end
end

nmap_leader('ga', '<Cmd>CodeDiff --staged<CR>', 'Added diff')
nmap_leader('gA', codediff_buf('--staged'), 'Added diff buffer')
nmap_leader('gc', term('git commit'), 'Commit')
nmap_leader('gC', term('git commit --amend'), 'Commit amend')
nmap_leader('gB', function() Snacks.gitbrowse() end, 'Browse on remote')
nmap_leader('gd', '<Cmd>CodeDiff<CR>', 'Diff')
nmap_leader('gD', codediff_buf(''), 'Diff buffer')
nmap_leader('gl', pick('git_log'), 'Log')
nmap_leader('gL', pick('git_log_file'), 'Log buffer')
nmap_leader('go', function() Config.toggle_git_overlay() end, 'Toggle overlay')
nmap_leader('gs', function() Snacks.git.blame_line() end, 'Show at cursor')

xmap_leader('gB', function() Snacks.gitbrowse() end, 'Browse on remote')
xmap_leader('gs', function() Snacks.git.blame_line() end, 'Show at selection')

nmap_leader('la', '<Cmd>lua vim.lsp.buf.code_action()<CR>', 'Actions')
nmap_leader('ld', '<Cmd>lua vim.diagnostic.open_float()<CR>', 'Diagnostic popup')
nmap_leader('lf', '<Cmd>lua require("conform").format()<CR>', 'Format')
nmap_leader('lF', function() Snacks.rename.rename_file() end, 'Rename file')
nmap_leader('li', '<Cmd>lua vim.lsp.buf.implementation()<CR>', 'Implementation')
nmap_leader('lh', '<Cmd>lua vim.lsp.buf.hover()<CR>', 'Hover')
nmap_leader('ll', '<Cmd>lua vim.lsp.codelens.run()<CR>', 'Lens')
nmap_leader('lr', '<Cmd>lua vim.lsp.buf.rename()<CR>', 'Rename')
nmap_leader('lR', '<Cmd>lua vim.lsp.buf.references()<CR>', 'References')
nmap_leader('ls', '<Cmd>lua vim.lsp.buf.definition()<CR>', 'Source definition')
nmap_leader('lt', '<Cmd>lua vim.lsp.buf.type_definition()<CR>', 'Type definition')

xmap_leader('lf', '<Cmd>lua require("conform").format()<CR>', 'Format selection')

nmap_leader('or', '<Cmd>lua MiniMisc.resize_window()<CR>', 'Resize to default width')
nmap_leader('ot', [[<Cmd>keeppatterns %s/\s\+$//e<CR>]], 'Trim trailspace')
nmap_leader('oz', function() Snacks.zoom() end, 'Zoom toggle')

nmap_leader('tT', function() Snacks.terminal.toggle(nil, { win = { position = 'right' } }) end, 'Terminal (right)')
nmap_leader('tt', function() Snacks.terminal.toggle() end, 'Terminal')
vim.keymap.set('t', '<C-/>', function() Snacks.terminal.toggle() end, { desc = 'Hide terminal' })

vim.keymap.set({ 'n', 't' }, ']]', function() Snacks.words.jump(vim.v.count1) end, { desc = 'Next reference' })
vim.keymap.set({ 'n', 't' }, '[[', function() Snacks.words.jump(-vim.v.count1) end, { desc = 'Prev reference' })
-- stylua: ignore end
