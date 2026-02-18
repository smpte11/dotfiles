-- 🎨 CENTRALIZED COLORSCHEME AND HIGHLIGHT MANAGEMENT
-- This file manages all colorscheme setup and custom highlight groups
-- Following mini.base16 canonical patterns for palette management

local M = {}

-- ═══════════════════════════════════════════════════════════════════
-- 🎨 PALETTE DEFINITIONS (Following mini.base16 patterns)
-- ═══════════════════════════════════════════════════════════════════

-- Your original custom palette (Kanagawa-like)
local kanagawa_palette = {
    base00 = "#1F1F28", -- bg
    base01 = "#2A2A37", -- bg_visual
    base02 = "#223249", -- bg_search
    base03 = "#727169", -- comment
    base04 = "#C8C093", -- fg_dim
    base05 = "#DCD7BA", -- fg
    base06 = "#938AA9", -- fg_reverse
    base07 = "#363646", -- bg_menu
    base08 = "#C34043", -- diag_error
    base09 = "#FFA066", -- diag_warning
    base0A = "#DCA561", -- diag_info
    base0B = "#98BB6C", -- diff_add
    base0C = "#7FB4CA", -- diff_change
    base0D = "#7E9CD8", -- diag_hint
    base0E = "#957FB8", -- statement
    base0F = "#D27E99", -- special
}

