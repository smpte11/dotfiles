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
		bufdelete = { enabled = true },
		dashboard = {
			preset = {
				keys = {
					{ icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.picker.files()" },
					{ icon = " ", key = "e", desc = "New File", action = ":ene | startinsert" },
					{ icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.picker.grep()" },
					{ icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
					{
						icon = " ",
						key = "c",
						desc = "Config",
						action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })",
					},
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
			},
			sections = {
				{ title = "Journal", padding = 1 },
				{
					indent = 2,
					padding = 1,
					{ icon = " ", key = "w", desc = "Today · work", action = open_today("work") },
					{ icon = " ", key = "p", desc = "Today · personal", action = open_today("personal") },
					{ icon = " ", key = "W", desc = "Previous · work", action = open_previous("work") },
					{ icon = " ", key = "P", desc = "Previous · personal", action = open_previous("personal") },
				},
				{ title = "Recent Files", padding = 1 },
				{ section = "recent_files", limit = 5, indent = 2, padding = 1 },
				{ section = "keys", padding = 1 },
			},
		},
		explorer = { replace_netrw = true },
		gh = {},
		indent = { indent = { enabled = false } },
		input = {},
		notifier = {},
		picker = {},
		scope = {},
		statuscolumn = {},
	})
end)

later(function()
	add({ "https://github.com/folke/which-key.nvim" })
	require("which-key").setup({
		preset = "helix",
		delay = 50,
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
