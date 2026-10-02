source "$ROOT_DIR/debian/modules/timezone.sh"

test_ok "UTC timezone exists" timezone_validate UTC
test_not_ok "missing timezone rejected" timezone_validate HostKit/Nowhere
test_not_ok "absolute path rejected" timezone_validate /etc/passwd
test_not_ok "parent traversal rejected" timezone_validate ../../etc/passwd
test_not_ok "embedded traversal rejected" timezone_validate Europe/../UTC
test_not_ok "backslash rejected" timezone_validate 'Europe\\London'
