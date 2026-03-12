package loader

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"time"

	"github.com/lamngockhuong/utilux/cli/internal/cache"
	"github.com/lamngockhuong/utilux/cli/internal/registry"
)

// Loader handles script downloading and execution
type Loader struct {
	Registry *registry.Registry
	Cache    *cache.Cache
}

// New creates a new Loader instance
func New(reg *registry.Registry, c *cache.Cache) *Loader {
	return &Loader{
		Registry: reg,
		Cache:    c,
	}
}

// Execute downloads (if needed) and runs a script
func (l *Loader) Execute(name string, args []string) error {
	script, err := l.Registry.GetScript(name)
	if err != nil {
		return err
	}

	// Check requirements
	if err := l.checkRequires(script.Requires); err != nil {
		return err
	}

	// Ensure script is cached
	if err := l.ensureCached(script); err != nil {
		return err
	}

	// Execute
	scriptPath := l.Cache.ScriptPath(name)
	return l.run(scriptPath, args)
}

// ensureCached downloads script if not cached or outdated
func (l *Loader) ensureCached(script *registry.Script) error {
	cached := l.Cache.Exists(script.Name)
	cachedVersion := l.Cache.Version(script.Name)

	// Check if we need to download
	needsDownload := !cached || cachedVersion != script.Version

	if needsDownload {
		return l.download(script)
	}

	// Verify integrity
	if !l.Cache.Verify(script.Name, script.SHA256) {
		return l.download(script)
	}

	return nil
}

// download fetches script from remote and caches it
func (l *Loader) download(script *registry.Script) error {
	url := l.Registry.BaseURL() + "/" + script.File

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return fmt.Errorf("failed to download %s: %w", script.Name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("HTTP %d downloading %s", resp.StatusCode, script.Name)
	}

	content, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("failed to read %s: %w", script.Name, err)
	}

	// Verify hash
	hash, err := cache.ComputeHash(bytes.NewReader(content))
	if err != nil {
		return fmt.Errorf("failed to compute hash: %w", err)
	}

	if hash != script.SHA256 {
		return fmt.Errorf("hash mismatch for %s: expected %s, got %s",
			script.Name, script.SHA256, hash)
	}

	// Save to cache
	return l.Cache.Put(script.Name, script.Version, content)
}

// run executes a cached script
func (l *Loader) run(scriptPath string, args []string) error {
	cmd := exec.Command("bash", append([]string{scriptPath}, args...)...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}

// findMissingDeps returns list of missing dependencies
func findMissingDeps(requires []string) []string {
	var missing []string
	for _, req := range requires {
		if _, err := exec.LookPath(req); err != nil {
			missing = append(missing, req)
		}
	}
	return missing
}

// checkRequires verifies all dependencies are available
func (l *Loader) checkRequires(requires []string) error {
	if missing := findMissingDeps(requires); len(missing) > 0 {
		return fmt.Errorf("missing dependencies: %v", missing)
	}
	return nil
}

// Update refreshes cached scripts
func (l *Loader) Update(name string) error {
	// Force refresh manifest to get latest versions
	if _, err := l.Registry.Fetch(true); err != nil {
		return fmt.Errorf("failed to refresh manifest: %w", err)
	}

	if name != "" {
		script, err := l.Registry.GetScript(name)
		if err != nil {
			return err
		}
		return l.download(script)
	}

	// Update all cached scripts
	cached, err := l.Cache.List()
	if err != nil {
		return err
	}

	for _, n := range cached {
		script, err := l.Registry.GetScript(n)
		if err != nil {
			continue // Skip unknown scripts
		}
		if err := l.download(script); err != nil {
			fmt.Fprintf(os.Stderr, "Warning: failed to update %s: %v\n", n, err)
		}
	}
	return nil
}

// CheckRequires returns missing dependencies for a script
func (l *Loader) CheckRequires(name string) ([]string, error) {
	script, err := l.Registry.GetScript(name)
	if err != nil {
		return nil, err
	}
	return findMissingDeps(script.Requires), nil
}
