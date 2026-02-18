--  This function gets run when an LSP attaches to a particular buffer.
--    That is to say, every time a new file is opened that is associated with
--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
--    function will be executed to configure the current buffer
vim.api.nvim_create_autocmd("lspattach", {
    group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
    callback = function(event)
        local window_ui_opts = Utils.ui.window_opts()
        local client = vim.lsp.get_client_by_id(event.data.client_id)

        -- 1. Define the map helper function
        local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, noremap = true, silent = true, desc = desc })
        end

        -- 2. Set omnifunc
        vim.api.nvim_buf_set_option(event.buf, "omnifunc", "v:lua.vim.lsp.omnifunc")

        -- stylua: ignore start
        -- 3. Implement keymappings
        map("n", "gd", function() MiniExtra.pickers.lsp({ scope = "definition" }) end, "[G]oto [D]efinition")
        map("n", "gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        map("n", "gr", function() MiniExtra.pickers.lsp({ scope = "references" }) end, "[G]oto [R]eferences")
        map("n", "gi", function() MiniExtra.pickers.lsp({ scope = "implementation" }) end, "[G]oto [I]mplementation")
        map("n", "<leader>lD", function() MiniExtra.pickers.lsp({ scope = "type_definition" }) end,
            "[L]SP Type [D]efinition")
        map("n", "<leader>ls", function() MiniExtra.pickers.lsp({ scope = "document_symbol" }) end,
            "[L]SP Document [S]ymbols")
        map("n", "<leader>lW", function() MiniExtra.pickers.lsp({ scope = "workspace_symbol" }) end,
            "[L]SP [W]orkspace [S]ymbols")

        map("n", "K", function() vim.lsp.buf.hover(window_ui_opts) end, "LSP: Hover Documentation")
        map("n", "<leader>lk", function() vim.lsp.buf.signature_help(window_ui_opts) end, "[L]SP Signature Help")

        map("n", "<leader>lr", vim.lsp.buf.rename, "[L]SP [R]ename")
        map({ "n", "x" }, "<leader>la", vim.lsp.buf.code_action, "[L]SP [C]ode [A]ction")

        -- Workspace folder management keymaps
        map("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder, "LSP: [W]orkspace [A]dd Folder")
        map("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, "LSP: [W]orkspace [R]emove Folder")
        map("n", "<leader>lwl", function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
            "LSP: [W]orkspace [L]ist Folders")

        if client and client.server_capabilities and client.server_capabilities.documentFormattingProvider then
            map("n", "<leader>lf",
                function() require("conform").format({ bufnr = event.buf, lsp_format = "fallback" }) end,
                "[L]SP [F]ormat with [C]onform")
        end
        map("n", "<leader>lF", function() vim.lsp.buf.format({ async = true, bufnr = event.buf }) end,
            "[L]SP direct [F]ormat")

        map("n", "<leader>le", vim.diagnostic.open_float, "[L]SP [E]rror (Line Diagnostics)")
        map("n", "[d", vim.diagnostic.goto_prev, "Diagnostics: Go to Previous")
        map("n", "]d", vim.diagnostic.goto_next, "Diagnostics: Go to Next")
        map("n", "<leader>ld", function() require("mini.extra").pickers.diagnostic({ buffer = event.buf }) end,
            "[L]SP [D]iagnostics Picker")
        -- stylua: ignore end

        -- 4. Autocommands for document highlighting
        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup_name = "NeovimLspHighlightBuffer_" .. event.buf
            local highlight_augroup = vim.api.nvim_create_augroup(highlight_augroup_name, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.document_highlight,
                desc = "LSP: Document Highlight",
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, { -- Added InsertEnter as per typical usage
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.clear_references,
                desc = "LSP: Clear References",
            })
        end

        -- 5. Keymap for toggling inlay hints
        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map("n", "<leader>uh", function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }), { bufnr = event.buf })
            end, "LSP: Toggle Inlay Hints")
        end

        -- 6. Informative print statement
        if client then
            local filetype = vim.bo[event.buf].filetype
            print("LSP client '" .. client.name .. "' attached to buffer " .. event.buf .. " (" .. filetype .. ")")
        else
            print("LSP client attached to buffer " .. event.buf .. ", but client object or name not available.")
        end
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("nvim-metals", { clear = true }),
    pattern = { "scala", "sbt", "java" },
    callback = function()
        require("metals").initialize_or_attach(require("metals").bare_config())
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("codecompanion-chat", { clear = true }),
    pattern = { "codecompanion" },
    callback = function()
        vim.keymap.set("n", "q", "<cmd>:bd<cr>", { silent = true })
    end,
})

-- Autocommands for Octo buffers
local octo_clues_augroup = vim.api.nvim_create_augroup("octo_clues", { clear = true })

-- Dynamic local leader (default to comma if not set)
local loc = vim.g.maplocalleader or ","

-- Mappings based on Octo default values
local octo_clues = {
    -- General
    { mode = "n", keys = loc .. "a", desc = " Assignee" },
    { mode = "n", keys = loc .. "c", desc = " Comment/Create" },
    { mode = "n", keys = loc .. "l", desc = " Label" },
    { mode = "n", keys = loc .. "r", desc = " React" },
    -- Issue/PR
    { mode = "n", keys = loc .. "i", desc = " Issue Action" },
    { mode = "n", keys = loc .. "p", desc = " PR Action" },
    -- Review
    { mode = "n", keys = loc .. "v", desc = " Review" },
    { mode = "n", keys = loc .. "va", desc = " Add Review Comment" },
    { mode = "n", keys = loc .. "vd", desc = " Delete Review Comment" },
    -- Threads
    { mode = "n", keys = loc .. "t", desc = " Thread" },
    { mode = "n", keys = loc .. "tr", desc = " Resolve Thread" },
    { mode = "n", keys = loc .. "tu", desc = " Unresolve Thread" },
    -- Navigation
    { mode = "n", keys = loc .. "g", desc = " Goto" },
    { mode = "n", keys = loc .. "gi", desc = " Goto Issue" },
    { mode = "n", keys = loc .. "gp", desc = " Goto PR" },
    { mode = "n", keys = loc .. "gf", desc = " Goto File" },
}

vim.api.nvim_create_autocmd("FileType", {
    pattern = "octo",
    group = octo_clues_augroup,
    callback = function()
        -- Add clues for octo buffer
        for _, clue in ipairs(octo_clues) do
            table.insert(MiniClue.config.clues, clue)
        end

        -- Auto remove clues when octo buffer is closed
        vim.api.nvim_create_autocmd("BufWinLeave", {
            buffer = 0,
            group = octo_clues_augroup,
            callback = function()
                for i = #MiniClue.config.clues, 1, -1 do
                    local clue = MiniClue.config.clues[i]
                    for _, octo_clue in ipairs(octo_clues) do
                        if clue.keys == octo_clue.keys and clue.desc == octo_clue.desc then
                            table.remove(MiniClue.config.clues, i)
                            break
                        end
                    end
                end
            end,
        })
    end,
})

-- Reapply custom highlights when colorscheme changes (simplified approach)
vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("custom-highlights", { clear = true }),
    callback = function()
        -- Always reapply custom highlights after any colorscheme change
        require("config.colors").apply_highlights()
    end,
})
