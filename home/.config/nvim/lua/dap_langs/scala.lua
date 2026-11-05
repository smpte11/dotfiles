local dap = require("dap")

local function metals_client()
	return vim.lsp.get_clients({ name = "metals", bufnr = 0 })[1]
end

local function pick_build_target(filter)
	return coroutine.create(function(co)
		local client = metals_client()
		if not client then
			vim.notify("Metals is not attached", vim.log.levels.ERROR)
			return coroutine.resume(co, dap.ABORT)
		end
		client:request("workspace/executeCommand", { command = "metals.list-build-targets" }, function(err, targets)
			targets = vim.tbl_filter(filter, err and {} or targets or {})
			if #targets == 0 then
				vim.notify("Metals reports no matching build target", vim.log.levels.ERROR)
				return coroutine.resume(co, dap.ABORT)
			end
			if #targets == 1 then return coroutine.resume(co, targets[1]) end
			vim.ui.select(targets, { prompt = "Build target" }, function(choice) coroutine.resume(co, choice or dap.ABORT) end)
		end)
	end)
end

local function is_test_target(name)
	return vim.endswith(name, "-test")
end

local function free_port()
	local tcp = assert(vim.uv.new_tcp())
	tcp:bind("127.0.0.1", 0)
	local port = assert(tcp:getsockname()).port
	tcp:close()
	return port
end

local scala_cli_jobs = {}

local function scala_cli_test()
	return coroutine.create(function(co)
		local client = metals_client()
		local root = client and client.root_dir or vim.fn.getcwd()
		local port = free_port()
		local resumed = false
		local function resume(value)
			if resumed then return end
			resumed = true
			vim.schedule(function() coroutine.resume(co, value) end)
		end
		local job = vim.system(
			{ "scala-cli", "test", root, "--debug-mode", "attach", "--debug-port", tostring(port) },
			{
				cwd = root,
				text = true,
				stdout = function(_, data)
					if data and data:find("Listening for transport dt_socket") then resume(port) end
				end,
				stderr = function(_, data)
					if data and data:find("Listening for transport dt_socket") then resume(port) end
				end,
			},
			function(out)
				scala_cli_jobs[port] = nil
				if not resumed then
					vim.schedule(function() vim.notify("scala-cli test exited with code " .. out.code, vim.log.levels.ERROR) end)
					resume(dap.ABORT)
				end
			end
		)
		scala_cli_jobs[port] = job
	end)
end

dap.listeners.after.event_terminated.scala_cli = function(session)
	local job = scala_cli_jobs[session.config.port]
	if job then job:kill(15) end
end

dap.configurations.scala = {
	{
		type = "scala",
		request = "launch",
		name = "Run Main",
		metals = { mainClass = "Main" },
	},
	{
		type = "scala",
		request = "attach",
	{
		type = "scala",
		request = "attach",
		name = "Debug tests (scala-cli)",
		hostName = "localhost",
		port = scala_cli_test,
		buildTarget = function() return pick_build_target(is_test_target) end,
	},
	{
		type = "scala",
		request = "attach",
		name = "Attach to test (JDWP 5005)",
		hostName = "localhost",
		port = 5005,
	},
	},
}
