-- Tests for notes.init module
-- Tests setup function, configuration, and high-level API

local helpers = require('tests.helpers')
helpers.setup_vim_mocks()

local MiniTest = require('mini.test')
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ '-u', 'scripts/minimal_init.lua' })
      child.lua('package.path = package.path .. ";./?.lua;./?/init.lua"')
      
      -- Mock sqlite for database tests
      child.lua([[
        package.preload['sqlite'] = function()
          return {
            new = function(path)
              return {
                path = path,
                open = function() end,
                close = function() end,
                eval = function(self, sql)
                  if sql:match("task_completed") then
                    return {{date = "2024-09-10", count = 5}, {date = "2024-09-11", count = 8}}
                  elseif sql:match("latest_states") then
                    return {{state = "FINISHED", count = 25}, {state = "CREATED", count = 12}}
                  elseif sql:match("task_text") then
                    return {{task_text = "Sample task", event_type = "task_completed", state = "FINISHED", event_date = "2024-09-11", event_time = "14:30"}}
                  else
                    return {{day = "2024-09-10", created = 2, completed = 5, carried_over = 1}}
                  end
                end
              }
            end
          }
        end
      ]])
    end,
  },
})

-- Test setup and configuration
T['setup_config'] = MiniTest.new_set()

T['setup_config']['default_setup'] = function()
  child.lua([[
    local notes = require('notes')
    notes.setup() -- Use all defaults
    _G.config = notes.get_config()
  ]])
  
  local config = child.lua_get('_G.config')
  
  -- Check default configuration structure
  MiniTest.expect.equality(type(config), 'table')
  MiniTest.expect.equality(type(config.visualization), 'table')
  MiniTest.expect.equality(type(config.visualization.charts), 'table')
  MiniTest.expect.equality(type(config.notifications), 'table')
  
  -- Check default values
  MiniTest.expect.equality(config.visualization.charts.histogram.width, 60)
  MiniTest.expect.equality(config.charts.pie_chart.radius, 8)
  MiniTest.expect.equality(config.data.date_format, "short")
  MiniTest.expect.equality(config.display.use_emojis, true)
end

T['setup_config']['custom_setup'] = function()
  child.lua([[
    local notes = require('notes')
    notes.setup({
      charts = {
        histogram = { width = 60 },
        pie_chart = { style = "unicode", radius = 12 }
      },
      data = {
        date_format = "medium",
        truncate_length = 25
      },
      display = {
        use_emojis = false,
        show_debug = true
      }
    })
    _G.config = notes.get_config()
  ]])
  
  local config = child.lua_get('_G.config')
  
  -- Check custom values were applied
  MiniTest.expect.equality(config.charts.histogram.width, 60)
  MiniTest.expect.equality(config.charts.pie_chart.style, "unicode")
  MiniTest.expect.equality(config.visualization.charts.pie_chart.radius, 12)
  MiniTest.expect.equality(config.visualization.data.date_format, "medium")
  MiniTest.expect.equality(config.visualization.data.truncate_length, 40)
  MiniTest.expect.equality(config.visualization.display.use_emojis, true)
  MiniTest.expect.equality(config.notifications.enabled, true)
  
  -- Check that non-overridden defaults remain
  MiniTest.expect.equality(config.visualization.charts.line_plot.width, 70) -- default
  MiniTest.expect.equality(config.visualization.data.productivity_weights.created, 1) -- default
end

T['setup_config']['partial_override'] = function()
  child.lua([[
    local notes = require('notes')
    notes.setup({
      charts = {
        histogram = { show_values = false } -- Only override one property
      }
    })
    _G.config = notes.get_config()
  ]])
  
  local config = child.lua_get('_G.config')
  
  -- Check that partial override works
  MiniTest.expect.equality(config.visualization.charts.histogram.show_values, false)
  MiniTest.expect.equality(config.visualization.charts.histogram.width, 60) -- Should keep default
end

-- Test convenience functions
T['convenience_functions'] = MiniTest.new_set()

