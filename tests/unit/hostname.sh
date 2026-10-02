source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/hostname.sh"

test_ok "simple hostname" hostname_validate host01
test_ok "FQDN hostname" hostname_validate host01.example
test_not_ok "empty hostname rejected" hostname_validate ""
test_not_ok "leading dot rejected" hostname_validate .bad
test_not_ok "double dot rejected" hostname_validate bad..name

test_not_ok "leading hyphen rejected" hostname_validate -bad
test_not_ok "trailing hyphen rejected" hostname_validate bad-
test_not_ok "overlong label rejected" hostname_validate aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
