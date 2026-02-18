pick_chezmoi = function()
    local pick = MiniPick

    -- Define the source items
    local source_items = require("chezmoi.commands").list()

    -- Start the picker
    pick.start({
        source = {
            items = source_items,
            choose = function(selected)
                require("chezmoi.commands").edit({
                    targets = { "~/" .. selected },
                    args = { "--watch" },
                })
            end,
        },
    })
end

vim.api.nvim_command("command! ChezmoiPick lua pick_chezmoi()")

-- Format commands
vim.api.nvim_create_user_command("FormatDisable", function(args)
    if args.bang then
        -- FormatDisable! will disable formatting just for this buffer
        vim.b.disable_autoformat = true
    else
        vim.g.disable_autoformat = true
    end
end, {
    desc = "Disable autoformat-on-save",
    bang = true,
})

vim.api.nvim_create_user_command("FormatEnable", function()
    vim.b.disable_autoformat = false
    vim.g.disable_autoformat = false
end, {
    desc = "Re-enable autoformat-on-save",
})

-- User commands for color palette management
vim.api.nvim_create_user_command("ColorPalettes", function()
    require("config.colors").pick_palette()
end, { desc = "Open color palette picker" })

vim.api.nvim_create_user_command("ColorPalette", function(opts)
    local palette_name = opts.args
    if palette_name == "" then
        require("config.colors").pick_palette()
    else
        require("config.colors").switch_palette(palette_name)
    end
end, {
    desc = "Switch color palette or open picker",
    nargs = '?',
    complete = function()
        return require("config.colors").list_palettes()
    end
})

vim.api.nvim_create_user_command("ColorToggle", function()
    require("config.colors").toggle_favorite_palettes()
end, { desc = "Toggle between favorite color palettes" })