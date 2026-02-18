local M = {}

-- Centralized UI border configuration
-- Change this one value to update all popups/floating windows
M.border_style = "double"

-- UI configuration that can be used across all plugins
M.ui = {
	-- Standard border style for floating windows
	border = M.border_style,
	
	-- Common window options for LSP hover/signature
	window_opts = function(opts)
		local defaults = { 
			border = M.border_style, 
			max_height = 25, 
			max_width = 120 
		}
		return vim.tbl_extend("force", defaults, opts or {})
	end,
	
	-- Common menu/completion border configuration
	menu_border = M.border_style,
}

M.starter = {
	header = function()
		local day = os.date("%A")
		local headers = {
			["Monday"] = [[
███╗   ███╗ ██████╗ ███╗   ██╗██████╗  █████╗ ██╗   ██╗
████╗ ████║██╔═══██╗████╗  ██║██╔══██╗██╔══██╗╚██╗ ██╔╝
██╔████╔██║██║   ██║██╔██╗ ██║██║  ██║███████║ ╚████╔╝
██║╚██╔╝██║██║   ██║██║╚██╗██║██║  ██║██╔══██║  ╚██╔╝
██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██████╔╝██║  ██║   ██║
╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝   ╚═╝
            ]],
			["Tuesday"] = [[
████████╗██╗   ██╗███████╗███████╗██████╗  █████╗ ██╗   ██╗
╚══██╔══╝██║   ██║██╔════╝██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝
   ██║   ██║   ██║█████╗  ███████╗██║  ██║███████║ ╚████╔╝
   ██║   ██║   ██║██╔══╝  ╚════██║██║  ██║██╔══██║  ╚██╔╝
   ██║   ╚██████╔╝███████╗███████║██████╔╝██║  ██║   ██║
   ╚═╝    ╚═════╝ ╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝   ╚═╝
            ]],
			["Wednesday"] = [[
██╗    ██╗███████╗██████╗ ███╗   ██╗███████╗███████╗██████╗  █████╗ ██╗   ██╗
██║    ██║██╔════╝██╔══██╗████╗  ██║██╔════╝██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝
██║ █╗ ██║█████╗  ██║  ██║██╔██╗ ██║█████╗  ███████╗██║  ██║███████║ ╚████╔╝
██║███╗██║██╔══╝  ██║  ██║██║╚██╗██║██╔══╝  ╚════██║██║  ██║██╔══██║  ╚██╔╝
╚███╔███╔╝███████╗██████╔╝██║ ╚████║███████╗███████║██████╔╝██║  ██║   ██║
 ╚══╝╚══╝ ╚══════╝╚═════╝ ╚═╝  ╚═══╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝   ╚═╝
            ]],
			["Thursday"] = [[
████████╗██╗  ██╗██╗   ██╗██████╗ ███████╗██████╗  █████╗ ██╗   ██╗
╚══██╔══╝██║  ██║██║   ██║██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝
   ██║   ███████║██║   ██║██████╔╝███████╗██║  ██║███████║ ╚████╔╝
   ██║   ██╔══██║██║   ██║██╔══██╗╚════██║██║  ██║██╔══██║  ╚██╔╝
   ██║   ██║  ██║╚██████╔╝██║  ██║███████║██████╔╝██║  ██║   ██║
   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝  ╚═╝   ╚═╝
            ]],
			["Friday"] = [[
███████╗██████╗ ██╗██████╗  █████╗ ██╗   ██╗
██╔════╝██╔══██╗██║██╔══██╗██╔══██╗╚██╗ ██╔╝
█████╗  ██████╔╝██║██║  ██║███████║ ╚████╔╝
██╔══╝  ██╔══██╗██║██║  ██║██╔══██║  ╚██╔╝
██║     ██║  ██║██║██████╔╝██║  ██║   ██║
╚═╝     ╚═╝  ╚═╝╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝
            ]],
			["Saturday"] = [[
███████╗ █████╗ ████████╗██╗   ██╗██████╗ ██████╗  █████╗ ██╗   ██╗
██╔════╝██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝
███████╗███████║   ██║   ██║   ██║██████╔╝██║  ██║███████║ ╚████╔╝
╚════██║██╔══██║   ██║   ██║   ██║██╔══██╗██║  ██║██╔══██║  ╚██╔╝
███████║██║  ██║   ██║   ╚██████╔╝██║  ██║██████╔╝██║  ██║   ██║
╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝
            ]],
			["Sunday"] = [[
███████╗██╗   ██╗███╗   ██╗██████╗  █████╗ ██╗   ██╗
██╔════╝██║   ██║████╗  ██║██╔══██╗██╔══██╗╚██╗ ██╔╝
███████╗██║   ██║██╔██╗ ██║██║  ██║███████║ ╚████╔╝
╚════██║██║   ██║██║╚██╗██║██║  ██║██╔══██║  ╚██╔╝
███████║╚██████╔╝██║ ╚████║██████╔╝██║  ██║   ██║
╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝   ╚═╝
            ]],
		}
		return headers[day]
	end,
}

