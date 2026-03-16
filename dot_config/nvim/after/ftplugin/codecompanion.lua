Config.new_autocmd("FileType", "codecompanion", function()
	vim.b.minicompletion_config = { fallback_action = "<C-x><C-o>" }
end, "Disable minicompletion for codecompanion filetype")
