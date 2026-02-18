-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ TypeScript/JavaScript Language Configuration                               │
-- │                                                                             │
-- │ - Treesitter parsers: typescript, tsx, javascript                          │
-- │ - LSP: typescript-tools.nvim                                               │
-- │ - Formatters: configured via conform in 04-lsp.lua                         │
-- └─────────────────────────────────────────────────────────────────────────────┘

spec({
	source = "pmizio/typescript-tools.nvim",
	depends = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
	config = function()
		-- Ensure TypeScript/JavaScript parsers
		Utils.treesitter.ensure_installed({ "typescript", "tsx", "javascript" })
		
		-- TypeScript LSP setup
		require("typescript-tools").setup({})
	end,
})

