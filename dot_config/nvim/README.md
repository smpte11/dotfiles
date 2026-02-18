# Neovim Configuration

A modern Neovim configuration built with `mini.deps` and focused on developer productivity.

## Recent Changes

**Completion System Migration** (2025-01):

- Migrated from `blink.cmp` to `mini.completion` for LSP completions
- Enabled `copilot.lua` suggestions for AI-powered ghost text
- Integrated `mini.keymap` multi-step mappings for smart completion navigation
- **New workflow**: LSP completions in popup menu (navigate with `<Tab>/<S-Tab>` or `<C-n>/<C-p>`, accept with `<CR>` or `<C-y>`), Copilot as inline ghost text (accept with `<M-l>`)
- **Why**: Full alignment with mini.nvim ecosystem philosophy, simpler configuration, clear separation between AI and LSP
- **Trade-offs**: Lost fuzzy matching and auto-brackets, gained simplicity and consistency with mini.nvim patterns
- **Rollback**: Old `blink.cmp` code is commented out in `plugin/04-lsp.lua`, `plugin/ai.lua`, and `lua/config/keymaps.lua` for easy reversion if needed
- **macOS/Kitty**: Add `macos_option_as_alt yes` to `~/.config/kitty/kitty.conf` to enable Option key as Meta for Copilot keybindings

## Keybinding System

This configuration uses a systematic approach to keybindings with logical categories and consistent patterns.

### Core Philosophy

- **Leader-based organization**: Most commands use `<leader>` prefix with mnemonic categories
- **Consistent patterns**: Similar operations follow similar key patterns
- **Dynamic context**: Some keymaps appear only when relevant (debugging, LSP)
- **Vim-native extensions**: Extend familiar vim patterns rather than replace them

### Main Categories

| Prefix             | Category            | Description                                        |
| ------------------ | ------------------- | -------------------------------------------------- |
| `<leader><leader>` | **Command Palette** | Quick access to all commands                       |
| `<leader>s*`       | **Search**          | All search operations (files, buffers, help, etc.) |
| `<leader>f*`       | **Files**           | File operations and navigation                     |
| `<leader>g*`       | **Git**             | Git operations and GitHub integration              |
| `<leader>u*`       | **UI**              | Interface toggles and visual enhancements          |
| `<leader>d*`       | **Debug**           | DAP debugging (dynamic when active)                |
| `<leader>l*`       | **LSP**             | Language server operations (dynamic when attached) |
| `<leader>a*`       | **AI**              | CodeCompanion AI assistance (normal + visual)      |
| `<leader>v*`       | **Visit**           | MiniVisits path management                         |
| `<leader>b*`       | **Buffers**         | Buffer operations                                  |
| `<leader>w*`       | **Windows**         | Window management                                  |
| `<leader>S*`       | **Sessions**        | Session management                                 |
| `<leader>i*`       | **Insert**          | Text insertion helpers                             |
| `<leader>q*`       | **Quit**            | Exit operations                                    |
| `<leader>m*`       | **Mini**            | Mini.deps plugin management                        |

### Smart Navigation Patterns

#### Buffer & Search Extensions

```lua
-- Extends vim's search metaphor
"/"            -- Search in current buffer
"<leader>/"    -- Search buffer lines (fuzzy)

-- Buffer navigation mirrors window/tmux patterns
"<C-h>/<C-l>"  -- Navigate windows/tmux panes
"<S-h>/<S-l>"  -- Navigate buffers (same direction, buffer scope)
```

#### Quick Access

```lua
"<leader><leader>"  -- Command palette (prime real estate)
"<leader>sb"        -- Search buffers
"<Esc>"            -- Clear search highlights
"<C-s>"            -- Save file
```

### Dynamic Keymaps

#### Debug Interface (DAP)

Keymaps appear only when debugging is active:

```lua
-- Always available (breakpoint management)
"<leader>db"  -- Toggle breakpoint
"<leader>dB"  -- Conditional breakpoint
"<leader>dC"  -- Clear all breakpoints

-- Active only during debug sessions
"<leader>dc"  -- Continue/Start
"<leader>di"  -- Step into
"<leader>do"  -- Step over
"<leader>dO"  -- Step out
"<leader>du"  -- Debug UI toggle
"<leader>dr"  -- Restart session
"<leader>dt"  -- Terminate session
"<leader>dp"  -- Pause execution
"<leader>de"  -- Evaluate expression
```

#### LSP Operations

Available when language server is attached:

```lua
"gd"           -- Go to definition
"gr"           -- Go to references
"gi"           -- Go to implementation
"<leader>lr"   -- Rename symbol
"<leader>la"   -- Code actions
"<leader>lf"   -- Format document
"<leader>le"   -- Show diagnostics
-- + workspace and symbol operations
```

### Advanced Input Features

#### Smart Combos

Quick two-key combinations for common patterns:

