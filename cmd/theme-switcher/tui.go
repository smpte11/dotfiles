package main

import (
	"fmt"
	"io"
	"os/exec"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

var (
	appStyle      = lipgloss.NewStyle().Padding(1, 2)
	titleStyle    = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#FAFAFA")).Background(lipgloss.Color("#7D56F4")).Padding(0, 1)
	statusStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("#FFFDF5")).Padding(0, 1)
	activeMarker  = lipgloss.NewStyle().Foreground(lipgloss.Color("#37f499")).Bold(true).Render("● ")
	inactiveMarker = "  "
)

// themeItem implements list.Item for a theme entry.
type themeItem struct {
	name   string
	theme  Theme
	active bool
}

func (i themeItem) FilterValue() string { return i.name }

// themeDelegate renders each theme item with color swatches.
type themeDelegate struct{}

func (d themeDelegate) Height() int                             { return 2 }
func (d themeDelegate) Spacing() int                            { return 0 }
func (d themeDelegate) Update(_ tea.Msg, _ *list.Model) tea.Cmd { return nil }
func (d themeDelegate) Render(w io.Writer, m list.Model, index int, listItem list.Item) {
	item, ok := listItem.(themeItem)
	if !ok {
		return
	}

	cursor := inactiveMarker
	if item.active {
		cursor = activeMarker
	}

	nameStyle := lipgloss.NewStyle()
	if index == m.Index() {
		nameStyle = nameStyle.Bold(true).Foreground(lipgloss.Color("#FAFAFA"))
	} else {
		nameStyle = nameStyle.Foreground(lipgloss.Color("#ADADAD"))
	}

	// Build color swatches
	var swatches strings.Builder
	for _, c := range item.theme.AccentColors() {
		if c == "" {
			continue
		}
		swatches.WriteString(lipgloss.NewStyle().Background(lipgloss.Color(c)).Render("  "))
	}

	line1 := cursor + nameStyle.Render(item.name)
	line2 := "  " + swatches.String()

	fmt.Fprintf(w, "%s\n%s", line1, line2)
}

type applyDoneMsg struct{ err error }

// model is the bubbletea model for the theme picker.
type model struct {
	list       list.Model
	dataPath   string
	quitting   bool
	applying   bool
	status     string
	err        error
}

func newModel(dataPath, activeTheme string, names []string, themes map[string]Theme) model {
	items := make([]list.Item, len(names))
	for i, name := range names {
		items[i] = themeItem{
			name:   name,
			theme:  themes[name],
			active: name == activeTheme,
		}
	}

	l := list.New(items, themeDelegate{}, 50, len(names)*2+6)
	l.Title = "Theme Switcher"
	l.Styles.Title = titleStyle
	l.SetShowStatusBar(false)
	l.SetShowHelp(true)
	l.SetFilteringEnabled(false)

	return model{list: l, dataPath: dataPath}
}

func (m model) Init() tea.Cmd { return nil }

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.list.SetWidth(msg.Width)
		return m, nil

	case tea.KeyMsg:
		if m.applying {
			return m, nil
		}
		switch msg.String() {
		case "q", "ctrl+c", "esc":
			m.quitting = true
			return m, tea.Quit
		case "enter":
			item, ok := m.list.SelectedItem().(themeItem)
			if !ok {
				return m, nil
			}
			if item.active {
				m.status = fmt.Sprintf("'%s' is already the active theme", item.name)
				return m, nil
			}
			m.applying = true
			m.status = fmt.Sprintf("Applying '%s'...", item.name)
			themeName := item.name
			return m, func() tea.Msg {
				if err := SetActiveTheme(m.dataPath, themeName); err != nil {
					return applyDoneMsg{err: err}
				}
				cmd := exec.Command("chezmoi", "apply")
				if out, err := cmd.CombinedOutput(); err != nil {
					return applyDoneMsg{err: fmt.Errorf("%w: %s", err, string(out))}
				}
				return applyDoneMsg{}
			}
		}

	case applyDoneMsg:
		m.applying = false
		if msg.err != nil {
			m.status = fmt.Sprintf("Error: %v", msg.err)
			return m, nil
		}
		item, _ := m.list.SelectedItem().(themeItem)
		m.status = fmt.Sprintf("Switched to '%s'!", item.name)
		m.quitting = true
		return m, tea.Quit
	}

	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

func (m model) View() string {
	if m.quitting && m.status != "" {
		return statusStyle.Render(m.status) + "\n"
	}
	view := m.list.View()
	if m.status != "" {
		view += "\n" + statusStyle.Render(m.status)
	}
	return appStyle.Render(view)
}
