# 🧪 Testing Guide for Notes Visualization Module

Comprehensive test suite using **mini.test** for the notes visualization system.

## 📁 Test Structure

```
tests/
├── helpers.lua              # Shared test utilities and mocks
├── test_notes_plot.lua      # Tests for plotting functions
├── test_notes_utils.lua     # Tests for utility functions  
├── test_notes_init.lua      # Tests for main module & setup
└── test_notes_migrations.lua # Tests for database migrations

scripts/
└── minimal_init.lua         # Minimal config for test environment

deps/
└── mini.nvim/              # mini.test dependency (auto-cloned)

# Test runners
├── justfile                 # Just recipes for easy testing
├── run_tests.lua           # Lua-based test runner
└── TESTING.md              # This file
```

## 🚀 Quick Start

### Run All Tests
```bash
just test
```

### Run Specific Test Suites  
```bash
just test-plot        # Plot functions only
just test-utils       # Utility functions only  
just test-init        # Main module only
just test-migrations  # Database migration system only
```

### Alternative Test Runner
```bash
nvim -l run_tests.lua all          # All tests
nvim -l run_tests.lua plot         # Plot tests only
nvim -l run_tests.lua utils        # Utils tests only
nvim -l run_tests.lua init         # Init tests only
nvim -l run_tests.lua migrations   # Migration tests only
```

## 📊 Test Coverage

### Plot Module (`lua/notes/plot.lua`)
- ✅ **histogram()** - Basic histogram, empty data, custom options
- ✅ **pie_chart()** - Circular pie charts, different styles, legend
- ✅ **line_plot()** - Basic line plots, axes, single point
- ✅ **table()** - Bordered/borderless tables, headers
- ✅ **Alternative data formats** - Array vs object format

**Coverage: 5 functions, 15+ test cases**

### Utils Module (`lua/notes/utils.lua`)
- ✅ **Data Conversion**
  - `sql_to_chart_data()` - SQL → chart format
  - `sql_to_table_data()` - SQL → table format
- ✅ **Text Enhancement**
  - `add_state_emoji()` - State emojis (✅🚀📝🗑️)
  - `add_event_emoji()` - Event emojis (➕✅🚀⏭️)
- ✅ **Date Formatting**  
  - `format_date()` - Short/medium/long formats
  - `relative_date()` - Today/yesterday/N days ago
- ✅ **Mathematical**
  - `calculate_productivity_score()` - Custom scoring
  - `date_range()` - Date range generation
- ✅ **Text Processing**
  - `truncate_text()` - Smart truncation
  - `clean_task_text()` - Remove markdown/URIs
- ✅ **Aggregation**
  - `group_by_period()` - Day/week/month grouping
  - `moving_average()` - Trend smoothing

**Coverage: 12 functions, 25+ test cases**

### Init Module (`lua/notes/init.lua`)
- ✅ **Setup & Configuration**
  - Default configuration
  - Custom configuration  
  - Partial overrides
- ✅ **High-Level Functions**
  - `daily_completions()` - Completion charts
  - `task_states()` - State pie charts
  - `recent_activity()` - Activity tables
  - `productivity_trend()` - Trend plots
  - `dashboard()` - Combined view
- ✅ **Convenience Functions**
  - `personal()`, `work()`, `completions()`, `states()`
- ✅ **Error Handling**
  - Missing database graceful handling
  - Invalid parameters
- ✅ **Module Exposure**
  - Access to `notes.plot` and `notes.utils`

**Coverage: 10+ functions, 15+ test cases**

### Migration Module (`lua/notes/init.lua` - Migration Functions)
- ✅ **Schema Detection**
  - `column_exists()` - Detect missing columns
  - Simple migration detection
- ✅ **Migration Execution**  
  - `M._run_database_migrations()` - Add nullable parent_id column and index
  - Error handling and notifications
- ✅ **URI Parsing**
  - `M._parse_task_uri()` - Parent-child relationships
  - Query parameter handling
- ✅ **Task Hierarchy**
  - `M.get_child_tasks()` - Find child tasks
  - `M.get_parent_task()` - Find parent task
  - `M.get_task_hierarchy()` - Full hierarchy trees
- ✅ **Simple Operations**
  - Consistent INSERT with parent_id column (nullable)
  - Old tasks have NULL parent_id, new tasks can have parent
- ✅ **Backward Compatibility**
  - Single migration adds nullable column
  - All INSERTs use same SQL format
  - Simple and reliable

**Coverage: 6+ functions, 13 test cases**

## 🔧 Test Utilities

