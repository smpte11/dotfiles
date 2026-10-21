local function sh(args)
	local r = vim.system(args, { text = true }):wait()
	return r.code, vim.trim(r.stdout or ""), vim.trim(r.stderr or "")
end

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

local function gh_pr_create_jj()
	local bm = bookmark_at("@") or bookmark_at("@-")
	if not bm then
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
			local repo, num = (url or ""):match("github%.com/([^/]+/[^/]+)/pull/(%d+)")
			if num then
				vim.cmd.edit(string.format("gh://%s/pr/%s", repo, num))
			end
		end)
	end)
end

local function gh_pr_checkout_jj()
	local current = vim.b.snacks_gh
	local nr = current and current.type == "pr" and current.number or nil
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

vim.api.nvim_create_user_command("GhPrCreateJj", gh_pr_create_jj, { desc = "PR create (jj)" })
vim.api.nvim_create_user_command("GhPrCheckoutJj", gh_pr_checkout_jj, { desc = "PR checkout (jj)" })

local map = function(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { desc = desc })
end
map("<Leader>Gp", function()
	Snacks.picker.gh_pr()
end, "PRs")
map("<Leader>GP", "<Cmd>GhPrCreateJj<CR>", "PR create (jj)")
map("<Leader>Gc", "<Cmd>GhPrCheckoutJj<CR>", "PR checkout (jj)")
map("<Leader>Gi", function()
	Snacks.picker.gh_issue()
end, "Issues")
map("<Leader>GI", "<Cmd>tab terminal gh issue create<CR>", "Issue create")
map("<Leader>Gs", function()
	Snacks.picker.gh_pr({ state = "all" })
end, "PRs (all)")
map("<Leader>GS", function()
	Snacks.picker.gh_issue({ state = "all" })
end, "Issues (all)")
