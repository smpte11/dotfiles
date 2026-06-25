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

-- Pick a foreground (near-black or white) readable on the given bg by luminance.
local function readable_fg(bg)
	local r = tonumber(bg:sub(2, 3), 16)
	local g = tonumber(bg:sub(4, 5), 16)
	local b = tonumber(bg:sub(6, 7), 16)
	local lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255
	return lum > 0.55 and "#212337" or "#ebfafa"
end

-- octo's *Bubble groups are the only ones with a background; recompute their
-- fg for contrast so labels stay legible whatever the theme picks.
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

local function fix_bubble_contrast()
	for _, name in ipairs(bubbles) do
		local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
		if ok and h.bg then
			vim.api.nvim_set_hl(0, name, { bg = h.bg, fg = readable_fg(string.format("#%06x", h.bg)) })
		end
	end
end

-- jj integration ============================================================
-- This is a jj-collocated repo, so git HEAD is detached and octo's git-branch
-- assumptions break: `Octo pr create` reads `git rev-parse --abbrev-ref HEAD`
-- (returns "HEAD") and `gh pr checkout` moves git HEAD behind jj's back. These
-- commands drive jj instead. See the bound keys below.

-- Synchronous: only for the quick `jj log` reads below.
local function sh(args)
	local r = vim.system(args, { text = true }):wait()
	return r.code, vim.trim(r.stdout or ""), vim.trim(r.stderr or "")
end

-- Async: for the slow network ops (push/create/fetch) so the UI stays
-- responsive. Callback runs on the main loop with (code, stdout, stderr).
local function sh_async(args, on_done)
	vim.system(args, { text = true }, function(r)
		vim.schedule(function()
			on_done(r.code, vim.trim(r.stdout or ""), vim.trim(r.stderr or ""))
		end)
	end)
end

local function err(msg)
	vim.notify(msg, vim.log.levels.ERROR)
end

-- Local bookmark at a revision, or nil.
local function bookmark_at(rev)
	local code, out = sh({ "jj", "log", "-r", rev, "--no-graph", "-T", 'local_bookmarks.map(|b| b.name()).join("\n")' })
	if code ~= 0 or out == "" then
		return nil
	end
	return vim.split(out, "\n")[1]
end

local function rev_is_empty(rev)
	local _, out = sh({ "jj", "log", "-r", rev, "--no-graph", "-T", "empty" })
	return out == "true"
end

-- Push the change as a bookmark, then `gh pr create --fill`. The bookmark
-- usually sits on @- (@ is the empty working copy), so check @ then @-.
local function octo_pr_create_jj()
	local bm = bookmark_at("@") or bookmark_at("@-")
	if not bm then
		-- New bookmark targets the real change: @ if it has content, else @-.
		local rev = rev_is_empty("@") and "@-" or "@"
		bm = vim.trim(vim.fn.input({ prompt = "New bookmark for " .. rev .. " (PR head): " }))
		if bm == "" then
			return err("PR create aborted: no bookmark")
		end
		local c, _, e = sh({ "jj", "bookmark", "create", bm, "-r", rev })
		if c ~= 0 then
			return err("jj bookmark create failed: " .. e)
		end
	end
	vim.notify("Pushing bookmark '" .. bm .. "' ...")
	sh_async({ "jj", "git", "push", "--allow-new", "-b", bm }, function(c, _, e)
		if c ~= 0 then
			return err("jj git push failed: " .. e)
		end
		vim.notify("Creating PR ...")
		sh_async({ "gh", "pr", "create", "--fill", "--head", bm }, function(c2, o2, e2)
			if c2 ~= 0 then
				return err("gh pr create failed: " .. (e2 ~= "" and e2 or o2))
			end
			local url = o2:match("https://%S+")
			vim.notify("PR created: " .. (url or o2))
			local num = url and url:match("/pull/(%d+)")
			if num then
				vim.cmd("Octo pr edit " .. num)
			end
		end)
	end)
end

-- Check out a PR via jj. Same-repo: fetch + `jj new <head>@origin`. Fork: fall
-- back to `gh pr checkout` then `jj git import` to sync git refs into jj.
local function octo_pr_checkout_jj()
	local nr
	local ok, u = pcall(require, "octo.utils")
	if ok then
		local buf = u.get_current_buffer()
		if buf and buf:isPullRequest() then
			nr = buf:pullRequest().number
		end
	end
	if not nr then
		nr = tonumber(vim.trim(vim.fn.input({ prompt = "PR number to checkout: " })))
	end
	if not nr then
		return err("PR checkout aborted: no number")
	end
	vim.notify("Resolving PR #" .. nr .. " ...")
	sh_async({ "gh", "pr", "view", tostring(nr), "--json", "headRefName,isCrossRepository" }, function(c, o, e)
		if c ~= 0 then
			return err("gh pr view failed: " .. e)
		end
		local info = vim.json.decode(o)
		local done = function()
			vim.notify("Checked out PR #" .. nr)
		end
		if info.isCrossRepository then
			vim.notify("Fork PR; using gh checkout + jj git import ...")
			sh_async({ "gh", "pr", "checkout", tostring(nr) }, function(cc, _, ce)
				if cc ~= 0 then
					return err("gh pr checkout failed: " .. ce)
				end
				sh_async({ "jj", "git", "import" }, done)
			end)
		else
			vim.notify("Fetching " .. info.headRefName .. " ...")
			sh_async({ "jj", "git", "fetch", "-b", info.headRefName }, function(fc, _, fe)
				if fc ~= 0 then
					return err("jj git fetch failed: " .. fe)
				end
				sh_async({ "jj", "new", info.headRefName .. "@origin" }, function(nc, _, ne)
					if nc ~= 0 then
						return err("jj new failed: " .. ne)
					end
					done()
				end)
			end)
		end
	end)
end

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
		mappings = {
			-- Default <leader>qa collides with the global <Leader>q +Quit group;
			-- fold approve into the PR (<localleader>p) group instead.
			pull_request = { approve_pr = { lhs = "<localleader>pa", desc = "Approve PR" } },
		},
	})

	fix_bubble_contrast()
	Config.new_autocmd("ColorScheme", "*", fix_bubble_contrast, "Octo bubble contrast")

	-- jj-native replacements for octo's git-branch create/checkout.
	vim.api.nvim_create_user_command("OctoPrCreateJj", octo_pr_create_jj, { desc = "PR create (jj)" })
	vim.api.nvim_create_user_command("OctoPrCheckoutJj", octo_pr_checkout_jj, { desc = "PR checkout (jj)" })

	-- Entry points under a dedicated <Leader>G +GitHub group (g is mini.git).
	local map = function(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { desc = desc })
	end
	map("<Leader>Gp", "<Cmd>Octo pr list<CR>", "PRs")
	map("<Leader>GP", "<Cmd>OctoPrCreateJj<CR>", "PR create (jj)")
	map("<Leader>Gc", "<Cmd>OctoPrCheckoutJj<CR>", "PR checkout (jj)")
	map("<Leader>Gi", "<Cmd>Octo issue list<CR>", "Issues")
	map("<Leader>GI", "<Cmd>Octo issue create<CR>", "Issue create")
	map("<Leader>Gr", "<Cmd>Octo review start<CR>", "Review start")
	map("<Leader>GR", "<Cmd>Octo review resume<CR>", "Review resume")
	map("<Leader>Gn", "<Cmd>Octo notification list<CR>", "Notifications")
	map("<Leader>Gs", "<Cmd>Octo search<CR>", "Search GitHub")
end)