-- Minischeme dark palette (using mini.base16's actual minischeme generator)
local minischeme_dark = require('mini.base16').mini_palette('#112641', '#e2e98f', 75)

-- Minischeme light palette (using mini.base16's actual minischeme generator)
local minischeme_light = require('mini.base16').mini_palette('#e2e98f', '#112641', 25)

-- Available palettes (following mini.base16 canonical pattern)
M.palettes = {
    kanagawa = kanagawa_palette,
    minischeme_dark = minischeme_dark,
    minischeme_light = minischeme_light,
}

-- Current active palette
M.current_palette = "minischeme_dark" -- Default to minischeme dark

local function get_active_palette()
    return M.palettes[M.current_palette] or kanagawa_palette
end

--- Apply all custom highlight groups using the active palette
--- Following mini.base16 canonical pattern for highlight management
M.apply_highlights = function(palette)
    -- If no palette provided, try to detect current context
    if not palette then
        -- Check if we're using a managed palette or external colorscheme
        local colorscheme = vim.g.colors_name or ""
        local is_base16_managed = colorscheme:match("^base16%-")

        if is_base16_managed then
            -- Use our managed palette
            palette = get_active_palette()
        else
            -- External colorscheme - extract colors for custom highlights
            palette = M.extract_external_colors() or get_active_palette()
        end
    end

    -- ═══════════════════════════════════════════════════════════════════
    -- 🔹 CORE UI HIGHLIGHTS
    -- ═══════════════════════════════════════════════════════════════════

    -- MiniJump2d customization
    vim.api.nvim_set_hl(0, "MiniJump2dSpot", { reverse = true })

    -- ═══════════════════════════════════════════════════════════════════
    -- 🔹 COMPLETION HIGHLIGHTS (mini.completion)
    -- ═══════════════════════════════════════════════════════════════════

    -- Popup menu (completion menu) - use normal background for better border visibility
    vim.api.nvim_set_hl(0, "Pmenu", { bg = palette.base01, fg = palette.base05 })
    vim.api.nvim_set_hl(0, "PmenuSel", { bg = palette.base02, fg = palette.base05, bold = true })
    vim.api.nvim_set_hl(0, "PmenuSbar", { bg = palette.base02 })
    vim.api.nvim_set_hl(0, "PmenuThumb", { bg = palette.base04 })
    vim.api.nvim_set_hl(0, "PmenuBorder", { fg = palette.base03, bg = palette.base01 })

    -- Mini.completion specific highlights
    vim.api.nvim_set_hl(0, "MiniCompletionActiveParameter", { bg = palette.base02, bold = true })
    vim.api.nvim_set_hl(0, "MiniCompletionDeprecated", { fg = palette.base03, strikethrough = true })

    -- COMMENTED OUT: Blink.cmp highlights (replaced by mini.completion)
    -- vim.api.nvim_set_hl(0, "BlinkCmpMenu", { link = "Pmenu" })
    -- vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { link = "Pmenu" })
    -- vim.api.nvim_set_hl(0, "BlinkCmpMenuSelection", { link = "PmenuSel" })
    -- vim.api.nvim_set_hl(0, "BlinkCmpDoc", { link = "NormalFloat" })
    -- vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { link = "NormalFloat" })
    -- vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelp", { link = "NormalFloat" })
    -- vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelpBorder", { link = "NormalFloat" })

    -- ═══════════════════════════════════════════════════════════════════
    -- 🔹 AI ASSISTANT HIGHLIGHTS (CodeCompanion)
    -- ═══════════════════════════════════════════════════════════════════

    vim.api.nvim_set_hl(0, "CodeCompanionChatInfo", { fg = palette.base0D, bg = palette.base01 })
    vim.api.nvim_set_hl(0, "CodeCompanionChatError", { fg = palette.base08, bg = palette.base01, bold = true })
    vim.api.nvim_set_hl(0, "CodeCompanionChatWarn", { fg = palette.base0A, bg = palette.base01 })
    vim.api.nvim_set_hl(0, "CodeCompanionChatSubtext", { fg = palette.base03, italic = true })
    vim.api.nvim_set_hl(0, "CodeCompanionChatHeader", { fg = palette.base0E, bold = true })
    vim.api.nvim_set_hl(0, "CodeCompanionChatSeparator", { fg = palette.base02 })
    vim.api.nvim_set_hl(0, "CodeCompanionChatTokens", { fg = palette.base06, italic = true })
    vim.api.nvim_set_hl(0, "CodeCompanionChatTool", { fg = palette.base0B, bg = palette.base01 })
    vim.api.nvim_set_hl(0, "CodeCompanionChatToolGroups", { fg = palette.base0C, bg = palette.base01, bold = true })
    vim.api.nvim_set_hl(0, "CodeCompanionChatVariable", { fg = palette.base09, italic = true })
    vim.api.nvim_set_hl(0, "CodeCompanionVirtualText", { fg = palette.base04, italic = true })

    -- ═══════════════════════════════════════════════════════════════════
    -- 🔹 GIT INTEGRATION HIGHLIGHTS (Neogit)
    -- ═══════════════════════════════════════════════════════════════════

    vim.api.nvim_set_hl(0, "NeogitChangeDeleted", { fg = palette.base08, bg = "NONE" })

    -- ═══════════════════════════════════════════════════════════════════
    -- 🔹 CODEDIFF HIGHLIGHTS
    -- ═══════════════════════════════════════════════════════════════════
    -- VSCode-style diff highlighting using theme colors
    
    local MiniColors = require('mini.colors')
    
    local add_color = palette.base0B -- Green
    local del_color = palette.base08 -- Red/Error
    
    local diff_add_bg, diff_del_bg
    local diff_add_char_bg = add_color
    local diff_del_char_bg = del_color
    local diff_fg

    if vim.o.background == "light" then
        -- Light mode: Subtle background is very light (high lightness)
        diff_add_bg = MiniColors.modify_channel(add_color, 'lightness', function() return 90 end)
        diff_del_bg = MiniColors.modify_channel(del_color, 'lightness', function() return 90 end)
        diff_fg = palette.base00 -- Dark text on strong background
    else
        -- Dark mode: Subtle background is very dark (low lightness)
        diff_add_bg = MiniColors.modify_channel(add_color, 'lightness', function() return 20 end)
        diff_del_bg = MiniColors.modify_channel(del_color, 'lightness', function() return 20 end)
        diff_fg = palette.base00 -- Dark text on bright colored background
    end

    -- Line highlights (subtle background)
    vim.api.nvim_set_hl(0, "CodeDiffLineInsert", { bg = diff_add_bg }) 
    vim.api.nvim_set_hl(0, "CodeDiffLineDelete", { bg = diff_del_bg }) 
    
    -- Character highlights (strong background)
    vim.api.nvim_set_hl(0, "CodeDiffCharInsert", { bg = diff_add_char_bg, fg = diff_fg }) 
    vim.api.nvim_set_hl(0, "CodeDiffCharDelete", { bg = diff_del_char_bg, fg = diff_fg })
    
    -- Filler lines
    vim.api.nvim_set_hl(0, "CodeDiffFiller", { fg = palette.base03 })

    -- ═══════════════════════════════════════════════════════════════════
    -- 🔹 DEBUG HIGHLIGHTS (DAP) - Currently commented out but ready
    -- ═══════════════════════════════════════════════════════════════════

    -- Uncomment when using DAP
    -- vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    -- vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })

    -- ═══════════════════════════════════════════════════════════════════
    -- 🔹 MARKDOWN HIGHLIGHTS (markview.nvim)
    -- ═══════════════════════════════════════════════════════════════════

    -- Headings
    vim.api.nvim_set_hl(0, "MarkviewHeading1", { fg = palette.base0D, bg = palette.base02, bold = true }) -- Blue
    vim.api.nvim_set_hl(0, "MarkviewHeading2", { fg = palette.base0E, bg = palette.base01, bold = true }) -- Purple
    vim.api.nvim_set_hl(0, "MarkviewHeading3", { fg = palette.base0C, bold = true }) -- Cyan
    vim.api.nvim_set_hl(0, "MarkviewHeading4", { fg = palette.base09, bold = true }) -- Orange
    vim.api.nvim_set_hl(0, "MarkviewHeading5", { fg = palette.base0A, bold = true }) -- Yellow
    vim.api.nvim_set_hl(0, "MarkviewHeading6", { fg = palette.base08, bold = true }) -- Red
    
    -- Heading Signs/Markers (link to heading color)
    vim.api.nvim_set_hl(0, "MarkviewHeading1Sign", { link = "MarkviewHeading1" })
    vim.api.nvim_set_hl(0, "MarkviewHeading2Sign", { link = "MarkviewHeading2" })
    vim.api.nvim_set_hl(0, "MarkviewHeading3Sign", { link = "MarkviewHeading3" })
    vim.api.nvim_set_hl(0, "MarkviewHeading4Sign", { link = "MarkviewHeading4" })
    vim.api.nvim_set_hl(0, "MarkviewHeading5Sign", { link = "MarkviewHeading5" })
    vim.api.nvim_set_hl(0, "MarkviewHeading6Sign", { link = "MarkviewHeading6" })

    -- Code blocks
    vim.api.nvim_set_hl(0, "MarkviewCode", { bg = palette.base01 })
    vim.api.nvim_set_hl(0, "MarkviewCodeInfo", { bg = palette.base01, fg = palette.base04 }) -- info string (language name)
    vim.api.nvim_set_hl(0, "MarkviewInlineCode", { fg = palette.base0C, bg = palette.base01 })

    -- Other elements
    vim.api.nvim_set_hl(0, "MarkviewBlockQuote", { fg = palette.base04 })
    vim.api.nvim_set_hl(0, "MarkviewTableBorder", { fg = palette.base0E })
    vim.api.nvim_set_hl(0, "MarkviewHyperlink", { fg = palette.base0D, underline = true })

    -- ═══════════════════════════════════════════════════════════════════
    -- 🔹 STATUSLINE HIGHLIGHTS (Custom enhancements)
    -- ═══════════════════════════════════════════════════════════════════

    vim.api.nvim_set_hl(0, "StatuslineCopilot", { fg = palette.base0D, bg = palette.base01 })
    vim.api.nvim_set_hl(0, "StatuslineRecording", { fg = palette.base08, bg = palette.base01, bold = true })
    vim.api.nvim_set_hl(0, "StatuslineSession", { fg = palette.base0E, bg = palette.base01, italic = true })
    vim.api.nvim_set_hl(0, "StatuslineLineLimitExceeded", { fg = palette.base00, bg = palette.base08, bold = true })

    -- ═══════════════════════════════════════════════════════════════════
    -- 🔹 CUSTOM HIGHLIGHTS
    -- Add your custom highlight groups here
    -- ═══════════════════════════════════════════════════════════════════

    -- Example custom highlights using active palette:
    -- vim.api.nvim_set_hl(0, "MyCustomHighlight", { fg = palette.base0D, bold = true })
