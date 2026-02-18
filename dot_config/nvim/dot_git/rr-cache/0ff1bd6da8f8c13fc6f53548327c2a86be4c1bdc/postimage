-- LSP configuration with Mason
spec({
    source = "neovim/nvim-lspconfig",
    immediate = true,
    depends = {
        "mason-org/mason.nvim",
        "mason-org/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
        require("mason").setup({
            ui = {
                border = Utils.ui.border,
            },
        })
    end,
})

-- Lua development configuration
spec({
    source = "folke/lazydev.nvim",
    immediate = true,
    config = function()
        require("lazydev").setup({
            library = {
                -- Load luvit types when the `vim.uv` word is found
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        })
    end,
})

-- Mini.completion - LSP completion engine
spec({
    source = "nvim-mini/mini.completion",
    config = function()
        require("mini.completion").setup({
            delay = {
                completion = 100,
                info = 100,
                signature = 50,
            },
            lsp_completion = {
                source_func = "completefunc",
                auto_setup = true,
                -- Use mini.snippets for snippet insertion (already configured)
                snippet_insert = nil, -- Uses default which prefers mini.snippets
            },
            -- Fallback to built-in keyword completion when LSP unavailable
            fallback_action = "<C-n>",
            window = {
                info = { height = 25, width = 80, border = Utils.ui.border },
                signature = { height = 25, width = 80, border = Utils.ui.border },
            },
            mappings = {
                force_twostep = "<C-Space>",
                force_fallback = "<A-Space>",
                scroll_down = "<C-f>",
                scroll_up = "<C-b>",
            },
        })

        -- Integration: Hide Copilot suggestions when completion menu is visible
        local completion_group = vim.api.nvim_create_augroup("MiniCompletionIntegration", { clear = true })

        -- Hide Copilot when popup menu is shown
        vim.api.nvim_create_autocmd("CompleteDone", {
            group = completion_group,
            callback = function()
                vim.b.copilot_suggestion_hidden = false
            end,
        })
    end,
})

-- COMMENTED OUT: Blink.cmp completion engine (replaced by mini.completion)
-- Uncomment to revert to blink.cmp
--[[
spec({
    source = "Saghen/blink.cmp",
    immediate = true,
    depends = {
        "giuxtaposition/blink-cmp-copilot",
        "Kaiser-Yang/blink-cmp-git",
    },
    checkout = "v1.7.0",
    hooks = {
        post_install = function(params)
            vim.notify("Building blink.cmp", vim.log.levels.INFO)
            local obj = vim.system({ "cargo", "build", "--release" }, { cwd = params.path }):wait()
            if obj.code == 0 then
                vim.notify("Building blink.cmp done", vim.log.levels.INFO)
            else
                vim.notify("Building blink.cmp failed", vim.log.levels.ERROR)
            end
        end,
        post_checkout = function(params)
            vim.notify("Building blink.cmp", vim.log.levels.INFO)
            local obj = vim.system({ "cargo", "build", "--release" }, { cwd = params.path }):wait()
            if obj.code == 0 then
                vim.notify("Building blink.cmp done", vim.log.levels.INFO)
            else
                vim.notify("Building blink.cmp failed", vim.log.levels.ERROR)
            end
        end,
    },
    config = function()
        require("blink.cmp").setup({
            snippets = { preset = "mini_snippets" },
            cmdline = {
                enabled = false,
            },
            sources = {
                default = { "lsp", "lazydev", "path", "snippets", "buffer", "copilot" },
                providers = {
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = 100, -- show at a higher priority than lsp
                    },
                    markdown = {
                        name = "RenderMarkdown",
                        module = "render-markdown.integ.blink",
                        fallbacks = { "lsp" },
                    },
                    copilot = {
                        name = "copilot",
                        module = "blink-cmp-copilot",
                        score_offset = 100,
                        async = true,
                        transform_items = function(_, items)
                            local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
                            local kind_idx = #CompletionItemKind + 1
                            CompletionItemKind[kind_idx] = "Copilot"
                            for _, item in ipairs(items) do
                                item.kind = kind_idx
                            end
                            return items
                        end,
                    },
                    git = {
                        module = "blink-cmp-git",
                        name = "Git",
                        enabled = function()
                            -- NOTE: Removed "octo" since we're using snacks.nvim gh
                            return vim.tbl_contains({ "gitcommit", "markdown" }, vim.bo.filetype)
                        end,
                    },
                },
                per_filetype = {
                    codecompanion = { "codecompanion" },
                },
            },
            keymap = {
                preset = "none",
                ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
                ["<C-b>"] = { "scroll_documentation_up", "fallback" },
                ["<C-f>"] = { "scroll_documentation_down", "fallback" },
                ["<C-n>"] = { "select_next", "fallback" },
                ["<C-p>"] = { "select_prev", "fallback" },
                ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
                ["<C-e>"] = { "hide", "fallback" },
                ["<C-c>"] = { "hide", "fallback" },
            },
            signature = { enabled = true, window = { border = Utils.ui.border } },
            completion = {
                accept = {
                    auto_brackets = {
                        enabled = true,
                        default_brackets = { "(", ")" },
                        override_brackets_for_filetypes = {},
                        blocked_filetypes = { "erlang" },
                        -- Disable semantic token resolution for Java/Scala to prevent unwanted parentheses on modules
                        semantic_token_resolution = {
                            enabled = true,
                            blocked_filetypes = { "java", "scala" },
                        },
                    },
                },
                menu = {
                    border = Utils.ui.menu_border,
                    auto_show = true,
                    auto_show_delay_ms = function(ctx, items)
                        return vim.bo.filetype == "markdown" and 1000 or 0
                    end,
                    draw = {
                        columns = {
                            { "kind_icon", "label", "label_description", gap = 1 },
                            { "kind" },
                        },
                        components = {
                            kind_icon = {
                                text = function(ctx)
                                    local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)
                                    return kind_icon
                                end,
                                -- (optional) use highlights from mini.icons
                                highlight = function(ctx)
                                    local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                                    return hl
                                end,
                            },
                            kind = {
                                highlight = function(ctx)
                                    local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                                    return hl
                                end,
                            },
                        },
                    },
                },
                documentation = {
                    window = { border = Utils.ui.border },
                    auto_show = true,
                    auto_show_delay_ms = 50,
                },
                ghost_text = { enabled = true },
            },
        })

        -- Highlights are managed in lua/colors.lua
    end,
})
--]]