### Mock System (`tests/helpers.lua`)
- **Vim API mocks** - For standalone testing
- **Sample data generators** - Consistent test data
- **Chart validators** - Verify output structure
- **SQLite mocks** - Database simulation
- **Output capture** - Test print-based functions

### Test Environment
- **Isolated environment** - Clean test state
- **Mock databases** - `/tmp/test_notebooks/`  
- **Dependency management** - Auto-setup mini.nvim
- **Cross-platform** - Works on macOS/Linux

## 📖 Test Examples

### Testing Plot Functions
```lua
T['histogram']['basic_histogram'] = function()
  local data = {{label = "Day 1", value = 5}, {label = "Day 2", value = 8}}
  
  child.lua([[
    local plot = require('notes.plot')
    local data = {
      {label = "Day 1", value = 5},
      {label = "Day 2", value = 8}
    }
    _G.result = plot.histogram(data, {title = "Test", width = 30})
  ]])
  
  local result = child.lua_get('_G.result')
  MiniTest.expect.equality(type(result), 'table')
  MiniTest.expect.equality(result[1], "Test") -- Title
  
  -- Validate histogram bars
  local has_bars = false
  for _, line in ipairs(result) do
    if line:match("█") then has_bars = true end
  end
  MiniTest.expect.equality(has_bars, true)
end
```

### Testing Configuration
```lua
T['setup_config']['custom_setup'] = function()
  child.lua([[
    local notes = require('notes')
    notes.setup({
      charts = { histogram = { width = 60 } },
      display = { use_emojis = false }
    })
    _G.config = notes.get_config()
  ]])
  
  local config = child.lua_get('_G.config')
  MiniTest.expect.equality(config.charts.histogram.width, 60)
  MiniTest.expect.equality(config.display.use_emojis, false)
end
```

## 🎯 Running Tests

### Just Recipes
```bash
# Basic testing
just test                 # All tests
just test-plot           # Plot module only
just test-utils          # Utils module only  
just test-init           # Init module only
just test-migrations     # Migration system only

# Advanced options
just test-interactive    # Open in Neovim
just test-function       # Test specific pattern
just verbose             # Verbose output
just lint-tests          # Lint test files
just coverage            # Show coverage info

# Maintenance  
just setup-deps          # Set up dependencies
just clean               # Clean artifacts
just help                # Show all options
```

### Direct Neovim Testing
```bash
# Headless testing
nvim --headless -u scripts/minimal_init.lua \
  -c "lua require('mini.test').execute(require('tests.test_notes_plot'))" \
  -c "qa!"

# Interactive testing  
nvim -u scripts/minimal_init.lua \
  -c "lua require('mini.test').execute(require('tests.test_notes_plot'))"
```

## 🐛 Debugging Tests

### Failed Test Investigation
1. **Run with verbose output**: `just verbose`
2. **Test specific function**: `just test-function`
3. **Interactive mode**: `just test-interactive`
4. **Check logs**: Look for error messages in output

### Common Issues
- **Missing dependencies**: Run `just setup-deps`
- **Path issues**: Verify `lua/` directory structure
- **Mock failures**: Check `tests/helpers.lua` mocks
- **Environment**: Ensure `/tmp/test_notebooks` exists
- **MiniTest in headless mode**: Use `MiniTest.run_file()` instead of `MiniTest.execute()` for proper test collection

## 📈 Test Metrics

### Performance
- **~60 total test cases** across all modules
- **Fast execution** - All tests complete in ~8-12 seconds
- **Isolated runs** - Each test runs in clean environment

### Quality Assurance
- **Comprehensive coverage** - All public functions tested
- **Edge case handling** - Empty data, invalid inputs
- **Error scenarios** - Missing files, bad config
- **Integration testing** - Module interaction verification

## 🚀 Next Steps

### Extending Tests
1. **Add new test case**:
   ```lua
   T['new_feature']['test_case_name'] = function()
     -- Your test here
   end
   ```

2. **Update helpers** for new data patterns
3. **Add to justfile** for new test categories
4. **Update coverage** metrics

### Continuous Integration
- Tests are ready for CI/CD integration  
- All tests are headless-compatible
- No external dependencies beyond mini.nvim
- Cross-platform compatible

## ✅ Verification

The test suite verifies:
- ✅ **All modules load correctly**
- ✅ **Plot functions generate valid output**
- ✅ **Utility functions handle edge cases**
- ✅ **Configuration system works**
- ✅ **Database migrations work safely**
- ✅ **Parent-child task relationships function**
- ✅ **Backward compatibility is maintained**
- ✅ **Error handling is graceful**
- ✅ **Integration between modules**
- ✅ **Performance is acceptable**

Your notes visualization module is **thoroughly tested** and **production ready**! 🎉
