-- 📊 STATUSLINE CONFIGURATION MODULE
-- Custom statusline sections and helpers for mini.statusline
-- Extracted from plugin configuration for better organization and testability
--
-- ═══════════════════════════════════════════════════════════════════════════════
-- 📚 MODULE STRUCTURE
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- This module provides enhanced statusline functionality for mini.statusline with:
--
-- 1. LINE LENGTH LIMITS (M.line_limits)
--    - Language-specific recommended line lengths (50+ languages)
--    - Used to show column position relative to style guide limits
--    - Example: `:12/80` means "column 12 of recommended 80"
--
-- 2. HELPER FUNCTIONS
--    - M.get_line_limit()         : Get recommended line length (textwidth > colorcolumn > language default)
--    - M.get_scrollbar()           : Generate visual scrollbar indicator (▁▂▃▄▅▆▇█)
--    - M.should_show_word_count()  : Check if filetype should display word count
--
-- 3. CUSTOM SECTIONS (drop-in replacements for mini.statusline defaults)
--    - M.section_location()   : Enhanced location with scrollbar, word count, line limits, warning
--    - M.section_lsp()        : Shows LSP client names instead of generic "LSP"
--    - M.section_copilot()    : GitHub Copilot status indicator
--    - M.section_recording()  : Macro recording indicator
--    - M.section_session()    : Current session name (mini.sessions)
--
-- 4. STATUSLINE BUILDER
--    - M.active()  : Complete active window statusline (used in mini.statusline setup)
--
-- ═══════════════════════════════════════════════════════════════════════════════
-- 📖 USAGE
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- In your plugin configuration (e.g., plugin/01-core.lua):
--
--   local statusline = require("config.statusline")
--   require("mini.statusline").setup({
--     content = {
--       active = statusline.active,
--     },
--   })
--
-- To customize line limits for a specific language:
--
--   local statusline = require("config.statusline")
--   statusline.line_limits.python = 100  -- Override default of 88
--
-- ═══════════════════════════════════════════════════════════════════════════════

local M = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📏 LINE LENGTH LIMITS BY LANGUAGE
-- ═══════════════════════════════════════════════════════════════════════════════

