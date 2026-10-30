local now, now_if_args, later = Config.now, Config.now_if_args, Config.later

now(function()
	require("mini.basics").setup({
		options = { basic = false },
		mappings = {
			option_toggle_prefix = "",
			windows = false,
		},
	})
end)

now_if_args(function()
	require("mini.misc").setup()
	MiniMisc.setup_auto_root()
	MiniMisc.setup_restore_cursor()
	MiniMisc.setup_termbg_sync()
end)

later(function()
	local ai = require("mini.ai")
	local buffer = function()
		local last = vim.fn.line("$")
		return { from = { line = 1, col = 1 }, to = { line = last, col = math.max(vim.fn.getline(last):len(), 1) } }
	end
	ai.setup({
		custom_textobjects = {
			B = buffer,
			F = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
		},
		search_method = "cover",
	})
end)

later(function()
	require("mini.align").setup()
end)

later(function()
	require("mini.operators").setup()
	vim.keymap.set("n", "(", "gxiagxila", { remap = true, desc = "Swap arg left" })
	vim.keymap.set("n", ")", "gxiagxina", { remap = true, desc = "Swap arg right" })
end)

later(function()
	require("mini.pairs").setup({ modes = { command = true } })
end)

later(function()
	require("mini.splitjoin").setup()
end)

later(function()
	require("mini.surround").setup()
end)
