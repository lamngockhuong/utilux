package tui

import "github.com/charmbracelet/lipgloss"

var (
	// Colors
	Primary   = lipgloss.Color("205")
	Secondary = lipgloss.Color("240")
	Success   = lipgloss.Color("82")
	Warning   = lipgloss.Color("214")
	Error     = lipgloss.Color("196")
	Info      = lipgloss.Color("39")

	// Text styles
	TitleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(Primary)

	SubtitleStyle = lipgloss.NewStyle().
			Foreground(Secondary)

	SuccessStyle = lipgloss.NewStyle().
			Foreground(Success)

	ErrorStyle = lipgloss.NewStyle().
			Foreground(Error)

	WarningStyle = lipgloss.NewStyle().
			Foreground(Warning)

	InfoStyle = lipgloss.NewStyle().
			Foreground(Info)

	// Box styles
	BoxStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(Primary).
			Padding(1, 2)

	// List styles
	SelectedStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("229")).
			Background(Primary).
			Bold(true)

	UnselectedStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("252"))

	// Category badge
	CategoryStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("241")).
			Background(lipgloss.Color("236")).
			Padding(0, 1)

	// Tag style
	TagStyle = lipgloss.NewStyle().
			Foreground(Info)

	// Cached indicator
	CachedStyle = lipgloss.NewStyle().
			Foreground(Success).
			Bold(true)
)

// FormatCategory returns styled category text
func FormatCategory(cat string) string {
	return CategoryStyle.Render(cat)
}

// FormatCached returns cached indicator
func FormatCached(cached bool) string {
	if cached {
		return CachedStyle.Render(" (cached)")
	}
	return ""
}

// FormatTags returns styled tags
func FormatTags(tags []string) string {
	if len(tags) == 0 {
		return ""
	}
	result := ""
	for i, t := range tags {
		if i > 0 {
			result += ", "
		}
		result += TagStyle.Render(t)
	}
	return result
}
