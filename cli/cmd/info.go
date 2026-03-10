package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/lamngockhuong/utilux/cli/internal/tui"
)

var infoCmd = &cobra.Command{
	Use:     "info <script>",
	Aliases: []string{"show"},
	Short:   "Show script details",
	Long:    `Display detailed information about a specific script.`,
	Example: `  utilux info git-clean
  utilux show docker-prune`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]

		// Fetch registry
		if _, err := getRegistry().Fetch(false); err != nil {
			return fmt.Errorf("failed to fetch registry: %w", err)
		}

		script, err := getRegistry().GetScript(name)
		if err != nil {
			return fmt.Errorf("script not found: %s", name)
		}

		cachedVersion := getCache().Version(name)
		tui.PrintScriptInfo(script, cachedVersion)

		return nil
	},
}
