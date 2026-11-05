local dap = require("dap")

dap.adapters.codelldb = function(callback)
	local adapter = require("rust_dap_adapter")()
	if not adapter then
		vim.notify("No codelldb or lldb-dap found", vim.log.levels.ERROR)
		return
	end
	callback(adapter)
end

local function notify_error(msg)
	vim.schedule(function() vim.notify(msg, vim.log.levels.ERROR) end)
	return dap.ABORT
end

local function pick(items, prompt, resume)
	if #items == 1 then return resume(items[1]) end
	vim.ui.select(items, { prompt = prompt }, function(choice) resume(choice or dap.ABORT) end)
end

local function cargo_json(args)
	local cmd = vim.list_extend({ "cargo" }, args)
	local out = vim.system(cmd, { text = true }):wait()
	if out.code ~= 0 then return nil, out.stderr end
	local messages = {}
	for line in out.stdout:gmatch("[^\n]+") do
		local ok, decoded = pcall(vim.json.decode, line)
		if ok and type(decoded) == "table" then table.insert(messages, decoded) end
	end
	return messages
end

local function build_executables(args, want)
	local messages, err = cargo_json(vim.list_extend({ "build", "--message-format=json" }, args))
	if not messages then return nil, err end
	local executables = {}
	for _, m in ipairs(messages) do
		if m.reason == "compiler-artifact" and m.executable and want(m) then
			table.insert(executables, m.executable)
		end
	end
	return executables
end

local function program_from(args, want, prompt)
	return function()
		return coroutine.create(function(co)
			vim.notify("cargo build...", vim.log.levels.INFO)
			local executables, err = build_executables(args, want)
			if not executables then return coroutine.resume(co, notify_error("cargo build failed: " .. err)) end
			if #executables == 0 then return coroutine.resume(co, notify_error("No executable produced")) end
			pick(executables, prompt, function(choice) coroutine.resume(co, choice) end)
		end)
	end
end

local function is_bin(m)
	return vim.tbl_contains(m.target.kind, "bin") and not m.profile.test
end

local function is_test(m)
	return m.profile.test
end

local function args_input()
	local input = vim.fn.input("Arguments: ")
	return vim.split(input, " ", { trimempty = true })
end

dap.configurations.rust = {
	{
		name = "Cargo: launch binary",
		type = "codelldb",
		request = "launch",
		program = program_from({}, is_bin, "Binary: "),
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
	},
	{
		name = "Cargo: launch binary (args)",
		type = "codelldb",
		request = "launch",
		program = program_from({}, is_bin, "Binary: "),
		args = args_input,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
	},
	{
		name = "Cargo: debug tests",
		type = "codelldb",
		request = "launch",
		program = program_from({ "--tests" }, is_test, "Test binary: "),
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
	},
	{
		name = "Launch executable",
		type = "codelldb",
		request = "launch",
		program = function() return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/target/debug/", "file") end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
	},
	{
		name = "Attach to process",
		type = "codelldb",
		request = "attach",
		pid = require("dap.utils").pick_process,
		cwd = "${workspaceFolder}",
	},
}
