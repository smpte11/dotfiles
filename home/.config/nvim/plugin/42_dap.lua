local add, later = vim.pack.add, Config.later

Config.dap_clues = {
	{ mode = "n", keys = "<Leader>d", desc = "+Debug" },
	{ mode = "x", keys = "<Leader>d", desc = "+Debug" },
}

for _, key in ipairs({ "c", "C", "n", "i", "o", "k", "j", "p" }) do
	table.insert(Config.dap_clues, { mode = "n", keys = "<Leader>d" .. key, postkeys = "<Leader>d" })
end

later(function()
	add({
		"https://github.com/mfussenegger/nvim-dap",
		"https://github.com/igorlfs/nvim-dap-view",
		"https://github.com/theHamsta/nvim-dap-virtual-text",
	})

	local dap = require("dap")
	local widgets = require("dap.ui.widgets")

	require("dap-view").setup({ auto_toggle = true })
	require("nvim-dap-virtual-text").setup({ commented = true })

	vim.fn.sign_define({
		{ name = "DapBreakpoint", text = "●", texthl = "DiagnosticError" },
		{ name = "DapBreakpointCondition", text = "◆", texthl = "DiagnosticWarn" },
		{ name = "DapBreakpointRejected", text = "○", texthl = "DiagnosticHint" },
		{ name = "DapLogPoint", text = "◉", texthl = "DiagnosticInfo" },
		{ name = "DapStopped", text = "▶", texthl = "DiagnosticOk", linehl = "Visual" },
	})

	local conditional_breakpoint = function()
		vim.ui.input({ prompt = "Condition: " }, function(cond)
			if cond and cond ~= "" then dap.set_breakpoint(cond) end
		end)
	end
	local log_point = function()
		vim.ui.input({ prompt = "Log message: " }, function(msg)
			if msg and msg ~= "" then dap.set_breakpoint(nil, nil, msg) end
		end)
	end

	local map = function(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { desc = desc })
	end

	map("n", "<Leader>db", dap.toggle_breakpoint, "Breakpoint toggle")
	map("n", "<Leader>dB", conditional_breakpoint, "Breakpoint condition")
	map("n", "<Leader>dL", log_point, "Log point")
	map("n", "<Leader>dx", dap.clear_breakpoints, "Breakpoints clear")
	map("n", "<Leader>dc", dap.continue, "Continue / start")
	map("n", "<Leader>dC", dap.run_to_cursor, "Run to cursor")
	map("n", "<Leader>dl", dap.run_last, "Run last")
	map("n", "<Leader>dn", dap.step_over, "Step over")
	map("n", "<Leader>di", dap.step_into, "Step into")
	map("n", "<Leader>do", dap.step_out, "Step out")
	map("n", "<Leader>dk", dap.up, "Frame up")
	map("n", "<Leader>dj", dap.down, "Frame down")
	map("n", "<Leader>dp", dap.pause, "Pause")
	map("n", "<Leader>dr", dap.repl.toggle, "REPL toggle")
	map("n", "<Leader>dt", dap.terminate, "Terminate")
	map("n", "<Leader>dv", "<Cmd>DapViewToggle<CR>", "View toggle")
	map("n", "<Leader>dw", "<Cmd>DapViewWatch<CR>", "Watch expression")
	map({ "n", "x" }, "<Leader>dh", widgets.hover, "Hover value")
	map("n", "<Leader>ds", function() widgets.centered_float(widgets.scopes) end, "Scopes")

	for _, file in ipairs(vim.api.nvim_get_runtime_file("lua/dap_langs/*.lua", true)) do
		local lang = vim.fn.fnamemodify(file, ":t:r")
		local ok, err = pcall(require, "dap_langs." .. lang)
		if not ok then vim.notify("DAP " .. lang .. ": " .. err, vim.log.levels.WARN) end
	end
end)
