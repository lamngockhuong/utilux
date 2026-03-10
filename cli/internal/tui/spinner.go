package tui

import (
	"fmt"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

var spinnerStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("205"))

// SpinnerModel represents a loading spinner
type SpinnerModel struct {
	spinner  spinner.Model
	message  string
	quitting bool
	done     bool
}

// NewSpinner creates a new spinner model
func NewSpinner(message string) SpinnerModel {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = spinnerStyle
	return SpinnerModel{
		spinner: s,
		message: message,
	}
}

// Init initializes the spinner
func (m SpinnerModel) Init() tea.Cmd {
	return m.spinner.Tick
}

// Update handles spinner updates
func (m SpinnerModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if msg.String() == "q" || msg.String() == "ctrl+c" {
			m.quitting = true
			return m, tea.Quit
		}
	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd
	case DoneMsg:
		m.done = true
		return m, tea.Quit
	}
	return m, nil
}

// View renders the spinner
func (m SpinnerModel) View() string {
	if m.done {
		return fmt.Sprintf("✓ %s\n", m.message)
	}
	if m.quitting {
		return ""
	}
	return fmt.Sprintf("%s %s\n", m.spinner.View(), m.message)
}

// DoneMsg signals completion
type DoneMsg struct{}

// RunWithSpinner executes a function with a loading spinner
func RunWithSpinner(message string, fn func() error) error {
	done := make(chan error, 1)

	m := NewSpinner(message)
	p := tea.NewProgram(m)

	go func() {
		err := fn()
		done <- err
		p.Send(DoneMsg{})
	}()

	if _, err := p.Run(); err != nil {
		return err
	}

	// Wait for function to complete (no timeout - avoids goroutine leak)
	return <-done
}
