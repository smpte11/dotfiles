-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ Rust Language Configuration                                                 │
-- │                                                                             │
-- │ Rust development with rustaceanvim - A heavily modified fork of            │
-- │ rust-tools.nvim that provides enhanced LSP, DAP, and tooling integration.  │
-- │                                                                             │
-- │ Features:                                                                   │
-- │ - Automatic rust-analyzer setup and configuration                          │
-- │ - DAP integration for debugging                                            │
-- │ - Test runner integration                                                  │
-- │ - Inlay hints, hover actions, and more                                     │
-- │                                                                             │
-- │ Uses global: spec (from 00-bootstrap.lua)                                  │
-- └─────────────────────────────────────────────────────────────────────────────┘

spec({
	source = "mrcjkb/rustaceanvim",
	checkout = "master",
	hooks = {
		-- Rustaceanvim is already lazy-loaded by filetype detection
		-- No post_checkout needed as it's a pure Lua plugin
	},
	config = function()
		-- Rustaceanvim is configured via vim.g.rustaceanvim
		-- This must be set BEFORE the plugin loads
		vim.g.rustaceanvim = {
			-- Plugin configuration
			tools = {
				-- Options for hover actions
				hover_actions = {
					auto_focus = true,
					border = Utils.ui.border,
				},
				-- Options for code actions
				code_actions = {
					ui_select_fallback = true, -- Use vim.ui.select for code actions
				},
			},
			-- LSP configuration
			server = {
				on_attach = function(client, bufnr)
					-- Rust-specific keymaps
					vim.keymap.set("n", "<leader>lc", function()
						vim.cmd.RustLsp("openCargo")
					end, { buffer = bufnr, desc = "[L]sp Open [C]argo.toml" })

					vim.keymap.set("n", "<leader>le", function()
						vim.cmd.RustLsp("explainError")
					end, { buffer = bufnr, desc = "[L]sp [E]xplain Error" })

					vim.keymap.set("n", "<leader>lm", function()
						vim.cmd.RustLsp("expandMacro")
					end, { buffer = bufnr, desc = "[L]sp Expand [M]acro" })

					vim.keymap.set("n", "<leader>lp", function()
						vim.cmd.RustLsp("rebuildProcMacros")
					end, { buffer = bufnr, desc = "[L]sp Rebuild [P]roc Macros" })

					-- Rust test keymaps
					vim.keymap.set("n", "<leader>tr", function()
						vim.cmd.RustLsp("runnables")
					end, { buffer = bufnr, desc = "[T]est [R]unnables" })

					vim.keymap.set("n", "<leader>tt", function()
						vim.cmd.RustLsp("testables")
					end, { buffer = bufnr, desc = "[T]est [T]estables" })
				end,
				-- Set default settings for rust-analyzer
				default_settings = {
					["rust-analyzer"] = {
						-- Enable all features by default
						cargo = {
							allFeatures = true,
							loadOutDirsFromCheck = true,
							runBuildScripts = true,
						},
						-- Enable proc macro support
						procMacro = {
							enable = true,
							ignored = {
								["async-trait"] = { "async_trait" },
								["napi-derive"] = { "napi" },
								["async-recursion"] = { "async_recursion" },
							},
						},
						-- Enable clippy on save
						checkOnSave = {
							command = "clippy",
							extraArgs = { "--all", "--", "-W", "clippy::all" },
						},
						-- Inlay hints
						inlayHints = {
							lifetimeElisionHints = {
								enable = "skip_trivial",
								useParameterNames = true,
							},
						},
					},
				},
			},
			-- DAP configuration
			dap = {
				-- DAP adapter configuration
				adapter = require("rustaceanvim.config").get_codelldb_adapter(
					vim.fn.stdpath("data") .. "/mason/bin/codelldb",
					vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/lldb/lib/liblldb.dylib"
				),
			},
		}
	end,
})
