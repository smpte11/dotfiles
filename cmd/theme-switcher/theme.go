package main

import (
	"fmt"
	"os"
	"regexp"
	"sort"

	"github.com/BurntSushi/toml"
)

// Theme holds the color values for a single theme.
type Theme struct {
	Background  string
	Foreground  string
	Cursor      string
	SelectionBG string `toml:"selection_bg"`
	SelectionFG string `toml:"selection_fg"`
	Palette     Palette
}

// Palette holds the 16 terminal colors.
type Palette struct {
	Black        string
	Red          string
	Green        string
	Yellow       string
	Blue         string
	Magenta      string
	Cyan         string
	Silver       string
	BrightBlack  string `toml:"bright_black"`
	BrightRed    string `toml:"bright_red"`
	BrightGreen  string `toml:"bright_green"`
	BrightYellow string `toml:"bright_yellow"`
	BrightBlue   string `toml:"bright_blue"`
	BrightMagenta string `toml:"bright_magenta"`
	BrightCyan   string `toml:"bright_cyan"`
	White        string
}

// AccentColors returns a small slice of representative colors for preview swatches.
func (t Theme) AccentColors() []string {
	return []string{
		t.Background,
		t.Foreground,
		t.Cursor,
		t.Palette.Red,
		t.Palette.Green,
		t.Palette.Yellow,
		t.Palette.Blue,
		t.Palette.Magenta,
		t.Palette.Cyan,
	}
}

type chezmoiData struct {
	ActiveTheme string           `toml:"active_theme"`
	Themes      map[string]Theme `toml:"themes"`
}

// LoadChezmoiData parses the TOML file and returns the active theme name,
// sorted theme names, and a map of theme name -> Theme.
func LoadChezmoiData(path string) (string, []string, map[string]Theme, error) {
	var data chezmoiData
	if _, err := toml.DecodeFile(path, &data); err != nil {
		return "", nil, nil, fmt.Errorf("parsing %s: %w", path, err)
	}

	names := make([]string, 0, len(data.Themes))
	for name := range data.Themes {
		names = append(names, name)
	}
	sort.Strings(names)

	return data.ActiveTheme, names, data.Themes, nil
}

// SetActiveTheme updates the active_theme line in the TOML file in-place,
// preserving the rest of the file content.
func SetActiveTheme(path, name string) error {
	content, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("reading %s: %w", path, err)
	}

	re := regexp.MustCompile(`(?m)^active_theme\s*=\s*"[^"]*"`)
	replacement := fmt.Sprintf(`active_theme = "%s"`, name)
	updated := re.ReplaceAll(content, []byte(replacement))

	if err := os.WriteFile(path, updated, 0644); err != nil {
		return fmt.Errorf("writing %s: %w", path, err)
	}
	return nil
}
