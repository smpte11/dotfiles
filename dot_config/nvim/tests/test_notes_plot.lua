-- Tests for notes.plot module
-- Tests all plotting functions: histogram, pie_chart, table, line_plot

local helpers = require('tests.helpers')
helpers.setup_vim_mocks()

-- Set up mini.test
local MiniTest = require('mini.test')
local child = MiniTest.new_child_neovim()

-- Set up test environment
local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ '-u', 'scripts/minimal_init.lua' })
      -- Add test directory to path
      child.lua('package.path = package.path .. ";./?.lua;./?/init.lua"')
    end,
  },
})

-- Test histogram function
T['histogram'] = MiniTest.new_set()

T['histogram']['basic_histogram'] = function()
  local data = helpers.sample_chart_data()
  
  child.lua([[
    local plot = require('notes.plot')
    local data = {
      {label = "Day 1", value = 5},
      {label = "Day 2", value = 8}, 
      {label = "Day 3", value = 3}
    }
    _G.result = plot.histogram(data, {title = "Test Histogram", width = 30})
  ]])
  
  local result = child.lua_get('_G.result')
  
  -- Validate output
  MiniTest.expect.equality(type(result), 'table')
  MiniTest.expect.equality(#result > 0, true)
  
  -- Check for title
  MiniTest.expect.equality(result[1], "Test Histogram")
  
  -- Check for bars
  local has_bars = false
  for _, line in ipairs(result) do
    if line:match("█") then
      has_bars = true
      break
    end
  end
  MiniTest.expect.equality(has_bars, true)
end

T['histogram']['empty_data'] = function()
  child.lua([[
    local plot = require('notes.plot')
    _G.result = plot.histogram({}, {title = "Empty"})
  ]])
  
  local result = child.lua_get('_G.result')
  MiniTest.expect.equality(result[1], "No data to display")
end

T['histogram']['custom_options'] = function()
  child.lua([[
    local plot = require('notes.plot')
    local data = {{label = "Test", value = 10}}
    _G.result = plot.histogram(data, {
      title = "Custom Test",
      width = 20,
      show_values = false
    })
  ]])
  
  local result = child.lua_get('_G.result')
  
  -- Should not show values when show_values = false
  local has_numbers = false
  for _, line in ipairs(result) do
    if line:match("%d+$") then -- ends with number
      has_numbers = true
      break
    end
  end
  MiniTest.expect.equality(has_numbers, false)
end

-- Test pie chart function
T['pie_chart'] = MiniTest.new_set()

T['pie_chart']['basic_pie_chart'] = function()
  local data = helpers.sample_pie_data()
  
  child.lua([[
    local plot = require('notes.plot')
    local data = {
      {label = "Finished", value = 25},
      {label = "In Progress", value = 8},
      {label = "Created", value = 12}
    }
    _G.result = plot.pie_chart(data, {
      title = "Test Pie",
      radius = 6,
      style = "solid",
      show_legend = true
    })
  ]])
  
  local result = child.lua_get('_G.result')
  
  -- Validate basic structure
  MiniTest.expect.equality(type(result), 'table')
  MiniTest.expect.equality(#result > 0, true)
  
  -- Check for title
  MiniTest.expect.equality(result[1], "Test Pie")
  
  -- Check for legend
  local has_legend = false
  for _, line in ipairs(result) do
    if line:match("Legend:") then
      has_legend = true
      break
    end
  end
  MiniTest.expect.equality(has_legend, true)
  
  -- Check for circular characters
  local has_pie_chars = false
  for _, line in ipairs(result) do
    if line:match("[█▓▒░]") then
      has_pie_chars = true
      break
    end
  end
  MiniTest.expect.equality(has_pie_chars, true)
end

T['pie_chart']['different_styles'] = function()
  child.lua([[
    local plot = require('notes.plot')
    local data = {{label = "Test", value = 10}}
    
    _G.solid_result = plot.pie_chart(data, {style = "solid", radius = 4})
    _G.pattern_result = plot.pie_chart(data, {style = "pattern", radius = 4})  
    _G.unicode_result = plot.pie_chart(data, {style = "unicode", radius = 4})
  ]])
  
  local solid = child.lua_get('_G.solid_result')
  local pattern = child.lua_get('_G.pattern_result')
  local unicode = child.lua_get('_G.unicode_result')
  
  -- All should be valid
  MiniTest.expect.equality(type(solid), 'table')
  MiniTest.expect.equality(type(pattern), 'table')
  MiniTest.expect.equality(type(unicode), 'table')
  
  -- Should use different character sets
  local solid_str = table.concat(solid, "\n")
  local unicode_str = table.concat(unicode, "\n")
  
  -- Unicode style should have different characters
  MiniTest.expect.equality(solid_str == unicode_str, false)
end

T['pie_chart']['zero_values'] = function()
  child.lua([[
    local plot = require('notes.plot')
    local data = {{label = "Zero", value = 0}}
    _G.result = plot.pie_chart(data)
  ]])
  
  local result = child.lua_get('_G.result')
  MiniTest.expect.equality(result[1], "No data to display")
end

-- Test table function  
T['table'] = MiniTest.new_set()

T['table']['basic_table'] = function()
  child.lua([[
    local plot = require('notes.plot')
    local data = {
      {"Task A", "FINISHED", "2024-09-11"},
      {"Task B", "IN_PROGRESS", "2024-09-10"},
      {"Task C", "CREATED", "2024-09-09"}
    }
    _G.result = plot.table(data, {
      title = "Test Table",
      headers = {"Task", "State", "Date"},
      show_borders = true
    })
  ]])
  
  local result = child.lua_get('_G.result')
  
  -- Validate structure
  MiniTest.expect.equality(type(result), 'table')
  MiniTest.expect.equality(#result > 0, true)
  
  -- Check for title
  MiniTest.expect.equality(result[1], "Test Table")
  
  -- Check for borders
  local has_borders = false
  for _, line in ipairs(result) do
    if line:match("[┌┐└┘│─]") then
      has_borders = true
      break
    end
  end
  MiniTest.expect.equality(has_borders, true)
  
  -- Check for data content
  local has_task_a = false
  for _, line in ipairs(result) do
    if line:match("Task A") then
      has_task_a = true
      break
    end
  end
  MiniTest.expect.equality(has_task_a, true)
end

T['table']['no_borders'] = function()
  child.lua([[
    local plot = require('notes.plot')
    local data = {{"Test", "Data"}}
    _G.result = plot.table(data, {
      headers = {"Col1", "Col2"},
      show_borders = false
    })
  ]])
  
  local result = child.lua_get('_G.result')
  
  -- Should not have border characters (excluding title separators)
  local has_borders = false
  for _, line in ipairs(result) do
    -- Skip title separator lines (all "═" characters)
    if not line:match("^═+$") then
      if line:match("[┌┐└┘│─┼┤├┬┴]") then
        has_borders = true
        break
      end
    end
  end
  MiniTest.expect.equality(has_borders, false)
end

-- Test line plot function
T['line_plot'] = MiniTest.new_set()

T['line_plot']['basic_line_plot'] = function()
  child.lua([[
    local plot = require('notes.plot')
    local data = {
      {label = "Point 1", value = 5},
      {label = "Point 2", value = 8},
      {label = "Point 3", value = 3},
      {label = "Point 4", value = 10}
    }
    _G.result = plot.line_plot(data, {
      title = "Test Plot",
      width = 40,
      height = 10,
      show_axes = true
    })
  ]])
  
  local result = child.lua_get('_G.result')
  
  -- Validate structure
  MiniTest.expect.equality(type(result), 'table')
  MiniTest.expect.equality(#result > 0, true)
  
  -- Check for title
  MiniTest.expect.equality(result[1], "Test Plot")
  
  -- Check for plot characters
  local has_plot_chars = false
  for _, line in ipairs(result) do
    if line:match("[•─│]") then
      has_plot_chars = true
      break
    end
  end
  MiniTest.expect.equality(has_plot_chars, true)
  
  -- Check for range info at the end
  local last_line = result[#result]
  MiniTest.expect.equality(last_line:match("Range:") ~= nil, true)
end

T['line_plot']['no_axes'] = function()
  child.lua([[
    local plot = require('notes.plot')
    local data = {{label = "Test", value = 5}}
    _G.result = plot.line_plot(data, {show_axes = false, width = 20, height = 5})
  ]])
  
  local result = child.lua_get('_G.result')
  MiniTest.expect.equality(type(result), 'table')
end

T['line_plot']['single_point'] = function()
  child.lua([[
    local plot = require('notes.plot')
    local data = {{label = "Single", value = 7}}
    _G.result = plot.line_plot(data, {width = 10, height = 5})
  ]])
  
  local result = child.lua_get('_G.result')
  MiniTest.expect.equality(type(result), 'table')
  MiniTest.expect.equality(#result > 0, true)
end

-- Test alternative formats
T['alternative_formats'] = MiniTest.new_set()

T['alternative_formats']['array_format'] = function()
  child.lua([[
    local plot = require('notes.plot')
    -- Test array format: {"label", value}
    local data = {
      {"Day 1", 5},
      {"Day 2", 8},
      {"Day 3", 3}
    }
    _G.result = plot.histogram(data, {title = "Array Format"})
  ]])
  
  local result = child.lua_get('_G.result')
  
  -- Should work the same as object format
  MiniTest.expect.equality(type(result), 'table')
  MiniTest.expect.equality(result[1], "Array Format")
  
  local has_bars = false
  for _, line in ipairs(result) do
    if line:match("█") then
      has_bars = true
      break
    end
  end
  MiniTest.expect.equality(has_bars, true)
end

T['alternative_formats']['mixed_format'] = function()
  child.lua([[
    local plot = require('notes.plot')
    -- Mix of object and array formats
    local data = {
      {label = "Object", value = 5},
      {"Array", 8},
      {label = "Object2", value = 3}
    }
    _G.result = plot.histogram(data, {})
  ]])
  
  local result = child.lua_get('_G.result')
  MiniTest.expect.equality(type(result), 'table')
  MiniTest.expect.equality(#result > 0, true)
end

-- Run the tests
return T
