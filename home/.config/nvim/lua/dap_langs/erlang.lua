local dap = require("dap")

dap.adapters["erlang-edb"] = { type = "executable", command = "edb", args = { "dap" } }

local function project_root()
	local root = vim.fs.root(0, { "rebar.config", "rebar.config.script" })
	return root or vim.fn.getcwd()
end

local function rebar3_run(rebar_args)
	local args = { "/bin/sh", "-c", 'exec "$0" "$@" --eval="$EDB_DAP_DEBUGGEE_INIT"', "rebar3", "as", "test" }
	vim.list_extend(args, rebar_args)
	return args
end

local function launch(name, rebar_args)
	return setmetatable({ type = "erlang-edb", request = "launch", name = name }, {
		__call = function()
			local root = project_root()
			return {
				type = "erlang-edb",
				request = "launch",
				name = name,
				run = { cwd = root, args = rebar3_run(rebar_args) },
				config = {
					nameDomain = "shortnames",
					nodeInitCodeInEnvVar = "EDB_DAP_DEBUGGEE_INIT",
					timeout = 120,
				},
			}
		end,
	})
end

local attach = setmetatable({ type = "erlang-edb", request = "attach", name = "Attach to running node" }, {
	__call = function()
		local root = project_root()
		local cookie = vim.fn.input("Cookie: ")
		return {
			type = "erlang-edb",
			request = "attach",
			name = "Attach to running node",
			config = {
				node = vim.fn.input("Node: ", "devel@localhost"),
				cookie = cookie ~= "" and cookie or nil,
				cwd = root,
			},
		}
	end,
})

dap.configurations.erlang = {
	launch("rebar3 shell (test profile)", { "shell" }),
	attach,
}
