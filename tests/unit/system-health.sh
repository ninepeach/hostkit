source "$ROOT_DIR/debian/modules/system-health.sh"

test_ok "free-space reader returns numeric value" test "$(health_root_free_kb)" -gt 0
