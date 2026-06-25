-- Neovim sources 'octo_*.lua' ftplugins for filetype 'octo' too, so bail out
-- unless this really is the 'octo_panel' buffer (else we'd clobber octo.lua's
-- buffer-local mini.clue config).
if vim.bo.filetype ~= "octo_panel" then
  return
end

-- Octo review file-panel: clue group for the review submit/discard maps.
-- Other panel maps (<LocalLeader>e/b/C/<space>) are single keys and already
-- carry octo's own `desc`, so mini.clue renders them without a group label.
vim.b.miniclue_config = {
  clues = {
    { mode = "n", keys = "<LocalLeader>v", desc = "+Review" },
  },
}

if MiniClue then MiniClue.ensure_buf_triggers() end
