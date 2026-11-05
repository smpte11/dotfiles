local dap = require("dap")

local function venv_python(root)
	local venv = vim.env.VIRTUAL_ENV
	if venv and venv ~= "" and vim.fn.executable(venv .. "/bin/python") == 1 then
		return venv .. "/bin/python"
	end
	local found = vim.fs.find(".venv", { path = root, upward = true, type = "directory" })[1]
	if found and vim.fn.executable(found .. "/bin/python") == 1 then return found .. "/bin/python" end
	for _, name in ipairs({ "python3", "python" }) do
		local exe = vim.fn.exepath(name)
		if exe ~= "" then return exe end
	end
	return "python3"
end

local function has_debugpy(python)
	vim.fn.system({ python, "-c", "import debugpy" })
	return vim.v.shell_error == 0
end

local function debugpy_command(root)
	local adapter = vim.fn.exepath("debugpy-adapter")
	if adapter ~= "" then return adapter, {} end
	local project = venv_python(root)
	if has_debugpy(project) then return project, { "-m", "debugpy.adapter" } end
	vim.fn.system({ "uv", "--version" })
	if vim.v.shell_error == 0 then
		return "uv", { "tool", "run", "--from", "debugpy", "python", "-m", "debugpy.adapter" }
	end
	return project, { "-m", "debugpy.adapter" }
end

dap.adapters.python = function(callback, config)
	if config.request == "attach" then
		local port = (config.connect or config).port
		local host = (config.connect or config).host or "127.0.0.1"
		callback({ type = "server", port = assert(port, "`connect.port` is required"), host = host, options = { source_filetype = "python" } })
		return
	end
	local root = vim.fn.getcwd()
	local command, args = debugpy_command(root)
	callback({
		type = "executable",
		command = command,
		args = args,
		options = { source_filetype = "python" },
	})
end

local function python_path()
	return venv_python(vim.fn.getcwd())
end

local function pick_args()
	local input = vim.fn.input("Arguments: ")
	return vim.split(input, " ", { trimempty = true })
end

dap.configurations.python = {
	{
		type = "python",
		request = "launch",
		name = "Launch file",
		program = "${file}",
		cwd = "${workspaceFolder}",
		console = "integratedTerminal",
		justMyCode = false,
		pythonPath = python_path,
	},
	{
		type = "python",
		request = "launch",
		name = "Launch file with arguments",
		program = "${file}",
		args = pick_args,
		cwd = "${workspaceFolder}",
		console = "integratedTerminal",
		justMyCode = false,
		pythonPath = python_path,
	},
	{
		type = "python",
		request = "launch",
		name = "Launch module",
		module = function() return vim.fn.input("Module: ") end,
		cwd = "${workspaceFolder}",
		console = "integratedTerminal",
		justMyCode = false,
		pythonPath = python_path,
	},
	{
		type = "python",
		request = "launch",
		name = "Pytest current file",
		module = "pytest",
		args = { "${file}", "-s" },
		cwd = "${workspaceFolder}",
		console = "integratedTerminal",
		justMyCode = false,
		pythonPath = python_path,
	},
	{
		type = "python",
		request = "attach",
		name = "Attach to debugpy (127.0.0.1:5678)",
		connect = function()
			local host = vim.fn.input("Host: ", "127.0.0.1")
			local port = tonumber(vim.fn.input("Port: ", "5678"))
			return { host = host, port = port }
		end,
		justMyCode = false,
	},
	{
		type = "python",
		request = "attach",
		name = "Attach to process",
		processId = require("dap.utils").pick_process,
		justMyCode = false,
	},
}
