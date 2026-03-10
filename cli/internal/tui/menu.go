package tui

import (
	"fmt"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// MenuItem represents a menu option
type MenuItem struct {
	Label string
	Value string
}

// MenuModel represents the main menu
type MenuModel struct {
	title    string
	items    []MenuItem
	cursor   int
	selected *MenuItem
	quitting bool
}

// NewMenu creates a new menu
func NewMenu(title string, items []MenuItem) MenuModel {
	return MenuModel{
		title: title,
		items: items,
	}
}

func (m MenuModel) Init() tea.Cmd {
	return nil
}

func (m MenuModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c":
			m.quitting = true
			return m, tea.Quit
		case "up", "k":
			if m.cursor > 0 {
				m.cursor--
			}
		case "down", "j":
			if m.cursor < len(m.items)-1 {
				m.cursor++
			}
		case "enter":
			m.selected = &m.items[m.cursor]
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m MenuModel) View() string {
	if m.quitting {
		return ""
	}

	s := "\n"
	s += TitleStyle.Render(m.title) + "\n\n"

	for i, item := range m.items {
		cursor := "  "
		style := UnselectedStyle
		if m.cursor == i {
			cursor = "> "
			style = lipgloss.NewStyle().
				Foreground(lipgloss.Color("229")).
				Bold(true)
		}
		s += fmt.Sprintf("%s%s\n", cursor, style.Render(item.Label))
	}

	s += "\n" + SubtitleStyle.Render("↑/↓: navigate • enter: select • q: quit") + "\n"
	return s
}

func (m MenuModel) Selected() *MenuItem {
	return m.selected
}

// RunMenu runs the menu and returns the selected item
func RunMenu(title string, items []MenuItem) (*MenuItem, error) {
	m := NewMenu(title, items)
	p := tea.NewProgram(m)

	finalModel, err := p.Run()
	if err != nil {
		return nil, err
	}

	if model, ok := finalModel.(MenuModel); ok {
		return model.Selected(), nil
	}
	return nil, nil
}
