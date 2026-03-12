package docs

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/lamngockhuong/utix/cli/internal/registry"
)

// Manager handles documentation loading, caching, and rendering
type Manager struct {
	cacheDir string
	registry *registry.Registry
}

// New creates a new docs Manager
func New(homeDir string, reg *registry.Registry) *Manager {
	return &Manager{
		cacheDir: filepath.Join(homeDir, "docs"),
		registry: reg,
	}
}

// Init ensures docs cache directory exists
func (m *Manager) Init() error {
	return os.MkdirAll(m.cacheDir, 0755)
}

// CachePath returns the cached path for script docs
func (m *Manager) CachePath(name string) string {
	return filepath.Join(m.cacheDir, name+".md")
}

// VersionPath returns the version file path for docs
func (m *Manager) VersionPath(name string) string {
	return filepath.Join(m.cacheDir, name+".version")
}

// Exists checks if docs are cached
func (m *Manager) Exists(name string) bool {
	_, err := os.Stat(m.CachePath(name))
	return err == nil
}

// Version returns cached docs version
func (m *Manager) Version(name string) string {
	data, err := os.ReadFile(m.VersionPath(name))
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(data))
}

// Load fetches docs from cache or downloads if needed
func (m *Manager) Load(name string) (string, error) {
	// Check cache first
	if m.Exists(name) {
		content, err := os.ReadFile(m.CachePath(name))
		if err == nil {
			return string(content), nil
		}
	}

	// Get script metadata
	script, err := m.registry.GetScript(name)
	if err != nil {
		return "", fmt.Errorf("script not found: %s", name)
	}

	// Check if docs exist
	if script.Docs == "" {
		return "", fmt.Errorf("no documentation available for %s", name)
	}

	// Download docs
	content, err := m.download(script)
	if err != nil {
		return "", err
	}

	// Cache the docs
	if err := m.cache(name, script.Version, content); err != nil {
		// Log but don't fail
		fmt.Fprintf(os.Stderr, "Warning: failed to cache docs: %v\n", err)
	}

	return string(content), nil
}

// download fetches docs from remote registry
func (m *Manager) download(script *registry.Script) ([]byte, error) {
	url := m.registry.BaseURL() + "/" + script.Docs

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to download docs for %s: %w", script.Name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("HTTP %d downloading docs for %s", resp.StatusCode, script.Name)
	}

	content, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read docs for %s: %w", script.Name, err)
	}

	// Verify hash if provided
	if script.DocsSHA256 != "" {
		hash := sha256.Sum256(content)
		actual := hex.EncodeToString(hash[:])
		if actual != script.DocsSHA256 {
			return nil, fmt.Errorf("docs hash mismatch for %s: expected %s, got %s",
				script.Name, script.DocsSHA256, actual)
		}
	}

	return content, nil
}

// cache stores docs locally
func (m *Manager) cache(name, version string, content []byte) error {
	if err := m.Init(); err != nil {
		return err
	}

	// Write docs file
	if err := os.WriteFile(m.CachePath(name), content, 0644); err != nil {
		return err
	}

	// Write version file
	return os.WriteFile(m.VersionPath(name), []byte(version), 0644)
}

// Show loads and renders docs to stdout
func (m *Manager) Show(name string) error {
	content, err := m.Load(name)
	if err != nil {
		return err
	}

	rendered, err := Render(content)
	if err != nil {
		// Fallback to plain text
		fmt.Println(content)
		return nil
	}

	fmt.Println(rendered)
	return nil
}

// Clear removes cached docs
func (m *Manager) Clear(name string) error {
	if name != "" {
		_ = os.Remove(m.VersionPath(name))
		return os.Remove(m.CachePath(name))
	}

	// Clear all
	return os.RemoveAll(m.cacheDir)
}

// List returns all cached doc names
func (m *Manager) List() ([]string, error) {
	entries, err := os.ReadDir(m.cacheDir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, err
	}

	var names []string
	for _, e := range entries {
		if strings.HasSuffix(e.Name(), ".md") {
			names = append(names, strings.TrimSuffix(e.Name(), ".md"))
		}
	}
	return names, nil
}

// Verify checks if cached docs match expected hash
func (m *Manager) Verify(name, expectedHash string) bool {
	if expectedHash == "" {
		return true
	}

	content, err := os.ReadFile(m.CachePath(name))
	if err != nil {
		return false
	}

	hash := sha256.Sum256(content)
	actual := hex.EncodeToString(hash[:])
	return actual == expectedHash
}

// GetContent returns raw docs content without rendering
func (m *Manager) GetContent(name string) (string, error) {
	return m.Load(name)
}

// RenderContent renders markdown content to terminal-friendly output
func (m *Manager) RenderContent(content string) (string, error) {
	return Render(content)
}

// HasDocs checks if a script has documentation
func (m *Manager) HasDocs(name string) bool {
	script, err := m.registry.GetScript(name)
	if err != nil {
		return false
	}
	return script.Docs != ""
}

// ShowPlain loads and outputs docs without rendering
func (m *Manager) ShowPlain(name string) error {
	content, err := m.Load(name)
	if err != nil {
		return err
	}

	// Strip excessive newlines for cleaner output
	content = strings.TrimSpace(content)
	reader := bytes.NewBufferString(content)

	_, err = io.Copy(os.Stdout, reader)
	fmt.Println()
	return err
}
