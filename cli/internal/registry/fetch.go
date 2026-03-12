package registry

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const (
	DefaultRegistryURL = "https://raw.githubusercontent.com/lamngockhuong/utilux/main/registry/manifest.json"
	CacheTTL           = 1 * time.Hour
)

// Registry manages script manifest fetching and caching
type Registry struct {
	URL       string
	CacheDir  string
	manifest  *Manifest
	cacheFile string
}

// New creates a new Registry instance
func New(url, cacheDir string) *Registry {
	if url == "" {
		url = DefaultRegistryURL
	}
	return &Registry{
		URL:       url,
		CacheDir:  cacheDir,
		cacheFile: filepath.Join(cacheDir, "manifest.json"),
	}
}

// Fetch retrieves the manifest, using cache if valid
func (r *Registry) Fetch(forceRefresh bool) (*Manifest, error) {
	if r.manifest != nil && !forceRefresh {
		return r.manifest, nil
	}

	// Check cache
	if !forceRefresh {
		if m, err := r.loadFromCache(); err == nil {
			r.manifest = m
			return m, nil
		}
	}

	// Fetch from remote
	m, err := r.fetchRemote()
	if err != nil {
		return nil, err
	}

	// Save to cache
	if err := r.saveToCache(m); err != nil {
		// Non-fatal, just log
		fmt.Fprintf(os.Stderr, "Warning: failed to cache manifest: %v\n", err)
	}

	r.manifest = m
	return m, nil
}

// loadFromCache loads manifest from local cache if valid
func (r *Registry) loadFromCache() (*Manifest, error) {
	info, err := os.Stat(r.cacheFile)
	if err != nil {
		return nil, err
	}

	// Check if cache is expired
	if time.Since(info.ModTime()) > CacheTTL {
		return nil, fmt.Errorf("cache expired")
	}

	data, err := os.ReadFile(r.cacheFile)
	if err != nil {
		return nil, err
	}

	var m Manifest
	if err := json.Unmarshal(data, &m); err != nil {
		return nil, err
	}

	return &m, nil
}

// fetchRemote fetches manifest from remote URL
func (r *Registry) fetchRemote() (*Manifest, error) {
	client := &http.Client{Timeout: 30 * time.Second}

	resp, err := client.Get(r.URL)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch manifest: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("HTTP %d: %s", resp.StatusCode, resp.Status)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var m Manifest
	if err := json.Unmarshal(data, &m); err != nil {
		return nil, fmt.Errorf("failed to parse manifest: %w", err)
	}

	return &m, nil
}

// saveToCache saves manifest to local cache
func (r *Registry) saveToCache(m *Manifest) error {
	if err := os.MkdirAll(r.CacheDir, 0755); err != nil {
		return err
	}

	data, err := json.MarshalIndent(m, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(r.cacheFile, data, 0644)
}

// GetScript returns a script by name
func (r *Registry) GetScript(name string) (*Script, error) {
	if r.manifest == nil {
		return nil, fmt.Errorf("manifest not loaded")
	}

	for _, s := range r.manifest.Scripts {
		if s.Name == name {
			return &s, nil
		}
	}
	return nil, fmt.Errorf("script not found: %s", name)
}

// ListScripts returns all non-draft scripts, optionally filtered by category
func (r *Registry) ListScripts(category string) []Script {
	if r.manifest == nil {
		return nil
	}

	var filtered []Script
	for _, s := range r.manifest.Scripts {
		// Skip draft scripts
		if s.Draft {
			continue
		}
		if category == "" || s.Category == category {
			filtered = append(filtered, s)
		}
	}
	return filtered
}

// Categories returns unique categories (only from non-draft scripts)
func (r *Registry) Categories() []string {
	if r.manifest == nil {
		return nil
	}

	seen := make(map[string]bool)
	var cats []string
	for _, s := range r.manifest.Scripts {
		// Skip draft scripts
		if s.Draft {
			continue
		}
		if !seen[s.Category] {
			seen[s.Category] = true
			cats = append(cats, s.Category)
		}
	}
	return cats
}

// Search finds non-draft scripts matching query in name, description, or tags
func (r *Registry) Search(query string) []Script {
	if r.manifest == nil {
		return nil
	}

	var results []Script
	for _, s := range r.manifest.Scripts {
		// Skip draft scripts
		if s.Draft {
			continue
		}
		if containsIgnoreCase(s.Name, query) || containsIgnoreCase(s.Description, query) || containsAny(s.Tags, query) {
			results = append(results, s)
		}
	}
	return results
}

// BaseURL returns the manifest base URL for scripts
func (r *Registry) BaseURL() string {
	if r.manifest != nil {
		return r.manifest.BaseURL
	}
	return ""
}

func containsIgnoreCase(s, substr string) bool {
	return strings.Contains(strings.ToLower(s), strings.ToLower(substr))
}

func containsAny(slice []string, substr string) bool {
	for _, s := range slice {
		if containsIgnoreCase(s, substr) {
			return true
		}
	}
	return false
}
