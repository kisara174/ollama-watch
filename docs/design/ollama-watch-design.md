# Ollama Watch Design

## Objective

Provide a single `ollama-watch [model]` command for running a local Ollama model beside live Apple Silicon resource monitoring in the terminal. Publish it as the public MIT-licensed project `kisara174/ollama-watch`.

## Interface

The command creates a temporary tmux session with an Ollama interaction pane on the left (about 65% width), macmon on the upper right, and `ollama ps` refreshed every two seconds on the lower right.

## Behavior

- `ollama-watch` defaults to `qwen3.5:9b`; one optional model argument overrides it.
- `--help` prints concise usage.
- The launcher validates `ollama`, `tmux`, `macmon`, and the requested locally installed model.
- Missing dependencies or models produce actionable errors and never trigger an automatic model download.
- Concurrent runs use unique tmux session names.
- Exiting Ollama cleans up only that run's monitor panes and temporary session.
- Calls from inside tmux switch the client instead of nesting an attachment.
- Arguments passed through tmux are shell-quoted.

## Installation

- `install.sh` installs the launcher to `~/.local/bin/ollama-watch` and adds one marked PATH stanza to `~/.zshrc` only when required.
- `uninstall.sh` removes only the launcher and the exact marked PATH stanza.
- Both scripts are idempotent, preserve unrelated shell configuration, require no administrator privileges, and do not change Ollama, tmux, or macmon configuration.
- Missing packages are reported with suggested Homebrew commands, but are not installed automatically.

## Repository

- Public GitHub repository: `kisara174/ollama-watch`
- Default branch: `main`
- Initial release: `v0.1.0`
- License: MIT
- Files: `bin/ollama-watch`, `install.sh`, `uninstall.sh`, `tests/test.sh`, `README.md`, `LICENSE`, and `.gitignore`.
- README content is English-first with a concise Chinese section and documents prerequisites, installation, usage, tmux controls, cleanup, unified-memory limitations, and troubleshooting.
- The README may reserve a screenshot location but will not include a fabricated screenshot.
- v0.1.0 does not include a Homebrew formula, signing, notarization, telemetry, a GUI, persistent metrics storage, or GitHub Actions.

## Verification

- Shell syntax and help behavior.
- Missing-dependency and missing-model failures.
- Three-pane layout and expected pane processes using dependency stubs.
- Cleanup after Ollama exits.
- Idempotent install/uninstall in an isolated temporary home.
- Discovery from a fresh zsh login shell.
- Scan for credentials and machine-specific paths before publication.
- Clean Git state, public repository availability, and `v0.1.0` tag/release availability.

The real interactive model prompt will not be left running after verification.
