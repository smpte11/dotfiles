-- Uses global: spec (from 00-bootstrap.lua)

spec({
	source = "topaxi/pipeline.nvim",
	-- optional, you can also install and use `yq` instead.
	-- build = "make",
	config = function()
		require("pipeline").setup({})
	end,
	-- stylua: ignore start
	keys = {
		{ "<leader>upo", "<cmd>Pipeline open<cr>", desc = "Open Pipeline" },
		{ "<leader>upc", "<cmd>Pipeline close<cr>", desc = "Close Pipeline" },
		{ "<leader>upt", "<cmd>Pipeline toggle<cr>", desc = "Toggle Pipeline" },
	},
	-- stylua: ignore end
})
