# CLI Screens and Actions

This document describes all screens and actions for both Bash and Go CLIs to
ensure feature parity.

## Main Menu

**Title:** "Utix - Choose an action"

| # | Action           | Bash              | Go                          | Description                           |
| - | ---------------- | ----------------- | --------------------------- | ------------------------------------- |
| 1 | Run a script     | `_action_run`     | `runScriptPicker()`         | Interactive script picker → execute   |
| 2 | List scripts     | `_action_list`    | `listScripts()`             | Print all scripts grouped by category |
| 3 | Search scripts   | `_action_search`  | `searchScripts()`           | Prompt for term → show matches        |
| 4 | Script info      | `_action_info`    | `showScriptInfo()`          | Select script → show details          |
| 5 | Update scripts   | `_action_update`  | `updateScripts()`           | Update all cached scripts             |
| 6 | Cache management | `_submenu_cache`  | `manageCacheInteractive()`  | Cache submenu                         |
| 7 | Configuration    | `_submenu_config` | `manageConfigInteractive()` | Config submenu                        |
| 8 | Exit             | return            | return nil                  | Exit program                          |

## Cache Management Submenu

**Title:** "Cache Management"

| # | Action              | Bash   | Go             | Description                  |
| - | ------------------- | ------ | -------------- | ---------------------------- |
| 1 | List cached scripts | list   | `case "list"`  | Show cached script names     |
| 2 | Clear all cache     | clear  | `case "clear"` | Remove all cached scripts    |
| 3 | Show cache size     | size   | `case "size"`  | Display cache directory size |
| 4 | Back                | return | `case "back"`  | Return to main menu          |

## Configuration Submenu

**Title:** "Configuration"

| # | Action              | Bash                | Go                  | Description                |
| - | ------------------- | ------------------- | ------------------- | -------------------------- |
| 1 | Show current config | `"Show current"*`   | `case "show"`       | Display config values      |
| 2 | Set registry URL    | `"Set registry"*`   | `case "registry"`   | Change custom registry     |
| 3 | Toggle offline mode | `"Toggle offline"*` | `case "offline"`    | Enable/disable offline     |
| 4 | Toggle auto-update  | `"Toggle auto"*`    | `case "autoupdate"` | Enable/disable auto-update |
| 5 | Reset to defaults   | `"Reset to"*`       | `case "reset"`      | Clear custom config        |
| 6 | Back                | (no match)          | `case "back"`       | Return to main menu        |

## Script Picker Screen

**Title:** "Select a script to run" or "Select a script for info"

- Shows all scripts with name + description
- Indicates cached status: `[cached]` or `(cached)`
- Filterable/searchable
- Arrow keys to navigate, Enter to select, q/Ctrl+C to cancel

## CLI Commands (Non-interactive)

| Command          | Bash                    | Go                         | Description                   |
| ---------------- | ----------------------- | -------------------------- | ----------------------------- |
| `run <script>`   | `./utix run <name>`     | `./utix-go run <name>`     | Run script by name            |
| `list`           | `./utix list`           | `./utix-go list`           | List all scripts              |
| `list -i`        | -                       | `./utix-go list -i`        | Interactive list mode         |
| `search <term>`  | `./utix search <term>`  | `./utix-go search <term>`  | Search scripts                |
| `info <script>`  | `./utix info <name>`    | `./utix-go info <name>`    | Show script details           |
| `info -d`        | `./utix info <name> -d` | `./utix-go info <name> -d` | Show script details with docs |
| `docs <script>`  | `./utix docs <name>`    | `./utix-go docs <name>`    | Show full documentation       |
| `update`         | `./utix update`         | `./utix-go update`         | Update cached scripts         |
| `cache list`     | `./utix cache list`     | `./utix-go cache list`     | List cached                   |
| `cache clear`    | `./utix cache clear`    | `./utix-go cache clear`    | Clear cache                   |
| `cache size`     | `./utix cache size`     | `./utix-go cache size`     | Show cache size               |
| `config`         | `./utix config`         | `./utix-go config`         | Show all config               |
| `config <key>`   | `./utix config <key>`   | `./utix-go config <key>`   | Get config value              |
| `config <k> <v>` | `./utix config <k> <v>` | `./utix-go config <k> <v>` | Set config value              |

## TUI Implementation

| Feature        | Bash (gum)   | Go (bubbletea)         |
| -------------- | ------------ | ---------------------- |
| Menu selection | `gum choose` | `tui.RunMenu()`        |
| Script list    | `gum choose` | `tui.RunList()`        |
| Input prompt   | `gum input`  | `fmt.Scanln()`         |
| Spinner        | `gum spin`   | `tui.RunWithSpinner()` |
| Styling        | gum colors   | lipgloss styles        |
| Fallback       | whiptail     | -                      |

## Parity Checklist

When adding new features, update both CLIs:

- [ ] Main menu action
- [ ] Submenu if needed
- [ ] CLI command
- [ ] This documentation
