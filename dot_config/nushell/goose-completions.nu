module completions {

  # An AI agent
  export extern goose [
    --help(-h)                # Print help
    --version(-V)             # Print version
  ]

  # Configure goose settings
  export extern "goose configure" [
    --help(-h)                # Print help
  ]

  # Display goose information
  export extern "goose info" [
    --verbose(-v)             # Show verbose information including config.yaml
    --check                   # Test provider connection and show status
    --help(-h)                # Print help
  ]

  # Check that your Goose setup is working
  export extern "goose doctor" [
    --help(-h)                # Print help
  ]

  # Run one of the mcp servers bundled with goose
  export extern "goose mcp" [
    --help(-h)                # Print help
    server: string
  ]

  # Run goose as an ACP agent server on stdio
  export extern "goose acp" [
    --with-builtin: string    # Add builtin extensions by name (e.g., 'developer' or multiple: 'developer,github')
    --help(-h)                # Print help (see more with '--help')
  ]

  # Start ACP server over HTTP and WebSocket
  export extern "goose serve" [
    --host: string
    --port: string
    --with-builtin: string    # Add builtin extensions by name (e.g., 'developer' or multiple: 'developer,github')
    --help(-h)                # Print help (see more with '--help')
  ]

  # Start or resume interactive chat sessions
  export extern "goose session" [
    --name(-n): string        # Name for the chat session (e.g., 'project-x')
    --session-id: string      # Session ID (e.g., '20250921_143022')
    --path: path              # Legacy: Path for the chat session
    --resume(-r)              # Resume a previous session (last used or specified by --name/--session-id)
    --fork                    # Fork a previous session (creates new session with copied history)
    --history                 # Show previous messages when resuming a session
    --debug                   # Enable debug output mode with full content and no truncation
    --max-tool-repetitions: string # Maximum number of consecutive identical tool calls allowed
    --max-turns: string       # Maximum number of turns allowed without user input (default: 1000)
    --container: string       # Docker container ID to run extensions inside
    --with-extension: string  # Add stdio extensions (can be specified multiple times)
    --with-streamable-http-extension: string # Add streamable HTTP extensions (can be specified multiple times)
    --with-builtin: string    # Add builtin extensions by name (e.g., 'developer' or multiple: 'developer,github')
    --no-profile              # Don't load your default extensions, only use CLI-specified extensions
    --help(-h)                # Print help (see more with '--help')
  ]

  # List all available sessions
  export extern "goose session list" [
    --format(-f): string      # Output format (text, json)
    --ascending               # Sort by date in ascending order (oldest first)
    --working_dir(-w): path   # Filter sessions by working directory
    --limit(-l): string       # Limit the number of results
    --help(-h)                # Print help (see more with '--help')
  ]

  # Remove sessions. Runs interactively if no ID, name, or regex is provided.
  export extern "goose session remove" [
    --name(-n): string        # Name for the chat session (e.g., 'project-x')
    --session-id: string      # Session ID (e.g., '20250921_143022')
    --path: path              # Legacy: Path for the chat session
    --regex(-r): string       # Regex for removing matched sessions (optional)
    --help(-h)                # Print help (see more with '--help')
  ]

  # Export a session
  export extern "goose session export" [
    --name(-n): string        # Name for the chat session (e.g., 'project-x')
    --session-id: string      # Session ID (e.g., '20250921_143022')
    --path: path              # Legacy: Path for the chat session
    --output(-o): path        # Output file path (default: stdout)
    --format: string          # Output format (markdown, json, yaml)
    --nostr                   # Publish the JSON session export as an encrypted Nostr event and print a Goose share link
    --relay: string           # Nostr relay URL to publish to (can be specified multiple times)
    --help(-h)                # Print help (see more with '--help')
  ]

  # Import a session from JSON or an encrypted Nostr share link
  export extern "goose session import" [
    --nostr                   # Treat input as an encrypted Nostr share link
    --help(-h)                # Print help
    input: string             # Path to a JSON session export, or a goose://sessions/nostr share link
  ]

  export extern "goose session diagnostics" [
    --name(-n): string        # Name for the chat session (e.g., 'project-x')
    --session-id: string      # Session ID (e.g., '20250921_143022')
    --path: path              # Legacy: Path for the chat session
    --output(-o): path        # Output path for the diagnostics zip file (optional, defaults to current directory)
    --help(-h)                # Print help (see more with '--help')
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose session help" [
  ]

  # List all available sessions
  export extern "goose session help list" [
  ]

  # Remove sessions. Runs interactively if no ID, name, or regex is provided.
  export extern "goose session help remove" [
  ]

  # Export a session
  export extern "goose session help export" [
  ]

  # Import a session from JSON or an encrypted Nostr share link
  export extern "goose session help import" [
  ]

  export extern "goose session help diagnostics" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose session help help" [
  ]

  # Open the last project directory
  export extern "goose project" [
    --help(-h)                # Print help
  ]

  # List recent project directories
  export extern "goose projects" [
    --help(-h)                # Print help
  ]

  def "nu-complete goose run output_format" [] {
    [ "text" "json" "stream-json" ]
  }

  # Execute commands from an instruction file or stdin
  export extern "goose run" [
    --instructions(-i): string # Path to instruction file containing commands. Use - for stdin.
    --text(-t): string        # Input text to provide to goose directly
    --recipe: string          # Recipe name to get recipe file or the full path of the recipe file (use --explain to see recipe details)
    --system: string          # Additional system prompt to customize agent behavior
    --params: string          # Dynamic parameters (e.g., --params username=alice --params channel_name=goose-channel)
    --sub-recipe: string      # Sub-recipe name or file path (can be specified multiple times)
    --explain                 # Show the recipe title, description, and parameters
    --render-recipe           # Print the rendered recipe instead of running it.
    --name(-n): string        # Name for the chat session (e.g., 'project-x')
    --session-id: string      # Session ID (e.g., '20250921_143022')
    --path: path              # Legacy: Path for the chat session
    --interactive(-s)         # Continue in interactive mode after processing initial input
    --no-session              # Run without storing a session file
    --resume(-r)              # Resume from a previous run
    --scheduled-job-id: string # ID of the scheduled job that triggered this execution (internal use)
    --debug                   # Enable debug output mode with full content and no truncation
    --max-tool-repetitions: string # Maximum number of consecutive identical tool calls allowed
    --max-turns: string       # Maximum number of turns allowed without user input (default: 1000)
    --container: string       # Docker container ID to run extensions inside
    --with-extension: string  # Add stdio extensions (can be specified multiple times)
    --with-streamable-http-extension: string # Add streamable HTTP extensions (can be specified multiple times)
    --with-builtin: string    # Add builtin extensions by name (e.g., 'developer' or multiple: 'developer,github')
    --no-profile              # Don't load your default extensions, only use CLI-specified extensions
    --quiet(-q)               # Quiet mode. Suppress non-response output, printing only the model response to stdout
    --output-format: string@"nu-complete goose run output_format" # Output format (text, json, stream-json)
    --provider: string        # Specify the LLM provider to use (e.g., 'openai', 'anthropic')
    --model: string           # Specify the model to use (e.g., 'gpt-4o', 'claude-sonnet-4-20250514')
    --help(-h)                # Print help (see more with '--help')
  ]

  # Recipe utilities for validation and deeplinking
  export extern "goose recipe" [
    --help(-h)                # Print help
  ]

  # Validate a recipe
  export extern "goose recipe validate" [
    --help(-h)                # Print help
    recipe_name: string       # recipe name to get recipe file or full path to the recipe file to validate
  ]

  # Generate a deeplink for a recipe
  export extern "goose recipe deeplink" [
    --param(-p): string       # Recipe parameter in key=value format (can be specified multiple times)
    --help(-h)                # Print help
    recipe_name: string       # recipe name to get recipe file or full path to the recipe file to generate deeplink
  ]

  # Open a recipe in Goose Desktop
  export extern "goose recipe open" [
    --param(-p): string       # Recipe parameter in key=value format (can be specified multiple times)
    --help(-h)                # Print help
    recipe_name: string       # recipe name or full path to the recipe file
  ]

  # List available recipes
  export extern "goose recipe list" [
    --format: string          # Output format (text, json)
    --verbose(-v)             # Show verbose information including recipe descriptions
    --help(-h)                # Print help
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose recipe help" [
  ]

  # Validate a recipe
  export extern "goose recipe help validate" [
  ]

  # Generate a deeplink for a recipe
  export extern "goose recipe help deeplink" [
  ]

  # Open a recipe in Goose Desktop
  export extern "goose recipe help open" [
  ]

  # List available recipes
  export extern "goose recipe help list" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose recipe help help" [
  ]

  # Manage plugins
  export extern "goose plugin" [
    --help(-h)                # Print help
  ]

  # Install a plugin from a git repository URL
  export extern "goose plugin install" [
    --auto-update             # Automatically update this plugin before plugin skills are loaded
    --help(-h)                # Print help
    url: string               # URL to a git repository containing a supported plugin
  ]

  # Update an installed git-backed plugin
  export extern "goose plugin update" [
    --help(-h)                # Print help
    name: string              # Name of the installed plugin to update
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose plugin help" [
  ]

  # Install a plugin from a git repository URL
  export extern "goose plugin help install" [
  ]

  # Update an installed git-backed plugin
  export extern "goose plugin help update" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose plugin help help" [
  ]

  # Manage scheduled jobs
  export extern "goose schedule" [
    --help(-h)                # Print help
  ]

  # Add a new scheduled job
  export extern "goose schedule add" [
    --schedule-id: string     # Unique ID for the recurring scheduled job
    --cron: string            # Cron expression for the schedule
    --recipe-source: string   # Recipe source (path to file, or base64 encoded recipe string)
    --params: string          # Recipe parameter in KEY=VALUE format (can be specified multiple times)
    --help(-h)                # Print help (see more with '--help')
  ]

  # List all scheduled jobs
  export extern "goose schedule list" [
    --help(-h)                # Print help
  ]

  # Remove a scheduled job by ID
  export extern "goose schedule remove" [
    --schedule-id: string     # ID of the scheduled job to remove (removes the recurring schedule)
    --help(-h)                # Print help
  ]

  # List sessions created by a specific schedule
  export extern "goose schedule sessions" [
    --schedule-id: string     # ID of the schedule
    --limit(-l): string       # Maximum number of sessions to return
    --help(-h)                # Print help
  ]

  # Run a scheduled job immediately
  export extern "goose schedule run-now" [
    --schedule-id: string     # ID of the schedule to run
    --help(-h)                # Print help
  ]

  # [Deprecated] Check status of scheduler services
  export extern "goose schedule services-status" [
    --help(-h)                # Print help
  ]

  # [Deprecated] Stop scheduler services
  export extern "goose schedule services-stop" [
    --help(-h)                # Print help
  ]

  # Show cron expression examples and help
  export extern "goose schedule cron-help" [
    --help(-h)                # Print help
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose schedule help" [
  ]

  # Add a new scheduled job
  export extern "goose schedule help add" [
  ]

  # List all scheduled jobs
  export extern "goose schedule help list" [
  ]

  # Remove a scheduled job by ID
  export extern "goose schedule help remove" [
  ]

  # List sessions created by a specific schedule
  export extern "goose schedule help sessions" [
  ]

  # Run a scheduled job immediately
  export extern "goose schedule help run-now" [
  ]

  # [Deprecated] Check status of scheduler services
  export extern "goose schedule help services-status" [
  ]

  # [Deprecated] Stop scheduler services
  export extern "goose schedule help services-stop" [
  ]

  # Show cron expression examples and help
  export extern "goose schedule help cron-help" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose schedule help help" [
  ]

  # Manage gateways for external platform integrations
  export extern "goose gateway" [
    --help(-h)                # Print help
  ]

  # Show gateway status
  export extern "goose gateway status" [
    --help(-h)                # Print help
  ]

  # Start a gateway
  export extern "goose gateway start" [
    --bot-token: string       # Bot token for the gateway platform
    --help(-h)                # Print help (see more with '--help')
    gateway_type: string      # Gateway type (e.g., 'telegram')
  ]

  # Stop a running gateway
  export extern "goose gateway stop" [
    --help(-h)                # Print help
    gateway_type: string      # Gateway type to stop (e.g., 'telegram')
  ]

  # Generate a pairing code for a gateway
  export extern "goose gateway pair" [
    --help(-h)                # Print help
    gateway_type: string      # Gateway type to generate pairing code for
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose gateway help" [
  ]

  # Show gateway status
  export extern "goose gateway help status" [
  ]

  # Start a gateway
  export extern "goose gateway help start" [
  ]

  # Stop a running gateway
  export extern "goose gateway help stop" [
  ]

  # Generate a pairing code for a gateway
  export extern "goose gateway help pair" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose gateway help help" [
  ]

  # Update the goose CLI version
  export extern "goose update" [
    --canary(-c)              # Update to canary version
    --reconfigure(-r)         # Enforce to re-configure goose during update
    --help(-h)                # Print help (see more with '--help')
  ]

  # Terminal-integrated goose session
  export extern "goose term" [
    --help(-h)                # Print help (see more with '--help')
  ]

  def "nu-complete goose term init shell" [] {
    [ "bash" "zsh" "fish" "nu" "powershell" ]
  }

  # Print shell initialization script
  export extern "goose term init" [
    --name(-n): string        # Name for the terminal session
    --default                 # Make goose the default handler for unknown commands
    --help(-h)                # Print help (see more with '--help')
    shell: string@"nu-complete goose term init shell" # Shell type (bash, zsh, fish, nu, powershell)
  ]

  # Log a shell command to the session
  export extern "goose term log" [
    --help(-h)                # Print help
    command: string           # The command that was executed
  ]

  # Run a prompt in the terminal session
  export extern "goose term run" [
    --help(-h)                # Print help (see more with '--help')
    ...prompt: string         # The prompt to send to goose (multiple words allowed without quotes)
  ]

  # Print session info for prompt integration
  export extern "goose term info" [
    --help(-h)                # Print help (see more with '--help')
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose term help" [
  ]

  # Print shell initialization script
  export extern "goose term help init" [
  ]

  # Log a shell command to the session
  export extern "goose term help log" [
  ]

  # Run a prompt in the terminal session
  export extern "goose term help run" [
  ]

  # Print session info for prompt integration
  export extern "goose term help info" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose term help help" [
  ]

  # Manage local inference models
  export extern "goose local-models" [
    --help(-h)                # Print help
  ]

  # Search HuggingFace for GGUF models
  export extern "goose local-models search" [
    --limit(-l): string       # Maximum number of results
    --help(-h)                # Print help
    query: string             # Search query
  ]

  # Download a GGUF model (e.g. bartowski/Llama-3.2-1B-Instruct-GGUF:Q4_K_M)
  export extern "goose local-models download" [
    --help(-h)                # Print help
    spec: string              # Model spec in user/repo:quantization format
  ]

  # List downloaded local models
  export extern "goose local-models list" [
    --help(-h)                # Print help
  ]

  # Delete a downloaded local model
  export extern "goose local-models delete" [
    --help(-h)                # Print help
    id: string                # Model ID to delete
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose local-models help" [
  ]

  # Search HuggingFace for GGUF models
  export extern "goose local-models help search" [
  ]

  # Download a GGUF model (e.g. bartowski/Llama-3.2-1B-Instruct-GGUF:Q4_K_M)
  export extern "goose local-models help download" [
  ]

  # List downloaded local models
  export extern "goose local-models help list" [
  ]

  # Delete a downloaded local model
  export extern "goose local-models help delete" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose local-models help help" [
  ]

  def "nu-complete goose completion shell" [] {
    [ "bash" "elvish" "fish" "powershell" "nu" "zsh" ]
  }

  # Generate the autocompletion script or Nushell module for the specified shell
  export extern "goose completion" [
    --bin-name: string        # Provide a custom binary name
    --help(-h)                # Print help
    shell: string@"nu-complete goose completion shell"
  ]

  # Review the current diff using goose
  export extern "goose review" [
    --prompt: path            # Path to a Markdown file with a custom base review prompt. Replaces the embedded default prompt
    --model: string           # Default model used for the main review agent and for any check that does not declare its own `model:` in frontmatter
    --provider: string        # Provider for the main review agent
    --override-model: string  # Force every discovered check to use this model, regardless of the check's own `model:` field
    --turn-limit: string      # Default `turn-limit` applied to checks that do not declare their own
    --dry-run                 # Print the assembled review prompt and discovered checks instead of running the review
    --quiet(-q)               # Suppress non-result output from the underlying agent
    --no-orchestrate          # Disable the Rust-driven parallel orchestrator and fall back to the single-prompt path that asks the main agent to delegate each check via `delegate(... async: true ...)`. The default orchestrator dispatches one `goose run` subprocess per check (capped at 4 concurrent), bounding wall-clock to the slowest single check rather than waiting on the model to issue dispatches
    --instructions(-i): string # Additional free-form instructions to prepend to the review (e.g. PR intent, commit-message context, "this is a refactor, flag any behavior change"). Mirrors `amp review --instructions` for drop-in compatibility with existing reviewer wrappers
    --files(-f): string       # Restrict the review to a specific set of files. Other files in the diff are still passed to the agent for context but are excluded from the assembled diff sent to checks. Mirrors `amp review --files`
    --check-filter(-c): string # Only run checks whose `name` matches one of these. Other discovered checks are skipped. Mirrors `amp review --check-filter`
    --check-scope(-s): path   # Alternate directory to search for `.agents/checks/*.md` instead of the repo root. Mirrors `amp review --check-scope`
    --checks-only             # Skip the main correctness pass and only run check subagents. Mirrors `amp review --checks-only`
    --summary-only            # Print only the diff summary; skip the full review. Mirrors `amp review --summary-only`
    --severity: string        # Minimum severity to display. Findings below this rank are dropped from the output. Default is `medium`, matching Amp's CLI which hides `low` from review output. Pass `--severity low` to surface every finding
    --help(-h)                # Print help (see more with '--help')
    range?: string            # Diff range to review (e.g. "main...HEAD"). Defaults to the working tree vs HEAD
  ]

  # Validate a bundled-extensions.json file
  export extern "goose validate-extensions" [
    --help(-h)                # Print help
    file: path                # Path to the bundled-extensions.json file
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose help" [
  ]

  # Configure goose settings
  export extern "goose help configure" [
  ]

  # Display goose information
  export extern "goose help info" [
  ]

  # Check that your Goose setup is working
  export extern "goose help doctor" [
  ]

  # Run one of the mcp servers bundled with goose
  export extern "goose help mcp" [
  ]

  # Run goose as an ACP agent server on stdio
  export extern "goose help acp" [
  ]

  # Start ACP server over HTTP and WebSocket
  export extern "goose help serve" [
  ]

  # Start or resume interactive chat sessions
  export extern "goose help session" [
  ]

  # List all available sessions
  export extern "goose help session list" [
  ]

  # Remove sessions. Runs interactively if no ID, name, or regex is provided.
  export extern "goose help session remove" [
  ]

  # Export a session
  export extern "goose help session export" [
  ]

  # Import a session from JSON or an encrypted Nostr share link
  export extern "goose help session import" [
  ]

  export extern "goose help session diagnostics" [
  ]

  # Open the last project directory
  export extern "goose help project" [
  ]

  # List recent project directories
  export extern "goose help projects" [
  ]

  # Execute commands from an instruction file or stdin
  export extern "goose help run" [
  ]

  # Recipe utilities for validation and deeplinking
  export extern "goose help recipe" [
  ]

  # Validate a recipe
  export extern "goose help recipe validate" [
  ]

  # Generate a deeplink for a recipe
  export extern "goose help recipe deeplink" [
  ]

  # Open a recipe in Goose Desktop
  export extern "goose help recipe open" [
  ]

  # List available recipes
  export extern "goose help recipe list" [
  ]

  # Manage plugins
  export extern "goose help plugin" [
  ]

  # Install a plugin from a git repository URL
  export extern "goose help plugin install" [
  ]

  # Update an installed git-backed plugin
  export extern "goose help plugin update" [
  ]

  # Manage scheduled jobs
  export extern "goose help schedule" [
  ]

  # Add a new scheduled job
  export extern "goose help schedule add" [
  ]

  # List all scheduled jobs
  export extern "goose help schedule list" [
  ]

  # Remove a scheduled job by ID
  export extern "goose help schedule remove" [
  ]

  # List sessions created by a specific schedule
  export extern "goose help schedule sessions" [
  ]

  # Run a scheduled job immediately
  export extern "goose help schedule run-now" [
  ]

  # [Deprecated] Check status of scheduler services
  export extern "goose help schedule services-status" [
  ]

  # [Deprecated] Stop scheduler services
  export extern "goose help schedule services-stop" [
  ]

  # Show cron expression examples and help
  export extern "goose help schedule cron-help" [
  ]

  # Manage gateways for external platform integrations
  export extern "goose help gateway" [
  ]

  # Show gateway status
  export extern "goose help gateway status" [
  ]

  # Start a gateway
  export extern "goose help gateway start" [
  ]

  # Stop a running gateway
  export extern "goose help gateway stop" [
  ]

  # Generate a pairing code for a gateway
  export extern "goose help gateway pair" [
  ]

  # Update the goose CLI version
  export extern "goose help update" [
  ]

  # Terminal-integrated goose session
  export extern "goose help term" [
  ]

  # Print shell initialization script
  export extern "goose help term init" [
  ]

  # Log a shell command to the session
  export extern "goose help term log" [
  ]

  # Run a prompt in the terminal session
  export extern "goose help term run" [
  ]

  # Print session info for prompt integration
  export extern "goose help term info" [
  ]

  # Manage local inference models
  export extern "goose help local-models" [
  ]

  # Search HuggingFace for GGUF models
  export extern "goose help local-models search" [
  ]

  # Download a GGUF model (e.g. bartowski/Llama-3.2-1B-Instruct-GGUF:Q4_K_M)
  export extern "goose help local-models download" [
  ]

  # List downloaded local models
  export extern "goose help local-models list" [
  ]

  # Delete a downloaded local model
  export extern "goose help local-models delete" [
  ]

  # Generate the autocompletion script or Nushell module for the specified shell
  export extern "goose help completion" [
  ]

  # Review the current diff using goose
  export extern "goose help review" [
  ]

  # Validate a bundled-extensions.json file
  export extern "goose help validate-extensions" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "goose help help" [
  ]

}

export use completions *
