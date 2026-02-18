-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ Markdown Configuration                                                      │
-- │                                                                             │
-- │ Uses global: spec (from 00-bootstrap.lua)                                  │
-- └─────────────────────────────────────────────────────────────────────────────┘
spec({
    source = "OXY2DEV/markview.nvim",
    -- Note: Ensure you have `markdown`, `markdown_inline` parsers installed via nvim-treesitter.
    -- :TSInstall markdown markdown_inline html latex
    config = function()
        -- Load presets if available, otherwise fallback to empty table
        local presets = require("markview.presets")

        require("markview").setup({
            preview = {
                -- Use mini.icons for consistency
                icon_provider = "mini",
                -- Hybrid mode for editing
                modes = {"n", "no", "c"},
                hybrid_modes = {"i"},
                callbacks = {
                    on_enable = function(_, win)
                        vim.wo[win].conceallevel = 2
                        vim.wo[win].concealcursor = "nc"
                    end
                }
            },
            markdown = {
                tables = presets.tables.double,
                -- Use marker preset for headings (cleaner look)
                headings = presets.headings.glow,
                code_blocks = {
                    -- No padding for code blocks
                    pad_amount = 0,
                    style = "simple",
                    sign = true,
                    label_direction = "left"
                },
                inline_codes = {
                    pad_amount = 0
                },
                block_quotes = {
                    default = {
                        pad_amount = 1
                    },
                    callouts = {
                        pad_amount = 1
                    }
                },
                list_items = {
                    shift_width = 1,
                    indent_size = 1
                },
                checkboxes = {
                    pad_amount = 1
                }
            }
        })

        vim.g.markview_dark_bg = true -- Enable dark background support
    end
})

