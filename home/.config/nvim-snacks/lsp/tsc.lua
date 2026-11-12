-- Native TypeScript 7 server; prefers the project's own tsc, like lspconfig's tsc
local function supports_lsp(bin)
	if vim.fn.executable(bin) ~= 1 then
		return false
	end
	local out = vim.system({ bin, "--version" }, { text = true }):wait()
	local version = vim.version.parse(out.stdout or "")
	return out.code == 0 and version ~= nil and version.major >= 7
end

return {
	cmd = function(dispatchers, config)
		local local_tsc = vim.fs.joinpath(config.root_dir or "", "node_modules/.bin/tsc")
		local bin = supports_lsp(local_tsc) and local_tsc or "tsc"
		return vim.lsp.rpc.start({ bin, "--lsp", "--stdio" }, dispatchers)
	end,
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	root_markers = { { "pnpm-lock.yaml", "package-lock.json", "yarn.lock", "bun.lock" }, { ".git" } },
}
