source "$ROOT_DIR/debian/modules/core.sh"

test_ok "require_command finds sh" require_command sh
test_not_ok "require_command rejects missing command" require_command hostkit-command-that-does-not-exist
