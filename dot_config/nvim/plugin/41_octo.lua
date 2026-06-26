-- octo.nvim: GitHub issues/PRs/reviews inside Neovim.
-- Kept in its own file for review/extension. Buffer-local keymaps and the
-- mini.clue group labels for them live in 'after/ftplugin/octo.lua'.

local add, later = vim.pack.add, Config.later

-- Read a resolved color (`fg`/`bg`) off the first existing highlight group,
-- so octo's palette tracks the active colorscheme instead of its hardcoded one.
local function hl(attr, groups, fallback)
	for _, g in ipairs(groups) do
		local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = g, link = false })
		if ok and h[attr] then
			return string.format("#%06x", h[attr])
		end
	end
	return fallback
end

local function octo_colors()
	return {
		white = hl("fg", { "Normal" }, "#ebfafa"),
		grey = hl("fg", { "Comment" }, "#7081d0"),
		-- Normal bg is transparent (NONE), so read an opaque bg for bubbles.
		black = hl("bg", { "Pmenu", "Visual", "NormalFloat" }, "#212337"),
		red = hl("fg", { "DiagnosticError", "Removed", "diffRemoved" }, "#f9515d"),
		dark_red = hl("fg", { "DiagnosticError", "Removed", "diffRemoved" }, "#f16c75"),
		green = hl("fg", { "DiagnosticOk", "Added", "diffAdded" }, "#37f499"),
		dark_green = hl("fg", { "DiagnosticOk", "Added", "diffAdded" }, "#69f8b3"),
		yellow = hl("fg", { "DiagnosticWarn", "Changed" }, "#e9f941"),
		dark_yellow = hl("fg", { "DiagnosticWarn", "Changed" }, "#f1fc79"),
		blue = hl("fg", { "DiagnosticInfo", "Function", "Directory" }, "#9071f4"),
		dark_blue = hl("fg", { "Function", "Directory", "DiagnosticInfo" }, "#a48cf2"),
		purple = hl("fg", { "Keyword", "Statement", "Special" }, "#f265b5"),
	}
end

-- Pure-terminal look: octo's *Bubble groups are colored-background "pills".
-- Flatten them to plain colored text (move the bg color to fg, drop the bg),
-- matching the flat OctoState* groups. Pill delimiters are disabled in setup().
local bubbles = {
	"OctoBubble",
	"OctoStateOpenBubble",
	"OctoStateClosedBubble",
	"OctoStateMergedBubble",
	"OctoStatePendingBubble",
	"OctoStateApprovedBubble",
	"OctoStateChangesRequestedBubble",
	"OctoStateDismissedBubble",
	"OctoStateCommentedBubble",
	"OctoStateSubmittedBubble",
}

local function flatten_bubbles()
	for _, name in ipairs(bubbles) do
		local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
		if ok and h.bg then
			vim.api.nvim_set_hl(0, name, { fg = h.bg, bg = "NONE" })
		end
	end
end

-- PR create/checkout are handled by jj.nvim (`:J` open_pr / fetch_pr), which
-- is jj-aware; octo's git-branch-based equivalents break in this colocated,
-- detached-HEAD repo. See keymaps in 'plugin/42_jj.lua'.

later(function()
	add({
		"https://github.com/pwntester/octo.nvim",
		"https://github.com/nvim-lua/plenary.nvim",
		"https://github.com/nvim-tree/nvim-web-devicons",
	})

	require("octo").setup({
		picker = "default", -- backed by mini.pick via vim.ui.select
		default_merge_method = "squash",
		colors = octo_colors(),
		-- Pure-terminal: no pill caps around bubbles (see flatten_bubbles).
		left_bubble_delimiter = "",
		right_bubble_delimiter = "",
		mappings = {
			-- Default <leader>qa collides with the global <Leader>q +Quit group;
			-- fold approve into the PR (<localleader>p) group instead.
			pull_request = { approve_pr = { lhs = "<localleader>pa", desc = "Approve PR" } },
		},
	})

	flatten_bubbles()
	Config.new_autocmd("ColorScheme", "*", flatten_bubbles, "Octo flat bubbles")

	-- Entry points under a dedicated <Leader>G +GitHub group (g is mini.git).
	-- PR create/checkout live under <Leader>J (jj.nvim), not here.
	local map = function(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { desc = desc })
	end
	map("<Leader>Gp", "<Cmd>Octo pr list<CR>", "PRs")
	map("<Leader>Gi", "<Cmd>Octo issue list<CR>", "Issues")
	map("<Leader>GI", "<Cmd>Octo issue create<CR>", "Issue create")
	map("<Leader>Gr", "<Cmd>Octo review start<CR>", "Review start")
	map("<Leader>GR", "<Cmd>Octo review resume<CR>", "Review resume")
	map("<Leader>Gn", "<Cmd>Octo notification list<CR>", "Notifications")
	map("<Leader>Gs", "<Cmd>Octo search<CR>", "Search GitHub")
end)
