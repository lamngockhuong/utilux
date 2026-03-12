package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/lamngockhuong/utix/cli/internal/tui"
)

var updateCmd = &cobra.Command{
	Use:   "update [script|--all]",
	Short: "Update cached scripts",
	Long: `Update cached scripts to their latest versions.

If no script is specified, updates all cached scripts.`,
	Example: `  utix update
  utix update --all
  utix update git-clean`,
	RunE: func(cmd *cobra.Command, args []string) error {
		all, _ := cmd.Flags().GetBool("all")

		// Force refresh registry
		if err := tui.RunWithSpinner("Refreshing registry...", func() error {
			_, err := getRegistry().Fetch(true)
			return err
		}); err != nil {
			return fmt.Errorf("failed to refresh registry: %w", err)
		}

		if len(args) > 0 && !all {
			// Update specific script
			name := args[0]
			fmt.Printf("Updating %s...\n", name)
			if err := getLoader().Update(name); err != nil {
				return err
			}
			fmt.Printf("%s updated successfully\n", tui.SuccessStyle.Render(name))
		} else {
			// Update all
			fmt.Println("Updating all cached scripts...")
			if err := getLoader().Update(""); err != nil {
				return err
			}
			fmt.Println(tui.SuccessStyle.Render("All scripts updated"))
		}

		return nil
	},
}

func init() {
	updateCmd.Flags().Bool("all", false, "update all cached scripts")
}
