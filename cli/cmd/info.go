package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/lamngockhuong/utilux/cli/internal/tui"
)

var showDocs bool

var infoCmd = &cobra.Command{
	Use:     "info <script>",
	Aliases: []string{"show"},
	Short:   "Show script details",
	Long:    `Display detailed information about a specific script.`,
	Example: `  utilux info git-clean
  utilux info docker-prune --docs
  utilux show backup-home -d`,
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

		// Show full docs if requested
		if showDocs {
			fmt.Println("\nDocumentation:")
			fmt.Println("============================================")
			if err := getDocs().Show(name); err != nil {
				fmt.Printf("No documentation available for '%s'\n", name)
			}
		}

		return nil
	},
}

func init() {
	infoCmd.Flags().BoolVarP(&showDocs, "docs", "d", false, "Show full documentation")
}
