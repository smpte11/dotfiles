-- ╔═══════════════════════╗
-- ║    Local Variables    ║
-- ╚═══════════════════════╝
local keymap = vim.keymap.set
local opts = { noremap = true, silent = false }

local insert_password = function()
    local command = "openssl rand -base64 18"
    for _, line in ipairs(vim.fn.systemlist(command)) do
        vim.api.nvim_put({ line }, "", true, true)
    end
end

local insert_uuid = function()
    local uuid = Utils.generate_uuid()
    vim.api.nvim_put({ uuid }, "", true, true)
end

local split_sensibly = function()
    if vim.api.nvim_win_get_width(0) > math.floor(vim.api.nvim_win_get_height(0) * 2.3) then
        vim.cmd("vs")
    else
        vim.cmd("split")
    end
end

local copy_file_path = function()
    local path = vim.fn.expand('%:.')
    if path ~= '' then
        -- Include project name for full context
        local cwd = vim.fn.getcwd()
        local project_name = cwd:match("([^/]+)$")
        path = project_name .. '/' .. path
        vim.fn.setreg('+', path)
        vim.notify('Copied path: ' .. path, vim.log.levels.INFO)
    else
        vim.notify('No file path to copy', vim.log.levels.WARN)
    end
end

-- stylua: ignore start
-- ╔═══════════════════════╗
-- ║    General Keymaps    ║
-- ╚═══════════════════════╝
keymap("n", "<leader>mu", function() require("mini.deps").update() end, { desc = "[M]ini [U]pdate Plugins" })
keymap("n", "<leader>ms", function() require("mini.deps").snap_save() end, { desc = "[M]ini [S]ave Snapshot" })
keymap("n", "<leader>ml", function() require("mini.deps").snap_load() end, { desc = "[M]ini [L]oad Snapshot" })
keymap("n", "<leader>mn", function() require("mini.notify").show_history() end,
    { desc = "[M]ini [N]otification History" })

-- Quit
keymap("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })
keymap("n", "<leader>qw", "<cmd>wqa<cr>", { desc = "Write and Quit All" })

-- Copy
keymap("n", "<C-s>", "<cmd>:w<cr>", { silent = true })

-- Buffers
keymap("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer", silent = true })
keymap("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer", silent = true })
keymap("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer", silent = true })
keymap("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window", silent = true })
keymap("n", "<leader>bd", function() MiniBufremove.delete() end, { desc = "Delete Buffer", silent = true })

-- Windows
keymap("n", "<leader>ws", split_sensibly, { desc = "[S]plit [S]ensibly", remap = true })
keymap("n", "<leader>wh", "<C-W>s", { desc = "Split [W]indow [H]orizontally", remap = true })
keymap("n", "<leader>wv", "<C-W>v", { desc = "Split [W]indow [V]ertically", remap = true })
keymap("n", "<leader>wd", "<C-W>c", { desc = "[W]indow [D]elete", remap = true })

-- Search
keymap('n', '<leader>sb', function() MiniPick.builtin.buffers() end, { desc = '[S]earch [B]uffers' })
keymap("n", "<leader>sh", function() MiniPick.builtin.help_tags() end, { desc = "[S]earch [H]elp Tags" })
keymap("n", "<leader>sf", function() MiniPick.builtin.files() end, { desc = "[S]earch [F]iles" })
keymap("n", "<leader>sH", function() MiniPick.builtin.help() end, { desc = "[S]earch [H]elp" })
keymap('n', '<leader>sk', function() MiniExtra.pickers.keymaps() end, { desc = '[S]earch [K]eymaps' })
keymap('n', '<leader>sd', function() MiniExtra.pickers.diagnostic() end, { desc = '[S]earch [D]iagnostics' })
keymap('n', '<leader>so', function() MiniExtra.pickers.options() end, { desc = '[S]earch [O]ptions' })
keymap('n', '<leader>s"', function() MiniExtra.pickers.registers() end, { desc = '[S]earch Registers' })
keymap('n', '<leader>st', function() MiniExtra.pickers.treesitter() end, { desc = '[S]earch [T]reesitter' })
keymap('n', '<leader>ss', function() MiniExtra.pickers.spellsuggest() end, { desc = '[S]pelling [S]uggestions' })
keymap('n', '<leader>sR', function() MiniPick.builtin.resume() end, { desc = '[S]earch [R]esume' })
keymap('n', '<leader>s.', function() MiniExtra.pickers.oldfiles() end,
    { desc = '[S]earch Recent Files ("." for repeat)' })
