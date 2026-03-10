package docs

import (
	"github.com/charmbracelet/glamour"
)

// Render converts markdown content to terminal-friendly styled output
func Render(content string) (string, error) {
	renderer, err := glamour.NewTermRenderer(
		glamour.WithAutoStyle(),
		glamour.WithWordWrap(100),
	)
	if err != nil {
		return content, err
	}

	rendered, err := renderer.Render(content)
	if err != nil {
		return content, err
	}

	return rendered, nil
}

// RenderWithStyle renders markdown with a specific style
func RenderWithStyle(content, style string) (string, error) {
	var opt glamour.TermRendererOption

	switch style {
	case "dark":
		opt = glamour.WithStylePath("dark")
	case "light":
		opt = glamour.WithStylePath("light")
	case "dracula":
		opt = glamour.WithStylePath("dracula")
	case "notty":
		opt = glamour.WithStylePath("notty")
	default:
		opt = glamour.WithAutoStyle()
	}

	renderer, err := glamour.NewTermRenderer(
		opt,
		glamour.WithWordWrap(100),
	)
	if err != nil {
		return content, err
	}

	return renderer.Render(content)
}
