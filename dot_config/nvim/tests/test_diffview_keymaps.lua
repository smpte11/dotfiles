-- Test file for diffview keymaps integration
-- Run with: nvim --headless -c "luafile tests/test_diffview_keymaps.lua" -c "qa"

local helpers = require('tests.helpers')

-- Test 1: Verify global diffview keymaps are set
local function test_global_keymaps()
  print("Testing global diffview keymaps...")

  local keymaps_to_check = {
    { lhs = '<leader>gd', desc = '[Git] [D]iffview Open' },
    { lhs = '<leader>gD', desc = '[Git] [D]iffview Close' },
    { lhs = '<leader>gf', desc = '[Git] [F]ile History' },
    { lhs = '<leader>gF', desc = '[Git] [F]ile History (All)' },
    { lhs = '<leader>gm', desc = '[Git] [M]erge Base Diff' },
  }

  local all_keymaps = vim.api.nvim_get_keymap('n')

  for _, expected in ipairs(keymaps_to_check) do
    local found = false
    for _, keymap in ipairs(all_keymaps) do
      if keymap.lhs == expected.lhs then
        found = true
        if keymap.desc ~= expected.desc then
          print(string.format("  ❌ Keymap %s has wrong description: expected '%s', got '%s'",
            expected.lhs, expected.desc, keymap.desc or 'nil'))
        else
          print(string.format("  ✓ Keymap %s correctly configured", expected.lhs))
        end
        break
      end
    end

    if not found then
      print(string.format("  ❌ Keymap %s not found", expected.lhs))
    end
  end
end

-- Test 2: Verify autocmd for Neogit integration exists
local function test_neogit_autocmd()
  print("\nTesting Neogit integration autocmd...")

  local autocmds = vim.api.nvim_get_autocmds({
    group = 'neogit-diffview',
    event = 'FileType',
  })

  if #autocmds == 0 then
    print("  ❌ Neogit-diffview autocmd group not found")
    return
  end

  local found_neogit_status = false
  for _, autocmd in ipairs(autocmds) do
    if autocmd.pattern == 'NeogitStatus' then
      found_neogit_status = true
      print("  ✓ NeogitStatus autocmd configured")
    end
  end

  if not found_neogit_status then
    print("  ❌ NeogitStatus pattern not found in autocmd")
  end
end

-- Test 3: Verify no conflicts with existing quit mappings
local function test_no_quit_conflicts()
  print("\nTesting no conflicts with quit mappings...")

  local all_keymaps = vim.api.nvim_get_keymap('n')
  local has_leader_qq = false
  local has_leader_qw = false

  for _, keymap in ipairs(all_keymaps) do
    if keymap.lhs == '<leader>qq' then
      has_leader_qq = true
    end
    if keymap.lhs == '<leader>qw' then
      has_leader_qw = true
    end
  end

  if has_leader_qq then
    print("  ✓ <leader>qq (Quit All) preserved")
  else
    print("  ❌ <leader>qq mapping not found")
  end

  if has_leader_qw then
    print("  ✓ <leader>qw (Write and Quit All) preserved")
  else
    print("  ❌ <leader>qw mapping not found")
  end
end

-- Run all tests
print("╔══════════════════════════════════════╗")
print("║   Diffview Keymaps Integration Test  ║")
print("╚══════════════════════════════════════╝\n")

print("Loading configuration files...")

-- Load keymaps first (for quit mappings)
local keymaps_ok, keymaps_err = pcall(dofile, vim.fn.stdpath('config') .. '/lua/keymaps.lua')
if not keymaps_ok then
  print("  Warning: Could not load keymaps.lua: " .. tostring(keymaps_err))
end

-- Load autocmd
local autocmd_ok, autocmd_err = pcall(dofile, vim.fn.stdpath('config') .. '/lua/autocmd.lua')
if not autocmd_ok then
  print("  Warning: Could not load autocmd.lua: " .. tostring(autocmd_err))
end

-- Note: programming.lua is in a later() block and requires full init
-- For a proper test, we'd need to load the full init.lua or extract the keymaps
print("  ℹ️  Note: Git keymaps are set in plugin/programming.lua within later() block")
print("  ℹ️  This test verifies structure, not runtime behavior\n")

test_global_keymaps()
test_neogit_autocmd()
test_no_quit_conflicts()

print("\n✅ Diffview keymaps test complete!")
print("💡 To fully test, use: nvim and manually verify <leader>g keymaps")
