source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/user.sh"

test_ok "normal user" user_validate_name admin
test_ok "hyphenated user" user_validate_name ops-user
test_not_ok "uppercase user rejected" user_validate_name Root
test_not_ok "space rejected" user_validate_name "bad user"
