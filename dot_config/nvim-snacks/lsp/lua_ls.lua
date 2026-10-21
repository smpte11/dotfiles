return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = {
		{ ".emmyrc.json", ".luarc.json", ".luarc.jsonc" },
		{ ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml" },
		{ ".git" },
	},
	on_attach = function(client)
		client.server_capabilities.completionProvider.triggerCharacters = { ".", ":", "#", "(" }
	end,
	settings = {
		Lua = {
			codeLens = { enable = true },
			hint = { enable = true, semicolon = "Disable" },
			runtime = { version = "LuaJIT", path = vim.split(package.path, ";") },
			workspace = {
				ignoreSubmodules = true,
				library = { vim.env.VIMRUNTIME },
			},
		},
	},
}
