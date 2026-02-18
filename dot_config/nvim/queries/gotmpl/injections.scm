; Inject Bash/Shell for chezmoi and general Go templates
((text) @injection.content
 (#set! injection.language "bash")
 (#set! injection.combined))

; Inject Nushell for .nu templates
((text) @injection.content
 (#lua-match? @injection.content "^%s*#!.*nu")
 (#set! injection.language "nu")
 (#set! injection.combined))

; Inject TOML for config files (detect [section] or key = "value")
((text) @injection.content
 (#lua-match? @injection.content "^%s*%[")
 (#set! injection.language "toml")
 (#set! injection.combined))

; Inject YAML for templates (detect key: value)
((text) @injection.content
 (#lua-match? @injection.content "^%s*%w+%s*:")
 (#set! injection.language "yaml")
 (#set! injection.combined))

; Inject JSON for templates (detect { or [ at start)
((text) @injection.content
 (#lua-match? @injection.content "^%s*[{%[]")
 (#set! injection.language "json")
 (#set! injection.combined))
