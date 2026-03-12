package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var configCmd = &cobra.Command{
	Use:     "config [key] [value]",
	Aliases: []string{"cfg"},
	Short:   "View or set configuration",
	Long:    `View all configuration values or get/set a specific key.`,
	Example: `  utix config
  utix config UTIX_OFFLINE
  utix config UTIX_OFFLINE 1
  utix config UTIX_REGISTRY_URL https://example.com/manifest.json`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if len(args) == 0 {
			cfg.Print()
			return nil
		}

		key := args[0]
		if len(args) == 1 {
			value := cfg.Get(key)
			if value == "" {
				return fmt.Errorf("unknown config key: %s", key)
			}
			fmt.Println(value)
			return nil
		}

		value := args[1]
		if err := cfg.Set(key, value); err != nil {
			return err
		}
		fmt.Printf("Set %s = %s\n", key, value)
		return nil
	},
}

func init() {
	rootCmd.AddCommand(configCmd)
}
