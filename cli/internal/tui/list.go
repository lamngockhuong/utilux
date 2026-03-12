package tui

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/lamngockhuong/utix/cli/internal/registry"
)

// ScriptItem represents a script in the list
type ScriptItem struct {
	Script registry.Script
	Cached bool
}

func (i ScriptItem) Title() string {
	cached := ""
	if i.Cached {
		cached = CachedStyle.Render(" [cached]")
	}
	return i.Script.Name + cached
}

func (i ScriptItem) Description() string {
	return i.Script.Description
}

func (i ScriptItem) FilterValue() string {
	return i.Script.Name + " " + i.Script.Description + " " + strings.Join(i.Script.Tags, " ")
}

// ListModel represents an interactive script list
type ListModel struct {
	list     list.Model
	selected *ScriptItem
	quitting bool
}

// NewList creates a new list model
func NewList(items []ScriptItem, title string) ListModel {
	listItems := make([]list.Item, len(items))
	for i, item := range items {
		listItems[i] = item
	}

	delegate := list.NewDefaultDelegate()
	delegate.Styles.SelectedTitle = delegate.Styles.SelectedTitle.
		Foreground(lipgloss.Color("229")).
		BorderLeftForeground(Primary)
	delegate.Styles.SelectedDesc = delegate.Styles.SelectedDesc.
		Foreground(lipgloss.Color("244")).
		BorderLeftForeground(Primary)

	l := list.New(listItems, delegate, 60, 20)
	l.Title = title
	l.SetShowStatusBar(true)
	l.SetFilteringEnabled(true)
	l.Styles.Title = TitleStyle

	return ListModel{list: l}
}

// Init initializes the list
func (m ListModel) Init() tea.Cmd {
	return nil
}

// Update handles list updates
func (m ListModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.list.SetWidth(msg.Width)
		m.list.SetHeight(msg.Height - 2)
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c":
			m.quitting = true
			return m, tea.Quit
		case "enter":
			if item, ok := m.list.SelectedItem().(ScriptItem); ok {
				m.selected = &item
			}
			return m, tea.Quit
		}
	}

	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

// View renders the list
func (m ListModel) View() string {
	if m.quitting {
		return ""
	}
	return m.list.View()
}

// Selected returns the selected item
func (m ListModel) Selected() *ScriptItem {
	return m.selected
}

// RunList runs an interactive script selector
func RunList(items []ScriptItem, title string) (*ScriptItem, error) {
	m := NewList(items, title)
	p := tea.NewProgram(m, tea.WithAltScreen())

	finalModel, err := p.Run()
	if err != nil {
		return nil, err
	}

	if model, ok := finalModel.(ListModel); ok {
		return model.Selected(), nil
	}
	return nil, nil
}

// PrintScriptList prints a formatted script list
func PrintScriptList(scripts []registry.Script, cachedNames map[string]bool) {
	if len(scripts) == 0 {
		fmt.Println("No scripts found")
		return
	}

	// Group by category
	byCategory := make(map[string][]registry.Script)
	for _, s := range scripts {
		byCategory[s.Category] = append(byCategory[s.Category], s)
	}

	for cat, catScripts := range byCategory {
		fmt.Printf("\n%s\n", TitleStyle.Render("["+cat+"]"))
		for _, s := range catScripts {
			cached := ""
			if cachedNames[s.Name] {
				cached = CachedStyle.Render(" (cached)")
			}
			fmt.Printf("  %s%s\n", s.Name, cached)
			fmt.Printf("    %s\n", SubtitleStyle.Render(s.Description))
		}
	}
	fmt.Println()
}

// PrintScriptInfo prints detailed script information
func PrintScriptInfo(s *registry.Script, cachedVersion string) {
	fmt.Println()
	fmt.Println(TitleStyle.Render(s.Name))
	fmt.Println(strings.Repeat("─", 44))
	fmt.Printf("Description:  %s\n", s.Description)
	fmt.Printf("Version:      %s\n", s.Version)
	fmt.Printf("Category:     %s\n", s.Category)
	fmt.Printf("Author:       %s\n", s.Author)
	fmt.Printf("File:         %s\n", s.File)

	if len(s.Requires) > 0 {
		fmt.Printf("Requires:     %s\n", strings.Join(s.Requires, ", "))
	}
	if len(s.Tags) > 0 {
		fmt.Printf("Tags:         %s\n", FormatTags(s.Tags))
	}

	fmt.Println()
	if cachedVersion != "" {
		fmt.Printf("Cache status: %s (v%s)\n", SuccessStyle.Render("cached"), cachedVersion)
	} else {
		fmt.Println("Cache status: not cached")
	}
	fmt.Println()
}
