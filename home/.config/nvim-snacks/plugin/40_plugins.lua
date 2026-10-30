local add = vim.pack.add
local now_if_args, later = Config.now_if_args, Config.later

now_if_args(function()
	local ts_update = function()
		vim.cmd("TSUpdate")
	end
	Config.on_packchanged("nvim-treesitter", { "update" }, ts_update, ":TSUpdate")

	add({
		"https://github.com/nvim-treesitter/nvim-treesitter",
		"https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
	})

	local languages = {
		"lua",
		"vimdoc",
		"markdown",
		"nu",
		"erlang",
		"yaml",
		"elixir",
		"heex",
		"go",
		"gomod",
		"gosum",
		"gotmpl",
		"ocaml",
		"ocaml_interface",
	}
	local isnt_installed = function(lang)
		return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0
	end
	local to_install = vim.tbl_filter(isnt_installed, languages)
	if #to_install > 0 then
		require("nvim-treesitter").install(to_install)
	end

	local filetypes = {}
	for _, lang in ipairs(languages) do
		for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
			table.insert(filetypes, ft)
		end
	end
	local ts_start = function(ev)
		vim.treesitter.start(ev.buf)
	end
	Config.new_autocmd("FileType", filetypes, ts_start, "Start tree-sitter")
end)

now_if_args(function()
	vim.lsp.enable({
		"lua_ls",
		"elp",
		"nushell",
		"gopls",
		"expert",
		"yamlls",
		"ocamllsp",
		"snippets",
	})
end)

now_if_args(function()
	local on_attach = function(ev)
		vim.lsp.completion.enable(true, ev.data.client_id, ev.buf)
	end
	Config.new_autocmd("LspAttach", nil, on_attach, "Enable LSP completion")
end)

later(function()
	local pum_selected = function()
		return vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected ~= -1
	end
	local tab = function(direction, pum_key)
		return function()
			if vim.fn.pumvisible() == 1 then
				return pum_key
			end
			if vim.snippet.active({ direction = direction }) then
				return string.format("<Cmd>lua vim.snippet.jump(%d)<CR>", direction)
			end
			return direction == 1 and "<Tab>" or "<S-Tab>"
		end
	end
	vim.keymap.set({ "i", "s" }, "<Tab>", tab(1, "<C-n>"), { expr = true, desc = "Next item or tabstop" })
	vim.keymap.set({ "i", "s" }, "<S-Tab>", tab(-1, "<C-p>"), { expr = true, desc = "Previous item or tabstop" })
	vim.keymap.set("i", "<CR>", function()
		if pum_selected() then
			return vim.keycode("<C-y>")
		end
		return MiniPairs.cr()
	end, { expr = true, replace_keycodes = false, desc = "Accept item or newline" })
end)

