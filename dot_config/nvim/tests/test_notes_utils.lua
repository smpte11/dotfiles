-- Tests for notes.utils module  
-- Tests data conversion, formatting, and utility functions

local helpers = require('tests.helpers')
helpers.setup_vim_mocks()

local MiniTest = require('mini.test')
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ '-u', 'scripts/minimal_init.lua' })
      child.lua('package.path = package.path .. ";./?.lua;./?/init.lua"')
    end,
  },
})

-- Test data conversion functions
T['data_conversion'] = MiniTest.new_set()

T['data_conversion']['sql_to_chart_data'] = function()
  child.lua([[
    local utils = require('notes.utils')
    local sql_results = {
      {date = "2024-09-09", count = 5},
      {date = "2024-09-10", count = 8},
      {date = "2024-09-11", count = 3}
    }
    _G.result = utils.sql_to_chart_data(sql_results, "date", "count")
  ]])
  
  local result = child.lua_get('_G.result')
  
  -- Should convert to proper chart format
  MiniTest.expect.equality(type(result), 'table')
  MiniTest.expect.equality(#result, 3)
  MiniTest.expect.equality(result[1].label, "2024-09-09")
  MiniTest.expect.equality(result[1].value, 5)
  MiniTest.expect.equality(result[2].label, "2024-09-10") 
  MiniTest.expect.equality(result[2].value, 8)
end

T['data_conversion']['sql_to_chart_data_empty'] = function()
  child.lua([[
    local utils = require('notes.utils')
    _G.result1 = utils.sql_to_chart_data(nil, "date", "count")
    _G.result2 = utils.sql_to_chart_data({}, "date", "count")
  ]])
  
  local result1 = child.lua_get('_G.result1')
  local result2 = child.lua_get('_G.result2')
  
  MiniTest.expect.equality(type(result1), 'table')
  MiniTest.expect.equality(#result1, 0)
  MiniTest.expect.equality(type(result2), 'table')
  MiniTest.expect.equality(#result2, 0)
end

T['data_conversion']['sql_to_table_data'] = function()
  child.lua([[
    local utils = require('notes.utils')
    local sql_results = {
      {task = "Task A", state = "FINISHED", date = "2024-09-11"},
      {task = "Task B", state = "IN_PROGRESS", date = "2024-09-10"}
    }
    _G.result = utils.sql_to_table_data(sql_results, {"task", "state", "date"})
  ]])
  
  local result = child.lua_get('_G.result')
  
  MiniTest.expect.equality(type(result), 'table')
  MiniTest.expect.equality(#result, 2)
  MiniTest.expect.equality(result[1][1], "Task A")
  MiniTest.expect.equality(result[1][2], "FINISHED") 
  MiniTest.expect.equality(result[2][1], "Task B")
  MiniTest.expect.equality(result[2][2], "IN_PROGRESS")
end

-- Test text enhancement functions
T['text_enhancement'] = MiniTest.new_set()

T['text_enhancement']['add_state_emoji'] = function()
  child.lua([[
    local utils = require('notes.utils')
    _G.finished = utils.add_state_emoji("FINISHED")
    _G.progress = utils.add_state_emoji("IN_PROGRESS")
    _G.created = utils.add_state_emoji("CREATED")
    _G.deleted = utils.add_state_emoji("DELETED")
    _G.unknown = utils.add_state_emoji("UNKNOWN_STATE")
  ]])
  
  local finished = child.lua_get('_G.finished')
  local progress = child.lua_get('_G.progress')
  local created = child.lua_get('_G.created')
  local deleted = child.lua_get('_G.deleted')
  local unknown = child.lua_get('_G.unknown')
  
  MiniTest.expect.equality(finished, "✅ FINISHED")
  MiniTest.expect.equality(progress, "🚀 IN_PROGRESS")
  MiniTest.expect.equality(created, "📝 CREATED")
  MiniTest.expect.equality(deleted, "🗑️ DELETED")
  MiniTest.expect.equality(unknown:match("📄"), "📄") -- default emoji
end

T['text_enhancement']['add_event_emoji'] = function()
  child.lua([[
    local utils = require('notes.utils')
    _G.created = utils.add_event_emoji("task_created")
    _G.completed = utils.add_event_emoji("task_completed")
    _G.started = utils.add_event_emoji("task_started")
    _G.carried = utils.add_event_emoji("task_carried_over")
    _G.unknown = utils.add_event_emoji("unknown_event")
  ]])
  
  local created = child.lua_get('_G.created')
  local completed = child.lua_get('_G.completed')
  local started = child.lua_get('_G.started')
  local carried = child.lua_get('_G.carried')
  local unknown = child.lua_get('_G.unknown')
  
  MiniTest.expect.equality(created, "➕ task_created")
  MiniTest.expect.equality(completed, "✅ task_completed")
  MiniTest.expect.equality(started, "🚀 task_started")
  MiniTest.expect.equality(carried, "⏭️ task_carried_over")
  MiniTest.expect.equality(unknown:match("📋"), "📋") -- default emoji
end

-- Test date formatting functions
T['date_formatting'] = MiniTest.new_set()

T['date_formatting']['format_date_variants'] = function()
  child.lua([[
    local utils = require('notes.utils')
    local date = "2024-09-11"
    _G.short = utils.format_date(date, "short")
    _G.medium = utils.format_date(date, "medium")
    _G.long = utils.format_date(date, "long")
    _G.default = utils.format_date(date) -- should default to short
  ]])
  
  local short = child.lua_get('_G.short')
  local medium = child.lua_get('_G.medium') 
  local long = child.lua_get('_G.long')
  local default = child.lua_get('_G.default')
  
  MiniTest.expect.equality(short, "09/11")
  MiniTest.expect.equality(medium, "Sep 11")
  MiniTest.expect.equality(long, "Sep 11, 2024")
  MiniTest.expect.equality(default, "09/11") -- should match short
end

T['date_formatting']['format_date_invalid'] = function()
  child.lua([[
    local utils = require('notes.utils')
    _G.empty = utils.format_date("", "short")
    _G.nil_date = utils.format_date(nil, "short")
    _G.invalid = utils.format_date("not-a-date", "short")
  ]])
  
  local empty = child.lua_get('_G.empty')
  local nil_date = child.lua_get('_G.nil_date')
  local invalid = child.lua_get('_G.invalid')
  
  MiniTest.expect.equality(empty, "Unknown")
  MiniTest.expect.equality(nil_date, "Unknown")
  MiniTest.expect.equality(invalid, "not-a-date") -- returns as-is if not parseable
end

T['date_formatting']['relative_date'] = function()
  -- Mock current time for predictable testing
  child.lua([[
    local utils = require('notes.utils')
    local today = os.date("%Y-%m-%d")
    local yesterday = os.date("%Y-%m-%d", os.time() - 24 * 60 * 60)
    
    _G.today_result = utils.relative_date(today)
    _G.yesterday_result = utils.relative_date(yesterday)
    _G.empty_result = utils.relative_date("")
  ]])
  
  local today_result = child.lua_get('_G.today_result')
  local yesterday_result = child.lua_get('_G.yesterday_result')
  local empty_result = child.lua_get('_G.empty_result')
  
  MiniTest.expect.equality(today_result, "Today")
  MiniTest.expect.equality(yesterday_result, "Yesterday")
  MiniTest.expect.equality(empty_result, "Unknown")
end

-- Test mathematical utilities
T['mathematical'] = MiniTest.new_set()

T['mathematical']['calculate_productivity_score'] = function()
  child.lua([[
    local utils = require('notes.utils')
    
    -- Default weights: created=1, completed=2, carried_over=-1
    _G.default_score = utils.calculate_productivity_score(5, 8, 2)
    
    -- Custom weights
    local custom_weights = {created = 2, completed = 3, carried_over = -2}
    _G.custom_score = utils.calculate_productivity_score(5, 8, 2, custom_weights)
    
    -- Edge cases
    _G.zero_score = utils.calculate_productivity_score(0, 0, 0)
    _G.nil_score = utils.calculate_productivity_score(nil, nil, nil)
  ]])
  
  local default_score = child.lua_get('_G.default_score')
  local custom_score = child.lua_get('_G.custom_score')
  local zero_score = child.lua_get('_G.zero_score')
  local nil_score = child.lua_get('_G.nil_score')
  
  -- Default: 5*1 + 8*2 + 2*(-1) = 5 + 16 - 2 = 19
  MiniTest.expect.equality(default_score, 19)
  
  -- Custom: 5*2 + 8*3 + 2*(-2) = 10 + 24 - 4 = 30
  MiniTest.expect.equality(custom_score, 30)
  
  MiniTest.expect.equality(zero_score, 0)
  MiniTest.expect.equality(nil_score, 0)
end

T['mathematical']['date_range'] = function()
  child.lua([[
    local utils = require('notes.utils')
    local start_date, end_date = utils.date_range(7)
    _G.start_date = start_date
    _G.end_date = end_date
    
    -- Test with custom days
    local start_14, end_14 = utils.date_range(14)
    _G.start_14 = start_14
    _G.end_14 = end_14
  ]])
  
  local start_date = child.lua_get('_G.start_date')
  local end_date = child.lua_get('_G.end_date')
  local start_14 = child.lua_get('_G.start_14')
  local end_14 = child.lua_get('_G.end_14')
  
  -- Should be ISO date format
  MiniTest.expect.equality(start_date:match("%d%d%d%d%-%d%d%-%d%d") ~= nil, true)
  MiniTest.expect.equality(end_date:match("%d%d%d%d%-%d%d%-%d%d") ~= nil, true)
  MiniTest.expect.equality(start_14:match("%d%d%d%d%-%d%d%-%d%d") ~= nil, true)
  MiniTest.expect.equality(end_14:match("%d%d%d%d%-%d%d%-%d%d") ~= nil, true)
  
  -- 14-day range should start earlier than 7-day range
  MiniTest.expect.equality(start_14 < start_date, true)
  MiniTest.expect.equality(end_14, end_date) -- Same end date (today)
end

-- Test text processing utilities  
T['text_processing'] = MiniTest.new_set()

T['text_processing']['truncate_text'] = function()
  child.lua([[
    local utils = require('notes.utils')
    
    local long_text = "This is a very long task description that should be truncated"
    _G.truncated = utils.truncate_text(long_text, 20)
    _G.truncated_custom = utils.truncate_text(long_text, 25, ">>")
    _G.short_text = utils.truncate_text("Short", 20)
    _G.exact_length = utils.truncate_text("Exactly twenty chars", 20)
  ]])
  
  local truncated = child.lua_get('_G.truncated')
  local truncated_custom = child.lua_get('_G.truncated_custom')
  local short_text = child.lua_get('_G.short_text')
  local exact_length = child.lua_get('_G.exact_length')
  
  MiniTest.expect.equality(#truncated, 20)
  MiniTest.expect.equality(truncated:match("%.%.%.$") ~= nil, true) -- ends with ...
  MiniTest.expect.equality(truncated_custom:match(">>$") ~= nil, true) -- ends with >>
  MiniTest.expect.equality(short_text, "Short") -- unchanged if short
  MiniTest.expect.equality(exact_length, "Exactly twenty chars") -- unchanged if exact
end

T['text_processing']['clean_task_text'] = function()
  child.lua([[
    local utils = require('notes.utils')
    
    _G.with_uri = utils.clean_task_text("Review PR #123 [ ](task://abc-123)")
    _G.with_checkbox = utils.clean_task_text("- [x] Complete the task")
    _G.extra_spaces = utils.clean_task_text("  Task   with   spaces  ")
    _G.empty = utils.clean_task_text("")
    _G.nil_text = utils.clean_task_text(nil)
  ]])
  
  local with_uri = child.lua_get('_G.with_uri')
  local with_checkbox = child.lua_get('_G.with_checkbox') 
  local extra_spaces = child.lua_get('_G.extra_spaces')
  local empty = child.lua_get('_G.empty')
  local nil_text = child.lua_get('_G.nil_text')
  
  MiniTest.expect.equality(with_uri, "Review PR #123")
  MiniTest.expect.equality(with_checkbox, "Complete the task")
  MiniTest.expect.equality(extra_spaces, "Task with spaces")
  MiniTest.expect.equality(empty, "Unknown task")
  MiniTest.expect.equality(nil_text, "Unknown task")
end

-- Test aggregation utilities
T['aggregation'] = MiniTest.new_set()

T['aggregation']['group_by_period'] = function()
  child.lua([[
    local utils = require('notes.utils')
    
    local daily_data = {
      {date = "2024-09-09", value = 5},
      {date = "2024-09-10", value = 3},
      {date = "2024-09-11", value = 7},
      {date = "2024-09-16", value = 2}, -- Different week
      {date = "2024-09-17", value = 4}
    }
    
    _G.by_day = utils.group_by_period(daily_data, "day")
    _G.by_week = utils.group_by_period(daily_data, "week") 
    _G.by_month = utils.group_by_period(daily_data, "month")
  ]])
  
  local by_day = child.lua_get('_G.by_day')
  local by_week = child.lua_get('_G.by_week')
  local by_month = child.lua_get('_G.by_month')
  
  -- Daily should be unchanged
  MiniTest.expect.equality(#by_day, 5)
  
  -- Weekly should group by week (test with actual numbers)
  -- The test data spans 2 different weeks, so by_week should have 2 entries
  MiniTest.expect.equality(#by_week, 2)
  MiniTest.expect.equality(#by_week < #by_day, true)
  
  -- Monthly should have 1 entry (all September)
  MiniTest.expect.equality(#by_month, 1)
  MiniTest.expect.equality(#by_month <= #by_week, true)
end

T['aggregation']['moving_average'] = function()
  child.lua([[
    local utils = require('notes.utils')
    
    local data = {
      {label = "Day 1", value = 10},
      {label = "Day 2", value = 20}, 
      {label = "Day 3", value = 30},
      {label = "Day 4", value = 40},
      {label = "Day 5", value = 50}
    }
    
    _G.ma3 = utils.moving_average(data, 3)
    _G.ma5 = utils.moving_average(data, 5)
    _G.insufficient = utils.moving_average({data[1], data[2]}, 5) -- Not enough data
  ]])
  
  local ma3 = child.lua_get('_G.ma3')
  local ma5 = child.lua_get('_G.ma5')
  local insufficient = child.lua_get('_G.insufficient')
  
  -- 3-period MA should have 3 entries (5-3+1)
  MiniTest.expect.equality(#ma3, 3)
  
  -- First MA3 value should be average of first 3: (10+20+30)/3 = 20
  MiniTest.expect.equality(ma3[1].value, 20)
  
  -- 5-period MA should have 1 entry
  MiniTest.expect.equality(#ma5, 1)
  MiniTest.expect.equality(ma5[1].value, 30) -- (10+20+30+40+50)/5 = 30
  
  -- Insufficient data should return original
  MiniTest.expect.equality(#insufficient, 2)
end

return T
