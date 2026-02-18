-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ Plugin Spec Function                                                        │
-- │                                                                             │
-- │ Provides a cleaner interface for plugin configuration with mini.deps.      │
-- │ Eliminates repetitive add() + now()/later() wrapper patterns.              │
-- └─────────────────────────────────────────────────────────────────────────────┘

local M = {}

--- Setup the spec function with mini.deps dependencies
--- @param deps table Table containing add, now, and later functions
--- @return function The configured spec function
function M.setup(deps)
	local add = deps.add
	local now = deps.now
	local later = deps.later

	--- Plugin specification function
	--- @param opts table Plugin specification options
	---   - source: string - Plugin source (required unless setup_only=true)
	---   - setup_only: boolean - If true, skip add() and only run config (for already-loaded plugins)
	---   - immediate: boolean - If true, use now(), else use later() (default: false)
	---   - enabled: boolean|function - Condition to enable plugin (default: true)
	---   - config: function - Configuration function to run after plugin loads
	---   - keys: table - List of keymaps in format { lhs, rhs, desc = "...", mode = "n", ... }
	---   - All other options are passed directly to add()
	return function(opts)
		-- Check enabled condition
		if opts.enabled ~= nil then
			local enabled = type(opts.enabled) == "function" and opts.enabled() or opts.enabled
			if not enabled then
				return
			end
		end

		-- Extract spec-specific options
		local setup_only = opts.setup_only or false
		local immediate = opts.immediate or false
		local config = opts.config
		local keys = opts.keys

		-- Build add() options (pass through everything else)
		local add_opts = {}
		for k, v in pairs(opts) do
			if k ~= "setup_only" and k ~= "immediate" and k ~= "config" and k ~= "keys" and k ~= "enabled" then
				add_opts[k] = v
			end
		end

		-- Choose loader function
		local loader = immediate and now or later

		loader(function()
			-- Only call add() if not setup_only
			if not setup_only then
				add(add_opts)
			end

			-- Run config
			if config then
				config()
			end

			-- Set up keymaps
			if keys then
				for _, key in ipairs(keys) do
					local lhs = key[1]
					local rhs = key[2]
					local modes = key.mode or "n"

					-- Build keymap options
					local keymap_opts = {}
					for k, v in pairs(key) do
						if k ~= 1 and k ~= 2 and k ~= "mode" then
							keymap_opts[k] = v
						end
					end

					vim.keymap.set(modes, lhs, rhs, keymap_opts)
				end
			end
		end)
	end
end

return M
