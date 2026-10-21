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
	return "%#StatusMode" .. m[1] .. "# " .. m[2] .. " %*"
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
		"%#StatusInfo#",
		wide and section(vcs()) or "",
		section(diagnostics()),
		wide and section(lsp()) or "",
		"%#StatusLine# %f%m%r %=",
		"%#StatusInfo#",
		section(vim.bo.filetype),
		mode():match("^%%#[^#]+#") or "",
		" %l:%v %P ",
	})
end

local mode_sources = {
	Normal = "Function",
	Insert = "String",
	Visual = "Keyword",
	Replace = "DiagnosticError",
	Command = "Constant",
	Other = "Type",
}

local function fg(group)
	return vim.api.nvim_get_hl(0, { name = group, link = false }).fg
end

local function set_highlights()
	local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
	for name, source in pairs(mode_sources) do
		vim.api.nvim_set_hl(0, "StatusMode" .. name, { fg = bg, bg = fg(source), bold = true })
	end
	local line = vim.api.nvim_get_hl(0, { name = "StatusLine", link = false })
	vim.api.nvim_set_hl(
		0,
		"StatusInfo",
		{ fg = line.fg, bg = vim.api.nvim_get_hl(0, { name = "CursorLine", link = false }).bg }
	)
end

set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("statusline", { clear = true }),
	callback = set_highlights,
})
vim.api.nvim_create_autocmd({ "ModeChanged", "DiagnosticChanged", "LspAttach", "LspDetach" }, {
	group = "statusline",
	command = "redrawstatus",
})

return M
