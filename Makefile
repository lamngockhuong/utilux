# Automatically get the current project directory
PROJECT_DIR := $(shell pwd)

# Detect container runtime (podman or docker)
CONTAINER_RUNTIME := $(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null)

# Default distro to use if none is provided
DEFAULT_DISTRO := ubuntu:22.04

# Detect shell based on distro (Alpine uses sh, others use bash)
CONTAINER_SHELL := $(if $(findstring alpine,$(DISTRO)),sh,bash)

# Launch a container with the selected distro and mount the current project directory
# Usage:
#   make dev                -> launches with default distro (ubuntu:22.04)
#   make dev DISTRO=alpine  -> launches with Alpine (uses sh, run 'apk add bash && bash' for history)
dev:
ifndef CONTAINER_RUNTIME
	$(error No container runtime found. Install docker or podman)
endif
	$(CONTAINER_RUNTIME) run -it --rm \
	-v $(PROJECT_DIR):/app \
	--workdir /app \
	$(if $(DISTRO),$(DISTRO),$(DEFAULT_DISTRO)) \
	$(CONTAINER_SHELL)

# Clean temporary or generated files
clean:
	rm -f *.log *.tmp

# Lint all bash scripts
lint-bash:
	@command -v shellcheck >/dev/null || { echo "Install shellcheck: sudo apt install shellcheck"; exit 1; }
	shellcheck -x -S warning utix lib/*.sh install.sh package.sh generate-manifest.sh || true

# Lint Go CLI
lint-go:
	$(MAKE) -C cli lint

# Lint all
lint: lint-bash lint-go

# Format bash scripts
fmt-bash:
	@command -v shfmt >/dev/null || { echo "Install shfmt: sudo apt install shfmt"; exit 1; }
	shfmt -w -i 2 -ci -bn utix lib/ install.sh package.sh generate-manifest.sh

# Format Go CLI
fmt-go:
	$(MAKE) -C cli fmt

# Format all
fmt: fmt-bash fmt-go
