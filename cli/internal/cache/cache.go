package cache

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

// Cache manages local script caching
type Cache struct {
	Dir string
}

// New creates a new Cache instance
func New(dir string) *Cache {
	return &Cache{Dir: dir}
}

// Init ensures cache directory exists
func (c *Cache) Init() error {
	return os.MkdirAll(c.Dir, 0755)
}

// ScriptPath returns the cached path for a script
func (c *Cache) ScriptPath(name string) string {
	return filepath.Join(c.Dir, "scripts", name+".sh")
}

// VersionPath returns the version file path for a script
func (c *Cache) VersionPath(name string) string {
	return filepath.Join(c.Dir, "scripts", name+".version")
}

// Exists checks if script is cached
func (c *Cache) Exists(name string) bool {
	_, err := os.Stat(c.ScriptPath(name))
	return err == nil
}

// Get returns cached script content
func (c *Cache) Get(name string) ([]byte, error) {
	return os.ReadFile(c.ScriptPath(name))
}

// Put saves script to cache with version
func (c *Cache) Put(name, version string, content []byte) error {
	scriptPath := c.ScriptPath(name)
	versionPath := c.VersionPath(name)

	// Ensure scripts directory exists
	if err := os.MkdirAll(filepath.Dir(scriptPath), 0755); err != nil {
		return err
	}

	// Write script file
	if err := os.WriteFile(scriptPath, content, 0755); err != nil {
		return err
	}

	// Write version file
	return os.WriteFile(versionPath, []byte(version), 0644)
}

// Version returns cached script version
func (c *Cache) Version(name string) string {
	data, err := os.ReadFile(c.VersionPath(name))
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(data))
}

// Verify checks script integrity against expected hash
func (c *Cache) Verify(name, expectedHash string) bool {
	content, err := c.Get(name)
	if err != nil {
		return false
	}

	hash := sha256.Sum256(content)
	actual := hex.EncodeToString(hash[:])
	return actual == expectedHash
}

// Remove deletes a cached script
func (c *Cache) Remove(name string) error {
	scriptPath := c.ScriptPath(name)
	versionPath := c.VersionPath(name)

	os.Remove(versionPath) // Ignore error
	return os.Remove(scriptPath)
}

// Clear removes all cached scripts
func (c *Cache) Clear() error {
	scriptsDir := filepath.Join(c.Dir, "scripts")
	return os.RemoveAll(scriptsDir)
}

// List returns all cached script names
func (c *Cache) List() ([]string, error) {
	scriptsDir := filepath.Join(c.Dir, "scripts")
	entries, err := os.ReadDir(scriptsDir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, err
	}

	var names []string
	for _, e := range entries {
		if strings.HasSuffix(e.Name(), ".sh") {
			names = append(names, strings.TrimSuffix(e.Name(), ".sh"))
		}
	}
	return names, nil
}

// ListAsSet returns cached script names as a map for quick lookup
func (c *Cache) ListAsSet() map[string]bool {
	list, _ := c.List()
	set := make(map[string]bool, len(list))
	for _, name := range list {
		set[name] = true
	}
	return set
}

// Size returns total cache size in bytes
func (c *Cache) Size() (int64, error) {
	var total int64
	err := filepath.Walk(c.Dir, func(_ string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			total += info.Size()
		}
		return nil
	})
	return total, err
}

// SizeHuman returns human-readable cache size
func (c *Cache) SizeHuman() string {
	size, err := c.Size()
	if err != nil {
		return "unknown"
	}
	return formatBytes(size)
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

// ComputeHash calculates SHA256 hash of reader content
func ComputeHash(r io.Reader) (string, error) {
	h := sha256.New()
	if _, err := io.Copy(h, r); err != nil {
		return "", err
	}
	return hex.EncodeToString(h.Sum(nil)), nil
}
