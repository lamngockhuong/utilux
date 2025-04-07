# Utilux

A utility management tool for Linux distributions.

## Installation

### From GitHub Release

```bash
# Download the installation script
curl -s -L https://raw.githubusercontent.com/lamngockhuong/utilux/main/install.sh -o install.sh

# Make it executable
chmod +x install.sh

# Run the installation script
sudo ./install.sh
```

### From Source

```bash
# Clone the repository
git clone https://github.com/lamngockhuong/utilux.git
cd utilux

# Run the installation script
sudo ./install.sh
```

## Usage

After installation, you can use the `utilux` command to manage your utilities:

```bash
# Install a package
utilux install <package>

# Install from GitHub Release
utilux install github:owner/repo

# Install from URL
utilux install https://example.com/pkg.tar.gz

# Remove a package
utilux remove <package>
```

## Uninstallation

To uninstall utilux, you can use the installation script with the `--uninstall` option:

```bash
# Uninstall utilux
sudo ./install.sh --uninstall

# Uninstall a custom-named installation
sudo ./install.sh --uninstall myutilux
```

## Custom Installation Name

If you already have an application named "utilux" installed, the installation script will prompt you to:

1. Remove the existing application and install as "utilux"
2. Install with a different name (e.g., "myutilux")
3. Cancel the installation

## Requirements

- Linux distribution (Ubuntu, Fedora, Alpine, etc.)
- Root privileges (sudo)
- Internet connection for downloading packages

## License

MIT

## Develop

```bash
make dev                # Launch with Ubuntu by default
make dev DISTRO=alpine  # Launch with Alpine Linux
make dev DISTRO=fedora  # Launch with Fedora
```

Inside the container:

```bash
apk add --no-cache bash curl whiptail   # Alpine
apt update && apt install -y curl whiptail bash  # Ubuntu/Debian

chmod +x tool.sh
./tool.sh
```