end

--- Extract colors from external colorscheme for custom highlights
M.extract_external_colors = function()
    local function get_color(group, attr)
        local hl = vim.api.nvim_get_hl(0, { name = group })
        return hl[attr] and string.format("#%06x", hl[attr]) or nil
    end

    -- Create base16-like palette from external colorscheme
    local extracted = {
        base00 = get_color("Normal", "bg") or "#000000",
        base01 = get_color("CursorLine", "bg") or get_color("Visual", "bg") or "#111111",
        base02 = get_color("Visual", "bg") or "#222222",
        base03 = get_color("Comment", "fg") or "#666666",
        base04 = get_color("LineNr", "fg") or "#888888",
        base05 = get_color("Normal", "fg") or "#ffffff",
        base06 = get_color("Normal", "fg") or "#ffffff",
        base07 = get_color("Normal", "fg") or "#ffffff",
        base08 = get_color("Error", "fg") or get_color("DiagnosticError", "fg") or "#ff5555",
        base09 = get_color("WarningMsg", "fg") or get_color("DiagnosticWarn", "fg") or "#ffb86c",
        base0A = get_color("WarningMsg", "fg") or "#f1fa8c",
        base0B = get_color("String", "fg") or "#50fa7b",
        base0C = get_color("Special", "fg") or "#8be9fd",
        base0D = get_color("Function", "fg") or get_color("Identifier", "fg") or "#6272a4",
        base0E = get_color("Statement", "fg") or get_color("Keyword", "fg") or "#bd93f9",
        base0F = get_color("Type", "fg") or "#ff79c6",
    }

    return extracted
