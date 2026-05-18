-- ┌─────────────────────────┐
-- │ Filetype config example │
-- └─────────────────────────┘
--
-- This is an example of a configuration that will apply only to a particular
-- filetype, which is the same as file's basename ('markdown' in this example;
-- which is for '*.md' files).
--
-- It can contain any code which will be usually executed when the file is opened
-- (strictly speaking, on every 'filetype' option value change to target value).
-- Usually it needs to define buffer/window local options and variables.
-- So instead of `vim.o` to set options, use `vim.bo` for buffer-local options and
-- `vim.cmd('setlocal ...')` for window-local options (currently more robust).
--
-- This is also a good place to set buffer-local 'mini.nvim' variables.
-- See `:h mini.nvim-buffer-local-config` and `:h mini.nvim-disabling-recipes`.

-- Enable spelling and wrap for window
vim.cmd('setlocal spell wrap')

-- Fold with tree-sitter
vim.cmd('setlocal foldmethod=expr foldexpr=v:lua.vim.treesitter.foldexpr()')

-- zk keymaps: only active inside a zk notebook
local zk_ok, zk_util = pcall(require, "zk.util")
local nb_root = zk_ok and zk_util.notebook_root(vim.fn.expand("%:p")) or nil
if nb_root ~= nil then
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = 0, desc = desc })
  end
  local journal = function(kind)
    return function() require("zk").new({ dir = nb_root .. "/journal/" .. kind }) end
  end
  map("n", "<CR>",         "<Cmd>lua vim.lsp.buf.definition()<CR>",                                                     "Follow link")
  map("n", "K",            "<Cmd>lua vim.lsp.buf.hover()<CR>",                                                          "Preview link")
  map("n", "<Leader>nn", function()
    local prefix = vim.fn.input('Prefix (empty for none): ')
    local title = vim.fn.input('Title: ')
    local opts = { dir = vim.fn.expand('%:p:h'), title = title }
    if prefix ~= '' then opts.extra = { prefix = prefix } end
    require("zk").new(opts)
  end, "New note")
  map("n", "<Leader>nf",   "<Cmd>ZkNotes { sort = { 'modified' } }<CR>",                                               "Find notes")
  map("n", "<Leader>nt",   "<Cmd>ZkTags<CR>",                                                                          "Tags")
  map("n", "<Leader>nb",   "<Cmd>ZkBacklinks<CR>",                                                                     "Backlinks")
  map("n", "<Leader>nl",   "<Cmd>ZkLinks<CR>",                                                                         "Links")
  map("n", "<Leader>ni",   "<Cmd>ZkInsertLink<CR>",                                                                    "Insert link")
  map("n", "<Leader>njp",  journal("personal"),                                                                        "Journal (personal)")
  map("n", "<Leader>njw",  journal("work"),                                                                            "Journal (work)")
  map("v", "<Leader>nnt",  ":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<CR>",                        "New from title")
  map("v", "<Leader>nnc",  ":'<,'>ZkNewFromContentSelection { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>", "New from content")
  map("v", "<Leader>nf",   ":'<,'>ZkMatch<CR>",                                                                        "Find matching")
  map("v", "<Leader>ni",   ":'<,'>ZkInsertLinkAtSelection<CR>",                                                        "Insert link")
end

-- Disable built-in `gO` mapping in favor of 'mini.basics'
vim.keymap.del('n', 'gO', { buffer = 0 })

-- Re-create mini.clue triggers so they remain the latest buffer-local mappings
MiniClue.ensure_buf_triggers()

-- Set markdown-specific surrounding in 'mini.surround'
vim.b.minisurround_config = {
  custom_surroundings = {
    -- Markdown link. Common usage:
    -- `saiwL` + [type/paste link] + <CR> - add link
    -- `sdL` - delete link
    -- `srLL` + [type/paste link] + <CR> - replace link
    L = {
      input = { '%[().-()%]%(.-%)' },
      output = function()
        local link = require('mini.surround').user_input('Link: ')
        return { left = '[', right = '](' .. link .. ')' }
      end,
    },
  },
}
