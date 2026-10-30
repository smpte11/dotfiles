local language_id_of = {
	menhir = "ocaml.menhir",
	ocaml = "ocaml",
	ocamlinterface = "ocaml.interface",
	ocamllex = "ocaml.ocamllex",
	reason = "reason",
	dune = "dune",
}

local language_id_of_ext = {
	mll = language_id_of.ocamllex,
	mly = language_id_of.menhir,
	mli = language_id_of.ocamlinterface,
}

return {
	cmd = { "ocamllsp" },
	filetypes = { "ocaml", "menhir", "ocamlinterface", "ocamllex", "reason", "dune" },
	root_markers = {
		{ "dune-project", "dune-workspace" },
		{ "*.opam", "opam", "esy.json", "package.json" },
		{ ".git" },
	},
	get_language_id = function(bufnr, ftype)
		if ftype == "ocaml" then
			local ext = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":e")
			return language_id_of_ext[ext] or language_id_of.ocaml
		end
		return language_id_of[ftype]
	end,
	settings = {
		codelens = { enable = true },
		inlayHints = { enable = true },
		syntaxDocumentation = { enable = true },
	},
}