T['convenience_functions']['convenience_shortcuts'] = function()
  child.lua([[
    local notes = require('notes')
    notes.setup({display = {show_debug = false}})
    
    -- Mock print to capture output
    local output = {}
    local old_print = print
    print = function(...) 
      table.insert(output, table.concat({...}, " "))
    end
    
    -- Test convenience functions (they should not error)
    local ok1, err1 = pcall(notes.personal)
    local ok2, err2 = pcall(notes.work)  
    local ok3, err3 = pcall(notes.completions, 7)
    local ok4, err4 = pcall(notes.states)
    
    print = old_print
    
    _G.results = {
      personal = {ok1, err1},
      work = {ok2, err2}, 
      completions = {ok3, err3},
      states = {ok4, err4},
      output_count = #output
    }
  ]])
  
  local results = child.lua_get('_G.results')
  
  -- All convenience functions should execute without error
  MiniTest.expect.equality(results.personal[1], true)
  MiniTest.expect.equality(results.work[1], true)
  MiniTest.expect.equality(results.completions[1], true)
  MiniTest.expect.equality(results.states[1], true)
  
  -- Should have produced some output
  MiniTest.expect.equality(results.output_count > 0, true)
end

-- Test high-level visualization functions
T['high_level_functions'] = MiniTest.new_set()

