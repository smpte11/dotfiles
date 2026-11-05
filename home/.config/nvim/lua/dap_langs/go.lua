local dap = require("dap")

dap.adapters.go = function(callback, config)
	if config.request == "attach" and config.mode == "remote" and config.host then
		callback({
			type = "server",
			host = config.host,
			port = config.port or 38697,
		})
		return
	end
	callback({
		type = "server",
		port = "${port}",
		executable = {
			command = "dlv",
			args = { "dap", "-l", "127.0.0.1:${port}" },
			detached = vim.fn.has("win32") == 0,
		},
	})
end

local function args_input()
	local input = vim.fn.input("Arguments: ")
	return vim.split(input, " ", { trimempty = true })
end

dap.configurations.go = {
	{
		type = "go",
		name = "Debug file",
		request = "launch",
		program = "${file}",
	},
	{
		type = "go",
		name = "Debug file (args)",
		request = "launch",
		program = "${file}",
		args = args_input,
	},
	{
		type = "go",
		name = "Debug package",
		request = "launch",
		program = "${fileDirname}",
	},
	{
		type = "go",
		name = "Debug test (file package)",
		request = "launch",
		mode = "test",
		program = "${fileDirname}",
	},
	{
		type = "go",
		name = "Debug test (module root)",
		request = "launch",
		mode = "test",
		program = "./${relativeFileDirname}",
	},
	{
		type = "go",
		name = "Attach to process",
		request = "attach",
		mode = "local",
		processId = require("dap.utils").pick_process,
	},
	{
		type = "go",
		name = "Attach remote (127.0.0.1:38697)",
		request = "attach",
		mode = "remote",
		host = "127.0.0.1",
		port = 38697,
	},
}
