-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ Go Language Configuration                                                   │
-- │                                                                             │
-- │ Complete Go development setup including:                                   │
-- │ - Treesitter parsers: go, gomod, gowork, gosum, gotmpl                     │
-- │ - LSP: gopls (via go.nvim)                                                 │
-- │ - Formatters: goimports, gofumpt (via conform)                             │
-- │ - DAP debugging, testing, and more via ray-x/go.nvim                       │
-- │                                                                             │
-- │ Uses global: spec (from 00-bootstrap.lua)                                  │
-- │                                                                             │
-- │ Conditional Loading:                                                        │
-- │   This plugin only loads if Go is installed on the system.                 │
-- │   The enabled parameter prevents add() from being called when Go is        │
-- │   not available, avoiding unnecessary plugin downloads and errors.         │
-- │                                                                             │
-- │ Testing:                                                                    │
-- │   Run: scripts/verify_go_conditional.sh                                    │
-- └─────────────────────────────────────────────────────────────────────────────┘

spec({
	source = "ray-x/go.nvim",
	depends = {
		"ray-x/guihua.lua", -- optional float term, codeaction gui support
		"nvim-treesitter/nvim-treesitter",
	},
	-- Only enable if Go is installed
	enabled = function()
		return vim.fn.executable("go") == 1
	end,
	config = function()
		-- ══════════════════════════════════════════════════════════════════════════
		-- 1. Ensure Go treesitter parsers are installed
		-- ══════════════════════════════════════════════════════════════════════════
		Utils.treesitter.ensure_installed({ "go", "gomod", "gowork", "gosum", "gotmpl" })
		-- ══════════════════════════════════════════════════════════════════════════
		-- 2. Configure conform formatters for Go
		-- ══════════════════════════════════════════════════════════════════════════
		require("conform").formatters_by_ft.go = { "goimports", "gofumpt" }
		-- ══════════════════════════════════════════════════════════════════════════
		-- 2.5. Setup Go-specific keymaps (buffer-local for Go filetypes)
		--      Complements standard LSP (<leader>l*) and DAP (<leader>d*) keymaps
		--      Dynamically adds mini.clue entries when in Go files
		-- ══════════════════════════════════════════════════════════════════════════
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "go", "gomod", "gowork", "gosum", "gotmpl", "gotexttmpl" },
			callback = function(event)
				local map = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
				end

				-- Add Go and Test clues to mini.clue (only if not already present)
				local MiniClue = require("mini.clue")
				local clues = MiniClue.config.clues

				-- Check if <leader>G clue already exists
				local has_go_clue = false
				local has_test_clue = false
				for _, entry in ipairs(clues) do
					if entry.mode == "n" and entry.keys == "<leader>G" then
						has_go_clue = true
					end
					if entry.mode == "n" and entry.keys == "<leader>t" then
						has_test_clue = true
					end
				end

				if not has_go_clue then
					table.insert(clues, { mode = "n", keys = "<leader>G", desc = " go" })
				end
				if not has_test_clue then
					table.insert(clues, { mode = "n", keys = "<leader>t", desc = "󰙨 test" })
				end

				-- Go-specific commands (not covered by standard LSP)
				map("n", "<leader>Gj", "<cmd>GoAddTag<cr>", "[Go] Add [j]son tags")
				map("n", "<leader>GJ", "<cmd>GoRmTag<cr>", "[Go] Remove [J]son tags")
				map("n", "<leader>Gf", "<cmd>GoFillStruct<cr>", "[Go] [F]ill struct")
				map("n", "<leader>Ge", "<cmd>GoIfErr<cr>", "[Go] Add if [e]rr")
				map("n", "<leader>Gi", "<cmd>GoImpl<cr>", "[Go] [I]mplement interface")
				map("n", "<leader>Gm", "<cmd>GoMod tidy<cr>", "[Go] [M]od tidy")
				map("n", "<leader>Ga", "<cmd>GoAlt<cr>", "[Go] [A]lt file (test toggle)")
				map("n", "<leader>GA", "<cmd>GoAltV<cr>", "[Go] [A]lt file (vsplit)")

				-- Test commands (buffer-local for Go files)
				map("n", "<leader>tr", "<cmd>GoTest<cr>", "[Test] [R]un package")
				map("n", "<leader>tf", "<cmd>GoTestFunc<cr>", "[Test] [F]unction")
				map("n", "<leader>tF", "<cmd>GoTestFile<cr>", "[Test] [F]ile (all)")
				map("n", "<leader>ta", "<cmd>GoAddTest<cr>", "[Test] [A]dd for function")
				map("n", "<leader>tc", "<cmd>GoCoverage<cr>", "[Test] [C]overage")
				map("n", "<leader>tC", "<cmd>GoCoverage -t<cr>", "[Test] [C]overage toggle")
			end,
		})

		-- Remove Go and Test clues when leaving Go buffers (cleanup on BufLeave)
		vim.api.nvim_create_autocmd("BufLeave", {
			pattern = { "*.go", "go.mod", "go.work", "go.sum", "*.tmpl" },
			callback = function()
				-- Small delay to allow the new buffer to be entered
				vim.defer_fn(function()
					-- Check if any visible window has a Go filetype
					local has_go_buffer = false
					for _, win in ipairs(vim.api.nvim_list_wins()) do
						local buf = vim.api.nvim_win_get_buf(win)
						local ft = vim.api.nvim_buf_get_option(buf, "filetype")
						if vim.tbl_contains({ "go", "gomod", "gowork", "gosum", "gotmpl", "gotexttmpl" }, ft) then
							has_go_buffer = true
							break
						end
					end

					-- Only remove clues if no Go buffers are visible
					if not has_go_buffer then
						local MiniClue = require("mini.clue")
						local clues = MiniClue.config.clues

						-- Remove <leader>G clue
						for i = #clues, 1, -1 do
							if clues[i].mode == "n" and clues[i].keys == "<leader>G" and clues[i].desc == " go" then
								table.remove(clues, i)
							end
						end

						-- Remove <leader>t clue
						for i = #clues, 1, -1 do
							if
								clues[i].mode == "n"
								and clues[i].keys == "<leader>t"
								and clues[i].desc == "󰙨 test"
							then
								table.remove(clues, i)
							end
						end
					end
				end, 50) -- 50ms delay to check visible windows
			end,
		})

		-- ══════════════════════════════════════════════════════════════════════════
		-- 3. Go.nvim setup (includes gopls LSP, DAP, testing, formatting)
		--    Note: Using our standard LSP/DAP keymaps (from lua/autocmd.lua)
		-- ══════════════════════════════════════════════════════════════════════════
		require("go").setup({
			goimports = "gopls", -- use gopls for import management
			gofmt = "gopls", -- use gopls for formatting
			tag_transform = false,
			test_dir = "",
			comment_placeholder = "   ",
			lsp_cfg = true, -- true: use go.nvim's gopls setup
			lsp_gofumpt = true, -- enable gofumpt formatting in gopls
			lsp_on_attach = false, -- false: use our standard LSP keymaps from lua/autocmd.lua
			lsp_keymaps = false, -- false: use our standard LSP keymaps (<leader>l*)
			lsp_codelens = true, -- enable code lens
			lsp_diag_hdlr = true, -- hook diagnostic handler
			lsp_diag_underline = true,
			lsp_diag_virtual_text = { space = 0, prefix = "󰠠" }, -- show diagnostic virtual text
			lsp_diag_signs = true,
			lsp_diag_update_in_insert = false,
			lsp_document_formatting = true,
			-- DAP debug setup
			dap_debug = true, -- enable dap debug
			dap_debug_keymap = false, -- false: use our standard DAP keymaps (<leader>d*)
			dap_debug_gui = true, -- enable dap gui (dapui)
			dap_debug_vt = true, -- enable dap virtual text
			-- Test setup
			test_runner = "go", -- use go test command
			run_in_floaterm = true, -- run tests in floating terminal
			-- Formatter
			trouble = true, -- trouble integration
			test_efm = false, -- errorformat
			luasnip = false, -- disable luasnip integration (not installed)
			-- Build system
			build_tags = "", -- build tags
			textobjects = true, -- enable text objects
			-- Icons
			icons_cfg = {
				breakpoint = "󰏃",
				currentpos = "󰁕",
			},
		})

		-- ══════════════════════════════════════════════════════════════════════════════
		-- NOTE: Chezmoi template handling
		-- ══════════════════════════════════════════════════════════════════════════════
		-- Chezmoi templates like `.sh.tmpl`, `.yaml.tmpl` are detected as their base
		-- filetype (sh, yaml, etc.) via the vim.filetype.add() patterns above.
		-- This means they get the correct LSP automatically (bashls for .sh.tmpl, etc.)
		--
		-- The Go template syntax highlighting is provided by treesitter injections in
		-- queries/gotmpl/injections.scm, which work even when filetype is set to the
		-- base language.
		--
		-- For actual Go template files (like Helm charts), they are detected as `gotmpl`
		-- or `helm` filetype and get gopls LSP from go.nvim.
	end,
})
