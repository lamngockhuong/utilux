# Automatically get the current project directory
PROJECT_DIR := $(shell pwd)

# Default distro to use if none is provided
DEFAULT_DISTRO := ubuntu:22.04

# Launch a container with the selected distro and mount the current project directory
# Usage:
#   make dev                -> launches with default distro (ubuntu:22.04)
#   make dev DISTRO=alpine -> launches with Alpine
dev:
	podman run -it --rm \
		-v $(PROJECT_DIR):/app:Z \
		--workdir /app \
		$(if $(DISTRO),$(DISTRO),$(DEFAULT_DISTRO)) \
		sh

# Clean temporary or generated files (customize as needed)
clean:
	rm -f *.log *.tmp