M.line_limits = {
    -- Functional Languages
    erlang = 80,
    scala = 100,
    haskell = 80,
    ocaml = 80,
    fsharp = 120,
    clojure = 80,
    racket = 80,
    scheme = 80,
    lisp = 80,
    elixir = 98,

    -- Systems & Performance
    c = 80,
    cpp = 80,
    rust = 100,
    zig = 100,
    nim = 80,
    crystal = 80,
    go = 100,

    -- Modern/Popular Languages
    python = 88, -- Black formatter default
    javascript = 80,
    typescript = 80,
    javascriptreact = 80,
    typescriptreact = 80,
    lua = 120,
    ruby = 80,
    java = 120,
    kotlin = 120,
    swift = 100,
    dart = 80,
    csharp = 120,

    -- Scientific/Data
    r = 80,
    julia = 92, -- Julia Blue Style

    -- Shell
    sh = 80,
    bash = 80,
    zsh = 80,
    fish = 80,
    vim = 80,

    -- Markup & Documentation
    markdown = 80,
    text = 80,
    org = 80,
    norg = 80,
    rst = 80,
    asciidoc = 80,

    -- Data Formats
    yaml = 80,
    toml = 80,
    json = 80,
    xml = 80,

    -- Web
    html = 120,
    css = 80,
    scss = 80,
    less = 80,

    -- DevOps & Infrastructure
    sql = 80,
    terraform = 80,
    hcl = 80,
    dockerfile = 80,
    proto = 80,
    graphql = 80,

    -- Git
    gitcommit = 72,
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔧 HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

--- Get recommended line length for current buffer
--- Priority: textwidth > colorcolumn > language defaults
--- @return number|nil line_limit The recommended line length, or nil if none
M.get_line_limit = function()
    -- First check textwidth
    if vim.bo.textwidth > 0 then
        return vim.bo.textwidth
    end

    -- Then check colorcolumn (take first value if multiple)
    if vim.wo.colorcolumn ~= "" then
        local cc = vim.wo.colorcolumn:match("^[+-]?(%d+)")
        if cc then return tonumber(cc) end
    end

    -- Language-specific defaults
    return M.line_limits[vim.bo.filetype]
end

--- Generate a visual scrollbar indicator
--- @param line number Current line number
--- @param total_lines number Total lines in buffer
--- @param win_height number Window height
--- @return string scrollbar Visual scrollbar character with space, or empty string
M.get_scrollbar = function(line, total_lines, win_height)
    -- Only show scrollbar if file is longer than window
    if total_lines <= win_height then
        return ""
    end

    local position = line / total_lines
    local bars = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
    local idx = math.max(1, math.min(#bars, math.floor(position * #bars) + 1))
    return bars[idx] .. " "
end

--- Check if current filetype should show word count
--- @param ft string Filetype
--- @return boolean
M.should_show_word_count = function(ft)
    local text_filetypes = {
        markdown = true,
        text = true,
        org = true,
        norg = true,
        rst = true,
        asciidoc = true,
    }
    return text_filetypes[ft] or false
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📍 CUSTOM STATUSLINE SECTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

--- Enhanced location section with scrollbar, word count, and line length limits
--- @return string location_text The formatted location string
--- @return boolean exceeds_limit Whether current column exceeds recommended limit
M.section_location = function()
    local line = vim.fn.line('.')
    local total_lines = vim.fn.line('$')
    local col = vim.fn.virtcol('.')
    local win_height = vim.fn.winheight(0)

    local line_limit = M.get_line_limit()
    local exceeds_limit = line_limit and col > line_limit
    local scrollbar = M.get_scrollbar(line, total_lines, win_height)

    -- For text files: include word count
    if M.should_show_word_count(vim.bo.filetype) then
        local words = vim.fn.wordcount().words
        if line_limit then
            local col_indicator = exceeds_limit and "!" or ":"
            local text = string.format("%s %dw  %d/%d%s%d/%d",
                scrollbar, words, line, total_lines, col_indicator, col, line_limit)
            return text, exceeds_limit
        else
            return string.format("%s %dw  %d/%d:%d",
                scrollbar, words, line, total_lines, col), false
        end
    end

    -- For code files: show line/total:col with optional limit
    if line_limit then
        local col_indicator = exceeds_limit and "!" or ":"
        local text = string.format("%s %d/%d%s%d/%d",
            scrollbar, line, total_lines, col_indicator, col, line_limit)
        return text, exceeds_limit
    else
        return string.format("%s %d/%d:%d", scrollbar, line, total_lines, col), false
    end
end

--- Enhanced LSP section showing client names instead of generic "LSP"
--- @param trunc_width number Width threshold for truncation
--- @return string lsp_info LSP client information
M.section_lsp = function(trunc_width)
    if MiniStatusline.is_truncated(trunc_width) then
        return MiniStatusline.section_lsp({ trunc_width = trunc_width })
    end

    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients > 0 then
        local names = vim.tbl_map(function(c) return c.name end, clients)
        return " " .. table.concat(names, ",")
    end

    return ""
end

--- Copilot status indicator
--- @param trunc_width number Width threshold for truncation
--- @return string copilot_status Copilot status icon or empty string
M.section_copilot = function(trunc_width)
    if MiniStatusline.is_truncated(trunc_width) then
        return ""
    end

    local ok, api = pcall(require, "copilot.api")
    if ok and api.status.data.status == "Normal" then
        return " "
    end

    return ""
end

--- Recording indicator for macro recording
--- @return string recording Recording status (e.g., "󰑊 @a") or empty string
M.section_recording = function()
    local reg = vim.fn.reg_recording()
    if reg ~= "" then
        return "󰑊 @" .. reg
    end
    return ""
end

--- Session name indicator
--- @param trunc_width number Width threshold for truncation
--- @return string session_name Session name with icon or empty string
M.section_session = function(trunc_width)
    if MiniStatusline.is_truncated(trunc_width) then
        return ""
    end

    local session_path = vim.v.this_session
    if session_path ~= "" then
        local name = vim.fn.fnamemodify(session_path, ":t:r")
        return "  " .. name
    end

    return ""
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎨 STATUSLINE CONTENT BUILDER
-- ═══════════════════════════════════════════════════════════════════════════════

--- Build the active window statusline content
--- @return string statusline The complete statusline string
M.active = function()
    local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
    local git = MiniStatusline.section_git({ trunc_width = 40 })
    local diff = MiniStatusline.section_diff({ trunc_width = 75 })
    local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })

    -- Custom sections
    local lsp = M.section_lsp(75)
    local copilot = M.section_copilot(90)
    local recording = M.section_recording()
    local session = M.section_session(100)

    -- Location with warning status
    local location = ""
    local location_hl = mode_hl
    if not MiniStatusline.is_truncated(75) then
        local loc_text, exceeds_limit = M.section_location()
        location = loc_text
        if exceeds_limit then
            location_hl = "StatuslineLineLimitExceeded"
        end
    end

    local filename = MiniStatusline.section_filename({ trunc_width = 140 })
    local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
    local search = MiniStatusline.section_searchcount({ trunc_width = 75 })

    return MiniStatusline.combine_groups({
        { hl = mode_hl,                 strings = { mode, session } },
        { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp, copilot } },
        "%<", -- Mark general truncate point
        { hl = "MiniStatuslineFilename", strings = { filename } },
        "%=", -- End left alignment
        { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
        { hl = location_hl,              strings = { recording, search, location } },
    })
end

return M
