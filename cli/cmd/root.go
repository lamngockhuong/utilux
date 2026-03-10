package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"

	"github.com/lamngockhuong/utilux/cli/internal/cache"
	"github.com/lamngockhuong/utilux/cli/internal/config"
	"github.com/lamngockhuong/utilux/cli/internal/loader"
	"github.com/lamngockhuong/utilux/cli/internal/registry"
	"github.com/lamngockhuong/utilux/cli/internal/tui"
)

var (
	Version = "1.0.0"

	// Global flags
	cfgFile     string
	registryURL string
	offline     bool
	verbose     bool

	// Shared instances
	cfg *config.Config
	reg *registry.Registry
	cch *cache.Cache
	ldr *loader.Loader
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
	RunE: func(cmd *cobra.Command, args []string) error {
		// Interactive mode when no subcommand
		return runInteractiveMode()
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
	// Initialize config
	cfg = config.New()
	if err := cfg.Load(); err != nil {
		return fmt.Errorf("failed to load config: %w", err)
	}

	// Override from flags
	if registryURL != "" {
		cfg.RegistryURL = registryURL
	}
	if offline {
		cfg.Offline = true
	}

	// Initialize cache
	cch = cache.New(cfg.HomeDir)
	if err := cch.Init(); err != nil {
		return fmt.Errorf("failed to init cache: %w", err)
	}

	// Initialize registry
	reg = registry.New(cfg.RegistryURL, cfg.HomeDir)

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

// runInteractiveMode shows main menu then handles selected action
func runInteractiveMode() error {
	// Fetch registry first
	if _, err := reg.Fetch(false); err != nil {
		return fmt.Errorf("failed to fetch registry: %w", err)
	}

	menuItems := []tui.MenuItem{
		{Label: "Run a script", Value: "run"},
		{Label: "List scripts", Value: "list"},
		{Label: "Search scripts", Value: "search"},
		{Label: "Script info", Value: "info"},
		{Label: "Update scripts", Value: "update"},
		{Label: "Cache management", Value: "cache"},
		{Label: "Configuration", Value: "config"},
		{Label: "Exit", Value: "exit"},
	}

	for {
		selected, err := tui.RunMenu("Utilux - Choose an action", menuItems)
		if err != nil {
			return err
		}
		if selected == nil || selected.Value == "exit" {
			return nil
		}

		var actionErr error
		switch selected.Value {
		case "run":
			actionErr = runScriptPicker()
		case "list":
			actionErr = listScripts()
		case "search":
			actionErr = searchScripts()
		case "info":
			actionErr = showScriptInfo()
		case "update":
			actionErr = updateScripts()
		case "cache":
			actionErr = manageCacheInteractive()
		case "config":
			actionErr = manageConfigInteractive()
		}

		if actionErr != nil {
			fmt.Printf("\nError: %v\n", actionErr)
		}

		// Pause before returning to menu
		fmt.Print("\nPress Enter to continue...")
		fmt.Scanln()
	}
}

// runScriptPicker shows interactive script picker
func runScriptPicker() error {
	scripts := reg.ListScripts("")
	if len(scripts) == 0 {
		fmt.Println("No scripts available")
		return nil
	}

	cachedNames := cch.ListAsSet()
	items := make([]tui.ScriptItem, len(scripts))
	for i, s := range scripts {
		items[i] = tui.ScriptItem{Script: s, Cached: cachedNames[s.Name]}
	}

	selected, err := tui.RunList(items, "Select a script to run")
	if err != nil {
		return err
	}
	if selected == nil {
		return nil
	}

	fmt.Printf("\nRunning %s...\n\n", selected.Script.Name)
	return ldr.Execute(selected.Script.Name, nil)
}

// listScripts shows all scripts grouped by category
func listScripts() error {
	scripts := reg.ListScripts("")
	cachedNames := cch.ListAsSet()
	fmt.Println("\nAvailable scripts:")
	tui.PrintScriptList(scripts, cachedNames)
	fmt.Printf("Categories: %v\n", reg.Categories())
	return nil
}

// searchScripts prompts for search term and shows results
func searchScripts() error {
	fmt.Print("\nEnter search term: ")
	var term string
	fmt.Scanln(&term)
	if term == "" {
		return nil
	}

	scripts := reg.Search(term)
	if len(scripts) == 0 {
		fmt.Println("No scripts found")
		return nil
	}

	cachedNames := cch.ListAsSet()
	tui.PrintScriptList(scripts, cachedNames)
	return nil
}

// showScriptInfo prompts for script name and shows info
func showScriptInfo() error {
	scripts := reg.ListScripts("")
	if len(scripts) == 0 {
		fmt.Println("No scripts available")
		return nil
	}

	cachedNames := cch.ListAsSet()
	items := make([]tui.ScriptItem, len(scripts))
	for i, s := range scripts {
		items[i] = tui.ScriptItem{Script: s, Cached: cachedNames[s.Name]}
	}

	selected, err := tui.RunList(items, "Select a script for info")
	if err != nil {
		return err
	}
	if selected == nil {
		return nil
	}

	cachedVer := cch.Version(selected.Script.Name)
	tui.PrintScriptInfo(&selected.Script, cachedVer)
	return nil
}

// updateScripts updates all cached scripts
func updateScripts() error {
	fmt.Println("\nUpdating cached scripts...")
	if err := ldr.Update(""); err != nil {
		return err
	}
	fmt.Println("Update complete")
	return nil
}

// manageCacheInteractive shows cache management menu
func manageCacheInteractive() error {
	menuItems := []tui.MenuItem{
		{Label: "List cached scripts", Value: "list"},
		{Label: "Clear all cache", Value: "clear"},
		{Label: "Show cache size", Value: "size"},
		{Label: "Back", Value: "back"},
	}

	selected, err := tui.RunMenu("Cache Management", menuItems)
	if err != nil {
		return err
	}
	if selected == nil || selected.Value == "back" {
		return nil
	}

	switch selected.Value {
	case "list":
		cached, _ := cch.List()
		if len(cached) == 0 {
			fmt.Println("\nNo cached scripts")
		} else {
			fmt.Println("\nCached scripts:")
			for _, name := range cached {
				fmt.Printf("  - %s\n", name)
			}
		}
	case "clear":
		if err := cch.Clear(); err != nil {
			return err
		}
		fmt.Println("\nCache cleared")
	case "size":
		size, _ := cch.Size()
		fmt.Printf("\nCache size: %s\n", formatBytes(size))
	}
	return nil
}

func formatBytes(b int64) string {
	const unit = 1024
	if b < unit {
		return fmt.Sprintf("%d B", b)
	}
	div, exp := int64(unit), 0
	for n := b / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %cB", float64(b)/float64(div), "KMGTPE"[exp])
}

// manageConfigInteractive shows configuration menu
func manageConfigInteractive() error {
	menuItems := []tui.MenuItem{
		{Label: "Show current config", Value: "show"},
		{Label: "Set registry URL", Value: "registry"},
		{Label: "Toggle offline mode", Value: "offline"},
		{Label: "Toggle auto-update", Value: "autoupdate"},
		{Label: "Reset to defaults", Value: "reset"},
		{Label: "Back", Value: "back"},
	}

	selected, err := tui.RunMenu("Configuration", menuItems)
	if err != nil {
		return err
	}
	if selected == nil || selected.Value == "back" {
		return nil
	}

	switch selected.Value {
	case "show":
		cfg.Print()
	case "registry":
		fmt.Printf("Current: %s\n", cfg.RegistryURL)
		fmt.Print("Enter new registry URL (empty to cancel): ")
		var url string
		fmt.Scanln(&url)
		if url != "" {
			if err := cfg.Set("UTILUX_REGISTRY_URL", url); err != nil {
				return err
			}
			fmt.Println("Registry URL updated")
		}
	case "offline":
		cfg.Offline = !cfg.Offline
		cfg.Save()
		fmt.Printf("Offline mode: %v\n", cfg.Offline)
	case "autoupdate":
		cfg.AutoUpdate = !cfg.AutoUpdate
		cfg.Save()
		fmt.Printf("Auto-update: %v\n", cfg.AutoUpdate)
	case "reset":
		if err := cfg.Reset(); err != nil {
			return err
		}
		fmt.Println("Configuration reset to defaults")
	}
	return nil
}

func getConfig() *config.Config {
	return cfg
}
