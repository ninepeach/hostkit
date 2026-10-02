source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/limits.sh"

test_not_ok "non-numeric nofile rejected" limits_configure_nofile invalid
test_not_ok "low nofile rejected" limits_configure_nofile 100
