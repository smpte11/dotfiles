-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ Testing Framework Configuration                                             │
-- │                                                                             │
-- │ Neotest framework for running and managing tests across languages.         │
-- │ Go testing is handled by ray-x/go.nvim.                                    │
-- │                                                                             │
-- │ Uses global: spec (from 00-bootstrap.lua)                                  │
-- └─────────────────────────────────────────────────────────────────────────────┘

spec({
	source = "nvim-neotest/neotest",
	depends = {
		"nvim-neotest/nvim-nio",
	},
	config = function()
		require("neotest").setup({
			adapters = {
				-- Go testing is handled by ray-x/go.nvim
				-- Add other test adapters here as needed
			},
		})
	end,
})

-- =====================================================