-- later(function()
-- 	add({ { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1") } })
-- 	vim.o.autocomplete = false
-- 	require("blink.cmp").setup({
-- 		keymap = { preset = "super-tab" },
-- 		completion = { documentation = { auto_show = true } },
-- 		sources = { default = { "lsp", "path", "snippets", "buffer" } },
-- 	})
-- end)

later(function()
	add({ "https://github.com/stevearc/conform.nvim" })

	require("conform").setup({
		default_format_opts = {
			lsp_format = "fallback",
		},
		formatters_by_ft = {
			lua = { "stylua" },
			erlang = { "erlfmt" },
			json = { "prettierd", "prettier" },
			markdown = { "wikilink_table_to_md", "prettierd", "prettier" },
			elixir = { "mix" },
			heex = { "mix" },
			go = { "goimports", "gofumpt" },
			ocaml = { "ocamlformat" },
			cucumber = { "reformat-gherkin" },
		},
		formatters = {
			erlfmt = {
				command = "rebar3",
				args = { "fmt", "$FILENAME" },
				stdin = false,
			},
			mix = {
				env = { MIX_ENV = "test" },
			},
			wikilink_table_to_md = {
				command = "perl",
				args = {
					"-pe",
					[==[if (/^\s*\|/) { s{\[\[(.*?)\]\]}{ my $i=$1; if ($i=~/\|/) { my($h,$l)=split(/\|/,$i,2); $h=~s/^\s+|\s+$//g; $l=~s/^\s+|\s+$//g; $h.=".md" unless ($h=~m{://}||$h=~/\.[A-Za-z0-9]+$/); "[$l]($h)" } else { "[[$i]]" } }ge; }]==],
				},
				stdin = true,
			},
		},
	})
end)

later(function()
	add({ "https://github.com/mfussenegger/nvim-lint" })

	require("lint").linters_by_ft = {
		elixir = { "credo" },
		markdown = { "markdownlint-cli2" },
	}

	vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
		group = vim.api.nvim_create_augroup("nvim-lint", {}),
		callback = function()
			require("lint").try_lint()
		end,
	})
end)

later(function()
	add({ "https://github.com/lewis6991/gitsigns.nvim" })
	local gs = require("gitsigns")
	gs.setup({
		on_attach = function(buf)
			local map = function(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
			end
			map("n", "]h", function()
				gs.nav_hunk("next")
			end, "Hunk forward")
			map("n", "[h", function()
				gs.nav_hunk("prev")
			end, "Hunk backward")
			map("n", "]H", function()
				gs.nav_hunk("last")
			end, "Hunk last")
			map("n", "[H", function()
				gs.nav_hunk("first")
			end, "Hunk first")
			map("n", "gh", gs.stage_hunk, "Apply hunk")
			map("n", "gH", gs.reset_hunk, "Reset hunk")
			map("x", "gh", function()
				gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Apply hunk")
			map("x", "gH", function()
				gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Reset hunk")
			map({ "o", "x" }, "ih", gs.select_hunk, "Hunk")
		end,
	})

	local overlay = false
	Config.toggle_git_overlay = function()
		overlay = not overlay
		gs.toggle_linehl(overlay)
		gs.toggle_word_diff(overlay)
		gs.toggle_deleted(overlay)
	end
end)

later(function()
	add({
		"https://github.com/ray-x/go.nvim",
		"https://github.com/ray-x/guihua.lua",
	})
	require("go").setup({
		lsp_cfg = false,
		lsp_gofumpt = false,
		lsp_on_client_start = nil,
	})

	vim.filetype.add({
		extension = {
			tmpl = function(path, _)
				local dir = vim.fs.dirname(path)
				if vim.fs.find("go.mod", { path = dir, upward = true })[1] then
					return "gotmpl"
				end
			end,
		},
	})
end)

later(function()
	add({ "https://github.com/rafamadriz/friendly-snippets" })
end)

now_if_args(function()
	add({ "https://github.com/mason-org/mason.nvim" })
	require("mason").setup({
		install_root_dir = vim.fs.joinpath(vim.fs.dirname(vim.fn.stdpath("data")), "nvim", "mason"),
	})
end)

now_if_args(function()
	local provider = vim.env.NVIM_AI_PROVIDER or "copilot"
	local keymap = { accept = "<M-y>", next = "<M-]>", prev = "<M-[>", dismiss = "<M-d>" }
	local debounce = 75

	local function setup_copilot()
		add({ "https://github.com/zbirenbaum/copilot.lua" })
		require("copilot").setup({
			suggestion = {
				enabled = true,
				auto_trigger = true,
				hide_during_completion = true,
				debounce = debounce,
				keymap = vim.tbl_extend("force", keymap, { accept_word = false, accept_line = false }),
			},
			panel = { enabled = false },
			filetypes = {
				yaml = true,
				markdown = true,
				help = false,
				gitcommit = true,
				gitrebase = false,
				["."] = false,
			},
		})
	end

	local function setup_minuet()
		add({ "https://github.com/milanglacier/minuet-ai.nvim" })
		require("minuet").setup({
			provider = provider,
			debounce = debounce,
			virtualtext = {
				auto_trigger_ft = { "*" },
				auto_trigger_ignore_ft = { "help", "gitrebase" },
				show_on_completion_menu = false,
				keymap = keymap,
			},
		})
	end

	local function map_toggle(toggle, is_on)
		vim.keymap.set("n", "\\a", function()
			toggle()
			vim.notify("AI completion: " .. (is_on() and "on" or "off"))
		end, { desc = "Toggle AI completion" })
	end

	if provider == "off" then
		return
	elseif provider == "copilot" then
		setup_copilot()
		map_toggle(function()
			require("copilot.suggestion").toggle_auto_trigger()
		end, function()
			return vim.b.copilot_suggestion_auto_trigger
		end)
	else
		setup_minuet()
		map_toggle(function()
			vim.b.minuet_virtual_text_auto_trigger = not vim.b.minuet_virtual_text_auto_trigger
		end, function()
			return vim.b.minuet_virtual_text_auto_trigger
		end)
	end
end)

later(function()
	add({ "https://github.com/zk-org/zk-nvim" })
	require("zk").setup({
		picker = "snacks_picker",
		lsp = {
			config = {
				name = "zk",
				cmd = { "zk", "lsp" },
				filetypes = { "markdown" },
			},
			auto_attach = {
				enabled = true,
			},
		},
	})

	require("which-key").add({
		{ "<Leader>n", group = "Notes", mode = { "n", "x" } },
		{ "<Leader>nj", group = "Journal" },
		{ "<Leader>nn", group = "New", mode = "x" },
	})
end)

later(function()
	add({ "https://github.com/OXY2DEV/markview.nvim" })
	require("markview").setup({
		preview = {
			icon_provider = "devicons",
			filetypes = { "markdown" },
			ignore_buftypes = {},
			modes = { "n", "i", "no", "c" },
			hybrid_modes = { "n", "i" },
			linewise_hybrid_mode = true,
		},
	})
end)

Config.now(function()
	add({ "https://github.com/esmuellert/codediff.nvim" })
	require("codediff").setup({
		keymaps = {
			view = {
				toggle_explorer = "<Tab>",
				focus_explorer = "<S-Tab>",
			},
			conflict = {
				accept_incoming = "<LocalLeader>t",
				accept_current = "<LocalLeader>o",
				accept_both = "<LocalLeader>b",
				discard = "<LocalLeader>0",
				accept_all_incoming = "<LocalLeader>T",
				accept_all_current = "<LocalLeader>O",
				accept_all_both = "<LocalLeader>B",
				discard_all = "<LocalLeader>X",
				next_conflict = "<LocalLeader>n",
				prev_conflict = "<LocalLeader>p",
			},
		},
	})
	Config.new_autocmd("BufEnter", "*", function()
		local buf = vim.api.nvim_get_current_buf()
		vim.defer_fn(function()
			if not vim.api.nvim_buf_is_valid(buf) then
				return
			end
			local is_codediff = false
			for _, m in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
				if m.lhs == "]c" and m.desc == "Next hunk" then
					is_codediff = true
					break
				end
			end
			if not is_codediff then
				return
			end
			local map = function(lhs, rhs, desc)
				vim.keymap.set("n", lhs, rhs, { buffer = buf, remap = true, silent = true, desc = desc })
			end
			map("<LocalLeader>t", "do", "Accept theirs (get from other)")
			map("<LocalLeader>o", "dp", "Push ours (put to other)")
			map("<LocalLeader>n", "]c", "Next hunk")
			map("<LocalLeader>p", "[c", "Prev hunk")
			map("<LocalLeader>q", "q", "Close diff")
			map("<LocalLeader>?", "g?", "Help")
			local ours, theirs = vim.env.CODEDIFF_OURS, vim.env.CODEDIFF_THEIRS
			if ours and theirs then
				local canon = function(p)
					return vim.fn.resolve(vim.fn.fnamemodify(p, ":p"))
				end
				local bufpath = canon(vim.api.nvim_buf_get_name(buf))
				if bufpath == canon(ours) then
					for _, w in ipairs(vim.fn.win_findbuf(buf)) do
						vim.wo[w].winbar = "%#DiffAdd# OURS (editable - do lands here) %*"
					end
				elseif bufpath == canon(theirs) then
					vim.bo[buf].modifiable = false
					for _, w in ipairs(vim.fn.win_findbuf(buf)) do
						vim.wo[w].winbar = "%#DiffChange# THEIRS (read-only reference) %*"
					end
				end
			end
		end, 100)
	end, "codediff: LocalLeader wrappers")
end)

later(function()
	add({ "https://github.com/MagicDuck/grug-far.nvim" })
	require("grug-far").setup({})
	vim.keymap.set("n", "<Leader>er", function()
		require("grug-far").open()
	end, { desc = "Search and replace (grug-far)" })
	vim.keymap.set("v", "<Leader>er", ":<C-u>GrugFar<CR>", { desc = "Search and replace selection (grug-far)" })
end)

Config.now(function()
	add({
		"https://github.com/julienvincent/hunk.nvim",
		"https://github.com/MunifTanjim/nui.nvim",
	})
	require("hunk").setup({
		ui = {
			layout = "vertical",
			tree = { width = 35 },
		},
	})
end)

Config.now(function()
	add({ "https://github.com/larpios/jj-conflict.nvim" })
	require("jj-conflict").setup({
		mappings = {
			ours = "<LocalLeader>o",
			theirs = "<LocalLeader>t",
			both = "<LocalLeader>b",
			base = "<LocalLeader>0",
			next = "<LocalLeader>n",
			prev = "<LocalLeader>p",
		},
	})
end)

later(function()
	add({
		{ src = "https://github.com/mrcjkb/rustaceanvim", version = vim.version.range("^9") },
	})
end)
