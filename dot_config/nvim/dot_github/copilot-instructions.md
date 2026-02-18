# Copilot Instructions for Neovim Configuration

## Architecture Overview

This is a **Mini.nvim-centric Neovim configuration** designed for productivity and extensibility. The setup uses `mini.deps` for plugin management and follows a two-stage initialization pattern optimizing startup performance.

### Core Architecture Principles

1. **Mini.nvim First**: Built around the mini.nvim ecosystem rather than traditional plugin collections
2. **Two-Stage Loading**: Critical plugins load via `now()`, everything else via `later()` for fast startup
3. **Modular Organization**: Functionality grouped by purpose in separate `/plugin/*.lua` files
4. **Self-Contained Systems**: Custom modules (like notes) are fully contained in `/lua/` subdirectories

### Key Structural Components

1. **Plugin Organization**: `/plugin/` directory contains domain-specific configurations:
   - `ai.lua`: GitHub Copilot + CodeCompanion with local LM Studio integration
   - `programming.lua`: LSP, Treesitter, language-specific tooling (Go, Elixir, Terraform)
   - `system.lua`: File management, terminal integration
   - `ui.lua`: Interface customization and theming
   - `notes.lua`: Custom notes management system (may be extracted to standalone plugin)
   - `octo.lua`, `pipeline.lua`, `tmux.lua`: Specialized workflow integrations

2. **Configuration Layer**: `/lua/` contains reusable modules:
   - `utils.lua`: Shared utilities and ASCII art headers
   - `autocmd.lua`, `cmd.lua`, `keymaps.lua`: Core Neovim configuration
   - `notes/`: Complete notes system with database backend (potential plugin extraction)

3. **Testing Infrastructure**: Comprehensive test suite using `mini.test`:
   - Tests organized in `/tests/` directory
   - `justfile` for convenient test execution
   - Mock system in `tests/helpers.lua`

4. **Mini.nvim Integration**: Deep integration with mini.nvim modules:
   - `mini.pick` for fuzzy finding with custom directory picker
   - `mini.sessions` for session management
   - `mini.statusline`, `mini.tabline` for UI
   - `mini.icons` with custom filetype mappings (gotmpl, chezmoi templates)

## Critical Developer Workflows

### Plugin Management Architecture
- Uses `mini.deps` exclusively - no lazy.nvim, packer, etc.
- Pattern: `local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later`
- `now()`: Load plugins immediately during startup (UI, critical functionality)
- `later()`: Load plugins asynchronously after startup (language servers, optional features)
- Plugin configuration happens inline with plugin loading - no separate config files

### Neovim Configuration Strategy
- `init.lua`: Bootstrap mini.deps, then delegate to plugin files
- Core Neovim settings configured in `now()` blocks for immediate availability
- Custom keymaps, autocmds, and commands in separate `/lua/` modules
- Global utilities accessible via `Utils` namespace

### Keymap Management and Collision Prevention
**CRITICAL**: Always check for keymap collisions before adding new keybindings:
- **Mini.clue submenu prefixes** define hierarchical key groups (e.g., `<leader>g` for git, `<leader>gH` for GitHub)
- **Direct mappings** should not conflict with submenu prefixes or other direct mappings
- **Collision detection process**:
  1. Search for existing keymaps: `grep_search` for the proposed keymap
  2. Check `plugin/01-core.lua` for mini.clue submenu definitions (search for `desc = "`)
  3. Verify no overlap between direct mappings and submenu prefixes
- **Common submenu prefixes**: `<leader>g` (git), `<leader>gh` (GitHub), `<leader>l` (LSP), `<leader>d` (debug), `<leader>a` (AI), etc.
- **Resolution strategy**: Use uppercase letters to differentiate (e.g., `<leader>gH` for git Hunks, `<leader>gh` for github submenu)

### Language Support Patterns
- **Treesitter**: Comprehensive language support including custom `gotmpl` filetype
- **LSP Integration**: Language servers configured per language in `programming.lua`
- **Custom Filetypes**: Helm templates, chezmoi templates with proper detection
- **Go Tooling**: Specialized support with `go.mod` and template handling

### Testing System
```bash
# Run all tests
just test
# Run specific test modules  
just test-plot
just test-utils
just test-init
just test-migrations
```

### Commit Message Conventions
**CRITICAL**: All commit messages MUST follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Common types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring without changing functionality
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks, dependency updates
- `ci`: CI/CD configuration changes

**Examples**:
- `feat(notes): add SQLite-backed task tracking`
- `fix(lsp): resolve gopls configuration issues`
- `docs: update keymap documentation in README`
- `refactor(plugin): extract AI configuration to separate file`
- `test(notes): add migration test coverage`
- `chore(deps): update mini.nvim to latest version`

