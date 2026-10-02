source "$ROOT_DIR/debian/modules/pppoe.sh"

test_ok "normal PPPoE user" pppoe_validate_user user@example.com
test_not_ok "empty PPPoE user rejected" pppoe_validate_user ""
