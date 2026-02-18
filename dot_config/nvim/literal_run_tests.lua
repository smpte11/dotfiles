#!/usr/bin/env nvim -l

-- Lua test runner script for notes visualization module
-- Can be run with: nvim -l run_tests.lua [test_name]

-- Setup paths
local current_dir = vim.fn.getcwd()
package.path = package.path .. ";" .. current_dir .. "/lua/?.lua;" .. current_dir .. "/lua/?/init.lua"

-- Add mini.nvim to path
local mini_path = current_dir .. "/deps/mini.nvim"
if vim.fn.isdirectory(mini_path) == 1 then
  vim.opt.runtimepath:prepend(mini_path)
end

-- Set up test environment
vim.env.ZK_NOTEBOOK_DIR = "/tmp/test_notebooks"
vim.env.ZK_PERSO_TASK_DB_PATH = "/tmp/test_notebooks/.perso-tasks.db"
vim.env.ZK_WORK_TASK_DB_PATH = "/tmp/test_notebooks/.work-tasks.db"
vim.fn.mkdir(vim.env.ZK_NOTEBOOK_DIR, "p")

-- Load mini.test
local ok, MiniTest = pcall(require, 'mini.test')
if not ok then
  print("❌ mini.test not available. Run 'make setup-deps' first.")
  os.exit(1)
end

-- Test modules to run
local test_modules = {
  plot = 'tests.test_notes_plot',
  utils = 'tests.test_notes_utils', 
  init = 'tests.test_notes_init',
  migrations = 'tests.test_notes_migrations'
}

-- Get command line argument for specific test
local test_name = arg and arg[1] or nil

print("🧪 Notes Visualization Module Test Runner")
print("=" .. string.rep("=", 45))

if test_name and test_modules[test_name] then
  -- Run specific test module
  print(string.format("🎯 Running %s tests...", test_name))
  
  local ok_load, test_set = pcall(require, test_modules[test_name])
  if not ok_load then
    print("❌ Failed to load test module: " .. test_modules[test_name])
    print("Error: " .. test_set)
    os.exit(1)
  end
  
  local ok_run, results = pcall(MiniTest.execute, test_set)
  if not ok_run then
    print("❌ Failed to run tests: " .. results)
    os.exit(1) 
  end
  
elseif test_name == "all" or not test_name then
  -- Run all test modules
  print("🚀 Running all test modules...")
  
  local all_passed = true
  local total_tests = 0
  local total_passed = 0
  
  for name, module_path in pairs(test_modules) do
    print(string.format("\n📊 Testing %s module (%s)", name, module_path))
    print("-" .. string.rep("-", 40))
    
    local ok_load, test_set = pcall(require, module_path)
    if not ok_load then
      print("❌ Failed to load: " .. test_set)
      all_passed = false
      goto continue
    end
    
    local ok_run, results = pcall(MiniTest.execute, test_set)
    if not ok_run then
      print("❌ Failed to execute: " .. results)
      all_passed = false
      goto continue
    end
    
    -- Count results if possible
    if type(results) == "table" and results.n_tests then
      total_tests = total_tests + results.n_tests
      total_passed = total_passed + (results.n_tests - (results.n_fail or 0))
    end
    
    ::continue::
  end
  
  -- Final summary
  print("\n" .. string.rep("=", 50))
  if all_passed then
    print(string.format("✅ All tests completed! (%d passed)", total_passed))
  else
    print("❌ Some tests failed. See output above.")
  end
  print(string.rep("=", 50))
  
else
  -- Invalid test name
  print("❌ Unknown test module: " .. (test_name or "nil"))
  print("\n📖 Available test modules:")
  for name, _ in pairs(test_modules) do
    print("  • " .. name)
  end
  print("  • all (run all tests)")
  print("\n💡 Usage: nvim -l run_tests.lua [test_name]")
  print("   Example: nvim -l run_tests.lua plot")
  os.exit(1)
end

print("\n🏁 Test runner complete!")