**Breaking changes**: Add `!` after type/scope or include `BREAKING CHANGE:` in footer:
- `feat(api)!: change session save format`
- `refactor!: restructure plugin loading order`

### AI Integration Workflow
- **GitHub Copilot**: Primary completion engine with panel disabled
- **CodeCompanion**: Chat interface with dual adapter support (Copilot + local LM Studio)
- **Local LLM**: LM Studio integration on localhost:1234 for privacy-sensitive work

## Project-Specific Conventions

### File Organization Pattern
- `/init.lua`: Main entry point with two-stage loading and mini.deps bootstrap
- `/plugin/*.lua`: Plugin configurations grouped by functionality  
- `/lua/`: Reusable modules and custom functionality
- `/tests/`: Test suites using mini.test framework
- `/scripts/minimal_init.lua`: Test environment configuration
- `/queries/gotmpl/`: Custom Treesitter queries for Go templates

### Configuration Loading Pattern
```lua
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

now(function()
  -- Critical plugins: UI, sessions, basics
  add("plugin/name")
  require("plugin").setup({})
end)

later(function() 
  -- Optional plugins: language servers, extras
  add("plugin/name")
  require("plugin").setup({})
end)
```

### Mini.nvim Integration Patterns
- **Picker Integration**: `mini.pick` with custom directory picker and `ui_select` override
- **Icons**: Custom filetype mappings for chezmoi, gotmpl, and version files
- **UI Consistency**: `mini.statusline`, `mini.tabline`, `mini.notify` for unified interface
- **Session Management**: `mini.sessions` with autowrite enabled
- **Color Scheme**: `mini.base16` with custom palette from `Utils.palette`

### Custom Functionality Extensions
- **Directory Picker**: Custom `MiniPick.registry.directories()` for workspace navigation
- **Filetype Detection**: Custom patterns for Helm charts, gotmpl templates
- **Diagnostic Configuration**: Custom severity sorting and formatting
- **Global Utils**: ASCII art headers, shared utilities in `Utils` namespace

### Notes Module Integration
- Environment variables: `ZK_NOTEBOOK_DIR` for notebook location
- Database paths: Auto-generated in notebook directory (`.perso-tasks.db`, `.work-tasks.db`)
- Filename patterns: `perso-YYYY-MM-DD.md`, `work-YYYY-MM-DD.md` for task tracking
- SQLite-backed task state tracking with visualization capabilities

### Testing Conventions
- Uses `mini.test` framework exclusively
- Tests organized by module: `test_notes_init.lua`, `test_notes_plot.lua`, etc.
- Mock setup in `tests/helpers.lua` for consistent test environment
- Justfile recipes for convenient test execution

## Key Integration Points

- **Mini.nvim Ecosystem**: Deep integration across 10+ mini modules for consistent UX
- **Language Toolchain**: Go, Elixir, Terraform with specialized Treesitter and LSP configs
- **Template Systems**: Helm charts, chezmoi dotfiles, Go templates with custom detection
- **AI Workflow**: Dual-mode AI (GitHub Copilot + local LM Studio) via CodeCompanion
- **Testing Framework**: mini.test with justfile automation and mock infrastructure
- **Notes System**: ZK integration with SQLite-backed task tracking (potential plugin extraction)

## Documentation Policy

**CRITICAL**: This repository maintains exactly **TWO** primary documentation files:

1. **`README.md`** - User-facing documentation, features, keymaps, architecture overview
2. **`TESTING.md`** - Testing infrastructure, conventions, and procedures

**All other documentation must be consolidated into these files.** Do not create standalone `.md` files like `INTEGRATION.md`, `SUMMARY.md`, `FEATURE.md`, etc.

When adding new features:
- Add keymap documentation to the appropriate section in `README.md`
- Add testing documentation to `TESTING.md` if introducing new test patterns
- Use code comments for implementation details
- Use docstrings for function documentation

This policy prevents documentation sprawl and ensures users have a single source of truth.

## Working with This Codebase

When adding new plugins, follow the two-stage loading pattern - UI and critical functionality in `now()`, language servers and optional features in `later()`. All plugin configuration should happen inline within the loading functions, not in separate config files.

For language support, add Treesitter parsers to `programming.lua` and configure LSP servers in the same file. Custom filetypes should be registered in the `vim.filetype.add()` call with appropriate patterns.

Testing is essential - always run `just test` when modifying core functionality. The notes system has comprehensive test coverage that should be maintained if making changes before potential extraction.

**Documentation**: Always update `README.md` with user-facing changes (keymaps, features) and `TESTING.md` with testing changes. Never create standalone documentation files.
