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
  local current_nb_root = function()
    return zk_util.notebook_root(vim.fn.expand("%:p")) or nb_root
  end
  -- Chained async prompts: aborts the whole flow if the user cancels any step (<Esc>).
  local ask = function(prompts, done)
    local results, i = {}, 0
    local function step()
      i = i + 1
      if i > #prompts then return done(results) end
      vim.ui.input({ prompt = prompts[i] }, function(v)
        if v == nil then return end
        results[i] = v
        step()
      end)
    end
    step()
  end
  local new_note = function(base_opts, prompts)
    ask(prompts, function(r)
      local opts = vim.tbl_extend("force", { dir = current_nb_root() }, base_opts)
      if r[1] ~= '' then opts.extra = { prefix = r[1] } end
      if r[2] and r[2] ~= '' then opts.title = r[2] end
      require("zk").new(opts)
    end)
  end
  local journal = function(group)
    return function() require("zk").new({ group = group }) end
  end
  -- Invoked via <Cmd>lua vim.b.zk_actions.fn()<CR> so visual mode is still
  -- active here; ESC commits '<'/'>' marks for the downstream readers. Without
  -- the <Cmd> indirection, mini.clue's dispatch consumes the visual context
  -- and the marks come back as [0,0,0,0].
  local new_from_selection = function(field)
    return function()
      vim.cmd('normal! \27')
      local mode = vim.fn.visualmode()
      local s, e = vim.fn.getpos("'<"), vim.fn.getpos("'>")
      local text = mode == '' and '' or table.concat(vim.fn.getregion(s, e, { type = mode }), "\n")
      if text == '' then
        vim.notify("No visual selection", vim.log.levels.WARN)
        return
      end
      local prompts = field == "content"
        and { 'Prefix (empty for none): ', 'Title: ' }
        or  { 'Prefix (empty for none): ' }
      new_note({ insertLinkAtLocation = zk_util.get_lsp_location_from_selection(), [field] = text }, prompts)
    end
  end
  vim.b.zk_actions = {
    new_from_title   = new_from_selection("title"),
    new_from_content = new_from_selection("content"),
  }
  -- LSP-dependent maps: wire when zk LSP attaches (may be after this ftplugin runs).
  local lsp_maps = function()
    map("n", "<CR>", "<Cmd>lua vim.lsp.buf.definition()<CR>", "Follow link")
    map("n", "K",    "<Cmd>lua vim.lsp.buf.hover()<CR>",      "Preview link")
  end
  if #vim.lsp.get_clients({ bufnr = 0, name = "zk" }) > 0 then
    lsp_maps()
  else
    vim.api.nvim_create_autocmd("LspAttach", {
      buffer = 0,
      callback = function(args)
        if vim.lsp.get_client_by_id(args.data.client_id).name == "zk" then
          lsp_maps()
          return true
        end
      end,
    })
  end
  map("n", "<Leader>nn", function()
    new_note({}, { 'Prefix (empty for none): ', 'Title: ' })
  end, "New note")
  map("n", "<Leader>nf",   "<Cmd>ZkNotes { sort = { 'modified' } }<CR>",                                               "Find notes")
  map("n", "<Leader>nt",   "<Cmd>ZkTags<CR>",                                                                          "Tags")
  map("n", "<Leader>nb",   "<Cmd>ZkBacklinks<CR>",                                                                     "Backlinks")
  map("n", "<Leader>nl",   "<Cmd>ZkLinks<CR>",                                                                         "Links")
  map("n", "<Leader>ni",   "<Cmd>ZkInsertLink<CR>",                                                                    "Insert link")
  map("n", "<Leader>njp",  journal("daily-personal"),                                                                  "Journal (personal)")
  map("n", "<Leader>njw",  journal("daily-work"),                                                                      "Journal (work)")
  map("v", "<Leader>nnt",  "<Cmd>lua vim.b.zk_actions.new_from_title()<CR>",                                             "New from title")
  map("v", "<Leader>nnc",  "<Cmd>lua vim.b.zk_actions.new_from_content()<CR>",                                           "New from content")
  map("v", "<Leader>nf",   ":'<,'>ZkMatch<CR>",                                                                        "Find matching")
  map("v", "<Leader>ni",   ":'<,'>ZkInsertLinkAtSelection<CR>",                                                        "Insert link")
end

-- Disable built-in `gO` mapping in favor of 'mini.basics'
pcall(vim.keymap.del, 'n', 'gO', { buffer = 0 })

-- Re-create mini.clue triggers so they remain the latest buffer-local mappings
if MiniClue then MiniClue.ensure_buf_triggers() end

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
