local M = {}

local cache = {}

local function fetch(root)
	local entry = cache[root]
	if entry.inflight then
		return
	end
	entry.inflight = true
	vim.system({
		"jj", "log", "-r", "@", "--no-graph", "--ignore-working-copy",
		"--repository", root,
		"-T", 'change_id.shortest() ++ " " ++ parents.map(|c| c.change_id().shortest()).join(",")',
	}, { text = true }, function(res)
		entry.inflight = false
		entry.ts = vim.uv.hrtime() / 1e9
		if res.code ~= 0 then
			return
		end
		local wc, parents = res.stdout:match("^(%S+)%s*(%S*)")
		if wc then
			entry.value = "@ " .. wc .. (parents ~= "" and (" ← " .. parents) or "")
			vim.schedule(function()
				vim.cmd("redrawstatus")
			end)
		end
	end)
end

function M.status(root)
	local entry = cache[root] or { value = "JJ", ts = 0, inflight = false }
	cache[root] = entry
	if (vim.uv.hrtime() / 1e9) - entry.ts > 5 then
		fetch(root)
	end
	local out = entry.value
	local ok, detection = pcall(require, "jj-conflict.detection")
	if ok then
		local conflicts = detection.detect_conflicts(0)
		if conflicts and #conflicts > 0 then
			out = out .. " ✗ " .. #conflicts
		end
	end
	return out
end

function M.find_root(bufnr)
	local f = vim.api.nvim_buf_get_name(bufnr or 0)
	local start = f ~= "" and vim.fs.dirname(f) or vim.uv.cwd()
	return vim.fs.root(start, ".jj")
end

vim.api.nvim_create_autocmd("FocusGained", {
	group = vim.api.nvim_create_augroup("JjStatuslineRefresh", { clear = true }),
	callback = function()
		for _, e in pairs(cache) do
			e.ts = 0
		end
	end,
})

return M
