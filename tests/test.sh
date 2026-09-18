#!/bin/sh
set -u

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
LAUNCHER="$ROOT_DIR/bin/ollama-watch"
INSTALLER="$ROOT_DIR/install.sh"
UNINSTALLER="$ROOT_DIR/uninstall.sh"
TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/ollama-watch-tests.XXXXXX")
STUB_BIN="$TEST_TMP/bin"
CALL_LOG="$TEST_TMP/calls.log"
FAILURES=0
TESTS=0

cleanup() {
    rm -rf "$TEST_TMP"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$STUB_BIN"
: > "$CALL_LOG"

cat > "$STUB_BIN/ollama" <<'STUB'
#!/bin/sh
if [ "${1:-}" = "list" ]; then
    printf '%s\n' 'NAME ID SIZE MODIFIED'
    for model in ${STUB_MODELS:-qwen3.5:9b}; do
        printf '%s\n' "$model stub-id 6.6GB now"
    done
    exit 0
fi
printf 'ollama %s\n' "$*" >> "$CALL_LOG"
STUB

cat > "$STUB_BIN/tmux" <<'STUB'
#!/bin/sh
printf 'tmux %s\n' "$*" >> "$CALL_LOG"
case " ${*} " in
    *' split-window '*)
        case " ${*} " in
            *' -P '*) printf '%s\n' '%stub-pane' ;;
        esac
        ;;
esac
STUB

cat > "$STUB_BIN/macmon" <<'STUB'
#!/bin/sh
printf 'macmon %s\n' "$*" >> "$CALL_LOG"
STUB

chmod +x "$STUB_BIN/ollama" "$STUB_BIN/tmux" "$STUB_BIN/macmon"

export CALL_LOG
export PATH="$STUB_BIN:/usr/bin:/bin"

pass() {
    TESTS=$((TESTS + 1))
    printf 'ok %s - %s\n' "$TESTS" "$1"
}

fail() {
    TESTS=$((TESTS + 1))
    FAILURES=$((FAILURES + 1))
    printf 'not ok %s - %s\n' "$TESTS" "$1" >&2
}

assert_contains() {
    description=$1
    needle=$2
    haystack=$3
    case "$haystack" in
        *"$needle"*) pass "$description" ;;
        *)
            fail "$description"
            printf '  expected output to contain: %s\n  actual: %s\n' "$needle" "$haystack" >&2
            ;;
    esac
}

assert_status() {
    description=$1
    expected=$2
    shift 2
    LAST_OUTPUT=$($@ 2>&1)
    LAST_STATUS=$?
    if [ "$LAST_STATUS" -eq "$expected" ]; then
        pass "$description"
    else
        fail "$description"
        printf '  expected status: %s\n  actual status: %s\n  output: %s\n' \
            "$expected" "$LAST_STATUS" "$LAST_OUTPUT" >&2
    fi
}

assert_log_contains() {
    description=$1
    needle=$2
    if grep -F -- "$needle" "$CALL_LOG" >/dev/null 2>&1; then
        pass "$description"
    else
        fail "$description"
        printf '  expected call log to contain: %s\n' "$needle" >&2
        sed 's/^/  /' "$CALL_LOG" >&2
    fi
}

assert_equals() {
    description=$1
    expected=$2
    actual=$3
    if [ "$actual" = "$expected" ]; then
        pass "$description"
    else
        fail "$description"
        printf '  expected: %s\n  actual: %s\n' "$expected" "$actual" >&2
    fi
}

assert_executable() {
    description=$1
    path=$2
    if [ -x "$path" ]; then
        pass "$description"
    else
        fail "$description"
        printf '  expected executable: %s\n' "$path" >&2
    fi
}

assert_absent() {
    description=$1
    path=$2
    if [ ! -e "$path" ]; then
        pass "$description"
    else
        fail "$description"
        printf '  expected path to be absent: %s\n' "$path" >&2
    fi
}

help_output=$($LAUNCHER --help 2>&1)
assert_contains 'help documents the command' 'Usage: ollama-watch [model]' "$help_output"

assert_status 'missing model is rejected' 1 env STUB_MODELS='qwen3.5:9b' "$LAUNCHER" missing:model
assert_contains 'missing model error names the model' 'Model is not installed: missing:model' "$LAST_OUTPUT"

: > "$CALL_LOG"
assert_status 'installed model launches successfully' 0 env STUB_MODELS='qwen3.5:9b' "$LAUNCHER" qwen3.5:9b
assert_log_contains 'detached session uses a unique prefix' 'tmux new-session -d -s ollama-watch-'
assert_log_contains 'layout creates a right column' 'tmux split-window -h -p 35'
assert_log_contains 'resource pane starts macmon' 'macmon'
assert_log_contains 'status pane polls ollama ps' 'ollama ps'
assert_log_contains 'outside tmux the session is attached' 'tmux attach-session -t ollama-watch-'

TEST_HOME="$TEST_TMP/home"
INSTALL_DIR="$TEST_HOME/.local/bin"
mkdir -p "$TEST_HOME"
printf '%s\n' 'export KEEP_THIS_LINE=1' > "$TEST_HOME/.zshrc"

assert_status 'first install succeeds' 0 env HOME="$TEST_HOME" OLLAMA_WATCH_INSTALL_DIR="$INSTALL_DIR" "$INSTALLER"
assert_status 'second install is idempotent' 0 env HOME="$TEST_HOME" OLLAMA_WATCH_INSTALL_DIR="$INSTALL_DIR" "$INSTALLER"
assert_executable 'installer creates an executable launcher' "$INSTALL_DIR/ollama-watch"
marker_count=$(grep -c '^# >>> ollama-watch >>>$' "$TEST_HOME/.zshrc" 2>/dev/null || true)
assert_equals 'installer writes one PATH block' 1 "$marker_count"
preserved_count=$(grep -c '^export KEEP_THIS_LINE=1$' "$TEST_HOME/.zshrc" 2>/dev/null || true)
assert_equals 'installer preserves existing zsh configuration' 1 "$preserved_count"

assert_status 'first uninstall succeeds' 0 env HOME="$TEST_HOME" OLLAMA_WATCH_INSTALL_DIR="$INSTALL_DIR" "$UNINSTALLER"
assert_status 'second uninstall is idempotent' 0 env HOME="$TEST_HOME" OLLAMA_WATCH_INSTALL_DIR="$INSTALL_DIR" "$UNINSTALLER"
assert_absent 'uninstaller removes only the installed launcher' "$INSTALL_DIR/ollama-watch"
marker_count=$(grep -c '^# >>> ollama-watch >>>$' "$TEST_HOME/.zshrc" 2>/dev/null || true)
assert_equals 'uninstaller removes the managed PATH block' 0 "$marker_count"
preserved_count=$(grep -c '^export KEEP_THIS_LINE=1$' "$TEST_HOME/.zshrc" 2>/dev/null || true)
assert_equals 'uninstaller preserves unrelated zsh configuration' 1 "$preserved_count"

if [ "$FAILURES" -ne 0 ]; then
    printf '%s of %s tests failed\n' "$FAILURES" "$TESTS" >&2
    exit 1
fi

printf 'all %s tests passed\n' "$TESTS"
