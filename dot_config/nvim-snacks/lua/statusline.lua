local M = {}

local modes = {
	n = { "Normal", "N" },
	v = { "Visual", "V" },
	V = { "Visual", "V-L" },
	["\22"] = { "Visual", "V-B" },
	s = { "Visual", "S" },
	S = { "Visual", "S-L" },
	["\19"] = { "Visual", "S-B" },
	i = { "Insert", "I" },
	R = { "Replace", "R" },
	c = { "Command", "C" },
	r = { "Other", "P" },
	["!"] = { "Other", "Sh" },
	t = { "Other", "T" },
}

local function mode()
	local m = modes[vim.fn.mode():sub(1, 1)] or modes.n
	return "%#MiniStatuslineMode" .. m[1] .. "# " .. m[2] .. " %*"
end

local function vcs()
	local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
	local jj = require("jj_statusline")
	local root = jj.find_root(buf)
	local head = root and jj.status(root) or vim.b[buf].gitsigns_head
	if not head or head == "" then
		return ""
	end
	local changes = vim.b[buf].gitsigns_status or ""
	return " " .. head .. (changes ~= "" and (" " .. changes) or "")
end

local function diagnostics()
	local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
	return vim.diagnostic.status(buf)
end

local function lsp()
	local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
	local names = vim.tbl_map(function(c)
		return c.name
	end, vim.lsp.get_clients({ bufnr = buf }))
	names = vim.tbl_filter(function(n)
		return n ~= "snippets"
	end, names)
	return #names > 0 and ("󰰎 " .. table.concat(names, ",")) or ""
end

local function section(text)
	return text ~= "" and (" " .. text .. " ") or ""
end

function M.render()
	local wide = vim.o.columns > 100
	return table.concat({
		mode(),
		"%#MiniStatuslineDevinfo#",
		wide and section(vcs()) or "",
		section(diagnostics()),
		wide and section(lsp()) or "",
		"%#MiniStatuslineFilename# %f%m%r %=",
		"%#MiniStatuslineFileinfo#",
		section(vim.bo.filetype),
		mode():match("^%%#[^#]+#") or "",
		" %l:%v %P ",
	})
end

local fallbacks = {
	MiniStatuslineModeNormal = "Cursor",
	MiniStatuslineModeInsert = "DiffChange",
	MiniStatuslineModeVisual = "DiffAdd",
	MiniStatuslineModeReplace = "DiffDelete",
	MiniStatuslineModeCommand = "DiffText",
	MiniStatuslineModeOther = "IncSearch",
	MiniStatuslineDevinfo = "StatusLine",
	MiniStatuslineFilename = "StatusLineNC",
	MiniStatuslineFileinfo = "StatusLine",
}

local function set_fallbacks()
	for group, link in pairs(fallbacks) do
		if vim.tbl_isempty(vim.api.nvim_get_hl(0, { name = group })) then
			vim.api.nvim_set_hl(0, group, { link = link })
		end
	end
end

set_fallbacks()
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("statusline", { clear = true }),
	callback = set_fallbacks,
})
vim.api.nvim_create_autocmd({ "ModeChanged", "DiagnosticChanged", "LspAttach", "LspDetach" }, {
	group = "statusline",
	command = "redrawstatus",
})

return M
