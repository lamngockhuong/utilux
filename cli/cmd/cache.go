package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/lamngockhuong/utix/cli/internal/tui"
)

var cacheCmd = &cobra.Command{
	Use:   "cache <subcommand>",
	Short: "Cache management",
	Long:  `Manage the local script cache.`,
}

var cacheClearCmd = &cobra.Command{
	Use:   "clear [script]",
	Short: "Clear cache",
	Long:  `Clear all cached scripts or a specific one.`,
	Example: `  utix cache clear
  utix cache clear git-clean`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if len(args) > 0 {
			name := args[0]
			if err := getCache().Remove(name); err != nil {
				return fmt.Errorf("failed to remove %s: %w", name, err)
			}
			fmt.Printf("Removed %s from cache\n", name)
		} else {
			if err := getCache().Clear(); err != nil {
				return fmt.Errorf("failed to clear cache: %w", err)
			}
			fmt.Println("Cache cleared")
		}
		return nil
	},
}

var cacheListCmd = &cobra.Command{
	Use:   "list",
	Short: "List cached scripts",
	RunE: func(cmd *cobra.Command, args []string) error {
		cached, err := getCache().List()
		if err != nil {
			return err
		}

		if len(cached) == 0 {
			fmt.Println("No cached scripts")
			return nil
		}

		fmt.Println("Cached scripts:")
		for _, name := range cached {
			ver := getCache().Version(name)
			fmt.Printf("  %s %s\n", name, tui.SubtitleStyle.Render("(v"+ver+")"))
		}
		return nil
	},
}

var cacheSizeCmd = &cobra.Command{
	Use:   "size",
	Short: "Show cache size",
	RunE: func(cmd *cobra.Command, args []string) error {
		fmt.Printf("Cache size: %s\n", getCache().SizeHuman())
		return nil
	},
}

func init() {
	cacheCmd.AddCommand(cacheClearCmd)
	cacheCmd.AddCommand(cacheListCmd)
	cacheCmd.AddCommand(cacheSizeCmd)
}