-- Code formatting with conform.nvim
spec({
    source = "stevearc/conform.nvim",
    config = function()
        require("conform").setup({
            notify_on_error = false,
            format_on_save = function(bufnr)
                if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return
                end
                -- Disable "format_on_save lsp_fallback" for languages that don't
                -- have a well standardized coding style. You can add additional
                -- languages here or re-enable it for the disabled ones.
                local disable_filetypes = { c = true, cpp = true }
                local lsp_format_opt
                if disable_filetypes[vim.bo[bufnr].filetype] then
                    lsp_format_opt = "never"
                else
                    lsp_format_opt = "fallback"
                end
                return {
                    timeout_ms = 500,
                    lsp_format = lsp_format_opt,
                }
            end,
            formatters_by_ft = {
                lua = { "stylua" },
                elixir = { "mix_format" },
                exs = { "mix_format" },
                heex = { "mix_format" },
                yaml = { "prettierd", "prettier" },
                markdown = { "prettier" },
                go = { "goimports", "gofumpt" },
                -- Conform can also run multiple formatters sequentially
                -- python = { "isort", "black" },
                --
                -- You can use 'stop_after_first' to run the first available formatter from the list
                -- javascript = { "prettierd", "prettier", stop_after_first = true },
            },
        })
    end,
})

-- Brief aside: **What is LSP?**
--
-- LSP is an initialism you've probably heard, but might not understand what it is.
--
-- LSP stands for Language Server Protocol. It's a protocol that helps editors
-- and language tooling communicate in a standardized fashion.
--
-- In general, you have a "server" which is some tool built to understand a particular
-- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
-- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
-- processes that communicate with some "client" - in this case, Neovim!
--
-- LSP provides Neovim with features like:
--  - Go to definition
--  - Find references
--  - Autocompletion
--  - Symbol Search
--  - and more!
--
-- Thus, Language Servers are external tools that must be installed separately from
-- Neovim. This is where `mason` and related plugins come into play.
--
-- If you're wondering about lsp vs treesitter, you can check out the wonderfully
-- and elegantly composed help section, `:help lsp-vs-treesitter`

-- change diagnostic symbols in the sign column (gutter)
if vim.g.have_nerd_font then
    local signs = { error = "", warn = "", hint = "", info = "" }
    for type, icon in pairs(signs) do
        local hl = "diagnosticsign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end
end

