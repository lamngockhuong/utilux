package registry

// Manifest represents the script registry manifest
type Manifest struct {
	Version  string   `json:"version"`
	Updated  string   `json:"updated"`
	BaseURL  string   `json:"base_url"`
	Scripts  []Script `json:"scripts"`
}

// Script represents a single script entry
type Script struct {
	Name        string   `json:"name"`
	Category    string   `json:"category"`
	Description string   `json:"description"`
	Version     string   `json:"version"`
	File        string   `json:"file"`
	SHA256      string   `json:"sha256"`
	Docs        string   `json:"docs,omitempty"`
	DocsSHA256  string   `json:"docs_sha256,omitempty"`
	Tags        []string `json:"tags"`
	Requires    []string `json:"requires"`
	Author      string   `json:"author"`
}
