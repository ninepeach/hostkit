source "$ROOT_DIR/debian/modules/locale.sh"

test_ok "normal locale name" locale_validate_name en_US.UTF-8
test_ok "locale modifier" locale_validate_name ja_JP.UTF-8
test_not_ok "empty locale rejected" locale_validate_name ""
test_not_ok "shell characters rejected" locale_validate_name 'en_US;id'
