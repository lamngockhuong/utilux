package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/lamngockhuong/utix/cli/internal/tui"
)

var searchCmd = &cobra.Command{
	Use:     "search <query>",
	Aliases: []string{"find"},
	Short:   "Search scripts by name/description",
	Long:    `Search for scripts matching the query in name, description, or tags.`,
	Example: `  utix search docker
  utix search backup
  utix find git`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		query := args[0]

		// Fetch registry
		if _, err := getRegistry().Fetch(false); err != nil {
			return fmt.Errorf("failed to fetch registry: %w", err)
		}

		results := getRegistry().Search(query)
		if len(results) == 0 {
			fmt.Printf("No scripts found matching '%s'\n", query)
			return nil
		}

		// Get cached names
		cachedNames := getCache().ListAsSet()

		fmt.Printf("Search results for '%s':\n", query)
		tui.PrintScriptList(results, cachedNames)

		return nil
	},
}
