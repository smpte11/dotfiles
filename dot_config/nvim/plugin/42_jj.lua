-- jj.nvim: in-editor Jujutsu client (log/status/diff buffers, `:J` command).
-- Kept in its own file for review/extension, mirroring 'plugin/41_octo.lua'.
-- Buffer-local tweaks for the jj buffers live in 'after/ftplugin/jjlog.lua'
-- and 'after/ftplugin/jjstatus.lua'.

local add, later = vim.pack.add, Config.later

-- Read a resolved color (`fg`/`bg`) off the first existing highlight group, so
-- the few hardcoded jj.nvim colors track the active colorscheme. Same approach
-- as octo (see 'plugin/41_octo.lua').
local function hl(attr, groups, fallback)
	for _, g in ipairs(groups) do
		local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = g, link = false })
		if ok and h[attr] then
			return string.format("#%06x", h[attr])
		end
	end
	return fallback
end

-- jj.nvim themes added/modified/deleted via Added/Changed/Removed (theme-aware),
-- but hardcodes log.selected/log.targeted/editor.renamed. Derive those too.
local function jj_highlights()
	return {
		editor = {
			renamed = { fg = hl("fg", { "DiagnosticWarn", "Changed" }, "#d29922") },
		},
		log = {
			selected = { bg = hl("bg", { "Visual", "PmenuSel", "Pmenu" }, "#3d2c52") },
			targeted = { fg = hl("fg", { "DiagnosticOk", "Added", "diffAdded" }, "#5a9e6f") },
		},
	}
end

later(function()
	-- codediff.nvim is jj.nvim's diff *viewer* backend (`:Jdiff`). It is distinct
	-- from hunk.nvim, which is jj's external diff *editor* (the `DiffEditor`
	-- command jj's CLI spawns for interactive split/squash). Different commands,
	-- different code paths, no conflict. codediff downloads a prebuilt binary, so
	-- (re)build it on install/update.
	Config.on_packchanged("codediff.nvim", { "install", "update" }, function()
		vim.cmd("CodeDiff install")
	end, ":CodeDiff install")

	add({
		"https://github.com/NicolasGB/jj.nvim",
		"https://github.com/esmuellert/codediff.nvim",
	})

	require("jj").setup({
		-- No snacks installed: pickers fall back to vim.ui.select, which is
		-- routed through mini.pick (see 'plugin/30_mini.lua').
		picker = {},
		diff = { backend = "codediff" },
		highlights = jj_highlights(),
	})

	Config.new_autocmd("ColorScheme", "*", function()
		require("jj").setup({ highlights = jj_highlights() })
	end, "jj.nvim highlight re-theme")

	-- Entry points under a dedicated <Leader>J +Jujutsu group (j is mini.jump2d,
	-- g is mini.git). Lowercase = common action, uppercase = variant.
	local map = function(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { desc = desc })
	end
	map("<Leader>Js", '<Cmd>lua require("jj.cmd").status()<CR>', "Status")
	map("<Leader>Jl", '<Cmd>lua require("jj.cmd").log()<CR>', "Log")
	map("<Leader>Jd", '<Cmd>lua require("jj.cmd").describe()<CR>', "Describe")
	map("<Leader>Jc", '<Cmd>lua require("jj.cmd").commit()<CR>', "Commit")
	map("<Leader>Jn", '<Cmd>lua require("jj.cmd").new()<CR>', "New")
	map("<Leader>JD", '<Cmd>lua require("jj.cmd").diff()<CR>', "Diff")
	map("<Leader>Jp", '<Cmd>lua require("jj.cmd").push()<CR>', "Push")
	map("<Leader>Jf", '<Cmd>lua require("jj.cmd").fetch()<CR>', "Fetch")
	map("<Leader>JP", '<Cmd>lua require("jj.cmd").open_pr()<CR>', "Open PR")
	map("<Leader>JF", '<Cmd>lua require("jj.cmd").fetch_pr()<CR>', "Fetch PR")
	map("<Leader>Ju", '<Cmd>lua require("jj.cmd").undo()<CR>', "Undo")
	map("<Leader>JU", '<Cmd>lua require("jj.cmd").redo()<CR>', "Redo")
	map("<Leader>Jq", '<Cmd>lua require("jj.cmd").squash()<CR>', "Squash")
	map("<Leader>Jr", '<Cmd>lua require("jj.cmd").rebase()<CR>', "Rebase")
	map("<Leader>Ja", '<Cmd>lua require("jj.cmd").abandon()<CR>', "Abandon")
	map("<Leader>Jb", '<Cmd>lua require("jj.cmd").bookmark_create()<CR>', "Bookmark create")
	map("<Leader>JR", '<Cmd>lua require("jj.cmd").resolve()<CR>', "Resolve")
	map("<Leader>Jx", '<Cmd>lua require("jj.cmd").split()<CR>', "Split")
	map("<Leader>JB", '<Cmd>lua require("jj.annotate").file()<CR>', "Blame")
end)
