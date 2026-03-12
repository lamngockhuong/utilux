VERSION ?= 1.0.0
BINARY = utix-go
LDFLAGS = -ldflags "-s -w -X github.com/lamngockhuong/utix/cli/cmd.Version=$(VERSION)"

.PHONY: build build-all clean test

# Build for current platform
build:
	go build $(LDFLAGS) -o $(BINARY) .

# Build optimized (smaller binary)
build-optimized:
	go build $(LDFLAGS) -trimpath -o $(BINARY) .

# Build for all platforms
build-all: clean
	mkdir -p dist
	# Linux
	GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -trimpath -o dist/$(BINARY)-linux-amd64 .
	GOOS=linux GOARCH=arm64 go build $(LDFLAGS) -trimpath -o dist/$(BINARY)-linux-arm64 .
	# macOS
	GOOS=darwin GOARCH=amd64 go build $(LDFLAGS) -trimpath -o dist/$(BINARY)-darwin-amd64 .
	GOOS=darwin GOARCH=arm64 go build $(LDFLAGS) -trimpath -o dist/$(BINARY)-darwin-arm64 .
	# Windows
	GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -trimpath -o dist/$(BINARY)-windows-amd64.exe .

# Run tests
test:
	go test -v ./...

# Clean build artifacts
clean:
	rm -f $(BINARY)
	rm -rf dist/

# Install locally
install: build
	cp $(BINARY) /usr/local/bin/utix-go

# Check binary size
size: build-optimized
	@ls -lh $(BINARY)
	@file $(BINARY)