end

--- Setup colorscheme and apply custom highlights (canonical mini.base16 pattern)
M.setup = function(palette_name)
    palette_name = palette_name or M.current_palette
    M.current_palette = palette_name

    local palette = M.palettes[palette_name]
    if not palette then
        print("❌ Unknown palette: " .. palette_name)
        return
    end

    -- Apply the base16 colorscheme with selected palette (canonical approach)
    require("mini.base16").setup({
        palette = palette,
    })

    -- Add transparency using mini.colors (as suggested by mini.nvim author)
    -- This makes background transparent while keeping the same color scheme
    local ok, mini_colors = pcall(require, 'mini.colors')
    if ok then
        mini_colors.get_colorscheme():add_transparency({
            general = true,       -- Make general background transparent (Normal, etc.)
            float = false,        -- Keep floating windows opaque to prevent artifacts
            statuscolumn = false, -- Keep status column opaque to prevent artifacts
            statusline = false,   -- Keep statusline opaque for readability
            tabline = false,      -- Keep tabline opaque for readability
            winbar = false,       -- Keep winbar opaque for readability
        }):apply()
    end

    -- Apply all custom highlights using the same palette
    -- MUST be done AFTER transparency to ensure our custom backgrounds aren't stripped
    M.apply_highlights(palette)

    print("🎨 Switched to " .. palette_name .. " palette")
end

--- Switch between available palettes (canonical mini.base16 approach)
M.switch_palette = function(palette_name)
    if not M.palettes[palette_name] then
        local available = vim.tbl_keys(M.palettes)
        print("❌ Unknown palette: " .. palette_name .. ". Available: " .. table.concat(available, ", "))
        return
    end

    M.setup(palette_name)
end

--- Get list of available palettes
M.list_palettes = function()
    local available = vim.tbl_keys(M.palettes)
    print("🎨 Available palettes: " .. table.concat(available, ", "))
    print("🎯 Current: " .. M.current_palette .. " palette")
    return available
end

