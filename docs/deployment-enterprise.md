# Enterprise Deployment

Advanced deployment scenarios for enterprise environments.

## Automated Deployment with Ansible

```yaml
---
- name: Deploy Utix
  hosts: all
  become: yes
  tasks:
    - name: Install dependencies
      package:
        name: [curl, bash, jq]
        state: present

    - name: Download Utix installer
      get_url:
        url: https://raw.githubusercontent.com/lamngockhuong/utix/main/install.sh
        dest: /tmp/utix-install.sh
        mode: "0755"

    - name: Install Utix
      command: /tmp/utix-install.sh
      args:
        creates: /usr/local/bin/utix

    - name: Verify installation
      command: utix version
      register: version_output

    - name: Display version
      debug:
        var: version_output.stdout
```

## Configuration Management

**System-wide Configuration** (`/etc/profile.d/utix.sh`):

```bash
export UTIX_LOG_LEVEL="warn"
export UTIX_CACHE_DIR="/var/cache/utix"
export UTIX_REGISTRY_URL="https://internal-registry.company.com/manifest.json"
```

**Shared Cache**:

```bash
sudo mkdir -p /var/cache/utix
sudo chmod 1777 /var/cache/utix  # Sticky bit for multi-user
echo 'export UTIX_CACHE_DIR="/var/cache/utix"' | sudo tee /etc/profile.d/utix.sh
```

## Custom Registry Deployment

**Setup Internal Registry**:

```bash
git clone https://github.com/lamngockhuong/utix.git
cd utix

# Customize registry
# Edit registry/manifest.json
# Add custom scripts to registry/

# Host on internal server
cd registry && python3 -m http.server 8080

# Or via Nginx
sudo cp -r registry /var/www/html/utix-registry
```

**Configure Clients**:

```bash
export UTIX_REGISTRY_URL="https://internal.company.com/utix-registry/manifest.json"
```

## Air-Gapped Deployment

**Step 1: Prepare Package (Online Machine)**:

```bash
VERSION="1.0.0"
wget https://github.com/lamngockhuong/utix/releases/download/v${VERSION}/utix-${VERSION}.tar.gz

git clone --depth 1 https://github.com/lamngockhuong/utix.git
cd utix

# Pre-cache all scripts
for script in registry/*/*.sh; do
  script_name=$(basename "$script" .sh)
  ./utix run "$script_name" --help || true
done

tar -czf utix-airgapped-${VERSION}.tar.gz utix-${VERSION}.tar.gz ~/.utix/
```

**Step 2: Deploy (Offline Machine)**:

```bash
tar -xzf utix-airgapped-1.0.0.tar.gz
tar -xzf utix-1.0.0.tar.gz && cd utix-1.0.0
sudo ./install.sh

cp -r .utix ~/
export UTIX_OFFLINE=1
utix list
```

## Docker Deployment

### Dockerfile

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y curl bash jq && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/lamngockhuong/utix/main/install.sh | bash

WORKDIR /workspace
CMD ["utix", "list"]
```

### Docker Compose

```yaml
version: "3.8"

services:
  utix:
    image: utix:latest
    environment:
      - UTIX_LOG_LEVEL=info
      - UTIX_CACHE_DIR=/cache
    volumes:
      - utix-cache:/cache
      - ./scripts:/workspace

volumes:
  utix-cache:
```

**Build and Run**:

```bash
docker build -t utix:latest .
docker run -it utix:latest bash
docker run utix:latest utix run system-info
```

## Troubleshooting

### Common Issues

**Command Not Found**:

```bash
# Check if installed
ls -la /usr/local/bin/utix

# Add to PATH
export PATH="/usr/local/bin:$PATH"
```

**Permission Denied**:

```bash
sudo chmod +x /usr/local/bin/utix
```

**Bash Version Too Old**:

```bash
bash --version
sudo apt update && sudo apt install --only-upgrade bash

# Or use Go CLI
utix-go list
```

**Cannot Download Scripts**:

```bash
curl -I https://raw.githubusercontent.com
echo $https_proxy

# Try offline mode
export UTIX_OFFLINE=1
utix list
```

**SHA256 Mismatch**:

```bash
utix cache clear script-name
utix run script-name
```

**Script Fails to Execute**:

```bash
UTIX_LOG_LEVEL=debug utix run script-name
utix info script-name  # Check @requires field
```

### Debug Mode

```bash
UTIX_LOG_LEVEL=debug utix run script-name 2>&1 | tee debug.log
bash -x /usr/local/bin/utix run script-name
utix-go --verbose run script-name
```

### Getting Help

```bash
utix help
utix run --help

# Include in bug report
utix version
bash --version
uname -a
```

## Security Considerations

### Verification Best Practices

```bash
# Download and inspect before installation
curl -fsSL https://raw.githubusercontent.com/lamngockhuong/utix/main/install.sh > install.sh
less install.sh
sudo bash install.sh
```

### Secure Configuration

```bash
chmod 700 ~/.utix
chmod 700 ~/.utix/cache

# Run scripts as non-root
utix run system-info

# Only use sudo when necessary
sudo utix run disk-cleanup
```

## Performance Tuning

### Cache Optimization

```bash
# Pre-cache frequently used scripts
for script in docker-prune git-clean system-info; do
  utix run "$script" --help &
done
wait

# Multi-user shared cache
export UTIX_CACHE_DIR="/shared/utix-cache"
```

### Network Optimization

```bash
export UTIX_REGISTRY_URL="https://cdn.company.com/utix/manifest.json"
export UTIX_HTTP_TIMEOUT=60
```

## Related Documentation

- [Deployment Guide](./deployment-guide.md)
- [System Architecture](./system-architecture.md)
- [Code Standards](./code-standards.md)
