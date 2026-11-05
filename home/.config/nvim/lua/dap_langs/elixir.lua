local dap = require("dap")

local function debugger()
	for _, candidate in ipairs({ "elixir-debug-adapter", "elixir-ls-debugger" }) do
		local path = vim.fn.exepath(candidate)
		if path ~= "" then return path end
	end
	return "elixir-debug-adapter"
end

local function project_dir()
	local root = vim.fs.root(0, { "mix.exs" }) or vim.fn.getcwd()
	return root
end

dap.adapters.mix_task = function(callback)
	callback({
		type = "executable",
		command = debugger(),
		args = {},
	})
end

local function mix_task(name, task, extra)
	return vim.tbl_extend("force", {
		type = "mix_task",
		name = name,
		request = "launch",
		task = task,
		projectDir = project_dir,
		exitAfterTaskReturns = false,
		debugAutoInterpretAllModules = false,
	}, extra or {})
end

local function test_file()
	return { vim.fn.expand("%:p") }
end

dap.configurations.elixir = {
	mix_task("mix test (current file)", "test", {
		taskArgs = test_file,
		startApps = true,
		requireFiles = {
			"test/**/test_helper.exs",
			"test/**/*_test.exs",
		},
	}),
	mix_task("mix test (all)", "test", {
		taskArgs = {},
		startApps = true,
		requireFiles = {
			"test/**/test_helper.exs",
			"test/**/*_test.exs",
		},
	}),
	mix_task("mix run", "run", { startApps = true }),
	mix_task("mix phx.server", "phx.server", { startApps = true }),
	mix_task("mix run (current file)", "run", {
		taskArgs = test_file,
		startApps = true,
	}),
}