M.palette = {
	base00 = "#1F1F28",
	base01 = "#2A2A37",
	base02 = "#223249",
	base03 = "#727169",
	base04 = "#C8C093",
	base05 = "#DCD7BA",
	base06 = "#938AA9",
	base07 = "#363646",
	base08 = "#C34043",
	base09 = "#FFA066",
	base0A = "#DCA561",
	base0B = "#98BB6C",
	base0C = "#7FB4CA",
	base0D = "#7E9CD8",
	base0E = "#957FB8",
	base0F = "#D27E99",
}

-- Generate a UUID v7 (time-ordered UUID with millisecond precision)
-- Format: XXXXXXXX-XXXX-7XXX-XXXX-XXXXXXXXXXXX
-- Where first 48 bits = Unix timestamp (ms), version = 7, rest = random
M.generate_uuid = function()
	-- Seed random number generator
	math.randomseed(os.time() + os.clock() * 1000000)
	
	-- Get current Unix timestamp in milliseconds
	local timestamp_ms = math.floor(os.time() * 1000)
	
	-- Generate random bytes function
	local function random_hex_byte()
		return string.format("%02x", math.random(0, 255))
	end
	
	-- Convert timestamp to hex (48 bits = 6 bytes = 12 hex chars)
	local timestamp_hex = string.format("%012x", timestamp_ms)
	
	-- Generate random data for the UUID
	local rand1 = random_hex_byte() .. random_hex_byte() .. random_hex_byte()  -- 24 bits
	local rand2 = random_hex_byte() .. random_hex_byte()                       -- 16 bits
	local rand3 = ""
	for i = 1, 6 do
		rand3 = rand3 .. random_hex_byte()                                    -- 48 bits
	end
	
	-- Set version (4 bits = 7) in the 13th hex digit position
	local version_rand = "7" .. rand1:sub(2, 3)
	
	-- Set variant (2 bits = 10) in the 17th hex digit position  
	local variant_byte = math.random(128, 191) -- 10xxxxxx in binary
	local variant_hex = string.format("%02x", variant_byte)
	local variant_rand = variant_hex .. rand2:sub(3, 4)
	
	-- Construct UUID v7: TTTTTTTT-TTTT-7RRR-VRRR-RRRRRRRRRRRR
	local uuid = string.format("%s-%s-%s-%s-%s",
		timestamp_hex:sub(1, 8),      -- First 32 bits of timestamp
		timestamp_hex:sub(9, 12),     -- Next 16 bits of timestamp  
		version_rand,                 -- Version 7 + 12 bits random
		variant_rand,                 -- Variant + 14 bits random
		rand3                         -- Final 48 bits random
	)
	
	return uuid:lower()
end

