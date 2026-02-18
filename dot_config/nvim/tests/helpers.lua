-- Test helpers for notes visualization module
-- Shared utilities and setup for all test files

local M = {}

-- Mock vim functions for standalone testing
function M.setup_vim_mocks()
  if not vim then
    _G.vim = {
      inspect = function(obj) return tostring(obj) end,
      fn = {
        expand = function(path) return path end,
        filereadable = function() return 1 end,
        isdirectory = function() return 1 end,
        mkdir = function() return 1 end,
        getcwd = function() return "/test" end
      },
      env = {
        ZK_NOTEBOOK_DIR = "/tmp/test_notebooks",
        ZK_PERSO_TASK_DB_PATH = "/tmp/test_notebooks/.perso-tasks.db"
      },
      tbl_deep_extend = function(mode, base, override)
        local result = {}
        for k, v in pairs(base) do result[k] = v end
        for k, v in pairs(override) do result[k] = v end
        return result
      end
    }
  end
end

-- Sample data generators for testing
function M.sample_chart_data()
  return {
    {label = "Day 1", value = 5},
    {label = "Day 2", value = 8},
    {label = "Day 3", value = 3},
    {label = "Day 4", value = 10},
    {label = "Day 5", value = 6}
  }
end

function M.sample_pie_data()
  return {
    {label = "Finished", value = 25},
    {label = "In Progress", value = 8},  
    {label = "Created", value = 12},
    {label = "Blocked", value = 3}
  }
end

function M.sample_table_data()
  return {
    {"Task A", "completed", "FINISHED", "2024-09-11"},
    {"Task B", "started", "IN_PROGRESS", "2024-09-10"},
    {"Task C", "created", "CREATED", "2024-09-09"}
  }
end

function M.sample_sql_results()
  return {
    {date = "2024-09-09", count = 5, state = "FINISHED"},
    {date = "2024-09-10", count = 8, state = "IN_PROGRESS"},
    {date = "2024-09-11", count = 3, state = "CREATED"}
  }
end

-- Chart validation helpers
function M.validate_chart_output(output)
  if type(output) ~= "table" then
    return false, "Output should be a table of strings"
  end
  
  if #output == 0 then
    return false, "Output should not be empty"
  end
  
  for i, line in ipairs(output) do
    if type(line) ~= "string" then
      return false, "Line " .. i .. " should be a string, got " .. type(line)
    end
  end
  
  return true, "Valid chart output"
end

function M.validate_histogram(output)
  local valid, msg = M.validate_chart_output(output)
  if not valid then return false, msg end
  
  -- Check for bars (should contain block characters)
  local has_bars = false
  for _, line in ipairs(output) do
    if line:match("█") then
      has_bars = true
      break
    end
  end
  
  if not has_bars then
    return false, "Histogram should contain bar characters (█)"
  end
  
  return true, "Valid histogram output"
end

function M.validate_pie_chart(output)
  local valid, msg = M.validate_chart_output(output)
  if not valid then return false, msg end
  
  -- Check for circular pattern (should be roughly square-ish)
  local line_lengths = {}
  for _, line in ipairs(output) do
    table.insert(line_lengths, #line)
  end
  
  -- Find lines with content (not just spaces)
  local content_lines = 0
  for _, line in ipairs(output) do
    if line:match("[^%s]") then
      content_lines = content_lines + 1
    end
  end
  
  if content_lines < 5 then
    return false, "Pie chart should have multiple lines of content"
  end
  
  return true, "Valid pie chart output"
end

function M.validate_table(output)
  local valid, msg = M.validate_chart_output(output)
  if not valid then return false, msg end
  
  -- Check for table borders
  local has_borders = false
  for _, line in ipairs(output) do
    if line:match("[┌┐└┘│─┼┤├┬┴]") then
      has_borders = true
      break
    end
  end
  
  if not has_borders then
    return false, "Table should contain border characters"
  end
  
  return true, "Valid table output"
end

function M.validate_line_plot(output)
  local valid, msg = M.validate_chart_output(output)
  if not valid then return false, msg end
  
  -- Check for plot elements
  local has_plot_chars = false
  for _, line in ipairs(output) do
    if line:match("[•─│]") then
      has_plot_chars = true
      break
    end
  end
  
  if not has_plot_chars then
    return false, "Line plot should contain plot characters"
  end
  
  return true, "Valid line plot output"
end

-- Mock SQLite for testing
function M.mock_sqlite()
  return {
    new = function(path)
      return {
        path = path,
        open = function() end,
        close = function() end,
        eval = function(self, sql)
          -- Return mock data based on SQL query
          if sql:match("task_completed") then
            return M.sample_sql_results()
          elseif sql:match("latest_states") then
            return {{state = "FINISHED", count = 25}, {state = "CREATED", count = 12}}
          else
            return M.sample_sql_results()
          end
        end
      }
    end
  }
end

-- Test output capture
function M.capture_print_output(func, ...)
  local output = {}
  local old_print = print
  
  print = function(...)
    local args = {...}
    table.insert(output, table.concat(vim.tbl_map(tostring, args), " "))
  end
  
  local ok, result = pcall(func, ...)
  print = old_print
  
  if not ok then
    error("Function failed: " .. tostring(result))
  end
  
  return output, result
end

return M
