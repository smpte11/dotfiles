-- Uses global: spec (from 00-bootstrap.lua)

spec({
	source = "christoomey/vim-tmux-navigator",
	-- stylua: ignore start
	keys = {
		{ "<c-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate left" },
		{ "<c-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate down" },
		{ "<c-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate up" },
		{ "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate right" },
		{ "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate previous" },
	},
	-- stylua: ignore end
})
