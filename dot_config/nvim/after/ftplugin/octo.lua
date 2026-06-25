-- Octo buffer-local clue group descriptions
vim.b.miniclue_config = {
  clues = {
    { mode = "n", keys = "<LocalLeader>a", desc = "+Assignee" },
    { mode = "n", keys = "<LocalLeader>c", desc = "+Comment" },
    { mode = "n", keys = "<LocalLeader>d", desc = "+Discussion" },
    { mode = "n", keys = "<LocalLeader>g", desc = "+Go to" },
    { mode = "n", keys = "<LocalLeader>i", desc = "+Issue/PR" },
    { mode = "n", keys = "<LocalLeader>l", desc = "+Label" },
    { mode = "n", keys = "<LocalLeader>n", desc = "+Notification" },
    { mode = "n", keys = "<LocalLeader>p", desc = "+PR" },
    { mode = "n", keys = "<LocalLeader>ps", desc = "+Squash" },
    { mode = "n", keys = "<LocalLeader>pr", desc = "+Rebase" },
    { mode = "n", keys = "<LocalLeader>r", desc = "+React/Resolve/Ref" },
    { mode = "n", keys = "<LocalLeader>s", desc = "+Suggestion" },
    { mode = "n", keys = "<LocalLeader>v", desc = "+Review" },
    { mode = "x", keys = "<LocalLeader>c", desc = "+Comment" },
    { mode = "x", keys = "<LocalLeader>s", desc = "+Suggestion" },
  },
}

-- Override octo's git-based checkout with the jj-native command on PR buffers.
-- Deferred so it lands after octo applies its own mappings; gated on octo
-- having set <LocalLeader>po (i.e. this is a PR buffer, not an issue buffer).
vim.schedule(function()
  if vim.fn.maparg(",po", "n") ~= "" then
    vim.keymap.set("n", "<LocalLeader>po", "<Cmd>OctoPrCheckoutJj<CR>", { buffer = 0, desc = "Checkout PR (jj)" })
    if MiniClue then MiniClue.ensure_buf_triggers() end
  end
end)

-- Re-create mini.clue triggers so they remain the latest buffer-local mappings
MiniClue.ensure_buf_triggers()
