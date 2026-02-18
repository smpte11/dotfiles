-- TEST: Fixed version of init module tests with proper config structure
-- This is a complete rewrite to match the current notes module structure

local MiniTest = require('mini.test')
local helpers = require('tests.helpers')

-- Create child neovim process for isolated testing
local child = MiniTest.new_child_neovim()

-- Test setup
local T = MiniTest.new_set()

-- Set up child environment
T['setup'] = function()
  child.restart({ '-u', 'scripts/minimal_init.lua' })
  child.lua([[M = {}]])
  
  -- Set up the helpers and mocks
  child.lua([=[
    _G.helpers = {}
    
    -- Mock vim object for compatibility
    if not vim then
      _G.vim = {
        tbl_deep_extend = function(behavior, ...)
          local result = {}
          for i = 1, select('#', ...) do
            local tbl = select(i, ...)
            if type(tbl) == 'table' then
              for k, v in pairs(tbl) do
                result[k] = v
              end
            end
          end
          return result
        end,
        fn = {
          expand = function(path) return path:gsub("^~/", os.getenv("HOME") .. "/") end,
          filereadable = function(file) local f = io.open(file, "r"); if f then f:close(); return 1 else return 0 end end
        },
        log = { levels = { ERROR = 1, WARN = 2, INFO = 3, DEBUG = 4 } },
        notify = function(msg, level, opts) print("[NOTIFY] " .. msg) end
      }
    end
    
    -- Mock sqlite for testing
    _G.sqlite = {
      new = function(path)
        return {
          open = function() return true end,
          close = function() end,
          execute = function(sql) return true end,
          eval = function(sql, params)
            if sql:match("COUNT") then
              return {{count = 5}}
            elseif sql:match("SELECT.*day") then
              return {
                {day = "2024-09-20", count = 2},
                {day = "2024-09-21", count = 1},
                {day = "2024-09-22", count = 3}
              }
            elseif sql:match("SELECT.*state") then
              return {
                {state = "CREATED", count = 5},
                {state = "FINISHED", count = 3},
                {state = "IN_PROGRESS", count = 2}
              }
            else
              return {}
            end
          end
        }
      end
    }
    
    -- Load the notes module
    package.loaded['sqlite'] = _G.sqlite
  ]=])
end

T['teardown'] = function()
  child.stop()
end

-- Test basic functionality
T['basic_functionality'] = MiniTest.new_set()

T['basic_functionality']['module_loads'] = function()
  child.lua([[
    local notes = require('notes')
    _G.module_type = type(notes)
    _G.has_setup = type(notes.setup) == 'function'
  ]])
  
  local module_type = child.lua_get('_G.module_type')
  local has_setup = child.lua_get('_G.has_setup')
  
  MiniTest.expect.equality(module_type, 'table')
  MiniTest.expect.equality(has_setup, true)
end

T['basic_functionality']['setup_works'] = function()
  child.lua([[
    local notes = require('notes')
    local config = notes.setup({
      visualization = { enabled = true },
      notifications = { enabled = false }
    })
    _G.config_returned = type(config) == 'table'
    _G.is_ready = notes.is_ready()
  ]])
  
  local config_returned = child.lua_get('_G.config_returned')
  local is_ready = child.lua_get('_G.is_ready')
  
  MiniTest.expect.equality(config_returned, true)
  MiniTest.expect.equality(is_ready, true)
end

-- Test API functions exist
T['api_functions'] = MiniTest.new_set()

T['api_functions']['all_functions_exist'] = function()
  child.lua([[
    local notes = require('notes')
    notes.setup() -- Initialize
    
    _G.functions = {
      personal = type(notes.personal) == 'function',
      work = type(notes.work) == 'function',
      help = type(notes.help) == 'function',
      health = type(notes.health) == 'function',
      dashboard = type(notes.dashboard) == 'function',
      recent_activity = type(notes.recent_activity) == 'function'
    }
  ]])
  
  local functions = child.lua_get('_G.functions')
  
  MiniTest.expect.equality(functions.personal, true)
  MiniTest.expect.equality(functions.work, true) 
  MiniTest.expect.equality(functions.help, true)
  MiniTest.expect.equality(functions.health, true)
  MiniTest.expect.equality(functions.dashboard, true)
  MiniTest.expect.equality(functions.recent_activity, true)
end

-- Test help and documentation functions work
T['documentation'] = MiniTest.new_set()

T['documentation']['help_functions_callable'] = function()
  child.lua([[
    local notes = require('notes')
    notes.setup()
    
    -- Test help functions don't crash
    local ok1, _ = pcall(notes.help)
    local ok2, _ = pcall(notes.health)
    local ok3, _ = pcall(notes.config)
    local ok4, _ = pcall(notes.examples)
    
    _G.help_results = { ok1, ok2, ok3, ok4 }
  ]])
  
  local results = child.lua_get('_G.help_results')
  
  MiniTest.expect.equality(results[1], true) -- help
  MiniTest.expect.equality(results[2], true) -- health
  MiniTest.expect.equality(results[3], true) -- config
  MiniTest.expect.equality(results[4], true) -- examples
end

-- Test configuration system
T['configuration'] = MiniTest.new_set()

T['configuration']['default_config_valid'] = function()
  child.lua([[
    local notes = require('notes')
    local config = notes.setup()
    
    _G.has_visualization = type(config.visualization) == 'table'
    _G.has_notifications = type(config.notifications) == 'table'
    _G.has_directories = type(config.directories) == 'table'
    _G.has_tracking = type(config.tracking) == 'table'
  ]])
  
  local has_visualization = child.lua_get('_G.has_visualization')
  local has_notifications = child.lua_get('_G.has_notifications')
  local has_directories = child.lua_get('_G.has_directories')
  local has_tracking = child.lua_get('_G.has_tracking')
  
  MiniTest.expect.equality(has_visualization, true)
  MiniTest.expect.equality(has_notifications, true)  
  MiniTest.expect.equality(has_directories, true)
  MiniTest.expect.equality(has_tracking, true)
end

-- Test that visualization functions don't crash with mocked data
T['visualization'] = MiniTest.new_set()

T['visualization']['functions_dont_crash'] = function()
  child.lua([[
    local notes = require('notes')
    notes.setup({
      tracking = {
        test = {
          enabled = true,
          filename_patterns = {"test%.md$"},
          database_path = "/tmp/test.db"
        }
      }
    })
    
    -- These should not crash with mocked sqlite
    local ok1, _ = pcall(notes.personal)
    local ok2, _ = pcall(notes.work)
    
    _G.viz_results = { ok1, ok2 }
  ]])
  
  local results = child.lua_get('_G.viz_results')
  
  MiniTest.expect.equality(results[1], true)
  MiniTest.expect.equality(results[2], true)
end

return T
