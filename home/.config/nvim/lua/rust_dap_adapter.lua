local function lldb_dap()
	for _, name in ipairs({ "lldb-dap", "lldb-vscode" }) do
		local path = vim.fn.exepath(name)
		if path ~= "" then return path end
	end
	if vim.fn.has("mac") == 1 then
		local out = vim.system({ "xcrun", "-f", "lldb-dap" }, { text = true }):wait()
		if out.code == 0 then return vim.trim(out.stdout) end
	end
end

return function()
	local codelldb = vim.fn.exepath("codelldb")
	if codelldb ~= "" then
		return {
			type = "server",
			host = "127.0.0.1",
			port = "${port}",
			executable = { command = codelldb, args = { "--port", "${port}" } },
		}
	end
	local lldb = lldb_dap()
	if lldb then return { type = "executable", command = lldb, name = "lldb-dap" } end
	return false
end
