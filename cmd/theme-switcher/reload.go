package main

import "fmt"

// PrintReloadNotes prints instructions for apps that need manual action
// after a theme change. Ghostty auto-reloads on macOS so it's omitted.
func PrintReloadNotes() {
	fmt.Println()
	fmt.Println("Reload notes:")
	fmt.Println("  • Ghostty: auto-reloads on config change (no action needed)")
	fmt.Println("  • Zellij:  open a new tab/session to pick up the new theme")
	fmt.Println("  • Neovim:  restart to pick up the new theme")
}
