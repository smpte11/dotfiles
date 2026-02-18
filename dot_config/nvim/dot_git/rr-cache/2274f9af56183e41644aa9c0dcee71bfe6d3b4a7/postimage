-- Uses global: add, later, spec (from 00-bootstrap.lua)

-- GitHub Copilot
spec({
    source = "zbirenbaum/copilot.lua",
    config = function()
        -- COMMENTED OUT: Old config with suggestions disabled (used only for CodeCompanion backend)
        -- Uncomment to revert to backend-only mode
        --[[
        require("copilot").setup({
            suggestion = { enabled = false },
            panel = { enabled = false },
        })
        --]]

        -- ACTIVE: Copilot with ghost text suggestions enabled
        require("copilot").setup({
            suggestion = {
                enabled = true,
                auto_trigger = true,
                hide_during_completion = true, -- Hide when completion menu is open
                debounce = 75,
                keymap = {
                    accept = "<M-l>", -- Option+l to accept suggestion
                    accept_word = false,
                    accept_line = false,
                    next = "<M-]>",    -- Option+] for next suggestion
                    prev = "<M-[>",    -- Option+[ for previous suggestion
                    dismiss = "<M-d>", -- Option+d to dismiss
                },
            },
            panel = { enabled = false },
            filetypes = {
                yaml = true,
                markdown = true,
                help = false,
                gitcommit = true,
                gitrebase = false,
                ["."] = false,
            },
        })
    end,
})

-- CodeCompanion AI assistant
spec({
    source = "olimorris/codecompanion.nvim",
    depends = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
        require("codecompanion").setup({
            ignore_warnings = true, -- Mute v18.0.0 breaking changes warning
            adapters = {
                http = {
                    ollama = function()
                        return require("codecompanion.adapters").extend("openai_compatible", {
                            env = {
                                url = "http://localhost:1234",
                                api_key = "lm-studio",
                            },
                        })
                    end,
                },
            },
            interactions = { -- Renamed from strategies in v18.0.0
                chat = {
                    adapter = "copilot",
                    keymaps = {
                        completion = {
                            modes = { i = "<C-n>" },
                            opts = { desc = "Trigger completion" },
                        },
                    },
                    opts = {
                        completion_provider = 'default', -- Use mini.completion provider
                    },
                },
                inline = {
                    adapter = "copilot",
                },
            },
            display = {
                action_palette = {
                    width = 95,
                    height = 10,
                    prompt = "Prompt ",      -- Prompt used for interactive LLM calls
                    provider = "mini_pick",  -- default|telescope|mini_pick
                    opts = {
                        show_presets = true, -- Renamed from show_default_actions in v18.0.0
                    },
                },
            },
        })
    end,
    -- stylua: ignore start
    keys = {
        { "<leader>aa", "<cmd>CodeCompanionActions<cr>", desc = "CodeCompanion [A]ctions",          mode = { "n", "v" }, noremap = true, silent = false },
        { "<leader>ac", "<cmd>CodeCompanionChat<cr>",    desc = "CodeCompanion [C]hat",             mode = { "n", "v" }, noremap = true, silent = false },
        { "<leader>ai", "<cmd>CodeCompanion<cr>",        desc = "CodeCompanion [I]nline Assistant", mode = { "n", "v" }, noremap = true, silent = false },
    },
    -- stylua: ignore end
})
