-- Uses global: spec (from 00-bootstrap.lua)

-- CodeDiff - VSCode-style side-by-side diff
-- To set CodeDiff as your default git difftool and mergetool, run:
-- git config --global difftool.codediff.cmd "nvim -c 'CodeDiff $LOCAL $REMOTE'"
-- git config --global mergetool.codediff.cmd "nvim -c 'CodeDiff $LOCAL $REMOTE $MERGED'"
-- git config --global diff.tool codediff
-- git config --global merge.tool codediff
spec({
	source = "esmuellert/codediff.nvim",
	depends = { "MunifTanjim/nui.nvim" },
	config = function()
		require("codediff").setup({
			-- Custom highlight configuration (defined in lua/config/colors.lua)
			highlights = {
				line_insert = "CodeDiffLineInsert",
				line_delete = "CodeDiffLineDelete",
				char_insert = "CodeDiffCharInsert",
				char_delete = "CodeDiffCharDelete",
				filler = "CodeDiffFiller",
			},
			keymaps = {
				view = {
					quit = "q",
					toggle_explorer = "<leader>gcp", -- [C]ommit/Diff [P]anel
					stage_hunk = "<leader>gcs", -- [S]tage Hunk
					unstage_hunk = "<leader>gcu", -- [U]nstage Hunk
					discard_hunk = "<leader>gcr", -- [R]evert Hunk
					next_hunk = "]c",
					prev_hunk = "[c",
				},
				conflict = {
					accept_incoming = "<leader>gct", -- [T]heirs
					accept_current = "<leader>gco", -- [O]urs
					accept_both = "<leader>gcb", -- [B]oth
					discard = "<leader>gcx", -- Discard
					next_conflict = "]x",
					prev_conflict = "[x",
				},
			},
		})
	end,
	-- stylua: ignore start
    keys = {
        { "<leader>gcd", "<cmd>CodeDiff<cr>",                    desc = "[Commit/Diff] [D]iff (CodeDiff)" },
        { "<leader>gcs", "<cmd>CodeDiff --cached<cr>",           desc = "[Commit/Diff] [S]taged Changes" },
        { "<leader>gcu", "<cmd>CodeDiff<cr>",                    desc = "[Commit/Diff] [U]nstaged Changes" },
        { "<leader>gcf", "<cmd>CodeDiff history %<cr>",          desc = "[Commit/Diff] [F]ile History" },
        { "<leader>gcF", "<cmd>CodeDiff history<cr>",            desc = "[Commit/Diff] [F]ile Project History" },
        { "<leader>gcm", "<cmd>CodeDiff main...HEAD<cr>",        desc = "[Commit/Diff] [M]erge Base Diff" },
        { "<leader>gcr", function()
             local branch = vim.fn.input("Review branch (default: main): ")
             if branch == "" then branch = "main" end
             vim.cmd("CodeDiff " .. branch .. "...HEAD")
        end, desc = "[CodeDiff] [R]eview Merge Base" },
    },
	-- stylua: ignore end
})

-- Neogit - Git interface
spec({
	source = "NeogitOrg/neogit",
	depends = {
		"nvim-lua/plenary.nvim",
		"esmuellert/codediff.nvim",
		"echasnovski/mini.pick",
	},
	config = function()
		require("neogit").setup({
			integrations = {
				mini_pick = true,
				fzf_lua = false,
				telescope = false,
				diffview = false,
			},
		})
	end,
    -- stylua: ignore start
    keys = {
        { "<leader>gg",  function() require("neogit").open() end,                     desc = "[Git] Status" },
        { "<leader>gb",  function() require("mini.extra").pickers.git_branches() end, desc = "[Git] [B]ranches" },
        { "<leader>gl",  function() require("mini.extra").pickers.git_commits() end,  desc = "[Git] [L]og" },
        { "<leader>gH",  function() require("mini.extra").pickers.git_hunks() end,    desc = "[Git] [H]unks" },
    },
	-- stylua: ignore end
})

-- Git Blame
spec({
	source = "f-person/git-blame.nvim",
	config = function()
		require("gitblame").setup({
			enabled = false, -- Don't enable by default
			message_template = " <author> • <date> • <summary>",
			date_format = "%c",
			virtual_text_column = 2,
		})
	end,
    -- stylua: ignore start
    keys = {
        { "<leader>gB", "<cmd>GitBlameToggle<cr>", desc = "[Git] [B]lame Toggle" },
    },
	-- stylua: ignore end
})

-- fzf-lua - Fuzzy finder (used by octo.nvim)
-- spec({
-- 	source = "ibhagwan/fzf-lua",
-- 	depends = { "echasnovski/mini.icons" },
-- 	immediate = true,
-- 	config = function()
-- 		require("fzf-lua").setup({
-- 			winopts = {
-- 				border = "double",
-- 				preview = {
-- 					border = "double",
-- 					scrollbar = "border",
-- 				},
-- 			},
-- 			fzf_opts = {
-- 				["--layout"] = "reverse",
-- 				["--info"] = "inline",
-- 			},
-- 		})
-- 	end,
-- })

-- Octo - GitHub integration
spec({
	source = "pwntester/octo.nvim",
	depends = {
		"nvim-lua/plenary.nvim",
		"folke/snacks.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("octo").setup({
			enable_builtin = true, -- Enable builtin actions menu
			picker = "snacks",
			picker_config = {
				use_emojis = true,
			},
			default_remote = { "upstream", "origin" }, -- order to try remotes
			default_merge_method = "squash", -- default merge method
			ssh_aliases = {
				["me.github.com"] = "github.com", -- Map SSH alias to github.com
				["kivra.github.com"] = "github.com", -- Map work SSH alias to github.com
			},
			timeout = 5000, -- timeout for requests
			gh_env = {
				GH_PROMPT_DISABLED = "1", -- Disable interactive prompts in gh CLI
			},
		})
	end,
    -- stylua: ignore start
    keys = {
        -- GitHub integration (grouped under <leader>gh)
        { "<leader>ghi", "<cmd>Octo issue list<cr>",           desc = "[GitHub] [I]ssues (open)" },
        { "<leader>ghI", "<cmd>Octo issue list state=all<cr>", desc = "[GitHub] [I]ssues (all)" },
        { "<leader>ghp", "<cmd>Octo pr list<cr>",              desc = "[GitHub] [P]ull Requests (open)" },
        { "<leader>ghP", "<cmd>Octo pr list state=all<cr>",    desc = "[GitHub] [P]ull Requests (all)" },
        { "<leader>gha", "<cmd>Octo actions<cr>",              desc = "[GitHub] [A]ctions" },
        { "<leader>ghc", "<cmd>Octo issue create<cr>",         desc = "[GitHub] [C]reate Issue" },
        { "<leader>ghC", "<cmd>Octo pr create<cr>",            desc = "[GitHub] [C]reate PR" },
        { "<leader>ghr", "<cmd>Octo review start<cr>",         desc = "[GitHub] Start [R]eview" },
        { "<leader>ghs", "<cmd>Octo review submit<cr>",        desc = "[GitHub] [S]ubmit Review" },
        { "<leader>ghS", "<cmd>Octo search<cr>",               desc = "[GitHub] [S]earch" },
    },
	-- stylua: ignore end
})