-- VSCode-style Command Palette Builder using MiniPick with mini.icons
M.create_command_palette = function()
	-- Define commands with their categories and actions for dynamic icon lookup
	local command_data = {
		-- File operations
		{ name = "File: Open File", category = "file", action = function() MiniPick.builtin.files() end },
		{ name = "File: Recent Files", category = "file", action = function() MiniExtra.pickers.oldfiles() end },
		{ name = "File: File Explorer", category = "directory", action = function() MiniExtra.pickers.explorer() end },
		
		-- Search operations
		{ name = "Search: Live Grep", category = "search", action = function() MiniPick.builtin.grep_live() end },
		{ name = "Search: Buffers", category = "search", action = function() MiniPick.builtin.buffers() end },
		{ name = "Search: Help", category = "search", action = function() MiniPick.builtin.help() end },
		{ name = "Search: Current Buffer Lines", category = "search", action = function() MiniExtra.pickers.buf_lines() end },
		{ name = "Search: Commands", category = "search", action = function() MiniExtra.pickers.commands() end },
		{ name = "Search: Keymaps", category = "search", action = function() MiniExtra.pickers.keymaps() end },
		{ name = "Search: Diagnostics", category = "search", action = function() MiniExtra.pickers.diagnostic() end },
		{ name = "Search: Options", category = "search", action = function() MiniExtra.pickers.options() end },
		{ name = "Search: Registers", category = "search", action = function() MiniExtra.pickers.registers() end },
		{ name = "Search: TreeSitter", category = "search", action = function() MiniExtra.pickers.treesitter() end },
		
		-- Git operations
		{ name = "Git: Status", category = "git", action = function() require('neogit').open() end },
		{ name = "Git: Branches", category = "git", action = function() MiniExtra.pickers.git_branches() end },
		{ name = "Git: Commits", category = "git", action = function() MiniExtra.pickers.git_commits() end },
		{ name = "Git: Hunks", category = "git", action = function() MiniExtra.pickers.git_hunks() end },
		
		-- LSP operations  
		{ name = "LSP: References", category = "lsp", action = function() MiniExtra.pickers.lsp({ scope = "references" }) end },
		{ name = "LSP: Definitions", category = "lsp", action = function() MiniExtra.pickers.lsp({ scope = "definition" }) end },
		{ name = "LSP: Document Symbols", category = "lsp", action = function() MiniExtra.pickers.lsp({ scope = "document_symbol" }) end },
		{ name = "LSP: Workspace Symbols", category = "lsp", action = function() MiniExtra.pickers.lsp({ scope = "workspace_symbol" }) end },
		
		-- Session operations
		{ name = "Session: Save Session", category = "default", icon = "󰆓", action = function()
			local cwd = vim.fn.getcwd()
			local last_folder = cwd:match("([^/]+)$")
			require('mini.sessions').write(last_folder)
			print("Session saved as: " .. last_folder)
		end },
		{ name = "Session: Load Session", category = "default", icon = "󰦛", action = function()
			vim.cmd('wa')
			require('mini.sessions').select()
		end },
		
		-- Buffer operations
		{ name = "Buffer: Close Buffer", category = "default", icon = "󰅖", action = function() MiniBufremove.delete() end },
		{ name = "Buffer: Close All Buffers", category = "default", icon = "󰱝", action = function() vim.cmd('bufdo bd') end },
		{ name = "Buffer: Next Buffer", category = "default", icon = "󰮰", action = function() vim.cmd('bnext') end },
		{ name = "Buffer: Previous Buffer", category = "default", icon = "󰮲", action = function() vim.cmd('bprevious') end },
		
		-- Window operations
		{ name = "Window: Split Horizontally", category = "default", icon = "󱂬", action = function() vim.cmd('split') end },
		{ name = "Window: Split Vertically", category = "default", icon = "󱂫", action = function() vim.cmd('vsplit') end },
		{ name = "Window: Close Window", category = "default", icon = "󰖭", action = function() vim.cmd('close') end },
		
		-- AI operations (verified commands only)
		{ name = "AI: Chat", category = "default", icon = "󰚩", action = function() vim.cmd('CodeCompanionChat') end },
		{ name = "AI: Actions", category = "default", icon = "󰒓", action = function() vim.cmd('CodeCompanionActions') end },
		{ name = "AI: Inline Assistant", category = "default", icon = "󰙎", action = function() vim.cmd('CodeCompanion') end },
		
		-- Color Palette operations (hierarchical - opens subpicker)
		{ name = "🎨 Colors", category = "default", icon = "🎨", action = function() require("config.colors").pick_palette() end },
		
		-- Visits
		{ name = "Visit: Paths", category = "directory", action = function() MiniExtra.pickers.visit_paths() end },
		{ name = "Visit: Labels", category = "default", icon = "󰃃", action = function() MiniExtra.pickers.visit_labels() end },
		
		-- Neovim operations
		{ name = "Neovim: Reload Config", category = "default", icon = "󰑓", action = function() vim.cmd('source $MYVIMRC'); print("Configuration reloaded!") end },
		{ name = "Neovim: Quit", category = "default", icon = "󰗼", action = function() vim.cmd('qa') end },
		{ name = "Neovim: Write & Quit", category = "default", icon = "󰈆", action = function() vim.cmd('wqa') end },
	}
	
	-- Build display items with mini.icons and create action lookup
	local commands = {}
	local action_lookup = {}
	
	for _, cmd_info in ipairs(command_data) do
		local icon = ""
		if cmd_info.icon then
			-- Use provided icon as fallback
			icon = cmd_info.icon
		elseif cmd_info.category == "file" then
			icon = require("mini.icons").get("file", "file")
		elseif cmd_info.category == "directory" then
			icon = require("mini.icons").get("directory", "directory")
		elseif cmd_info.category == "search" then
			-- Use search-related mini.icons  
			icon = require("mini.icons").get("file", "search") or ""
		elseif cmd_info.category == "git" then
			-- Use git-related mini.icons
			icon = require("mini.icons").get("file", ".git") or "󰊢"
		elseif cmd_info.category == "lsp" then
			-- Use different LSP icons based on the operation
			local lsp_type = cmd_info.name:match("LSP: (%w+)"):lower() or "definition"
			icon = require("mini.icons").get("lsp", lsp_type)
		else
			-- Try to get mini.icons default based on the command name
			if cmd_info.name:match("Buffer:") then
				icon = require("mini.icons").get("default", "buffer") or ""
			elseif cmd_info.name:match("Window:") then
				icon = require("mini.icons").get("default", "window") or ""
			elseif cmd_info.name:match("Session:") then
				icon = require("mini.icons").get("file", ".session") or "󰆓"
			else
				icon = require("mini.icons").get("default", "default") or ""
			end
		end
		
		local display_item = icon .. " " .. cmd_info.name
		table.insert(commands, display_item)
		action_lookup[display_item] = cmd_info.action
	end
	
	local choose_action = function(item)
		local action = action_lookup[item]
		if action then
			action()
		else
			print("Command not found: " .. item)
		end
	end
	
	return MiniPick.start({
		source = {
			items = commands,
			name = "Command Palette",
			choose = choose_action,
		},
		window = {
			config = function()
				local height = math.floor(0.8 * vim.o.lines)
				local width = math.floor(0.7 * vim.o.columns)
				return {
					anchor = "NW",
					height = height,
					width = width,
					row = math.floor(0.1 * vim.o.lines),
					col = math.floor(0.5 * (vim.o.columns - width)),
					border = M.ui.border,
				}
			end
		}
	})
end

-- Treesitter parser utilities
M.treesitter = {
	--- Ensure treesitter parsers are installed without calling setup() again
	--- @param parsers string|table Parser name or list of parser names
	ensure_installed = function(parsers)
		-- Normalize to table
		if type(parsers) == "string" then
			parsers = { parsers }
		end
		
		-- Schedule to avoid blocking
		vim.schedule(function()
			-- Use nvim-treesitter's API to check installed parsers
			local has_ts, ts_parsers = pcall(require, "nvim-treesitter.parsers")
			if not has_ts then
				vim.notify("nvim-treesitter not available yet", vim.log.levels.WARN)
				return
			end
			
			for _, parser in ipairs(parsers) do
				-- Check if parser is installed using treesitter's API
				if not ts_parsers.has_parser(parser) then
					vim.notify("Installing treesitter parser: " .. parser, vim.log.levels.INFO)
					vim.cmd("TSInstall " .. parser)
				end
			end
		end)
	end,
}

_G.Utils = M
