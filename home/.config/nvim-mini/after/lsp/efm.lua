-- efm-langserver: markdown formatting with prettier, mirroring the main
-- config's wikilink table pre-pass so zk links inside tables survive.
return {
	filetypes = { "markdown" },
	init_options = { documentFormatting = true },
	settings = {
		languages = {
			markdown = {
				{ formatCommand = "md-wikilink-table-to-md | prettier --parser markdown --prose-wrap preserve", formatStdin = true },
			},
		},
	},
}
