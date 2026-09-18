#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
INSTALL_DIR=${OLLAMA_WATCH_INSTALL_DIR:-"$HOME/.local/bin"}
DESTINATION="$INSTALL_DIR/ollama-watch"
ZSHRC="$HOME/.zshrc"
START_MARKER='# >>> ollama-watch >>>'
END_MARKER='# <<< ollama-watch <<<'

require_command() {
    command_name=$1
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'Missing dependency: %s\n' "$command_name" >&2
        printf 'Install it with: brew install %s\n' "$command_name" >&2
        exit 1
    fi
}

require_command ollama
require_command tmux
require_command macmon

mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/bin/ollama-watch" "$DESTINATION"
chmod 0755 "$DESTINATION"

case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *)
        if [ "$INSTALL_DIR" = "$HOME/.local/bin" ]; then
            if [ ! -f "$ZSHRC" ] || ! grep -Fx -- "$START_MARKER" "$ZSHRC" >/dev/null 2>&1; then
                {
                    printf '\n%s\n' "$START_MARKER"
                    printf '%s\n' 'export PATH="$HOME/.local/bin:$PATH"'
                    printf '%s\n' "$END_MARKER"
                } >> "$ZSHRC"
            fi
        else
            printf 'Installed to %s\n' "$DESTINATION"
            printf 'Add %s to PATH if needed.\n' "$INSTALL_DIR"
            exit 0
        fi
        ;;
esac

printf 'Installed ollama-watch to %s\n' "$DESTINATION"
