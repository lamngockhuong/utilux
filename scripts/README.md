# Utilux Scripts

This directory contains all the scripts for the Utilux tool.

## Directory Structure

```
scripts/
├── core.sh           # Core functionality
├── distro-detect.sh  # Distribution detection
├── ubuntu/           # Ubuntu-specific scripts
│   ├── ubuntu.sh     # Main Ubuntu package manager
│   └── ...           # Other Ubuntu-specific scripts
├── alpine/           # Alpine-specific scripts
│   ├── alpine.sh     # Main Alpine package manager
│   └── ...           # Other Alpine-specific scripts
├── fedora/           # Fedora-specific scripts
│   ├── fedora.sh     # Main Fedora package manager
│   └── ...           # Other Fedora-specific scripts
└── ...               # Other scripts
```

## Adding New Distribution Support

To add support for a new distribution:

1. Create a new directory with the distribution name (lowercase)
2. Add the main package manager script (e.g., `debian.sh` for Debian)
3. Add any additional scripts specific to that distribution

## Script Naming Convention

- Main package manager scripts should be named after the distribution (e.g., `ubuntu.sh`, `alpine.sh`)
- Additional scripts should have descriptive names that indicate their purpose
- All scripts should have the `.sh` extension
