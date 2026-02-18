-- ⚡ COMPREHENSIVE NOTES PLUGIN ⚡
-- Complete notes system with proper MiniDeps initialization
-- SQLite for task tracking

-- Aufzeichnung - Markdown task tracking system
spec({
    source = "smpte11/aufzeichnung",
    depends = {"kkharji/sqlite.lua", "zk-org/zk-nvim"},
    config = function()
        local notes = require("notes")
        notes.setup({
            -- 📁 Directory Configuration (Optimized for Your Workflow!)
            directories = {
                notebook = vim.env.ZK_NOTEBOOK_DIR or "~/notebook", -- Use existing ZK_NOTEBOOK_DIR
                personal_journal = "journal/daily", -- Matches your existing structure
                work_journal = "work", -- Matches your existing structure
                archive = "archive" -- For completed projects
            },

            -- 📊 Note Tracking Configuration (Matches Your File Patterns!)
            tracking = {
                personal = {
                    enabled = true,
                    filename_patterns = {"perso%-.*%.md$", -- perso-YYYY-MM-DD.md (your existing pattern)
                    "personal%-.*%.md$" -- Alternative pattern
                    },
                    database_path = (vim.env.ZK_NOTEBOOK_DIR or "~/notebook") .. "/.personal-tasks.db"
                },
                work = {
                    enabled = true,
                    filename_patterns = {"work%-.*%.md$" -- work-YYYY-MM-DD.md (your existing pattern)
                    },
                    database_path = (vim.env.ZK_NOTEBOOK_DIR or "~/notebook") .. "/.work-tasks.db"
                },
                job = {
                    enabled = true, -- Track job-related notes
                    filename_patterns = {"job%-.*%.md$", "career%-.*%.md$"},
                    database_path = (vim.env.ZK_NOTEBOOK_DIR or "~/notebook") .. "/.job-tasks.db"
                },
                vacation = {
                    enabled = true, -- Track vacation planning
                    filename_patterns = {"vacation%-.*%.md$", "travel%-.*%.md$"},
                    database_path = (vim.env.ZK_NOTEBOOK_DIR or "~/notebook") .. "/.vacation-tasks.db"
                }
            },

            -- 🔌 Integration Configuration
            integrations = {
                zk = {
                    enabled = "auto"
                } -- Auto-detect zk-nvim
            },

            -- 📝 ZK-nvim Configuration
            zk = {
                enabled = true,
                picker = "minipick"
            },

            -- 🎨 Visualization Preferences (Optimized for Readability!)
            visualization = {
                enabled = true,
                charts = {
                    histogram = {
                        width = 60,
                        show_values = true
                    }, -- Wider for better readability
                    pie_chart = {
                        radius = 12,
                        style = "solid",
                        show_legend = true
                    }, -- Larger radius
                    line_plot = {
                        width = 70,
                        height = 15,
                        show_axes = true
                    }, -- Wider plots
                    table = {
                        show_borders = true,
                        max_rows = 15
                    } -- More rows for detailed view
                },
                data = {
                    date_format = "medium", -- "Sep 22" format (readable)
                    truncate_length = 40, -- Longer text for context
                    productivity_weights = {
                        created = 1, -- Creating tasks
                        completed = 3, -- Heavily reward completions
                        carried_over = -1 -- Light penalty for procrastination
                    }
                },
                display = {
                    use_emojis = true, -- Pretty output
                    show_debug = false -- Clean production output
                }
            },

            -- ⌨️ Keybinding Configuration
            keymaps = {
                enabled = true,
                prefix = "<leader>n"
                -- All default mappings enabled
            },

            -- 📝 Journal Templates (Productivity-Focused!)
            journal = {
                carryover_enabled = true, -- Carry unfinished tasks forward (essential!)
                daily_template = {
                    personal = {
                        prefix = "perso", -- Matches your perso-YYYY-MM-DD.md pattern
                        sections = {"🎯 Today's Priority", -- Single most important goal
                        "📋 Tasks & Actions", -- Actionable items
                        "💭 Ideas & Notes", -- Thoughts and inspiration
                        "🌟 Daily Reflection" -- Evening review
                        }
                    },
                    work = {
                        prefix = "work", -- Matches your work-YYYY-MM-DD.md pattern
                        sections = {"🚀 Daily Sprint Goal", -- Main work objective
                        "📋 Action Items", -- Concrete tasks
                        "🤝 Team & Meetings", -- Collaboration notes
                        "📈 Progress & Learnings" -- End-of-day review
                        }
                    }
                }
            },

            -- 🔔 Notification Settings
            notifications = {
                enabled = true, -- Enable task operation notifications
                task_operations = true, -- Notify on task save/update
                journal_carryover = true, -- Notify when tasks carried over
                level = "info" -- Notification level
            },

            -- 🔧 Advanced Options
            advanced = {
                auto_create_directories = true,
                database_optimization = true,
                debug_mode = false -- Set to true for verbose logging
            }
        })

        -- Org-mode style heading task counters (virtual text)
        -- General markdown enhancement that works with any markdown files
        pcall(function()
            require("notes.task_counter").setup({
                -- Works with any markdown files, not just notes
                filetypes = {"markdown", "vimwiki", "quarto", "telekasten"},
                -- Optional: restrict to notebook directory if desired
                -- path_patterns = vim.env.ZK_NOTEBOOK_DIR and { vim.env.ZK_NOTEBOOK_DIR .. "/*" } or {},
                show_percent = true,
                virt_text_hl = "Comment",
                priority = 85 -- Lower than render-markdown decorations
            })
        end)
    end
})
