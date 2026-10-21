local add = vim.pack.add
local now, later = Config.now, Config.later

now(function()
	add({ "https://github.com/nvim-tree/nvim-web-devicons" })
	require("nvim-web-devicons").setup()
end)

local notebook = vim.env.ZK_NOTEBOOK_DIR or vim.fn.expand("~/notebook")

local journal_dir = function(kind)
	return string.format("%s/journal/%s", notebook, kind)
end

local open_today = function(kind)
	return function()
		local path = string.format("%s/%s.md", journal_dir(kind), os.date("%Y-%m-%d"))
		if vim.uv.fs_stat(path) then
			vim.cmd.edit(vim.fn.fnameescape(path))
		else
			require("zk").new({ group = "daily-" .. kind })
		end
	end
end

local open_previous = function(kind)
	return function()
		local today, best = os.date("%Y-%m-%d"), nil
		for name, type in vim.fs.dir(journal_dir(kind)) do
			local date = type == "file" and name:match("^(%d%d%d%d%-%d%d%-%d%d)%.md$")
			if date and date < today and (best == nil or date > best) then
				best = date
			end
		end
		if not best then
			return vim.notify("No previous " .. kind .. " journal", vim.log.levels.WARN)
		end
		vim.cmd.edit(vim.fn.fnameescape(string.format("%s/%s.md", journal_dir(kind), best)))
	end
end

now(function()
	add({ "https://github.com/folke/snacks.nvim" })
	require("snacks").setup({
		bigfile = {},
		bufdelete = {},
		dashboard = {
			preset = {
				keys = {
					{ icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
					{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
					{ icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
					{ icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
					{
						icon = " ",
						key = "c",
						desc = "Config",
						action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
					},
					{ icon = " ", key = "s", desc = "Restore Session", action = ":lua require('persistence').load()" },
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
			},
			sections = {
				{ section = "header" },
				{ section = "keys", gap = 1, padding = 1 },
				{ title = "Journal", icon = " ", padding = 1 },
				{
					indent = 2,
					padding = 1,
					{ icon = " ", key = "w", desc = "Today - work", action = open_today("work") },
					{ icon = " ", key = "p", desc = "Today - personal", action = open_today("personal") },
					{ icon = " ", key = "W", desc = "Previous - work", action = open_previous("work") },
					{ icon = " ", key = "P", desc = "Previous - personal", action = open_previous("personal") },
				},
				{ title = "Recent Files", icon = " ", padding = 1 },
				{ section = "recent_files", cwd = true, limit = 5, indent = 2, padding = 1 },
			},
		},
		explorer = { replace_netrw = true },
		gh = {},
		image = {},
		indent = {},
		input = {},
		notifier = {},
		picker = {},
		quickfile = {},
		scope = {},
		statuscolumn = {},
		terminal = {},
		toggle = {},
		words = {},
	})

	Config.new_autocmd("LspProgress", nil, function(ev)
		local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
		vim.notify(vim.lsp.status(), vim.log.levels.INFO, {
			id = "lsp_progress",
			title = "LSP Progress",
			opts = function(notif)
				notif.icon = ev.data.params.value.kind == "end" and " "
					or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
			end,
		})
	end, "Show LSP progress")
end)

later(function()
	local toggle = Snacks.toggle
	toggle.option("background", { off = "light", on = "dark", name = "Dark background" }):map("\\b")
	toggle.option("cursorline", { name = "Cursor line" }):map("\\c")
	toggle.option("cursorcolumn", { name = "Cursor column" }):map("\\C")
	toggle.diagnostics():map("\\d")
	toggle.dim():map("\\D")
	toggle.indent():map("\\g")
	toggle.option("hlsearch", { name = "Search highlight" }):map("\\h")
	toggle.inlay_hints():map("\\H")
	toggle.option("ignorecase", { name = "Ignore case" }):map("\\i")
	toggle.option("list", { name = "List chars" }):map("\\l")
	toggle.line_number():map("\\n")
	toggle.option("relativenumber", { name = "Relative number" }):map("\\r")
	toggle.option("spell", { name = "Spelling" }):map("\\s")
	toggle.treesitter():map("\\t")
	toggle.option("wrap", { name = "Wrap" }):map("\\w")
	toggle.words():map("\\W")
	toggle.zen():map("\\z")
	toggle.zoom():map("\\Z")
end)

later(function()
	add({ "https://github.com/folke/which-key.nvim" })
	require("which-key").setup({
		preset = "modern",
		win = { border = vim.o.winborder },
		spec = { Config.leader_groups },
	})
end)

later(function()
	add({ "https://github.com/folke/flash.nvim" })
	require("flash").setup()
	vim.keymap.set({ "n", "x", "o" }, "<Leader>j", function()
		require("flash").jump()
	end, { desc = "Jump" })
end)

now(function()
	add({ "https://github.com/folke/persistence.nvim" })
	require("persistence").setup()
end)

now(function()
	add({ "https://github.com/folke/lazydev.nvim" })
	require("lazydev").setup({
		library = {
			{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			{ path = "snacks.nvim", words = { "Snacks" } },
		},
	})
end)
