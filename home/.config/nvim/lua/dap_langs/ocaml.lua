local dap = require("dap")

local function project_root()
	return vim.fs.root(0, { "dune-project", "dune-workspace" }) or vim.fn.getcwd()
end

local function executable()
	local candidates = { project_root() .. "/_opam/bin/ocamlearlybird" }
	local prefix = vim.env.OPAM_SWITCH_PREFIX
	if prefix and prefix ~= "" then table.insert(candidates, prefix .. "/bin/ocamlearlybird") end
	for _, path in ipairs(candidates) do
		if vim.fn.executable(path) == 1 then return path end
	end
	return "ocamlearlybird"
end

local function build_and_pick()
	local root = project_root()
	local build = vim.system({ "dune", "build" }, { cwd = root, text = true }):wait()
	if build.code ~= 0 then
		vim.notify("dune build failed:\n" .. (build.stderr or ""), vim.log.levels.ERROR)
		return dap.ABORT
	end
	local found = vim.fn.glob(root .. "/_build/default/**/*.bc", false, true)
	found = vim.tbl_filter(function(path) return not path:find("/%.") end, found)
	if #found == 0 then
		vim.notify("No .bc found: add (modes byte exe) to the dune executable stanza", vim.log.levels.ERROR)
		return dap.ABORT
	end
	if #found == 1 then return found[1] end
	return coroutine.create(function(co)
		vim.ui.select(found, {
			prompt = "Bytecode program",
			format_item = function(path) return vim.fn.fnamemodify(path, ":.") end,
		}, function(choice) coroutine.resume(co, choice or dap.ABORT) end)
	end)
end

dap.listeners.before.stackTrace.ocaml_sources = function(session, err, response)
	if err or session.config.type ~= "ocamlearlybird" then return end
	local build_dir = session.config.cwd .. "/_build/default/"
	for _, frame in ipairs(response.stackFrames or {}) do
		local path = frame.source and frame.source.path
		if path and vim.startswith(path, build_dir) then
			local source = session.config.cwd .. "/" .. path:sub(#build_dir + 1)
			if vim.uv.fs_stat(source) then frame.source.path = source end
		end
	end
end

dap.adapters.ocamlearlybird = function(callback)
	callback({
		type = "executable",
		command = executable(),
		args = { "debug" },
	})
end

dap.configurations.ocaml = {
	{
		name = "OCaml: launch bytecode (dune build)",
		type = "ocamlearlybird",
		request = "launch",
		program = build_and_pick,
		cwd = project_root,
		stopOnEntry = false,
		yes = true,
	},
	{
		name = "OCaml: launch bytecode (path)",
		type = "ocamlearlybird",
		request = "launch",
		program = function()
			return vim.fn.input("Bytecode program: ", project_root() .. "/_build/default/", "file")
		end,
		cwd = project_root,
		stopOnEntry = false,
		yes = true,
	},
	{
		name = "OCaml: launch bytecode with arguments",
		type = "ocamlearlybird",
		request = "launch",
		program = build_and_pick,
		arguments = function()
			return vim.split(vim.fn.input("Arguments: "), " +", { trimempty = true })
		end,
		cwd = project_root,
		stopOnEntry = false,
		yes = true,
	},
}
