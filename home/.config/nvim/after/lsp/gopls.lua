return {
  on_attach = function(client)
    client.server_capabilities.completionProvider.triggerCharacters = { ".", ":" }
  end,
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
        shadow = true,
      },
      staticcheck = true,
      gofumpt = true,
      -- Enable Go template support for .tmpl files
      templateExtensions = { "tmpl", "tpl", "html" },
    },
  },
}
