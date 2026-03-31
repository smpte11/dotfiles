package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
)

func resolveDataPath() (string, error) {
	// Try chezmoi source-path first
	out, err := exec.Command("chezmoi", "source-path").Output()
	if err == nil {
		srcDir := strings.TrimSpace(string(out))
		path := filepath.Join(srcDir, ".chezmoidata.toml")
		if _, err := os.Stat(path); err == nil {
			return path, nil
		}
	}

	// Fallback to default location
	home, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("could not determine home directory: %w", err)
	}
	path := filepath.Join(home, ".local", "share", "chezmoi", ".chezmoidata.toml")
	if _, err := os.Stat(path); err != nil {
		return "", fmt.Errorf("chezmoi data file not found at %s", path)
	}
	return path, nil
}

func main() {
	dataPath, err := resolveDataPath()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	activeTheme, names, themes, err := LoadChezmoiData(dataPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	if len(names) == 0 {
		fmt.Fprintln(os.Stderr, "No themes found in .chezmoidata.toml")
		os.Exit(1)
	}

	m := newModel(dataPath, activeTheme, names, themes)
	p := tea.NewProgram(m)
	result, err := p.Run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	// Print reload notes if a theme was successfully applied
	if finalModel, ok := result.(model); ok && finalModel.quitting && finalModel.err == nil && finalModel.status != "" && strings.HasPrefix(finalModel.status, "Switched") {
		PrintReloadNotes()
	}
}
