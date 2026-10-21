return {
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
	root_markers = { { "go.work" }, { "go.mod" }, { ".git" } },
	on_attach = function(client)
		client.server_capabilities.completionProvider.triggerCharacters = { ".", ":" }
	end,
	settings = {
		gopls = {
			semanticTokens = true,
			analyses = {
				unusedparams = true,
				shadow = true,
			},
			staticcheck = true,
			gofumpt = true,
			templateExtensions = { "tmpl", "tpl", "html" },
		},
	},
}
