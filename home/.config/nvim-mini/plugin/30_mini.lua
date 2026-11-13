-- MINI configuration for the minimal writing/editing setup.
-- Kept modules focus on: navigation, text editing, prose, and config tweaking.

-- mini.basics: common options and mappings in one call
require('mini.basics').setup({
  options = {
    basic = true,
    extra_ui = true,
    win_borders = 'single',
  },
  mappings = {
    basic = true,
    prefix = true,
    windows = true,
    move_with_alt = true,
    jumps = true,
  },
})

-- mini.icons: icon provider for statusline, files, pick
require('mini.icons').setup()

-- mini.notify: show `vim.notify()` messages as notifications
Config.later(function() require('mini.notify').setup() end)

-- mini.statusline: minimal statusline
Config.now(function() require('mini.statusline').setup() end)

-- mini.sessions: session persistence (useful on a handheld: reopen your config)
Config.later(function()
  require('mini.sessions').setup({ directory = vim.fn.stdpath('data') .. '/session-mini' })
end)

-- mini.starter: lightweight start screen
Config.now_if_args(function()
  local starter = require('mini.starter')
  local pad = string.rep(' ', 12)
  local header = pad .. 'mini - edit / write'
  starter.setup({
    header = header,
    items = {
      starter.new_item('Find files', '<cmd>Pick files<cr>'),
      starter.new_item('Recent sessions', '<cmd>lua MiniSessions.read()<cr>'),
      starter.new_item('Explorer', '<cmd>lua MiniFiles.open()<cr>'),
      starter.new_item('Open config', function() vim.cmd('edit ' .. vim.fn.stdpath('config')) end),
    },
    content_hooks = {
      starter.gen_hook.adding_bullet(),
      starter.gen_hook.aligning('center', 'top'),
    },
  })
end)

-- mini.files: file explorer
Config.now_if_args(function()
  require('mini.files').setup({ windows = { preview = true, width_preview = 80 } })
  local add_marks = function()
    MiniFiles.set_bookmark('c', vim.fn.stdpath('config'), { desc = 'Config' })
    MiniFiles.set_bookmark('w', vim.fn.getcwd, { desc = 'Working directory' })
  end
  Config.new_autocmd('User', 'MiniFilesExplorerOpen', add_marks, 'Add bookmarks')
end)

-- mini.pick: fuzzy finder
Config.later(function()
  require('mini.pick').setup()
end)

-- mini.clue: which-key style hints (essential without muscle memory)
Config.later(function()
  local miniclue = require('mini.clue')
  miniclue.setup({
    triggers = {
      { mode = 'n', keys = '<Leader>' },
      { mode = 'x', keys = '<Leader>' },
      { mode = 'n', keys = '[' },
      { mode = 'n', keys = ']' },
      { mode = 'n', keys = 'g' },
      { mode = 'x', keys = 'g' },
      { mode = 'n', keys = 's' },
      { mode = 'x', keys = 's' },
      { mode = 'n', keys = 'z' },
    },
    clues = {
      miniclue.gen_clues.g(),
      miniclue.gen_clues.builtin_completion(),
      miniclue.gen_clues.marks(),
      miniclue.gen_clues.registers(),
      miniclue.gen_clues.windows(),
      miniclue.gen_clues.z(),
      Config.leader_group_clues,
    },
    window = { delay = 300 },
  })
end)

-- mini.ai: enhanced textobjects
Config.later(function()
  require('mini.ai').setup()
end)

-- mini.align: align text interactively (markdown tables, lists)
Config.later(function() require('mini.align').setup() end)

-- mini.bracketed: bracket navigation for buffers, diagnostics, etc.
Config.later(function() require('mini.bracketed').setup() end)

-- mini.bufremove: delete buffers without losing window layout
Config.later(function() require('mini.bufremove').setup() end)

-- mini.comment: comment operator
Config.later(function() require('mini.comment').setup() end)

-- mini.completion: completion with path fallback and LSP integration
Config.later(function()
  local fallback_action = function()
    local col = vim.fn.col('.')
    local line = vim.fn.getline('.'):sub(1, col - 1)
    if line:match('[%.~/][%w_%.~/%-]*$') then
      local keys = vim.api.nvim_replace_termcodes('<C-g><C-g><C-x><C-f>', true, false, true)
      vim.api.nvim_feedkeys(keys, 'n', false)
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-n>', true, false, true), 'n', false)
    end
  end

  require('mini.completion').setup({
    lsp_completion = { source_func = 'omnifunc', auto_setup = false },
    fallback_action = fallback_action,
  })

  local on_attach = function(ev)
    vim.bo[ev.buf].omnifunc = 'v:lua.MiniCompletion.completefunc_lsp'
  end
  Config.new_autocmd('LspAttach', nil, on_attach, "Set 'omnifunc'")

  vim.lsp.config('*', { capabilities = MiniCompletion.get_lsp_capabilities() })
end)

-- mini.jump2d: fast cursor movement without a mouse
Config.later(function()
  require('mini.jump2d').setup()
end)

-- mini.move: move lines and selections with Alt-hjkl / Shift-hjkl
Config.later(function()
  require('mini.move').setup()
end)

-- mini.pairs: autopairs
Config.later(function() require('mini.pairs').setup({ modes = { command = true } }) end)

-- mini.snippets: snippets for markdown and config languages
Config.later(function()
  local snippets = require('mini.snippets')
  local config_path = vim.fn.stdpath('config')
  snippets.setup({
    snippets = {
      snippets.gen_loader.from_file(config_path .. '/snippets/global.json'),
    },
  })
  MiniSnippets.start_lsp_server()

  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniSnippetsSessionJump',
    callback = function(args)
      if args.data.tabstop_to == '0' then MiniSnippets.session.stop() end
    end,
  })
end)

-- mini.splitjoin: toggle joined/split arguments (useful in YAML/TOML lists)
Config.later(function() require('mini.splitjoin').setup() end)

-- mini.surround: add/replace/delete surroundings (markdown emphasis, brackets)
Config.later(function() require('mini.surround').setup() end)

-- mini.trailspace: highlight and remove trailing whitespace
Config.later(function() require('mini.trailspace').setup() end)
