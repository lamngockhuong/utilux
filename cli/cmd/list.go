package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/lamngockhuong/utilux/cli/internal/tui"
)

var interactive bool

var listCmd = &cobra.Command{
	Use:     "list [category]",
	Aliases: []string{"ls"},
	Short:   "List available scripts",
	Long:    `List all available scripts, optionally filtered by category.`,
	Example: `  utilux list
  utilux list -i
  utilux list dev
  utilux ls system`,
	RunE: func(cmd *cobra.Command, args []string) error {
		category := ""
		if len(args) > 0 {
			category = args[0]
		}

		// Fetch registry
		if _, err := getRegistry().Fetch(false); err != nil {
			return fmt.Errorf("failed to fetch registry: %w", err)
		}

		scripts := getRegistry().ListScripts(category)
		if len(scripts) == 0 {
			if category != "" {
				fmt.Printf("No scripts found in category: %s\n", category)
			} else {
				fmt.Println("No scripts available")
			}
			return nil
		}

		// Get cached names
		cachedNames := getCache().ListAsSet()

		// Interactive mode
		if interactive {
			items := make([]tui.ScriptItem, len(scripts))
			for i, s := range scripts {
				items[i] = tui.ScriptItem{
					Script: s,
					Cached: cachedNames[s.Name],
				}
			}

			selected, err := tui.RunList(items, "Select a script to run")
			if err != nil {
				return err
			}

			if selected != nil {
				fmt.Printf("\nRunning %s...\n\n", selected.Script.Name)
				return getLoader().Execute(selected.Script.Name, nil)
			}
			return nil
		}

		// Non-interactive: print list
		fmt.Println("Available scripts:")
		tui.PrintScriptList(scripts, cachedNames)

		// Show categories if no filter
		if category == "" {
			cats := getRegistry().Categories()
			fmt.Printf("Categories: %v\n", cats)
		}

		return nil
	},
}

func init() {
	listCmd.Flags().BoolVarP(&interactive, "interactive", "i", false, "interactive mode - select and run script")
}
