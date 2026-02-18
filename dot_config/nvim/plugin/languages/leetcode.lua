-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ LeetCode Configuration                                                      │
-- │                                                                             │
-- │ LeetCode integration for competitive programming practice.                 │
-- │                                                                             │
-- │ Uses global: spec (from 00-bootstrap.lua)                                  │
-- └─────────────────────────────────────────────────────────────────────────────┘

spec({
	source = "smpte11/leetcode.nvim",
	immediate = true,
	depends = {
		"echasnovski/mini.pick",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
	},
	hooks = {
		post_checkout = function()
			vim.cmd("TSUpdate html")
		end,
	},
	config = function()
		require("leetcode").setup({
			lang = "python3",
		})
	end,
})
