local M = {}

local cache = {}

local function read_json(path)
	local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
	return ok and type(data) == "table" and data or {}
end

local function files_for(lang)
	local files, after = { vim.fn.stdpath("config") .. "/snippets/global.json" }, {}
	if lang == "" then
		return files
	end
	for _, pattern in ipairs({ "snippets/" .. lang .. ".json", "snippets/" .. lang .. "/*.json" }) do
		for _, file in ipairs(vim.api.nvim_get_runtime_file(pattern, true)) do
			table.insert(file:find("/after/snippets/", 1, true) and after or files, file)
		end
	end
	return vim.list_extend(files, after)
end

local function load(lang)
	if cache[lang] then
		return cache[lang]
	end
	local by_prefix = {}
	for _, file in ipairs(files_for(lang)) do
		for name, snippet in pairs(read_json(file)) do
			local prefixes = type(snippet.prefix) == "table" and snippet.prefix or { snippet.prefix or name }
			local body = type(snippet.body) == "table" and table.concat(snippet.body, "\n") or snippet.body
			for _, prefix in ipairs(prefixes) do
				by_prefix[prefix] = body and { body = body, description = snippet.description or name } or nil
			end
		end
	end
	cache[lang] = by_prefix
	return by_prefix
end

local variables = {
	CURRENT_YEAR = "%Y",
	CURRENT_YEAR_SHORT = "%y",
	CURRENT_MONTH = "%m",
	CURRENT_MONTH_NAME = "%B",
	CURRENT_MONTH_NAME_SHORT = "%b",
	CURRENT_DATE = "%d",
	CURRENT_DAY_NAME = "%A",
	CURRENT_DAY_NAME_SHORT = "%a",
	CURRENT_HOUR = "%H",
	CURRENT_MINUTE = "%M",
	CURRENT_SECOND = "%S",
}

local function resolve(body)
	return (body:gsub("%${?([%u_]+)}?", function(var)
		return variables[var] and os.date(variables[var]) or nil
	end))
end

local function items(buf)
	local result = {}
	for prefix, snippet in pairs(load(vim.bo[buf].filetype)) do
		table.insert(result, {
			label = prefix,
			kind = vim.lsp.protocol.CompletionItemKind.Snippet,
			insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
			insertText = resolve(snippet.body),
			detail = snippet.description,
			documentation = {
				kind = "markdown",
				value = "```" .. vim.bo[buf].filetype .. "\n" .. snippet.body .. "\n```",
			},
		})
	end
	return result
end

function M.server(dispatchers)
	local closing = false
	local id = 0
	return {
		request = function(method, params, callback)
			id = id + 1
			vim.schedule(function()
				if method == "initialize" then
					callback(nil, { capabilities = { completionProvider = {} } })
				elseif method == "textDocument/completion" then
					callback(nil, items(vim.uri_to_bufnr(params.textDocument.uri)))
				else
					callback(nil, nil)
				end
			end)
			return true, id
		end,
		notify = function(method)
			if method == "exit" then
				dispatchers.on_exit(0, 15)
			end
			return true
		end,
		is_closing = function()
			return closing
		end,
		terminate = function()
			closing = true
		end,
	}
end

return M
