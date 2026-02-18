# Justfile for notes visualization module tests
# Uses mini.test for comprehensive testing

# Default recipe
default: test-all

# Individual test recipes
test-plot: setup-deps
    echo "🧪 Running plot module tests..."
    nvim --headless -u scripts/minimal_init.lua -c "lua require('mini.test').execute(require('tests.test_notes_plot'))" -c "qa!"

test-utils: setup-deps
    echo "🔧 Running utils module tests..."
    nvim --headless -u scripts/minimal_init.lua -c "lua require('mini.test').execute(require('tests.test_notes_utils'))" -c "qa!"

test-init: setup-deps
    echo "⚙️ Running init module tests..."
    nvim --headless -u scripts/minimal_init.lua -c "lua require('mini.test').execute(require('tests.test_notes_init'))" -c "qa!"

test-migrations: setup-deps
    echo "🔄 Running database migration tests..."
    nvim --headless -u scripts/minimal_init.lua -c "lua require('mini.test').setup(); MiniTest.run_file('tests/test_notes_migrations.lua')" -c "qa!"

# Test diffview keymaps integration
test-diffview:
    echo "🔧 Testing diffview keymaps integration..."
    nvim --headless -c "luafile tests/test_diffview_keymaps.lua" -c "qa"

# Run all tests
test-all: setup-deps
    echo "🚀 Running all notes module tests..."
    echo "======================================="
    just test-plot
    echo ""
    just test-utils
    echo ""
    just test-init
    echo ""
    just test-migrations
    echo ""
    echo "✅ All tests completed!"

# Alias for test-all
test: test-all

# Interactive test mode (opens in Neovim)
test-interactive:
    echo "🖥️ Opening interactive test mode..."
    nvim -u scripts/minimal_init.lua -c "lua require('mini.test').execute(require('tests.test_notes_plot'))"

# Set up dependencies
setup-deps:
    echo "📦 Setting up test dependencies..."
    mkdir -p deps
    bash -c 'if [ ! -d "deps/mini.nvim" ]; then echo "Cloning mini.nvim..."; git clone https://github.com/echasnovski/mini.nvim deps/mini.nvim; else echo "mini.nvim already exists"; fi'
    mkdir -p /tmp/test_notebooks
    echo "✅ Dependencies ready!"

# Test specific function or module
test-function:
    bash -c 'read -p "Enter test pattern (e.g., histogram, pie_chart): " pattern; nvim --headless -u scripts/minimal_init.lua -c "lua require(\"mini.test\").execute(require(\"tests.test_notes_plot\"), {filter = \"$pattern\"})" -c "qa!"'

# Clean test artifacts
clean:
    echo "🧹 Cleaning test artifacts..."
    rm -rf /tmp/test_notebooks
    echo "✅ Clean complete!"

# Lint the test files
lint-tests:
    echo "🔍 Linting test files..."
    bash -c 'for file in tests/test_*.lua; do echo "Checking $file..."; luacheck "$file" --globals vim MiniTest || true; done'

# Show test coverage (manual inspection)
coverage:
    echo "📊 Test coverage analysis:"
    echo "Plot module functions:"
    -grep -n "^function M\." lua/notes/plot.lua
    echo ""
    echo "Utils module functions:"
    -grep -n "^function M\." lua/notes/utils.lua
    echo ""
    echo "Init module functions:"
    -grep -n "^function M\." lua/notes/init.lua

# Run specific test suite with verbose output
verbose:
    bash -c 'read -p "Enter test file (plot/utils/init/migrations): " module; nvim --headless -u scripts/minimal_init.lua -c "lua MiniTest = require(\"mini.test\"); MiniTest.execute(require(\"tests.test_notes_$module\"), {verbose = true})" -c "qa!"'

# Help recipe
help:
    echo "📖 Available recipes:"
    echo "  default           - Run all tests (default)"
    echo "  test              - Run all tests (alias)"
    echo "  test-plot         - Test plotting functions"
    echo "  test-utils        - Test utility functions"
    echo "  test-init         - Test main module and setup"
    echo "  test-migrations   - Test database migration system"
    echo "  test-all          - Run all test suites"
    echo "  test-interactive  - Open tests in Neovim"
    echo "  test-function     - Test specific function pattern"
    echo "  setup-deps        - Set up mini.nvim dependency"
    echo "  clean             - Clean test artifacts"
    echo "  lint-tests        - Lint test files"
    echo "  coverage          - Show function coverage"
    echo "  verbose           - Run tests with verbose output"
    echo "  help              - Show this help"
