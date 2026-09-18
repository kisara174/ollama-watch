# Ollama Watch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build, install, verify, and publicly release an `ollama-watch [model]` command that runs Ollama beside Apple Silicon and model-status monitoring in a temporary tmux session.

**Architecture:** A dependency-light shell launcher owns a uniquely named tmux session with three panes. Separate idempotent installer and uninstaller scripts manage only the user-local executable and a marked zsh PATH block; shell tests use stub executables to verify behavior without loading a real model.

**Tech Stack:** POSIX shell with zsh/bash compatibility, tmux 3.7+, Ollama, macmon, Git, GitHub CLI.

**Spec:** `docs/design/ollama-watch-design.md`

## Global Constraints

- Target macOS on Apple Silicon.
- Default model is exactly `qwen3.5:9b`.
- Install to `~/.local/bin/ollama-watch` without administrator privileges.
- Never download a model or install a dependency automatically.
- Never alter Ollama, tmux, or macmon configuration.
- Cleanup may target only the uniquely named session created by the current invocation.
- Publish `kisara174/ollama-watch` publicly under MIT as `v0.1.0` only after local verification.

---

## File Map

- `bin/ollama-watch`: argument parsing, validation, tmux layout, session lifecycle.
- `install.sh`: dependency checks and idempotent user-local installation.
- `uninstall.sh`: scoped executable and PATH-block removal.
- `tests/test.sh`: self-contained test harness and stub commands.
- `README.md`: installation, usage, layout, limitations, troubleshooting, English and Chinese guidance.
- `LICENSE`: MIT license.
- `.gitignore`: macOS/editor artifacts.

### Task 1: Tested tmux launcher

**Files:**
- Create: `bin/ollama-watch`
- Create: `tests/test.sh`

**Interfaces:**
- Consumes: executables named `ollama`, `tmux`, and `macmon` from `PATH`; optional model argument.
- Produces: CLI `ollama-watch [model]`, `ollama-watch --help`, exit codes `0` for help/success and `1` for validation failure.

- [ ] **Step 1: Write the failing launcher tests**

Create a shell harness that uses `mktemp -d`, writes stub `ollama`, `tmux`, and `macmon` executables, prepends the stub directory to `PATH`, records calls in `$CALL_LOG`, and asserts:

```sh
assert_contains "Usage: ollama-watch [model]" "$($LAUNCHER --help)"
assert_status 1 env STUB_MODELS='qwen3.5:9b' "$LAUNCHER" missing:model
assert_contains "Model is not installed: missing:model" "$LAST_OUTPUT"
STUB_MODELS='qwen3.5:9b' "$LAUNCHER" qwen3.5:9b
assert_file_contains "$CALL_LOG" "new-session -d -s ollama-watch-"
assert_file_contains "$CALL_LOG" "split-window -h"
assert_file_contains "$CALL_LOG" "macmon"
assert_file_contains "$CALL_LOG" "ollama ps"
```

The tmux stub must accept commands without opening a client and return pane/session identifiers expected by the launcher.

- [ ] **Step 2: Run tests and verify failure**

Run: `sh tests/test.sh`

Expected: nonzero exit with `bin/ollama-watch: not found` or the first missing behavior assertion.

- [ ] **Step 3: Implement the minimal launcher**

Implement these concrete behaviors:

```sh
#!/bin/sh
set -eu
DEFAULT_MODEL='qwen3.5:9b'
MODEL=${1:-$DEFAULT_MODEL}
SESSION="ollama-watch-$$"
```

- Recognize only `-h` and `--help`; reject more than one model argument.
- Validate dependencies with `command -v` and print `Missing dependency: NAME` plus the relevant Homebrew command.
- Read exact model names from `ollama list` by skipping its header and comparing column one with `awk`.
- Create a detached session, split a 35% right column, split the right pane vertically, and run macmon plus a two-second `ollama ps` loop.
- Start Ollama in the left pane through `sh -c` with safely single-quoted model/session values; after Ollama exits, kill only `$SESSION`.
- Use `tmux switch-client -t "$SESSION"` when `$TMUX` is nonempty, otherwise `tmux attach-session -t "$SESSION"`.
- Install a trap before attachment that kills `$SESSION` only if session creation fails partway.

- [ ] **Step 4: Run launcher tests and syntax checks**

Run:

```bash
sh -n bin/ollama-watch
sh -n tests/test.sh
sh tests/test.sh
```

Expected: all assertions print `ok` and exit status is zero.

- [ ] **Step 5: Commit the launcher**

```bash
git add bin/ollama-watch tests/test.sh
git commit -m "feat: add monitored Ollama launcher"
```

### Task 2: Idempotent installer and uninstaller

**Files:**
- Create: `install.sh`
- Create: `uninstall.sh`
- Modify: `tests/test.sh`

**Interfaces:**
- Consumes: source checkout, `HOME`, and optional `OLLAMA_WATCH_INSTALL_DIR` for isolated tests.
- Produces: executable at `${OLLAMA_WATCH_INSTALL_DIR:-$HOME/.local/bin}/ollama-watch`; exact marked block in `$HOME/.zshrc` when the default directory is not already on PATH.

- [ ] **Step 1: Add failing install lifecycle tests**

Use a temporary `HOME` and set `OLLAMA_WATCH_INSTALL_DIR="$HOME/.local/bin"`. Assert that running `install.sh` twice produces one executable and at most one block delimited by:

```text
# >>> ollama-watch >>>
export PATH="$HOME/.local/bin:$PATH"
# <<< ollama-watch <<<
```