```lua
-- Navigation
"ll"  -- End of line (g$)
"hh"  -- Start of line (g^)

-- Text editing (insert mode)
";;"  -- Add semicolon at end, keep cursor position
",,"  -- Smart comma spacing for parameters
"=="  -- Smart assignment with spacing
"::"  -- Type annotations with spacing
"->"  -- Arrow functions/returns with spacing
".."  -- Method chaining
'""'  -- Context-aware quote wrapping

-- Quick escape
"jk"/"kj"  -- Escape from any mode
```

#### Multi-step Keys

Context-aware keys with cascading behavior:

```lua
-- Insert & Select modes
"<Tab>"    -- Navigate completion → snippets → indent → tree → brackets
"<S-Tab>"  -- Reverse navigation through same chain
"<CR>"     -- Accept completion → handle pairs
"<BS>"     -- Handle pairs → hungry whitespace deletion
```

### Completion & AI

**LSP Completion** (popup menu):

| Keymap      | Action         | Description                                        |
| ----------- | -------------- | -------------------------------------------------- |
| `<Tab>`     | Next Item      | Navigate to next completion (smart multi-step)     |
| `<S-Tab>`   | Previous Item  | Navigate to previous completion (smart multi-step) |
| `<CR>`      | Accept         | Accept selected completion (smart multi-step)      |
| `<C-n>`     | Next Item      | Navigate to next completion (built-in)             |
| `<C-p>`     | Previous Item  | Navigate to previous completion (built-in)         |
| `<C-y>`     | Accept         | Accept selected completion (built-in)              |
| `<C-e>`     | Close Menu     | Close completion menu (built-in)                   |
| `<C-Space>` | Force LSP      | Force two-step completion (LSP → fallback)         |
| `<A-Space>` | Force Fallback | Force fallback completion                          |
| `<C-f>`     | Scroll Down    | Scroll documentation/info window down              |
| `<C-b>`     | Scroll Up      | Scroll documentation/info window up                |

**Copilot Suggestions** (ghost text):

