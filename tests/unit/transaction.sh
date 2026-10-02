source "$ROOT_DIR/debian/modules/transaction.sh"

test_ok "default timeout" transaction_validate_timeout 180
test_ok "minimum timeout" transaction_validate_timeout 30
test_ok "maximum timeout" transaction_validate_timeout 3600
test_not_ok "too-short timeout rejected" transaction_validate_timeout 10
test_not_ok "too-long timeout rejected" transaction_validate_timeout 3601
test_not_ok "non-numeric timeout rejected" transaction_validate_timeout abc
