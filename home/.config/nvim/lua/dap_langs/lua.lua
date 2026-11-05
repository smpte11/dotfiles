vim.pack.add({ "https://github.com/jbyuki/one-small-step-for-vimkind" })

local dap = require("dap")
local default_port = 8086

dap.adapters.nlua = function(callback, config)
	callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or default_port })
end

dap.configurations.lua = {
	{
		type = "nlua",
		request = "attach",
		name = "Attach to Neovim (osv)",
		host = function()
			local value = vim.fn.input("Host: ", "127.0.0.1")
			return value ~= "" and value or "127.0.0.1"
		end,
		port = function()
			local value = tonumber(vim.fn.input("Port: ", tostring(default_port)))
			return value or default_port
		end,
	},
}

vim.api.nvim_create_user_command("OsvServer", function(opts)
	local port = tonumber(opts.args) or default_port
	require("osv").launch({ port = port })
	vim.notify("osv server listening on port " .. port)
end, { nargs = "?", desc = "Start osv debug server in this Neovim" })

vim.api.nvim_create_user_command("OsvStop", function()
	require("osv").stop()
end, { desc = "Stop osv debug server" })
