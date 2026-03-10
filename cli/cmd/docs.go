package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var docsCmd = &cobra.Command{
	Use:   "docs <script>",
	Short: "Show script documentation",
	Long: `Display full documentation for a specific script.

Documentation includes detailed usage instructions, options,
examples, and troubleshooting tips.`,
	Example: `  utilux docs backup-home
  utilux docs docker-prune
  utilux docs git-clean`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]

		// Fetch registry
		if _, err := getRegistry().Fetch(false); err != nil {
			return fmt.Errorf("failed to fetch registry: %w", err)
		}

		// Check if script exists
		if _, err := getRegistry().GetScript(name); err != nil {
			return fmt.Errorf("script not found: %s", name)
		}

		// Show documentation
		if err := getDocs().Show(name); err != nil {
			fmt.Printf("\nNo documentation available for '%s'\n", name)
			fmt.Printf("Try running 'utilux info %s' for basic script information.\n", name)
			return nil
		}

		return nil
	},
}

func init() {
	rootCmd.AddCommand(docsCmd)
}
