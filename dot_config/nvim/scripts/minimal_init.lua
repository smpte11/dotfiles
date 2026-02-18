-- Minimal init file for testing
-- Sets up the environment for running tests on the notes visualization module

-- Add current directory to package path so we can require our modules
local current_dir = vim.fn.getcwd()
package.path = package.path .. ";" .. current_dir .. "/lua/?.lua;" .. current_dir .. "/lua/?/init.lua"

-- Set up minimal vim environment
vim.opt.runtimepath:prepend(current_dir)

-- Add mini.nvim to runtimepath if it exists
local mini_path = current_dir .. "/deps/mini.nvim"
if vim.fn.isdirectory(mini_path) == 1 then
  vim.opt.runtimepath:prepend(mini_path)
end

-- Set up test environment variables
vim.env.ZK_NOTEBOOK_DIR = "/tmp/test_notebooks"
vim.env.ZK_PERSO_TASK_DB_PATH = "/tmp/test_notebooks/.perso-tasks.db"
vim.env.ZK_WORK_TASK_DB_PATH = "/tmp/test_notebooks/.work-tasks.db"

-- Ensure test notebook directory exists
vim.fn.mkdir(vim.env.ZK_NOTEBOOK_DIR, "p")