| Keymap  | Action   | Description                     |
| ------- | -------- | ------------------------------- |
| `<M-l>` | Accept   | Accept AI suggestion (Option+L) |
| `<M-]>` | Next     | Next suggestion (Option+])      |
| `<M-[>` | Previous | Previous suggestion (Option+[)  |
| `<M-d>` | Dismiss  | Dismiss suggestion (Option+D)   |

**Built-in Completion Sources**:

- `<C-x><C-f>` - File path completion
- `<C-x><C-l>` - Whole line completion
- `<C-x><C-n>` - Keyword completion

> **Architecture**: LSP completion uses `mini.completion` for popup menu, Copilot provides inline ghost text suggestions. Ghost text auto-hides when completion menu is open. Tab/Shift-Tab use `mini.keymap` multi-step logic to navigate completion when visible, otherwise handle snippets/indentation. Copilot uses Meta/Option key (`<M-*>`) for ergonomic single-key combos. See "Recent Changes" section for migration details.

### Search Operations

| Keymap             | Action             | Description                     |
| ------------------ | ------------------ | ------------------------------- |
| `<leader><leader>` | Command Palette    | Quick access to all commands    |
| `<leader>sb`       | Search Buffers     | Find and switch to open buffers |
| `<leader>sf`       | Search Files       | Find files in project           |
| `<leader>sg`       | Search by Grep     | Live grep search                |
| `<leader>sh`       | Search Help        | Neovim help documentation       |
| `<leader>sk`       | Search Keymaps     | Find keybindings                |
| `<leader>sd`       | Search Diagnostics | LSP diagnostics                 |
| `<leader>sw`       | Search Word        | Grep current word               |
| `<leader>s.`       | Search Recent      | Recently opened files           |
| `<leader>/`        | Buffer Lines       | Fuzzy search in current buffer  |

### File Operations

| Keymap       | Action              | Description                         |
| ------------ | ------------------- | ----------------------------------- |
| `<leader>ff` | File Explorer       | Open at current file location       |
| `<leader>fF` | File Explorer (cwd) | Open at working directory           |
| `<leader>fp` | File Picker         | Mini.extra file picker              |
| `<leader>fy` | Yank Path           | Copy file path with project context |

### Git Integration

| Keymap       | Action       | Description                |
| ------------ | ------------ | -------------------------- |
| `<leader>gg` | Git Status   | Open Neogit interface      |
| `<leader>gb` | Git Branches | Browse and switch branches |
| `<leader>gH` | Git Hunks    | View and navigate changes  |
| `<leader>gB` | Git Blame    | Toggle blame annotations   |

**Commit/Diff Submenu** (`<leader>gc*`):

| Keymap        | Action             | Description                                |
| ------------- | ------------------ | ------------------------------------------ |
| `<leader>gcc` | Git Commits        | Browse commit history                      |
| `<leader>gcd` | Diffview Open      | Open diffview to compare working directory |
| `<leader>gcD` | Diffview Close     | Close the current diffview                 |
| `<leader>gcf` | File History       | Show git history for current file          |
| `<leader>gcF` | File History (All) | Show git history for entire repository     |
| `<leader>gcm` | Merge Base Diff    | Compare current branch with origin/HEAD    |

**DiffView Panel Controls** (active in DiffView, `<leader>gcp*`):

| Keymap         | Action       | Description                      |
| -------------- | ------------ | -------------------------------- |
| `<leader>gcpe` | Panel Focus  | Bring focus to the file panel    |
| `<leader>gcpt` | Panel Toggle | Toggle the file panel visibility |

**DiffView Conflict Resolution** (active during merge conflicts, `<leader>gc[otba]*`):

| Keymap        | Action               | Description                              |
| ------------- | -------------------- | ---------------------------------------- |
| `<leader>gco` | Choose Ours          | Accept OURS version of conflict (hunk)   |
| `<leader>gct` | Choose Theirs        | Accept THEIRS version of conflict (hunk) |
| `<leader>gcb` | Choose Base          | Accept BASE version of conflict (hunk)   |
| `<leader>gca` | Choose All           | Accept all versions of conflict (hunk)   |
| `<leader>gcO` | Choose Ours (file)   | Accept OURS version for entire file      |
| `<leader>gcT` | Choose Theirs (file) | Accept THEIRS version for entire file    |
| `<leader>gcB` | Choose Base (file)   | Accept BASE version for entire file      |
| `<leader>gcA` | Choose All (file)    | Accept all versions for entire file      |

**GitHub Submenu** (`<leader>gh*`):

| Keymap        | Action              | Description               |
| ------------- | ------------------- | ------------------------- |
| `<leader>ghi` | GitHub Issues       | Browse open GitHub issues |
| `<leader>ghI` | GitHub Issues (All) | Browse all GitHub issues  |
| `<leader>ghp` | GitHub PRs          | Browse open pull requests |
| `<leader>ghP` | GitHub PRs (All)    | Browse all pull requests  |
| `<leader>gha` | GitHub Actions      | Open Octo actions menu    |
| `<leader>ghc` | Create Issue        | Create new GitHub issue   |
| `<leader>ghr` | Start Review        | Start PR review           |
| `<leader>ghs` | Submit Review       | Submit PR review          |

**Diffview Buffer Mappings** (non-leader keys, active in diffview):

- `q` - Close diffview panel
- `<tab>` / `<s-tab>` - Navigate between changed files
- `[c` / `]c` - Jump between hunks (vim diff-mode)
- `[x` / `]x` - Jump between conflict markers
- `-` or `s` - Stage/unstage selected entry
- `gf` - Open file in previous tabpage
- `g<C-x>` - Cycle through available layouts
- `X` - Restore entry to left side state

**Neogit Integration**: When in Neogit status buffer, `<leader>gcd` opens diffview for quick diff access.

### UI & Visual

| Keymap       | Action           | Description                     |
| ------------ | ---------------- | ------------------------------- |
| `<leader>uc` | Color Picker     | Interactive palette selection   |
| `<leader>ut` | Toggle Favorites | Cycle through favorite palettes |
| `<leader>uC` | Color Toggle     | Quick color scheme toggle       |
| `<leader>ui` | Paste Image      | Insert image in document        |

### AI Assistance

| Keymap       | Mode    | Action     | Description                                  |
| ------------ | ------- | ---------- | -------------------------------------------- |
| `<leader>aa` | **n,v** | AI Actions | CodeCompanion action palette (context-aware) |
| `<leader>ac` | **n**   | AI Chat    | Open CodeCompanion chat buffer               |
| `<leader>ai` | **n,v** | AI Inline  | CodeCompanion inline assistant               |

> **Verified Commands**: Only uses [documented CodeCompanion commands](https://github.com/olimorris/codecompanion.nvim/tree/main/doc). The action palette (`<leader>aa`) provides comprehensive operations including explain, generate, refactor, documentation, and optimization for both normal and visual mode selections.

## Architecture Notes

### Plugin Organization

- **Core keymaps**: `lua/keymaps.lua` - Static, general-purpose mappings
- **Plugin-specific**: `plugin/*.lua` - Dynamic keymaps colocated with plugin setup
- **Context-aware**: `lua/autocmd.lua` - Filetype and buffer-specific mappings

### Dynamic Keymap Management

- Debug keymaps managed in `plugin/programming.lua` alongside DAP setup
- LSP keymaps in `lua/autocmd.lua` triggered on server attach
- Uses autocommands and plugin event listeners for proper lifecycle

### Conflict Resolution

- Systematic categorization prevents most conflicts
- Dynamic keymaps avoid permanent namespace pollution
- Mini.clue integration provides contextual hints

## Dependencies

Built with [mini.deps](https://github.com/echasnovski/mini.deps) for plugin management and leverages the mini.nvim ecosystem extensively.

Key plugins:

- **mini.pick** - File and buffer selection
- **mini.clue** - Keymap hints and organization
- **mini.keymap** - Advanced keymap features (combos, multi-step)
- **nvim-dap** + **nvim-dap-ui** - Debugging interface
- **neogit** + **diffview** - Git integration
- **codecompanion** - AI assistance