keymap('n', '<leader>sc', function() MiniExtra.pickers.commands() end, { desc = '[S]earch commands' })
keymap('n', '<leader>sg', function() MiniPick.builtin.grep_live() end, { desc = '[S]earch by [G]rep' })
keymap('n', '<leader>sw', function() MiniPick.builtin.grep({ pattern = vim.fn.expand('<cword>') }) end,
    { desc = '[S]earch current [W]ord' })

-- Fuzzily search in current buffer (mini.pick equivalent of telescope current_buffer_fuzzy_find)
keymap('n', '<leader>/', function()
    MiniExtra.pickers.buf_lines({}, {
        window = {
            config = function()
                local height = math.floor(0.4 * vim.o.lines)
                local width = math.floor(0.8 * vim.o.columns)
                return {
                    anchor = "NW",
                    height = height,
                    width = width,
                    row = 1,
                    col = math.floor(0.5 * (vim.o.columns - width)),
                }
            end
        }
    })
end, { desc = '[/] Fuzzily search in current buffer' })

-- keymap('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })

-- ╔═══════════════════════╗
-- ║   Command Palette     ║
-- ╚═══════════════════════╝

keymap('n', '<leader><leader>', Utils.create_command_palette, { desc = 'Command Palette' })


-- ╔═══════════════════════╗
-- ║	   Editor          ║
-- ╚═══════════════════════╝
-- Format toggle with status indicator
local function get_format_status()
    if vim.b.disable_autoformat then
        return "disabled (buffer)"
    elseif vim.g.disable_autoformat then
        return "disabled (global)"
    else
        return "enabled"
    end
end

local function format_status_icon()
    if vim.g.disable_autoformat or vim.b.disable_autoformat then
        return "󰉿" -- Disabled
    else
        return "󰸞" -- Enabled
    end
end

keymap("n", "<leader>ef", function()
    local status = get_format_status()
    local icon = format_status_icon()
    vim.notify(string.format("%s Format is currently %s", icon, status), vim.log.levels.INFO)
end, { desc = "[E]ditor [F]ormat Status" })

keymap("n", "<leader>eF", function()
    vim.cmd("FormatEnable")
    vim.notify("󰸞 Format enabled", vim.log.levels.INFO)
end, { desc = "[E]ditor [F]ormat Enable" })

keymap("n", "<leader>ed", function()
    vim.cmd("FormatDisable")
    vim.notify("󰉿 Format disabled (global)", vim.log.levels.INFO)
end, { desc = "[E]ditor [D]isable Format (global)" })

keymap("n", "<leader>eD", function()
    vim.cmd("FormatDisable!")
    vim.notify("󰉿 Format disabled (buffer only)", vim.log.levels.INFO)
end, { desc = "[E]ditor [D]isable Format (buffer)" })

-- ╔═══════════════════════╗
-- ║	      UI           ║
-- ╚═══════════════════════╝
keymap("n", "<leader>ui", "<cmd>PasteImage<cr>", { desc = "[U]I Paste [I]mage" })

-- Color Palette Switching - Essential only
keymap("n", "<leader>uc", function() require("config.colors").pick_palette() end,
    { desc = "[U]I [C]olor Palette Picker" })
keymap("n", "<leader>ut", function() require("config.colors").toggle_favorite_palettes() end,
    { desc = "[U]I [T]oggle Favorite Palettes" })

-- Alternative quick access keymaps
keymap("n", "<leader>uC", "<cmd>ColorToggle<cr>", { desc = "[U]I [C]olor Toggle" })
keymap("n", "<F10>", function() require("config.colors").toggle_favorite_palettes() end, { desc = "Quick Color Toggle" })
keymap("n", "<F11>", function() require("config.colors").pick_palette() end, { desc = "Quick Color Picker" })

-- ╔═══════════════════════╗
-- ║	     File          ║
-- ╚═══════════════════════╝

keymap('n', '<leader>ff', function()
    local path = vim.api.nvim_buf_get_name(0)
    -- If buffer has no valid path or is a special buffer, use cwd instead
    if path == "" or path:match("^%w+:") then
        path = vim.uv.cwd()
    end
    require('mini.files').open(path, true)
end, { desc = "[F]ile Explorer" })
keymap('n', '<leader>fF', function() require('mini.files').open(vim.uv.cwd(), true) end,
    { desc = "[F]ile Explorer (cwd)" })
keymap('n', '<leader>fy', copy_file_path, { desc = "[F]ile [Y]ank Path" })

-- ╔═══════════════════════╗
-- ║	     LSP           ║
-- ╚═══════════════════════╝
-- Jump to the definition of the word under your cursor.
--  This is where a variable was first declared, or where a function is defined, etc.
--  To jump back, press <C-t>.
-- keymap("n", "gd", function() MiniExtra.pickers.lsp({ scope = "definition" }) end, { desc = "[G]oto [D]efinition" })

-- WARN: This is not Goto Definition, this is Goto Declaration.
--  For example, in C this would take you to the header.
-- keymap("n", "gD", vim.lsp.buf.declaration, { desc = "[G]oto [D]eclaration" })

-- Find references for the word under your cursor.
-- keymap("n", "gr", function() MiniExtra.pickers.lsp({ scope = "references" }) end, { desc = "[G]oto [R]eferences" })

-- jump to the implementation of the word under your cursor.
--  useful when your language has ways of declaring types without an actual implementation.
-- keymap("n", "gi", function() MiniExtra.pickers.lsp({ scope = "implementation" }) end,
-- { desc = "[G]oto [I]mplementation" })

-- jump to the type of the word under your cursor.
--  useful when you're not sure what type a variable is and you want to see
--  the definition of its *type*, not where it was *defined*.

-- todo: look into keymapping this the same as lazyvim
-- keymap("n", "<leader>lD", function() MiniExtra.pickers.lsp({ scope = "type_definition" }) end,
-- { desc = "[L]sp Type [D]efinition" })

-- Fuzzy find all the symbols in your current document.
--  Symbols are things like variables, functions, types, etc.
-- keymap("n", "<leader>ls", function() MiniExtra.pickers.lsp({ scope = "document_symbol" }) end,
-- { desc = "[L]sp Document [S]ymbols" })

-- Fuzzy find all the symbols in your current workspace.
--  Similar to document symbols, except searches over your entire project.
-- keymap("n", "<leader>lW", function() MiniExtra.pickers.lsp({ scope = "workspace_symbol" }) end,
-- { desc = "[L]sp workspace [S]ymbols" })

-- Rename the variable under your cursor.
--  Most Language Servers support renaming across files, etc.
-- keymap("n", "<leader>lr", vim.lsp.buf.rename, { desc = "[L]sp [R]ename" })

-- Execute a code action, usually your cursor needs to be on top of an error
-- or a suggestion from your LSP for this to activate.
-- keymap({ "n", "x" }, "<leader>la", vim.lsp.buf.code_action, { desc = "[C]ode [A]ction" })

-- keymap("n", "<leader>lf", function() require('conform').format { async = true, lsp_format = "fallback" } end, { desc = "[L]sp [F]ormat" })


-- keymap("n", "<leader>le", function() vim.diagnostic.open_float() end, { desc = "[L]sp [E]rror" })

-- ╔═══════════════════════╗
-- ║    Session Keymaps    ║
-- ╚═══════════════════════╝
keymap("n", "<leader>Ss", function()
    vim.cmd('wa')
    require('mini.sessions').write()
    require('mini.sessions').select()
end, { desc = 'Switch Session' })

keymap("n", "<leader>Sw",
    function()
        local cwd = vim.fn.getcwd()
        local last_folder = cwd:match("([^/]+)$")
        require('mini.sessions').write(last_folder)
    end, { desc = 'Save Session' })

keymap("n", "<leader>Sf", function()
    vim.cmd('wa')
    require('mini.sessions').select()
end, { desc = 'Load Session' })

-- ╔═══════════════════════╗
-- ║    Editing Keymaps    ║
-- ╚═══════════════════════╝
-- Insert a Password at point
keymap("n", "<leader>ip", insert_password, { desc = 'Insert Password' })
keymap("n", "<leader>iu", insert_uuid, { desc = 'Insert uuid' })
keymap("n", "YY", "<cmd>%y<cr>", { desc = 'Yank Buffer' })
keymap("n", "<Esc>", "<cmd>noh<cr>", { desc = 'Clear Search' })


-- ╔═══════════════════════╗
-- ║         Visit         ║
-- ╚═══════════════════════╝
keymap('n', '<leader>vp', function() MiniExtra.pickers.visit_paths() end, { desc = '[V]isit [P]aths' })
keymap('n', '<leader>vl', function() MiniExtra.pickers.visit_labels() end, { desc = '[V]isit [L]abels' })

local map_vis = function(keys, call, desc)
    local rhs = '<Cmd>lua MiniVisits.' .. call .. '<CR>'
    vim.keymap.set('n', '<Leader>' .. keys, rhs, { desc = desc })
end

map_vis('va', 'add_label()', '[A]dd Label')
map_vis('vr', 'remove_label()', '[R]emove Label')


-- ╔═══════════════════════╗
-- ║        COMBOS         ║
-- ╚═══════════════════════╝
local minikeymap = require('mini.keymap')
local map_combo = minikeymap.map_combo

-- ┌─────────────────────────────────────────────────────────────────┐
-- │ Navigation Combos (Normal & Visual)                             │
-- │ Quick line movement shortcuts                                   │
-- │                                                                 │
-- │ ll  →  g$ (end of visual line)                                  │
-- │ hh  →  g^ (start of visual line)                                │
-- │ Perfect for: Quick line navigation without reaching for $ ^     │
-- └─────────────────────────────────────────────────────────────────┘
map_combo({ 'n', 'x' }, 'll', 'g$')
map_combo({ 'n', 'x' }, 'hh', 'g^')
-- map_combo({ 'n', 'x' }, 'jj', '}')  -- Disabled: conflicts with common typing
-- map_combo({ 'n', 'x' }, 'kk', '{')  -- Disabled: conflicts with common typing

-- ╔═══════════════════════╗
-- ║   TEXT HELPER COMBOS  ║
-- ╚═══════════════════════╝

-- ┌─────────────────────────────────────────────────────────────────┐
-- │ Smart Semicolon (;;)                                            │
-- │ Add semicolon at end of line and return cursor to position      │
-- │                                                                 │
-- │ Examples:                                                       │
-- │ let count = getMy|Value()  →  let count = getMy|Value();        │
-- │ println!("Debug: {}", var|) → println!("Debug: {}", var|);      │
-- │ Perfect for: C/C++/Java/JavaScript/Rust/Erlang                  │
-- └─────────────────────────────────────────────────────────────────┘
map_combo('i', ';;', function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_input('<End>;<Esc>')
    vim.api.nvim_win_set_cursor(0, { row, col })
    vim.api.nvim_input('a')
end)

-- ┌─────────────────────────────────────────────────────────────────┐
-- │ Smart Comma (,,)                                                │
-- │ Add comma + space for function parameters and lists             │
-- │                                                                 │
-- │ Examples:                                                       │
-- │ def func(arg1|)           →  def func(arg1, |)                  │
-- │ spawn(Module|, Function   →  spawn(Module, |, Function          │
-- │ [item1| item2]            →  [item1, | item2]                   │
-- │ Perfect for: Function params, Erlang lists, JSON objects        │
-- └─────────────────────────────────────────────────────────────────┘
map_combo('i', ',,', '<BS><BS>, ')

-- ┌─────────────────────────────────────────────────────────────────┐
-- │ Smart Assignment (==)                                           │
-- │ Complete variable assignments with proper spacing               │
-- │                                                                 │
-- │ Examples:                                                       │
-- │ let myVariable|    →  let myVariable = |                        │
-- │ count|             →  count = |                                 │
-- │ result|            →  result = |                                │
-- │ Perfect for: Variable assignments in any language               │
-- └─────────────────────────────────────────────────────────────────┘
map_combo('i', '==', '<BS><BS> = ')

-- ┌─────────────────────────────────────────────────────────────────┐
-- │ Smart Quotes ("")                                               │
-- │ Context-aware quote wrapping and creation                       │
-- │                                                                 │
-- │ Examples:                                                       │
-- │ Inside word:  hello|world  →  "hello|world"                     │
-- │ At boundary:  name = |     →  name = "|"                        │
-- │ Empty space:  |            →  "|"                               │
-- │ Perfect for: String literals, wrapping existing text            │
-- └─────────────────────────────────────────────────────────────────┘
map_combo('i', '""', function()
    local mode = vim.fn.mode()
    if mode == 'v' or mode == 'V' then
        -- Wrap selection in quotes
        return '<Esc>`<i"<Esc>`>la"<Esc>i'
    else
        -- Check if we're at word boundary or inside word
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local char_before = col > 0 and line:sub(col, col) or ' '
        local char_after = col < #line and line:sub(col + 1, col + 1) or ' '

        if char_before:match('%w') and char_after:match('%w') then
            -- Inside word - wrap word in quotes
            return '<BS><BS><Esc>viw<Esc>`<i"<Esc>`>la"<Esc>i'
        else
            -- Create quote pair
            return '<BS><BS>""<Left>'
        end
    end
end)

-- ┌─────────────────────────────────────────────────────────────────┐
-- │ Type Annotations (::)                                           │
-- │ Add type annotations with proper spacing                        │
-- │                                                                 │
-- │ Examples:                                                       │
-- │ let count|           →  let count: |                            │
-- │ function(param|)     →  function(param: |)                      │
-- │ -spec func(Args|)    →  -spec func(Args: |) [Erlang]            │
-- │ Perfect for: TypeScript, Rust, Erlang specs                     │
-- └─────────────────────────────────────────────────────────────────┘
map_combo('i', '::', '<BS><BS>: ')

-- ┌─────────────────────────────────────────────────────────────────┐
-- │ Arrow Helper (->)                                               │
-- │ Add arrows/returns with proper spacing                          │
-- │                                                                 │
-- │ Examples:                                                       │
-- │ fn get_name()|         →  fn get_name() -> |  [Rust]            │
-- │ case Value of Pattern| →  case Value of Pattern -> | [Erlang]   │
-- │ (x, y)|               →  (x, y) -> | [Arrow functions]          │
-- │ Perfect for: Rust returns, Erlang cases, arrow functions        │
-- └─────────────────────────────────────────────────────────────────┘
map_combo('i', '->', '<BS><BS> -> ')

-- ┌─────────────────────────────────────────────────────────────────┐
-- │ Method Chaining (..)                                            │
-- │ Quick method chaining for fluent interfaces                     │
-- │                                                                 │
-- │ Examples:                                                       │
-- │ myObject|          →  myObject.|                                │
-- │ builder|           →  builder.|                                 │
-- │ stream|            →  stream.|                                  │
-- │ Perfect for: Builder patterns, fluent APIs, method chaining     │
-- └─────────────────────────────────────────────────────────────────┘
map_combo('i', '..', '<BS><BS>.')
-- ╔═══════════════════════╗
-- ║   MULTI-STEP KEYMAPS  ║
-- ╚═══════════════════════╝
-- ┌─────────────────────────────────────────────────────────────────┐
-- │ Smart Insert Mode Keys                                          │
-- │ Context-aware keys that cascade through multiple behaviors      │
-- │                                                                 │
-- │ <Tab>     → expand → snippets → completion → tree → brackets    │
-- │ <S-Tab>   → snippets ← completion ← tree ← brackets ← indent    │
-- │ <CR>      → accept completion → handle pairs                    │
-- │ <BS>      → handle pairs → hungry whitespace deletion           │
-- │ Perfect for: Snippets + completion + smart navigation           │
-- └─────────────────────────────────────────────────────────────────┘
local map_multistep = minikeymap.map_multistep

-- ┌─────────────────────────────────────────────────────────────────┐
-- │ Snippet Navigation in Insert + Select Mode                      │
-- │ Essential for navigating snippet tabstops with placeholder text │
-- │                                                                 │
-- │ Works in both Insert and Select modes for snippet placeholders  │
-- │ Select mode is activated when snippet has ${1:placeholder}      │
-- │ Perfect for: Tab-ing through function parameters, etc.          │
-- └─────────────────────────────────────────────────────────────────┘
-- Priority order: completion, snippets, indent, then smart jumps
-- NOTE: Using pmenu_* for mini.completion. For blink.cmp, replace with blink_* steps
local tab_steps = {
    'pmenu_next',        -- Navigate mini.completion menu if visible (blink: 'blink_next')
    'minisnippets_next', -- Jump to next snippet tabstop if in snippet
    'increase_indent',   -- Increase indent (prioritized over smart jumps)
    'jump_after_tsnode', -- Jump after current tree-sitter node
    'jump_after_close',  -- Jump after closing brackets/quotes
}

local shift_tab_steps = {
    'pmenu_prev',         -- Navigate mini.completion menu backwards if visible (blink: 'blink_prev')
    'minisnippets_prev',  -- Jump to previous snippet tabstop if in snippet
    'decrease_indent',    -- Decrease indent (prioritized over smart jumps)
    'jump_before_tsnode', -- Jump before current tree-sitter node
    'jump_before_open',   -- Jump before opening brackets/quotes
}

-- Apply the multi-step mappings for both insert and select modes
map_multistep({ 'i', 's' }, '<Tab>', tab_steps)
map_multistep({ 'i', 's' }, '<S-Tab>', shift_tab_steps)

-- Smart Enter that accepts completion and respects pairs
-- NOTE: Using pmenu_accept for mini.completion. For blink.cmp, use 'blink_accept'
map_multistep('i', '<CR>', { 'pmenu_accept', 'minipairs_cr' })

-- Smart Backspace that respects pairs and does hungry deletion
map_multistep('i', '<BS>', { 'minipairs_bs', 'hungry_bs' })

-- ╔═══════════════════════╗
-- ║    ESCAPE COMBOS      ║
-- ╚═══════════════════════╝

-- ┌─────────────────────────────────────────────────────────────────┐
-- │ Better Escape (jk / kj)                                         │
-- │ Quick escape from any mode without reaching for Esc key         │
-- │                                                                 │
-- │ Works in modes: Insert, Command, Visual, Select                 │
-- │ jk  →  <Esc> (remove jk and escape)                             │
-- │ kj  →  <Esc> (remove kj and escape)                             │
-- │ Perfect for: Fast mode switching, ergonomic typing              │
-- └─────────────────────────────────────────────────────────────────┘
local escape_modes = { 'i', 'c', 'x', 's' }
map_combo(escape_modes, 'jk', '<BS><BS><Esc>')
map_combo(escape_modes, 'kj', '<BS><BS><Esc>')

-- ╔═══════════════════════╗
-- ║         Tmux          ║
-- ╚═══════════════════════╝
-- Tmux navigation keymaps are set up in plugin/tmux.lua after vim-tmux-navigator is loaded
-- stylua: ignore end
