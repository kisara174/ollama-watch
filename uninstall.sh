#!/bin/sh
set -eu

INSTALL_DIR=${OLLAMA_WATCH_INSTALL_DIR:-"$HOME/.local/bin"}
DESTINATION="$INSTALL_DIR/ollama-watch"
ZSHRC="$HOME/.zshrc"
START_MARKER='# >>> ollama-watch >>>'
END_MARKER='# <<< ollama-watch <<<'

if [ -e "$DESTINATION" ] || [ -L "$DESTINATION" ]; then
    rm -f "$DESTINATION"
fi

if [ -f "$ZSHRC" ] && grep -Fx -- "$START_MARKER" "$ZSHRC" >/dev/null 2>&1; then
    TEMP_FILE=$(mktemp "$ZSHRC.ollama-watch.XXXXXX")
    cleanup_temp() {
        rm -f "$TEMP_FILE"
    }
    trap cleanup_temp EXIT HUP INT TERM

    awk -v start="$START_MARKER" -v end="$END_MARKER" '
        $0 == start { managed = 1; next }
        managed && $0 == end { managed = 0; next }
        !managed { print }
    ' "$ZSHRC" > "$TEMP_FILE"

    if file_mode=$(stat -f '%Lp' "$ZSHRC" 2>/dev/null); then
        chmod "$file_mode" "$TEMP_FILE"
    fi
    mv "$TEMP_FILE" "$ZSHRC"
    trap - EXIT HUP INT TERM
fi

printf 'Uninstalled ollama-watch from %s\n' "$DESTINATION"