--- Create a color palette picker using mini.pick (hierarchical subpicker)
M.pick_palette = function()
    local items = {}

    -- Add a toggle option at the top for quick access
    table.insert(items, {
        text = "🔄 Toggle Favorites (kanagawa ↔ minischeme_dark)",
        palette_name = "_toggle",
        is_action = true,
    })

    -- Add separator
    table.insert(items, {
        text = "────────────────────────────────────────",
        palette_name = "_separator",
        is_separator = true,
    })

    -- Create formatted items for each palette
    for name, palette in pairs(M.palettes) do
        local is_current = (name == M.current_palette)
        local prefix = is_current and "🎯 " or "🎨 "
        local suffix = is_current and " (current)" or ""

        -- Create a preview with some color samples
        local preview = string.format("%s%s%s", prefix, name:gsub("_", " "):gsub("^%l", string.upper), suffix)

        table.insert(items, {
            text = preview,
            palette_name = name,
            palette = palette,
        })
    end

    -- Sort palette items (keeping toggle and separator at top)
    local non_palette_items = {}
    local palette_items = {}

    for _, item in ipairs(items) do
        if item.is_action or item.is_separator then
            table.insert(non_palette_items, item)
        else
            table.insert(palette_items, item)
        end
    end

    -- Sort palette items to put current first
    table.sort(palette_items, function(a, b)
        if a.palette_name == M.current_palette then return true end
        if b.palette_name == M.current_palette then return false end
        return a.palette_name < b.palette_name
    end)

    -- Rebuild items with proper order
    items = {}
    for _, item in ipairs(non_palette_items) do
        table.insert(items, item)
    end
    for _, item in ipairs(palette_items) do
        table.insert(items, item)
    end

    -- Create the picker with enhanced functionality
    local choose_palette = function(item)
        if not item then return end

        if item.palette_name == "_toggle" then
            M.toggle_favorite_palettes()
        elseif item.palette_name == "_separator" then
            -- Do nothing for separator
            return
        elseif item.palette_name then
            M.switch_palette(item.palette_name)
        end
    end

    local preview_palette = function(buf_id, item)
        if not item then return end

        -- Handle special items
        if item.palette_name == "_toggle" then
            local lines = {
                "🔄 Toggle Between Favorites",
                "",
                "Quickly switch between your two favorite palettes:",
                "• kanagawa",
                "• minischeme_dark",
                "",
                "Current: " .. M.current_palette,
                "",
                "Press <Enter> to toggle!"
            }
            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
            return
        end

        if item.palette_name == "_separator" or not item.palette then
            local lines = {
                "Choose a color palette below:",
                "",
                "🎯 Current palette is highlighted",
                "👀 Preview colors in this panel",
                "⚡ Press <Enter> to switch",
            }
            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
            return
        end

        -- Regular palette preview
        local palette = item.palette
        local lines = {
            "🎨 " .. (item.palette_name:gsub("_", " "):gsub("^%l", string.upper)) .. " Palette",
            "",
            "Background Colors:",
            "  base00 (bg): " .. palette.base00,
            "  base01 (bg_visual): " .. palette.base01,
            "  base02 (bg_search): " .. palette.base02,
            "",
            "Foreground Colors:",
            "  base05 (fg): " .. palette.base05,
            "  base04 (fg_dim): " .. palette.base04,
            "  base03 (comment): " .. palette.base03,
            "",
            "Accent Colors:",
            "  base08 (red/error): " .. palette.base08,
            "  base09 (orange/warn): " .. palette.base09,
            "  base0A (yellow/info): " .. palette.base0A,
            "  base0B (green/diff_add): " .. palette.base0B,
            "  base0C (cyan/diff_change): " .. palette.base0C,
            "  base0D (blue/hint): " .. palette.base0D,
            "  base0E (purple/statement): " .. palette.base0E,
            "  base0F (magenta/special): " .. palette.base0F,
        }

        vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)

        -- Add some basic syntax highlighting to the preview
        vim.api.nvim_buf_set_option(buf_id, 'filetype', 'text')
    end

    return MiniPick.start({
        source = {
            name = "Command Palette → Colors", -- Breadcrumb-style title
            items = items,
            choose = choose_palette,
            preview = preview_palette,
        },
        window = {
            config = function()
                local height = math.floor(0.6 * vim.o.lines)
                local width = math.floor(0.8 * vim.o.columns)
                return {
                    anchor = "NW",
                    height = height,
                    width = width,
                    row = math.floor(0.2 * vim.o.lines),
                    col = math.floor(0.1 * vim.o.columns),
                    border = Utils.ui.border,
                }
            end
        }
    })
end

--- Toggle between your two favorite palettes
M.toggle_favorite_palettes = function()
    local favorites = { "kanagawa", "minischeme_dark" }
    local current_idx = 1

    for i, name in ipairs(favorites) do
        if name == M.current_palette then
            current_idx = i
            break
        end
    end

    -- Switch to the other favorite
    local next_idx = (current_idx % #favorites) + 1
    M.switch_palette(favorites[next_idx])
end

return M
