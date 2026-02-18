-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ Debug Adapter Protocol (DAP) Configuration                                  │
-- │                                                                             │
-- │ Comprehensive debugging setup for multiple languages.                      │
-- │ Supports: Python, JavaScript/TypeScript, Lua, Bash, Elixir, Erlang, Scala  │
-- │ Note: Go debugging is handled by ray-x/go.nvim                             │
-- └─────────────────────────────────────────────────────────────────────────────┘
-- Comprehensive Debug Adapter Protocol (DAP) Setup
-- =====================================================
-- Supports: Python, JavaScript/TypeScript, Lua, Bash, Elixir, Erlang + Scala (via nvim-metals)
-- Features:
-- - Auto-installation of debug adapters via Mason
-- - Comprehensive debug configurations for each language
-- - Dynamic keymaps during debug sessions
-- - Virtual text showing variable values
-- - Enhanced UI with nvim-dap-ui
-- - Breakpoint management with custom icons
-- - Scala debugging via official nvim-metals DAP integration
-- - TypeScript/JavaScript debugging complements typescript-tools.nvim
-- - Elixir debugging via elixir-ls (complements ELP LSP server)
-- - Erlang: Full DAP support via Erlang LS els_dap (https://erlang-ls.github.io/articles/tutorial-debugger/)
--
-- Note: Go is handled by ray-x/go.nvim (includes LSP + DAP + testing)
-- TypeScript LSP features are handled by typescript-tools.nvim
-- Elixir/Erlang LSP features are handled by ELP (Erlang Language Platform)
-- =====================================================
spec({
    source = "mfussenegger/nvim-dap",
    depends = { -- Creates a beautiful debugger UI
    "rcarriga/nvim-dap-ui", -- Required dependency for nvim-dap-ui
    "nvim-neotest/nvim-nio", -- Installs the debug adapters for you
    "mason-org/mason.nvim", "jay-babu/mason-nvim-dap.nvim"},
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        require("mason-nvim-dap").setup({
            -- Makes a best effort to setup the various debuggers with
            -- reasonable debug configurations
            automatic_installation = true,

            -- You can provide additional configuration to the handlers,
            -- see mason-nvim-dap README for more information
            handlers = {},

            -- Core language debuggers
            -- Note: Go uses nvim-dap-go, Scala uses nvim-metals built-in DAP
            -- TypeScript uses typescript-tools.nvim for LSP but needs separate DAP setup
            -- Elixir uses ELP for LSP and elixir-ls for DAP
            ensure_installed = { -- Python
            "debugpy", -- JavaScript/TypeScript/Node.js (complements typescript-tools.nvim)
            "js-debug-adapter", -- Lua
            "local-lua-debugger-vscode", -- Bash
            "bash-debug-adapter", -- Elixir (DAP support - LSP handled by ELP)
            "elixir-ls", -- Erlang DAP support via Erlang LS (els_dap)
            "erlang-debugger"}
        })

        -- =====================================================
        -- Manual DAP Adapter and Configuration Setup
        -- =====================================================
        -- Some adapters may need manual configuration for optimal functionality
        -- These complement the mason-nvim-dap automatic setup

        -- Python Configuration (debugpy)
        -- Works with basedpyright and ruff LSPs
        dap.adapters.python = function(cb, config)
            if config.request == 'attach' then
                ---@diagnostic disable-next-line: undefined-field
                local port = (config.connect or config).port
                ---@diagnostic disable-next-line: undefined-field
                local host = (config.connect or config).host or '127.0.0.1'
                cb({
                    type = 'server',
                    port = assert(port, '`connect.port` is required for a python `attach` configuration'),
                    host = host,
                    options = {
                        source_filetype = 'python'
                    }
                })
            else
                cb({
                    type = 'executable',
                    command = 'python3',
                    args = {'-m', 'debugpy.adapter'},
                    options = {
                        source_filetype = 'python'
                    }
                })
            end
        end

        dap.configurations.python = {{
            type = 'python',
            request = 'launch',
            name = 'Launch file',
            program = '${file}', -- Current file
            console = 'integratedTerminal',
            cwd = '${workspaceFolder}'
        }, {
            type = 'python',
            request = 'launch',
            name = 'Launch file with arguments',
            program = '${file}',
            args = function()
                local args_string = vim.fn.input('Arguments: ')
                return vim.split(args_string, " +")
            end,
            console = 'integratedTerminal',
            cwd = '${workspaceFolder}'
        }, {
            type = 'python',
            request = 'launch',
            name = 'Launch module',
            module = function()
                return vim.fn.input('Module name: ')
            end,
            console = 'integratedTerminal',
            cwd = '${workspaceFolder}'
        }, {
            type = 'python',
            request = 'attach',
            name = 'Attach remote',
            connect = function()
                local host = vim.fn.input('Host [127.0.0.1]: ')
                host = host ~= '' and host or '127.0.0.1'
                local port = tonumber(vim.fn.input('Port [5678]: ')) or 5678
                return {
                    host = host,
                    port = port
                }
            end
        }}

        -- JavaScript/TypeScript/Node.js Configuration
        -- Complements typescript-tools.nvim (which handles LSP) with debugging capabilities
        dap.adapters['pwa-node'] = {
            type = 'server',
            host = 'localhost',
            port = '${port}',
            executable = {
                command = 'js-debug-adapter',
                args = {'${port}'}
            }
        }

        dap.configurations.javascript = {{
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch file',
            program = '${file}',
            cwd = '${workspaceFolder}'
        }, {
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch with npm script',
            runtimeExecutable = 'npm',
            runtimeArgs = function()
                local script = vim.fn.input('npm script: ')
                return {'run', script}
            end,
            rootPath = '${workspaceFolder}',
            cwd = '${workspaceFolder}',
            console = 'integratedTerminal',
            internalConsoleOptions = 'neverOpen'
        }, {
            type = 'pwa-node',
            request = 'attach',
            name = 'Attach to process',
            processId = require('dap.utils').pick_process,
            cwd = '${workspaceFolder}'
        }}

        dap.configurations.typescript = {{
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch file',
            program = '${file}',
            cwd = '${workspaceFolder}',
            sourceMaps = true,
            protocol = 'inspector',
            console = 'integratedTerminal'
        }, {
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch with ts-node',
            runtimeExecutable = 'npx',
            runtimeArgs = {'ts-node', '${file}'},
            cwd = '${workspaceFolder}',
            sourceMaps = true,
            protocol = 'inspector',
            console = 'integratedTerminal'
        }, {
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch with tsx',
            runtimeExecutable = 'npx',
            runtimeArgs = {'tsx', '${file}'},
            cwd = '${workspaceFolder}',
            sourceMaps = true,
            protocol = 'inspector',
            console = 'integratedTerminal'
        }, {
            type = 'pwa-node',
            request = 'attach',
            name = 'Attach to process',
            processId = require('dap.utils').pick_process,
            cwd = '${workspaceFolder}'
        }}

        -- Lua Configuration (local-lua-debugger-vscode)
        -- Works with lua_ls LSP
        dap.adapters['local-lua'] = {
            type = 'executable',
            command = 'local-lua-debugger-vscode',
            enrich_config = function(config, on_config)
                if not config['extensionPath'] then
                    local c = vim.deepcopy(config)
                    -- 💀 If you have trouble with the debugger adapter, try specifying the full path
                    c.extensionPath = vim.fn.stdpath('data') .. '/mason/packages/local-lua-debugger-vscode/'
                    on_config(c)
                else
                    on_config(config)
                end
            end
        }

        dap.configurations.lua = {{
            type = 'local-lua',
            request = 'launch',
            name = 'Debug current file (local-lua-dbg, lua)',
            program = {
                lua = 'lua',
                file = '${file}'
            },
            cwd = '${workspaceFolder}',
            args = {}
        }, {
            type = 'local-lua',
            request = 'launch',
            name = 'Debug current file (local-lua-dbg, luajit)',
            program = {
                lua = 'luajit',
                file = '${file}'
            },
            cwd = '${workspaceFolder}',
            args = {}
        }, {
            type = 'local-lua',
            request = 'launch',
            name = 'Debug with arguments',
            program = {
                lua = 'lua',
                file = '${file}'
            },
            args = function()
                local args_string = vim.fn.input('Arguments: ')
                return vim.split(args_string, " +")
            end,
            cwd = '${workspaceFolder}'
        }}

        -- Elixir Configuration (elixir-ls debug adapter)
        -- Complements ELP LSP server with debugging capabilities
        -- Uses elixir-ls debug_adapter.sh for DAP support
        dap.adapters.mix_task = {
            type = 'executable',
            command = vim.fn.stdpath("data") .. '/mason/packages/elixir-ls/debug_adapter.sh',
            args = {}
        }

        -- Erlang Configuration (using Erlang LS DAP support)
        -- Uses els_dap from Erlang LS for full Debug Adapter Protocol support
        -- See: https://erlang-ls.github.io/articles/tutorial-debugger/
        dap.adapters.erlang = {
            type = 'executable',
            command = vim.fn.stdpath("data") .. '/mason/packages/erlang-debugger/els_dap',
            args = {}
        }

        dap.configurations.elixir = {{
            type = "mix_task",
            name = "mix test",
            task = 'test',
            taskArgs = {"--trace"},
            request = "launch",
            startApps = true, -- for Phoenix projects
            projectDir = "${workspaceFolder}",
            requireFiles = {"test/**/test_helper.exs", "test/**/*_test.exs"}
        }, {
            type = "mix_task",
            name = "mix test (current file)",
            task = 'test',
            taskArgs = {"${file}", "--trace"},
            request = "launch",
            startApps = true,
            projectDir = "${workspaceFolder}",
            requireFiles = {"test/**/test_helper.exs"}
        }, {
            type = "mix_task",
            name = "mix run",
            task = 'run',
            taskArgs = {"--no-halt"},
            request = "launch",
            startApps = true,
            projectDir = "${workspaceFolder}"
        }, {
            type = "mix_task",
            name = "mix phx.server",
            task = 'phx.server',
            request = "launch",
            startApps = true,
            projectDir = "${workspaceFolder}"
        }, {
            type = "mix_task",
            name = "mix run (with args)",
            task = 'run',
            taskArgs = function()
                local args_string = vim.fn.input('Arguments: ')
                return vim.split(args_string, " +")
            end,
            request = "launch",
            startApps = true,
            projectDir = "${workspaceFolder}"
        }}

        -- Erlang debug configurations (using Erlang LS DAP)
        -- Full Debug Adapter Protocol support via els_dap
        -- Supports breakpoints, variable inspection, conditional breakpoints, logpoints, etc.
        -- See: https://erlang-ls.github.io/articles/tutorial-debugger/
        dap.configurations.erlang = {{
            type = "erlang",
            name = "Launch Erlang Project",
            request = "launch",
            cwd = "${workspaceFolder}",
            timeout = 300
        }, {
            type = "erlang",
            name = "Attach to Existing Node",
            request = "attach",
            projectnode = function()
                return vim.fn.input('Node name (without @hostname): ')
            end,
            cookie = function()
                return vim.fn.input('Cookie (or press Enter for default): ')
            end,
            timeout = 300,
            cwd = "${workspaceFolder}"
        }, {
            type = "erlang",
            name = "Debug Rebar3 Project",
            request = "launch",
            projectnode = "debug_session",
            cookie = "debug_cookie",
            timeout = 300,
            cwd = "${workspaceFolder}",
            -- This will launch a node that can be attached to
            preLaunchTask = {
                type = "shell",
                command = "rebar3",
                args = {"shell", "--name", "debug_session@localhost", "--setcookie", "debug_cookie"}
            }
        }, {
            type = "erlang",
            name = "Debug EUnit Tests",
            request = "launch",
            projectnode = "eunit_debug",
            cookie = "eunit_cookie",
            timeout = 300,
            cwd = "${workspaceFolder}",
            -- Setup for debugging EUnit tests
            preLaunchTask = {
                type = "shell",
                command = "rebar3",
                args = {"shell", "--name", "eunit_debug@localhost", "--setcookie", "eunit_cookie"}
            }
        }}

        -- Bash Configuration (bash-debug-adapter)
        -- Works with bashls LSP
        dap.adapters.bashdb = {
            type = 'executable',
            command = 'bash-debug-adapter',
            name = 'bashdb'
        }

        dap.configurations.sh = {{
            type = 'bashdb',
            request = 'launch',
            name = 'Launch file',
            showDebugOutput = true,
            pathBashdb = vim.fn.stdpath('data') .. '/mason/packages/bash-debug-adapter/extension/bashdb_dir/bashdb',
            pathBashdbLib = vim.fn.stdpath('data') .. '/mason/packages/bash-debug-adapter/extension/bashdb_dir',
            trace = true,
            file = '${file}',
            program = '${file}',
            cwd = '${workspaceFolder}',
            pathCat = 'cat',
            pathBash = '/bin/bash',
            pathMkfifo = 'mkfifo',
            pathPkill = 'pkill',
            args = {},
            env = {},
            terminalKind = 'integrated'
        }}

        -- =====================================================
        -- DAP UI Configuration
        -- =====================================================
        dapui.setup({
            icons = {
                expanded = "▾",
                collapsed = "▸",
                current_frame = "*"
            },
            controls = {
                icons = {
                    pause = "⏸",
                    play = "▶",
                    step_into = "⏎",
                    step_over = "⏭",
                    step_out = "⏮",
                    step_back = "b",
                    run_last = "▶▶",
                    terminate = "⏹",
                    disconnect = "⏏"
                }
            }
        })

        -- Configure breakpoint icons and highlights
        vim.api.nvim_set_hl(0, 'DapBreakpoint', {
            fg = '#e51400'
        })
        vim.api.nvim_set_hl(0, 'DapBreakpointCondition', {
            fg = '#e51400'
        })
        vim.api.nvim_set_hl(0, 'DapBreakpointRejected', {
            fg = '#888888'
        })
        vim.api.nvim_set_hl(0, 'DapLogPoint', {
            fg = '#61afef'
        })
        vim.api.nvim_set_hl(0, 'DapStopped', {
            fg = '#ffcc00'
        })

        local breakpoint_icons = vim.g.have_nerd_font and {
            Breakpoint = '',
            BreakpointCondition = '',
            BreakpointRejected = '',
            LogPoint = '',
            Stopped = ''
        } or {
            Breakpoint = '●',
            BreakpointCondition = '⊜',
            BreakpointRejected = '⊘',
            LogPoint = '◆',
            Stopped = '⭔'
        }
        for type, icon in pairs(breakpoint_icons) do
            local tp = 'Dap' .. type
            local hl = (type == 'Stopped') and 'DapStopped' or 'Dap' .. type
            vim.fn.sign_define(tp, {
                text = icon,
                texthl = hl,
                numhl = hl
            })
        end

        -- =====================================================
        -- Static Breakpoint Keymaps (always available)
        -- =====================================================
        vim.keymap.set("n", "<leader>db", function()
            require("dap").toggle_breakpoint()
        end, {
            desc = "[D]ebug Toggle [B]reakpoint"
        })

        vim.keymap.set("n", "<leader>dB", function()
            require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: '))
        end, {
            desc = "[D]ebug Conditional [B]reakpoint"
        })

        vim.keymap.set("n", "<leader>dC", function()
            require("dap").clear_breakpoints()
        end, {
            desc = "[D]ebug [C]lear All Breakpoints"
        })

        vim.keymap.set("n", "<leader>dl", function()
            require("dap").set_breakpoint(nil, nil, vim.fn.input('Log point message: '))
        end, {
            desc = "[D]ebug [L]og Point"
        })

        -- =====================================================
        -- Dynamic Debug Keymap Management
        -- =====================================================
        local function setup_debug_keymaps()
            -- Core debugging flow
            vim.keymap.set("n", "<leader>dc", function()
                require("dap").continue()
            end, {
                desc = "[D]ebug [C]ontinue/Start"
            })

            vim.keymap.set("n", "<leader>di", function()
                require("dap").step_into()
            end, {
                desc = "[D]ebug Step [I]nto"
            })

            vim.keymap.set("n", "<leader>do", function()
                require("dap").step_over()
            end, {
                desc = "[D]ebug Step [O]ver"
            })

            vim.keymap.set("n", "<leader>dO", function()
                require("dap").step_out()
            end, {
                desc = "[D]ebug Step [O]ut"
            })

            vim.keymap.set("n", "<leader>du", function()
                require("dapui").toggle()
            end, {
                desc = "[D]ebug [U]I Toggle"
            })

            -- Session management
            vim.keymap.set("n", "<leader>dr", function()
                require("dap").restart()
            end, {
                desc = "[D]ebug [R]estart"
            })

            vim.keymap.set("n", "<leader>dt", function()
                require("dap").terminate()
            end, {
                desc = "[D]ebug [T]erminate"
            })

            vim.keymap.set("n", "<leader>dp", function()
                require("dap").pause()
            end, {
                desc = "[D]ebug [P]ause"
            })

            -- Advanced debugging
            vim.keymap.set("n", "<leader>dS", function()
                require("dap").run_to_cursor()
            end, {
                desc = "[D]ebug Run to Cursor [S]top"
            })

            vim.keymap.set("n", "<leader>dU", function()
                require("dap").up()
            end, {
                desc = "[D]ebug Stack [U]p"
            })

            vim.keymap.set("n", "<leader>dD", function()
                require("dap").down()
            end, {
                desc = "[D]ebug Stack [D]own"
            })

            -- Evaluation & inspection
            vim.keymap.set("n", "<leader>de", function()
                require("dapui").eval()
            end, {
                desc = "[D]ebug [E]valuate Expression"
            })

            vim.keymap.set("v", "<leader>de", function()
                require("dapui").eval()
            end, {
                desc = "[D]ebug [E]valuate Selection"
            })

            vim.keymap.set("n", "<leader>dh", function()
                require("dap.ui.widgets").hover()
            end, {
                desc = "[D]ebug [H]over Variables"
            })

            vim.keymap.set("n", "<leader>ds", function()
                local widgets = require("dap.ui.widgets")
                widgets.centered_float(widgets.scopes)
            end, {
                desc = "[D]ebug [S]copes"
            })

            vim.keymap.set("n", "<leader>df", function()
                local widgets = require("dap.ui.widgets")
                widgets.centered_float(widgets.frames)
            end, {
                desc = "[D]ebug [F]rames"
            })

            -- REPL
            vim.keymap.set("n", "<leader>dR", function()
                require("dap").repl.open()
            end, {
                desc = "[D]ebug [R]EPL Open"
            })

            vim.keymap.set("n", "<leader>dk", function()
                require("dap").repl.run_last()
            end, {
                desc = "[D]ebug REPL Run Last [K]ommand"
            })

            -- Update debug clue in mini.clue (change description during active session)
            for i, entry in ipairs(MiniClue.config.clues) do
                if entry.mode == "n" and entry.keys == "<leader>d" then
                    MiniClue.config.clues[i].desc = "󰃤 debug session"
                    break
                end
            end
        end

        local function teardown_debug_keymaps()
            -- Restore debug clue in mini.clue (back to default description)
            for i, entry in ipairs(MiniClue.config.clues) do
                if entry.mode == "n" and entry.keys == "<leader>d" and entry.desc == "󰃤 debug session" then
                    MiniClue.config.clues[i].desc = "󰃤 debug"
                    break
                end
            end

            -- Remove dynamic keymaps
            pcall(vim.keymap.del, "n", "<leader>dc")
            pcall(vim.keymap.del, "n", "<leader>di")
            pcall(vim.keymap.del, "n", "<leader>do")
            pcall(vim.keymap.del, "n", "<leader>dO")
            pcall(vim.keymap.del, "n", "<leader>du")
            pcall(vim.keymap.del, "n", "<leader>dr")
            pcall(vim.keymap.del, "n", "<leader>dt")
            pcall(vim.keymap.del, "n", "<leader>dp")
            pcall(vim.keymap.del, "n", "<leader>dS")
            pcall(vim.keymap.del, "n", "<leader>dU")
            pcall(vim.keymap.del, "n", "<leader>dD")
            pcall(vim.keymap.del, "n", "<leader>de")
            pcall(vim.keymap.del, "v", "<leader>de")
            pcall(vim.keymap.del, "n", "<leader>dh")
            pcall(vim.keymap.del, "n", "<leader>ds")
            pcall(vim.keymap.del, "n", "<leader>df")
            pcall(vim.keymap.del, "n", "<leader>dR")
            pcall(vim.keymap.del, "n", "<leader>dk")
        end

        -- =====================================================
        -- Event Listeners - Auto-open/close UI and manage keymaps
        -- =====================================================
        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
            setup_debug_keymaps()
        end

        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
            teardown_debug_keymaps()
        end

        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
            teardown_debug_keymaps()
        end
    end
})

-- DAP virtual text - shows variable values inline
spec({
    source = "theHamsta/nvim-dap-virtual-text",
    config = function()
        require("nvim-dap-virtual-text").setup({
            enabled = true,
            enabled_commands = true,
            highlight_changed_variables = true,
            highlight_new_as_changed = false,
            show_stop_reason = true,
            commented = false,
            only_first_definition = true,
            all_references = false,
            clear_on_continue = false,
            display_callback = function(variable, buf, stackframe, node, options)
                if options.virt_text_pos == 'inline' then
                    return ' = ' .. variable.value
                else
                    return variable.name .. ' = ' .. variable.value
                end
            end,
            virt_text_pos = vim.fn.has 'nvim-0.10' == 1 and 'inline' or 'eol',
            all_frames = false,
            virt_lines = false,
            virt_text_win_col = nil
        })
    end
})