T['high_level_functions']['daily_completions'] = function()
  child.lua([[
    local notes = require('notes')
    notes.setup({display = {show_debug = false}})
    
    -- Capture output
    local output = {}
    local old_print = print
    print = function(...) 
      table.insert(output, table.concat({...}, " "))
    end
    
    notes.daily_completions("personal", 7)
    
    print = old_print
    _G.output = output
  ]])
  
  local output = child.lua_get('_G.output')
  
  -- Should generate output
  MiniTest.expect.equality(#output > 0, true)
  
  -- Should contain histogram title
  local has_title = false
  for _, line in ipairs(output) do
    if line:match("Daily Completions") then
      has_title = true
      break
    end
  end
  MiniTest.expect.equality(has_title, true)
end

T['high_level_functions']['task_states'] = function()
  child.lua([[
    local notes = require('notes')
    notes.setup({
      charts = { pie_chart = { radius = 6, style = "solid" }},
      display = { use_emojis = true, show_debug = false }
    })
    
    local output = {}
    local old_print = print
    print = function(...) 
      table.insert(output, table.concat({...}, " "))
    end
    
    notes.task_states("personal")
    
    print = old_print
    _G.output = output
  ]])
  
  local output = child.lua_get('_G.output')
  
  -- Should generate pie chart output
  MiniTest.expect.equality(#output > 0, true)
  
  -- Should contain pie chart content
  local has_legend = false
  local has_pie_chars = false
  for _, line in ipairs(output) do
    if line:match("Legend:") then
      has_legend = true
    end
    if line:match("[█▓▒░]") then
      has_pie_chars = true
    end
  end
  MiniTest.expect.equality(has_legend, true)
  MiniTest.expect.equality(has_pie_chars, true)
end

T['high_level_functions']['recent_activity'] = function()
  child.lua([[
    local notes = require('notes')
    notes.setup({
      charts = { table = { show_borders = true }},
      display = { use_emojis = true, show_debug = false }
    })
    
    local output = {}
    local old_print = print
    print = function(...) 
      table.insert(output, table.concat({...}, " "))
    end
    
    notes.recent_activity("personal", 5)
    
    print = old_print
    _G.output = output
  ]])
  
  local output = child.lua_get('_G.output')
  
  -- Should generate table output
  MiniTest.expect.equality(#output > 0, true)
  
  -- Should contain table borders
  local has_borders = false
  for _, line in ipairs(output) do
    if line:match("[┌┐└┘│─]") then
      has_borders = true
      break
    end
  end
  MiniTest.expect.equality(has_borders, true)
end

T['high_level_functions']['productivity_trend'] = function()
  child.lua([[
    local notes = require('notes')
    notes.setup({
      data = { 
        productivity_weights = { created = 1, completed = 3, carried_over = -2 }
      },
      display = { show_debug = false }
    })
    
    local output = {}
    local old_print = print
    print = function(...) 
      table.insert(output, table.concat({...}, " "))
    end
    
    notes.productivity_trend("personal", 14)
    
    print = old_print
    _G.output = output
  ]])
  
  local output = child.lua_get('_G.output')
  
  -- Should generate line plot output
  MiniTest.expect.equality(#output > 0, true)
  
  -- Should contain formula explanation
  local has_formula = false
  for _, line in ipairs(output) do
    if line:match("Formula:") then
      has_formula = true
      break
    end
  end
  MiniTest.expect.equality(has_formula, true)
end

T['high_level_functions']['dashboard'] = function()
  child.lua([[
    local notes = require('notes')
    notes.setup({display = {show_debug = false}})
    
    local output = {}
    local old_print = print
    print = function(...) 
      table.insert(output, table.concat({...}, " "))
    end
    
    notes.dashboard("personal", {compact = true})
    
    print = old_print
    _G.output = output
  ]])
  
  local output = child.lua_get('_G.output')
  
  -- Dashboard should generate substantial output
  MiniTest.expect.equality(#output > 10, true) -- Should be many lines
  
  -- Should contain dashboard header
  local has_dashboard = false
  for _, line in ipairs(output) do
    if line:match("DASHBOARD") then
      has_dashboard = true
      break
    end
  end
  MiniTest.expect.equality(has_dashboard, true)
end

-- Test error handling and edge cases
T['error_handling'] = MiniTest.new_set()

T['error_handling']['missing_database'] = function()
  child.lua([[
    local notes = require('notes')
    notes.setup({
      database = { 
        personal_path = "/nonexistent/path/db.sqlite" 
      },
      display = { show_debug = false }
    })
    
    local output = {}
    local old_print = print
    print = function(...) 
      table.insert(output, table.concat({...}, " "))
    end
    
    -- Should handle missing database gracefully
    notes.daily_completions("personal", 7)
    
    print = old_print
    _G.output = output
  ]])
  
  local output = child.lua_get('_G.output')
  
  -- Should show error message about database
  local has_error = false
  for _, line in ipairs(output) do
    if line:match("Database not available") then
      has_error = true
      break
    end
  end
  MiniTest.expect.equality(has_error, true)
end

T['error_handling']['invalid_db_type'] = function()
  child.lua([[
    local notes = require('notes')
    notes.setup({display = {show_debug = false}})
    
    local output = {}
    local old_print = print
    print = function(...) 
      table.insert(output, table.concat({...}, " "))
    end
    
    -- Test with invalid database type
    notes.dashboard("invalid_db_type")
    
    print = old_print
    _G.output = output
  ]])
  
  local output = child.lua_get('_G.output')
  
  -- Should handle gracefully
  MiniTest.expect.equality(#output > 0, true)
end

-- Test module exposure
T['module_exposure'] = MiniTest.new_set()

T['module_exposure']['submodules_accessible'] = function()
  child.lua([[
    local notes = require('notes')
    
    _G.has_plot = notes.plot ~= nil
    _G.has_utils = notes.utils ~= nil
    
    -- Test that submodules work
    if notes.plot then
      local data = {{label = "Test", value = 5}}
      _G.plot_works = type(notes.plot.histogram(data)) == "table"
    end
    
    if notes.utils then
      _G.utils_works = type(notes.utils.format_date("2024-09-11", "short")) == "string"
    end
  ]])
  
  local has_plot = child.lua_get('_G.has_plot')
  local has_utils = child.lua_get('_G.has_utils')
  local plot_works = child.lua_get('_G.plot_works')
  local utils_works = child.lua_get('_G.utils_works')
  
  MiniTest.expect.equality(has_plot, true)
  MiniTest.expect.equality(has_utils, true)  
  MiniTest.expect.equality(plot_works, true)
  MiniTest.expect.equality(utils_works, true)
end

return T
