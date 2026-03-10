package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/lamngockhuong/utilux/cli/internal/tui"
)

var runCmd = &cobra.Command{
	Use:   "run <script> [args...]",
	Short: "Run a script (downloads on first use)",
	Long: `Run a script by name. The script will be downloaded
and cached on first use, then executed locally.

Any additional arguments are passed to the script.`,
	Example: `  utilux run git-clean
  utilux run backup-home /path/to/backup
  utilux run docker-prune --force`,
	Args: cobra.MinimumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		scriptName := args[0]
		scriptArgs := args[1:]

		// Fetch registry
		if !offline {
			if err := tui.RunWithSpinner("Fetching registry...", func() error {
				_, err := getRegistry().Fetch(false)
				return err
			}); err != nil {
				return fmt.Errorf("failed to fetch registry: %w", err)
			}
		} else {
			if _, err := getRegistry().Fetch(false); err != nil {
				return fmt.Errorf("failed to load registry (offline): %w", err)
			}
		}

		// Check dependencies
		missing, err := getLoader().CheckRequires(scriptName)
		if err != nil {
			return err
		}
		if len(missing) > 0 {
			return fmt.Errorf("missing dependencies: %v", missing)
		}

		// Execute script
		fmt.Printf("Running %s...\n\n", scriptName)
		return getLoader().Execute(scriptName, scriptArgs)
	},
}