Then run `uninstall.sh` twice and assert the executable and only that marked block are absent while pre-existing `.zshrc` lines remain.

- [ ] **Step 2: Run tests and verify failure**

Run: `sh tests/test.sh`

Expected: failure because `install.sh` and `uninstall.sh` do not exist.

- [ ] **Step 3: Implement installation scripts**

Both scripts use `#!/bin/sh` and `set -eu`. `install.sh` resolves its own directory, checks dependencies, creates the destination, copies `bin/ollama-watch`, applies mode `0755`, and appends the marked PATH block only when needed. `uninstall.sh` removes the destination file and uses `awk` to rewrite `.zshrc` while excluding only lines between the two exact markers; it replaces the file atomically through a sibling temporary file.

- [ ] **Step 4: Verify lifecycle tests**

Run:

```bash
sh -n install.sh uninstall.sh
sh tests/test.sh
```

Expected: zero failures, including double-install and double-uninstall cases.

- [ ] **Step 5: Commit installer work**

```bash
git add install.sh uninstall.sh tests/test.sh
git commit -m "feat: add scoped install and uninstall"
```

### Task 3: Open-source documentation and licensing

**Files:**
- Create: `README.md`
- Create: `LICENSE`
- Create: `.gitignore`

**Interfaces:**
- Produces: complete public documentation and MIT licensing for release consumers.

- [ ] **Step 1: Write documentation checklist test**

Extend `tests/test.sh` to assert that README contains `brew install ollama tmux macmon`, `ollama-watch qwen3.5:9b`, `Ctrl-b`, `Unified memory`, `卸载`, and `MIT`; assert that LICENSE contains `MIT License` and `Copyright (c) 2026 kisara174`.

- [ ] **Step 2: Run tests and verify failure**

Run: `sh tests/test.sh`

Expected: failure because README and LICENSE are absent.

- [ ] **Step 3: Write public files**

README sections: overview, a note that a real screenshot will be added in a future release, prerequisites, install, usage, layout, tmux controls, how cleanup works, unified-memory limitations, troubleshooting, uninstall, concise Chinese guide, license. `.gitignore` contains `.DS_Store`, editor swap files, and temporary test directories. LICENSE uses the standard MIT text.

- [ ] **Step 4: Verify docs and repository hygiene**

Run:

```bash
sh tests/test.sh
rg -n '/Users/|gho_|github_pat_|BEGIN .*PRIVATE KEY|api[_-]?key' --glob '!docs/design/**' --glob '!docs/superpowers/**' .
git diff --check
```

Expected: tests pass; secret/path scan returns no matches; diff check is clean.

- [ ] **Step 5: Commit documentation**

```bash
git add README.md LICENSE .gitignore tests/test.sh
git commit -m "docs: prepare public v0.1.0 release"
```

### Task 4: Real installation, integration verification, and public release

**Files:**
- Modify: `~/.zshrc` through `install.sh`
- Create: `~/.local/bin/ollama-watch` through `install.sh`
- Modify: Git metadata and GitHub remote/release state.

**Interfaces:**
- Consumes: installed Ollama/tmux/macmon, authenticated GitHub CLI account `kisara174`.
- Produces: working local command, public GitHub repository, annotated `v0.1.0` tag, and GitHub release.

- [ ] **Step 1: Run the full clean test suite**

Run: `sh tests/test.sh`

Expected: all tests pass.

- [ ] **Step 2: Install and verify command discovery**

Run:

```bash
./install.sh
/bin/zsh -lic 'command -v ollama-watch && ollama-watch --help'
```

Expected: path resolves to `$HOME/.local/bin/ollama-watch` and help exits zero.

- [ ] **Step 3: Verify a real three-pane session without leaving it running**

Start `ollama-watch qwen3.5:9b`, inspect with `tmux list-panes -a -F '#{session_name} #{pane_current_command}'`, confirm exactly one temporary session has three panes containing Ollama/shell, macmon, and the status loop, then exit the Ollama pane and confirm `tmux has-session -t SESSION` fails.

- [ ] **Step 4: Final repository and privacy checks**

Run:

```bash
sh tests/test.sh
git diff --check
git status --short
rg -n '/Users/|gho_|github_pat_|BEGIN .*PRIVATE KEY' --glob '!docs/design/**' --glob '!docs/superpowers/**' .
```

Expected: tests pass, no diff errors, a clean working tree, and no public-file scan matches.

- [ ] **Step 5: Create and push the public repository**

Run:

```bash
gh repo create kisara174/ollama-watch --public --source=. --remote=origin --push --description "Run Ollama beside live Apple Silicon resource monitoring in your terminal."
```

Expected: repository URL `https://github.com/kisara174/ollama-watch` and successful push of `main`.

- [ ] **Step 6: Tag and publish v0.1.0**

Run:

```bash
git tag -a v0.1.0 -m "ollama-watch v0.1.0"
git push origin v0.1.0
gh release create v0.1.0 --title "ollama-watch v0.1.0" --notes "Initial public release: monitored Ollama sessions with tmux, macmon, and live model status."
```

Expected: public release URL under `https://github.com/kisara174/ollama-watch/releases/tag/v0.1.0`.

- [ ] **Step 7: Verify remote release state**

Run:

```bash
gh repo view kisara174/ollama-watch --json nameWithOwner,visibility,url,defaultBranchRef
gh release view v0.1.0 --repo kisara174/ollama-watch --json tagName,url,isDraft,isPrerelease
git status --short
```

Expected: public repository, default branch `main`, non-draft/non-prerelease `v0.1.0`, and clean local tree.
