-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ Erlang Language Configuration                                               │
-- │                                                                             │
-- │ Erlang development configuration with rebar3 project detection.            │
-- │                                                                             │
-- │ Features:                                                                   │
-- │ - Automatic rebar3 project detection                                       │
-- │ - Sets appropriate filetypes for rebar3 project files                      │
-- │ - Configures Erlang development environment                                │
-- │                                                                             │
-- │ Uses global: spec (from 00-bootstrap.lua)                                  │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- ══════════════════════════════════════════════════════════════════════════════
-- Rebar3 Project Detection and Filetype Configuration
-- ══════════════════════════════════════════════════════════════════════════════

-- Function to detect if current directory is a rebar3 project
local function is_rebar3_project()
	-- Check for rebar3 project indicators
	local indicators = {
		"rebar.config",
		"rebar.config.script",
		"rebar.lock",
		"_build",
	}
	
	for _, indicator in ipairs(indicators) do
		if vim.fn.filereadable(indicator) == 1 or vim.fn.isdirectory(indicator) == 1 then
			return true
		end
	end
	
	return false
end

-- Set up autocommand for rebar3 project detection
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = {
		-- Configuration files
		"rebar.config",
		"rebar.config.script",
		"rebar.lock",
		"relx.config",
		"sys.config",
		"vm.args",
		-- Application files
		"*.app",
		"*.app.src",
		-- Release files  
		"*.rel",
		"*.relup",
		"*.appup",
		-- Build and script files
		"Makefile",
		"*.mk",
		"*.script",
		-- Documentation
		"*.edoc",
		-- Test files (if they don't already have .erl extension)
		"*_SUITE",
		"*_tests",
		-- Common config directories
		"config/*",
		"rel/*",
		"apps/*/src/*",
		"src/*",
	},
	callback = function()
		-- Only set filetype if we're in a rebar3 project
		if is_rebar3_project() then
			local filename = vim.fn.expand("%:t")
			local extension = vim.fn.expand("%:e")
			local path = vim.fn.expand("%:p")
			
			-- Set filetype based on file patterns
			if filename:match("^rebar%.config") or filename:match("^relx%.config") then
				vim.bo.filetype = "erlang"
			elseif filename:match("^sys%.config") or filename:match("^vm%.args") then
				vim.bo.filetype = "erlang"
			elseif extension == "app" or filename:match("%.app%.src$") then
				vim.bo.filetype = "erlang"
			elseif extension == "rel" or extension == "relup" or extension == "appup" then
				vim.bo.filetype = "erlang"
			elseif filename:match("_SUITE$") or filename:match("_tests$") then
				vim.bo.filetype = "erlang"
			elseif extension == "script" then
				vim.bo.filetype = "erlang"
			elseif extension == "edoc" then
				vim.bo.filetype = "erlang"
			elseif path:match("/config/") or path:match("/rel/") then
				-- Files in config/ or rel/ directories in rebar3 projects
				if extension == "" or extension == "config" then
					vim.bo.filetype = "erlang"
				end
			elseif filename == "Makefile" or extension == "mk" then
				-- Keep Makefile as makefile, but could be erlang-related
				-- This is optional - you might want to keep these as 'make' filetype
				-- vim.bo.filetype = "make"  -- Keep default
			end
		end
	end,
	desc = "Set Erlang filetype for rebar3 project files",
})

-- ══════════════════════════════════════════════════════════════════════════════
-- Erlang Treesitter and LSP Configuration
-- ══════════════════════════════════════════════════════════════════════════════

spec({
	source = "nvim-treesitter/nvim-treesitter",
	config = function()
		-- Ensure Erlang treesitter parser is installed
		Utils.treesitter.ensure_installed({ "erlang" })
	end,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- Erlang-specific Keymaps (when in Erlang files)
-- ══════════════════════════════════════════════════════════════════════════════

vim.api.nvim_create_autocmd("FileType", {
	pattern = "erlang",
	callback = function(event)
		local map = function(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
		end
		
		-- Erlang-specific mappings can be added here
		-- For example:
		-- map("n", "<leader>er", ":!rebar3 compile<CR>", "Rebar3 [C]ompile")
		-- map("n", "<leader>et", ":!rebar3 eunit<CR>", "Rebar3 [T]est (EUnit)")
		-- map("n", "<leader>ect", ":!rebar3 ct<CR>", "Rebar3 [C]ommon [T]est")
		
		-- Add Erlang clue to mini.clue if available
		local ok, MiniClue = pcall(require, "mini.clue")
		if ok then
			local clues = MiniClue.config.clues or {}
			
			-- Check if <leader>e clue already exists
			local has_erlang_clue = false
			for _, entry in ipairs(clues) do
				if entry.mode == "n" and entry.keys == "<leader>e" then
					has_erlang_clue = true
					break
				end
			end
			
			if not has_erlang_clue then
				table.insert(clues, { mode = "n", keys = "<leader>e", desc = " erlang" })
				MiniClue.config.clues = clues
			end
		end
	end,
	desc = "Setup Erlang-specific keymaps and configurations",
})