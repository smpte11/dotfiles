local markers = {
	"graphql.config.ts",
	"graphql.config.js",
	"graphql.config.yml",
	"graphql.config.yaml",
	"graphql.config.json",
	".graphqlrc",
	".graphqlrc.yml",
	".graphqlrc.yaml",
	".graphqlrc.json",
}

return {
	cmd = { "graphql-lsp", "server", "-m", "stream" },
	filetypes = { "graphql", "typescript", "typescriptreact", "javascriptreact" },
	-- Attach only below a GraphQL config, not to every TS file
	root_dir = function(bufnr, on_dir)
		local root = vim.fs.root(bufnr, markers)
		if root then
			on_dir(root)
		end
	end,
}
