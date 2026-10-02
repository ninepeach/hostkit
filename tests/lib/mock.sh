# PATH-based command mocking for HostKit unit tests.

mock_begin() {
    HOSTKIT_MOCK_DIR="$(mktemp -d)"
    HOSTKIT_ORIGINAL_PATH="$PATH"
    PATH="$HOSTKIT_MOCK_DIR:$PATH"
    export PATH HOSTKIT_MOCK_DIR HOSTKIT_ORIGINAL_PATH
}

mock_command() {
    local name="$1"
    shift
    cat >"$HOSTKIT_MOCK_DIR/$name" <<EOF
#!/usr/bin/env bash
$*
EOF
    chmod +x "$HOSTKIT_MOCK_DIR/$name"
}

mock_end() {
    PATH="$HOSTKIT_ORIGINAL_PATH"
    export PATH
    rm -rf "$HOSTKIT_MOCK_DIR"
    unset HOSTKIT_MOCK_DIR HOSTKIT_ORIGINAL_PATH
}
