package cmd

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"

	"github.com/lamngockhuong/utilux/cli/internal/cache"
	"github.com/lamngockhuong/utilux/cli/internal/loader"
	"github.com/lamngockhuong/utilux/cli/internal/registry"
)

var (
	Version = "1.0.0"

	// Global flags
	cfgFile     string
	registryURL string
	offline     bool
	verbose     bool

	// Shared instances
	cacheDir string
	reg      *registry.Registry
	cch      *cache.Cache
	ldr      *loader.Loader
)

var rootCmd = &cobra.Command{
	Use:   "utilux",
	Short: "Lightweight script aggregator with lazy loading",
	Long: `Utilux is a lightweight utility that aggregates useful scripts
with on-demand downloading and local caching.

Scripts are fetched from GitHub on first use and cached locally
for fast subsequent execution.`,
	Version: Version,
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		return initApp()
	},
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default $HOME/.utilux/config)")
	rootCmd.PersistentFlags().StringVar(&registryURL, "registry", "", "custom registry URL")
	rootCmd.PersistentFlags().BoolVar(&offline, "offline", false, "offline mode (use cached only)")
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "verbose output")

	// Add subcommands
	rootCmd.AddCommand(runCmd)
	rootCmd.AddCommand(listCmd)
	rootCmd.AddCommand(searchCmd)
	rootCmd.AddCommand(infoCmd)
	rootCmd.AddCommand(updateCmd)
	rootCmd.AddCommand(cacheCmd)
}

func initApp() error {
	// Determine cache directory
	home, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get home directory: %w", err)
	}
	cacheDir = filepath.Join(home, ".utilux")

	// Initialize cache
	cch = cache.New(cacheDir)
	if err := cch.Init(); err != nil {
		return fmt.Errorf("failed to init cache: %w", err)
	}

	// Initialize registry
	reg = registry.New(registryURL, cacheDir)

	// Initialize loader
	ldr = loader.New(reg, cch)

	return nil
}

func getRegistry() *registry.Registry {
	return reg
}

func getCache() *cache.Cache {
	return cch
}

func getLoader() *loader.Loader {
	return ldr
}
