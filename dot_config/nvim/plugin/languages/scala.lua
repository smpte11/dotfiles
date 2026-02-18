-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ Scala Language Configuration                                                │
-- │                                                                             │
-- │ Scala development with nvim-metals LSP, DAP debugging, and custom          │
-- │ command picker for Mini.pick integration.                                  │
-- │                                                                             │
-- │ Uses global: spec (from 00-bootstrap.lua)                                  │
-- └─────────────────────────────────────────────────────────────────────────────┘

spec({
    source = "scalameta/nvim-metals",
    config = function()
        local metals_config = require("metals").bare_config()

        -- Metals settings
        metals_config.settings = {
            showImplicitArguments = true,
            excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
        }

        metals_config.init_options.statusBarProvider = "off"

        -- Set capabilities for completion
        metals_config.capabilities = vim.lsp.protocol.make_client_capabilities()
        -- For blink.cmp, uncomment: metals_config.capabilities = require("blink.cmp").get_lsp_capabilities()

        -- Configure on_attach to setup DAP integration
        metals_config.on_attach = function(client, bufnr)
            -- Set up nvim-dap integration with metals
            -- This enables Scala debugging through nvim-metals
            require("metals").setup_dap()

            -- Set buffer-local keymap for metals commands picker
            if _G.MiniPick and MiniPick.registry.metals then
                vim.keymap.set("n", "<leader>lm", function()
                    MiniPick.registry.metals()
                end, {
                    buffer = true,
                    desc = "[L]sp [M]etals Commands",
                    silent = true
                })
            end

            -- Additional Scala-specific debug keymaps
            vim.keymap.set("n", "<leader>dt", function()
                require("metals").run_test()
            end, { buffer = true, desc = "[D]ebug Run [T]est" })

            vim.keymap.set("n", "<leader>dT", function()
                require("metals").test_target()
            end, { buffer = true, desc = "[D]ebug [T]est Target" })
        end

        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("nvim-metals", { clear = true }),
            pattern = { "scala", "sbt", "java", "sc" },
            callback = function()
                require("metals").initialize_or_attach(metals_config)
            end,
        })

        -- Metals command picker for mini.pick
        -- Only works in Scala-related files (.scala, .sbt, .java, .sc)
        -- Dynamically loads available commands from metals.commands module
        if _G.MiniPick then
            MiniPick.registry.metals = function(local_opts)
                local_opts = local_opts or {}

                -- Check if we're in a Scala-related file
                local filetype = vim.bo.filetype
                local scala_filetypes = { "scala", "sbt", "java", "sc" }
                local is_scala_file = vim.tbl_contains(scala_filetypes, filetype)

                if not is_scala_file then
                    vim.notify("Metals commands are only available in Scala files (.scala, .sbt, .java, .sc)",
                        vim.log.levels.WARN)
                    return
                end

                -- Check if metals LSP client is active
                local function is_metals_active()
                    local clients = vim.lsp.get_clients({ bufnr = 0 })
                    for _, client in ipairs(clients) do
                        if client.name == "metals" then
                            return true
                        end
                    end
                    return false
                end

                if not is_metals_active() then
                    vim.notify("Metals LSP client is not active in current buffer", vim.log.levels.WARN)
                    return
                end

                -- Static fallback commands to avoid dynamic loading issues
                local metals_commands = {
                    { name = "Build Import",        command = "metals.build-import",        desc = "Import build" },
                    { name = "Build Connect",       command = "metals.build-connect",       desc = "Connect to build server" },
                    { name = "Build Disconnect",    command = "metals.build-disconnect",    desc = "Disconnect from build server" },
                    { name = "Build Restart",       command = "metals.build-restart",       desc = "Restart build server" },
                    { name = "Compile Cascade",     command = "metals.compile-cascade",     desc = "Compile current file and dependencies" },
                    { name = "Generate BSP Config", command = "metals.generate-bsp-config", desc = "Generate BSP config files" },
                    { name = "Doctor Run",          command = "metals.doctor-run",          desc = "Run metals doctor" },
                    { name = "Sources Scan",        command = "metals.sources-scan",        desc = "Scan workspace sources" },
                    { name = "New Scala File",      command = "metals.new-scala-file",      desc = "Create new Scala file" },
                    { name = "New Java File",       command = "metals.new-java-file",       desc = "Create new Java file" },
                    { name = "Restart Server",      command = "metals.restart-server",      desc = "Restart metals server" },
                }

                local source = {
                    name = "Metals Commands",
                    items = metals_commands,
                    show = function(buf_id, items, query)
                        local lines = {}
                        for _, item in ipairs(items) do
                            -- Format: "Command Name - Description"
                            table.insert(lines, string.format("%-25s - %s", item.name, item.desc))
                        end
                        vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
                    end,
                    choose = function(item)
                        if not item then return end
                        vim.notify("Executing: " .. item.name, vim.log.levels.INFO)
                        -- Execute the LSP command
                        local success, err = pcall(vim.lsp.buf.execute_command, { command = item.command })
                        if not success then
                            vim.notify("Error executing " .. item.name .. ": " .. tostring(err), vim.log.levels.ERROR)
                        end
                    end,
                }

                -- Use proper MiniPick.start with explicit source
                MiniPick.start({ source = source }, local_opts)
            end
        end
    end,
})
