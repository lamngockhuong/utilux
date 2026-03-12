# Feature Ideas

> Danh sách các tính năng tiềm năng cho Utix. Đánh dấu `[x]` khi hoàn thành.

## Scripts Mới

### Security

- [ ] `firewall-setup` - Cấu hình ufw/iptables cơ bản
- [ ] `ssh-harden` - Hardening SSH (disable root, key-only auth)
- [ ] `fail2ban-setup` - Setup fail2ban chống brute force

### Database

- [ ] `pg-backup` - Backup PostgreSQL database
- [ ] `mysql-backup` - Backup MySQL/MariaDB
- [ ] `redis-flush` - Clear Redis cache safely

### Dev

- [ ] `node-cleanup` - Xóa node_modules cũ, clear npm/pnpm cache
- [ ] `vscode-setup` - Install VS Code + extensions
- [ ] `git-config` - Interactive git config setup

### Cloud

- [ ] `aws-cli-setup` - Setup AWS CLI + credentials
- [ ] `gh-cli-setup` - Setup GitHub CLI
- [ ] `gcloud-setup` - Setup Google Cloud CLI

---

## CLI Features

### Essential

- [ ] Self-update - `utix self-update` update CLI
- [ ] Doctor - `utix doctor` chẩn đoán vấn đề (deps, cache, config)
- [ ] Uninstall - `utix uninstall` clean removal
- [ ] Verify - `utix verify <script>` check SHA256 integrity
- [ ] Changelog - `utix changelog <script>` xem thay đổi versions
- [ ] Aliases - `utix alias gc=git-clean` shortcut

### Easy

- [ ] Script favorites - `utix fav add/list/rm`
- [ ] Script history - `utix history` (recently used)
- [ ] Man pages - Generate từ docs
- [ ] Script templates - `utix new <name>` boilerplate tạo script mới
- [ ] Update notifications - Alert khi có script version mới
- [ ] Script preview - `utix preview <script>` xem source trước khi chạy
- [ ] JSON output - `utix list --json` cho piping/scripting
- [ ] Quiet mode - `utix run -q` suppress output
- [ ] Execution log - History với timestamps, exit codes

### Medium

- [ ] Shell completions - Bash/Zsh/Fish autocomplete
- [ ] Dry-run mode - `utix run --dry-run` preview script
- [ ] Script chaining - `utix run script1 script2`
- [ ] Export/import settings
- [ ] Script linting - Validate với shellcheck trước khi chạy
- [ ] Backup before run - Auto backup files trước khi script modify
- [ ] Notifications - Desktop notify khi script chạy xong
- [ ] Config profiles - `utix --profile work` cho different environments
- [ ] Timeout - `utix run --timeout 60s` giới hạn thời gian
- [ ] Pre/post hooks - Chạy commands trước/sau script
- [ ] Custom scripts - User's own scripts trong local registry

### Hard

- [ ] Script dependencies auto-install
- [ ] Sandboxed execution (firejail/bubblewrap)
- [ ] Remote execution - `utix run --host user@server` via SSH
- [ ] Script bundles - Gom nhóm scripts liên quan (vd: `security-bundle`)
- [ ] Plugin system - Extend utix với custom commands
- [ ] WSL support - Windows Subsystem for Linux
- [ ] macOS support - Mở rộng ngoài Linux

---

## Registry Features

- [ ] Private registries - Custom URL với auth
- [ ] Script versions - `utix run git-clean@v1.0.0`
- [ ] Community scripts - User contributions
- [ ] Script ratings/reviews

---

## Packaging & Distribution

- [ ] Homebrew formula (macOS)
- [ ] AUR package (Arch Linux)
- [ ] deb package (Debian/Ubuntu)
- [ ] rpm package (Fedora/RHEL)
- [ ] Snap package
- [ ] Nix package

---

## Website

- [ ] Script playground - Test scripts online
- [ ] Search with filters
- [ ] Dark/light theme toggle
- [ ] i18n support

---

## Testing

- [ ] Unit tests với bats-core cho registry scripts
- [ ] Integration tests cho CLI commands
- [ ] E2E tests cho website (Playwright/Cypress)
- [ ] CI pipeline (GitHub Actions) chạy tests
- [ ] Code coverage report

---

## Notes

_Ghi chú thêm ý tưởng ở đây..._
