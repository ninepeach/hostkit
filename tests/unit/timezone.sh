source "$ROOT_DIR/debian/modules/timezone.sh"

test_ok "UTC timezone exists" timezone_validate UTC
test_not_ok "missing timezone rejected" timezone_validate HostKit/Nowhere