-- lsp servers and clients are able to communicate to each other what features they support.
--  by default, neovim doesn't support everything that is in the lsp specification.
--  when you add nvim-cmp, luasnip, etc. neovim now has *more* capabilities.
--  so, we create new capabilities and then broadcast that to the servers.
local capabilities = vim.lsp.protocol.make_client_capabilities()
-- mini.completion uses default capabilities, no need to extend
-- For blink.cmp, uncomment: capabilities = vim.tbl_deep_extend("force", capabilities, require("blink.cmp").get_lsp_capabilities())

-- enable the following language servers
--  feel free to add/remove any lsps that you want here. they will automatically be installed.
--
--  add any additional override configuration in the following tables. available keys are:
--  - cmd (table): override the default command used to start the server
--  - filetypes (table): override the default list of associated filetypes for the server
--  - capabilities (table): override fields in capabilities. can be used to disable certain lsp features.
--  - settings (table): override the default settings passed when initializing the server.
--        for example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
local servers = {
    -- clangd = {},
    -- rust_analyzer = {},
    -- ... etc. see `:help lspconfig-all` for a list of all the pre-configured lsps
    --
    -- some languages (like typescript) have entire language plugins that can be useful:
    --    https://github.com/pmizio/typescript-tools.nvim
    --
    -- but for many setups, the lsp (`ts_ls`) will work just fine
    terraformls = {},
    ts_ls = {},
    basedpyright = {
        settings = {
            basedpyright = {
                analysis = {
                    autosearchpaths = true,
                    diagnosticmode = "openfilesonly",
                    uselibrarycodefortypes = true,
                },
            },
        },
    },
    ruff = {},
    nushell = {},
    dockerls = {},
    -- Erlang Language Platform (ELP) - WhatsApp's advanced Erlang/Elixir LSP
    -- Provides superior semantic analysis, go-to-definition, find references, call hierarchy
    -- Designed to be scalable and fully incremental, inspired by rust-analyzer
    elp = {
        cmd = { "elp", "server" },
        filetypes = { "erlang", "elixir" },
        root_dir = function(fname)
            -- Look for rebar.config, mix.exs, or .git directory
            return require("lspconfig.util").find_git_ancestor(fname)
                or require("lspconfig.util").root_pattern("rebar.config", "mix.exs", "OTP_VERSION")(fname)
        end,
        settings = {
            elp = {
                -- Enable incremental compilation for better performance
                incremental = true,
                -- Enable all diagnostics
                diagnostics = {
                    enabled = true,
                    -- Show warnings and errors
                    disabled = {},
                },
                -- Enable code lens for additional information
                codeLens = {
                    enabled = true,
                },
            },
        },
    },
    bashls = {},
    html = {},
    jsonls = {},
    yamlls = {},
    marksman = {},
    lua_ls = {
        -- cmd = { ... },
        -- filetypes = { ... },
        -- capabilities = {},
        settings = {
            lua = {
                completion = {
                    callsnippet = "replace",
                },
                -- you can toggle below to ignore lua_ls's noisy `missing-fields` warnings
                diagnostics = { disable = { "missing-fields" } },
            },
        },
    },
}

-- ensure the servers and tools above are installed
--
-- to check the current status of installed tools and/or manually install
-- other tools, you can run
--    :mason
--
-- you can press `g?` for help in this menu.
--
-- `mason` had to be setup earlier: to configure its options see the
-- `dependencies` table for `nvim-lspconfig` above.
--
-- you can add other tools here that you want mason to install
-- for you, so that they are available from within neovim.
local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
    "stylua", -- used to format lua code
    "shfmt",
    "shellcheck",
    "taplo",
    -- ELP (Erlang Language Platform) for Erlang/Elixir
    -- Note: May need manual installation if not available in Mason registry
    -- Installation: cargo install --git https://github.com/whatsapp/erlang-language-platform --bin elp
    -- Go tools are handled by ray-x/go.nvim
    -- "tflint",
})

local i = 1
while i <= #ensure_installed do
    if ensure_installed[i] == "nushell" then
        table.remove(ensure_installed, i)
    else
        i = i + 1
    end
end

require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

require("mason-lspconfig").setup({
    handlers = {
        function(server_name)
            local server = servers[server_name] or {}
            -- this handles overriding only values explicitly passed
            -- by the server configuration above. useful when disabling
            -- certain features of an lsp (for example, turning off formatting for ts_ls)
            server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})

            require("lspconfig")[server_name].setup(server)
        end,
    },
})
