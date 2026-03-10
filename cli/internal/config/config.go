package config

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// Config holds application configuration
type Config struct {
	HomeDir     string
	CacheDir    string
	ConfigFile  string
	RegistryURL string
	Offline     bool
	AutoUpdate  bool
}

// DefaultRegistryURL is the default manifest location
const DefaultRegistryURL = "https://raw.githubusercontent.com/lamngockhuong/utilux/main/registry/manifest.json"

// New creates a new Config with defaults
func New() *Config {
	home, _ := os.UserHomeDir()
	homeDir := filepath.Join(home, ".utilux")

	return &Config{
		HomeDir:     homeDir,
		CacheDir:    filepath.Join(homeDir, "cache"),
		ConfigFile:  filepath.Join(homeDir, "config"),
		RegistryURL: DefaultRegistryURL,
		Offline:     false,
		AutoUpdate:  true,
	}
}

// Load reads configuration from file
func (c *Config) Load() error {
	file, err := os.Open(c.ConfigFile)
	if err != nil {
		if os.IsNotExist(err) {
			return nil // No config file yet
		}
		return err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}

		key := strings.TrimSpace(parts[0])
		value := strings.TrimSpace(parts[1])

		switch key {
		case "UTILUX_REGISTRY_URL":
			c.RegistryURL = value
		case "UTILUX_OFFLINE":
			c.Offline = value == "1" || value == "true"
		case "UTILUX_AUTO_UPDATE":
			c.AutoUpdate = value == "1" || value == "true"
		case "UTILUX_CACHE_DIR":
			c.CacheDir = value
		}
	}

	return scanner.Err()
}

// Save writes configuration to file
func (c *Config) Save() error {
	if err := os.MkdirAll(c.HomeDir, 0755); err != nil {
		return err
	}

	content := fmt.Sprintf(`# Utilux Configuration
# Generated on %s

# Registry URL for manifest.json
UTILUX_REGISTRY_URL=%s

# Enable offline mode (0=disabled, 1=enabled)
UTILUX_OFFLINE=%s

# Auto-update scripts (0=disabled, 1=enabled)
UTILUX_AUTO_UPDATE=%s

# Cache directory
UTILUX_CACHE_DIR=%s
`, time.Now().Format(time.RFC3339), c.RegistryURL, boolToStr(c.Offline), boolToStr(c.AutoUpdate), c.CacheDir)

	return os.WriteFile(c.ConfigFile, []byte(content), 0644)
}

// Get returns a config value by key
func (c *Config) Get(key string) string {
	switch key {
	case "UTILUX_REGISTRY_URL":
		return c.RegistryURL
	case "UTILUX_OFFLINE":
		return boolToStr(c.Offline)
	case "UTILUX_AUTO_UPDATE":
		return boolToStr(c.AutoUpdate)
	case "UTILUX_CACHE_DIR":
		return c.CacheDir
	default:
		return ""
	}
}

// Set updates a config value by key
func (c *Config) Set(key, value string) error {
	switch key {
	case "UTILUX_REGISTRY_URL":
		c.RegistryURL = value
	case "UTILUX_OFFLINE":
		c.Offline = value == "1" || value == "true"
	case "UTILUX_AUTO_UPDATE":
		c.AutoUpdate = value == "1" || value == "true"
	case "UTILUX_CACHE_DIR":
		c.CacheDir = value
	default:
		return fmt.Errorf("unknown config key: %s", key)
	}
	return c.Save()
}

// Reset restores default values
func (c *Config) Reset() error {
	c.RegistryURL = DefaultRegistryURL
	c.Offline = false
	c.AutoUpdate = true
	return c.Save()
}

// Print displays current configuration
func (c *Config) Print() {
	fmt.Println("\nCurrent configuration:")
	fmt.Println()
	fmt.Printf("  UTILUX_REGISTRY_URL = %s\n", c.RegistryURL)
	fmt.Printf("  UTILUX_OFFLINE      = %s\n", boolToStr(c.Offline))
	fmt.Printf("  UTILUX_AUTO_UPDATE  = %s\n", boolToStr(c.AutoUpdate))
	fmt.Printf("  UTILUX_CACHE_DIR    = %s\n", c.CacheDir)
	fmt.Println()
}

func boolToStr(b bool) string {
	if b {
		return "1"
	}
	return "0"
}
